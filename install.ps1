# ==============================================================================
# awesome-agentic-stack -- Smart Windows Installer (v2)
# Idempotent, stateful, parallel, self-healing
# ==============================================================================

param (
    [switch]$Essential,
    [switch]$Interactive,
    [switch]$Yes,
    [switch]$List,
    [switch]$DryRun,
    [switch]$Resume
)

$ErrorActionPreference = "Stop"

function Write-Color { param([string]$Text,[string]$Color) Write-Host $Text -ForegroundColor $Color }

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$ConfigDir  = "$env:USERPROFILE\.config\awesome-agentic-stack"
$StateFile  = "$ConfigDir\install-state.json"
$TempDir    = "$env:TEMP\awesome-agentic-stack-install"
$SkillPaths = @(
    "$env:USERPROFILE\.claude\skills",
    "$env:USERPROFILE\.config\opencode\skills",
    "$env:USERPROFILE\.gemini\antigravity\skills",
    "$env:USERPROFILE\.agent\skills"
)

# ---------------------------------------------------------------------------
# Exponential backoff with jitter
# ---------------------------------------------------------------------------
function Backoff-Sleep {
    param([int]$attempt)
    $base = [Math]::Pow(2, $attempt) * 1000
    $jitter = Get-Random -Minimum 0 -Maximum 500
    $ms = [Math]::Min($base + $jitter, 30000)
    Start-Sleep -Milliseconds $ms
}

# ---------------------------------------------------------------------------
# State machine helpers
# ---------------------------------------------------------------------------
function Read-State {
    if (Test-Path $StateFile) {
        try { return Get-Content -Raw -Path $StateFile | ConvertFrom-Json } catch {}
    }
    return $null
}

function Write-State {
    param($State)
    $dir = Split-Path $StateFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $State | ConvertTo-Json -Depth 3 | Set-Content -Path $StateFile -Force
}

function New-State {
    return [PSCustomObject]@{
        version         = "2"
        started_at      = (Get-Date -Format "o")
        phase           = "cli"
        cli_completed   = @()
        cli_failed      = @()
        cli_skipped     = @()
        skills_completed = @()
        skills_failed   = @()
        skills_skipped  = @()
    }
}

# ---------------------------------------------------------------------------
# Manifest validation
# ---------------------------------------------------------------------------
function Validate-Manifest {
    param($Manifest)
    $errors = @()
    if (-not $Manifest.cli_binaries) { $errors += "Missing cli_binaries" }
    if (-not $Manifest.skills)       { $errors += "Missing skills" }
    foreach ($cli in $Manifest.cli_binaries) {
        if (-not $cli.name)  { $errors += "CLI entry missing name" }
        if (-not $cli.binary){ $errors += "CLI '$($cli.name)' missing binary" }
    }
    foreach ($s in $Manifest.skills) {
        if (-not $s.repo) { $errors += "Skill entry missing repo" }
        if (-not $s.name) { $errors += "Skill entry missing name" }
    }
    if ($errors.Count -gt 0) {
        Write-Color "  [-] Manifest schema errors:" "Red"
        foreach ($e in $errors) { Write-Color "    - $e" "Red" }
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Dependency resolver (topological sort)
# ---------------------------------------------------------------------------
function Resolve-Order {
    param($Items, $NameField)
    $sorted = @()
    $visited = @{}
    $byName = @{}
    foreach ($item in $Items) { $byName[$item.$NameField] = $item }

    function Visit($name, $path) {
        if ($visited[$name] -eq "visiting") { throw "Circular dependency: $($path -join ' -> ')" }
        if ($visited[$name] -eq "done") { return }
        $visited[$name] = "visiting"
        $item = $byName[$name]
        if ($item -and $item.depends_on) {
            foreach ($dep in $item.depends_on) {
                if ($dep -and $dep -ne "") {
                    Visit $dep ($path + $name)
                }
            }
        }
        $visited[$name] = "done"
        $sorted += $name
    }

    foreach ($item in $Items) {
        if (-not $visited[$item.$NameField]) { Visit $item.$NameField @() }
    }
    return $sorted
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
Write-Color "======================================================================" "Cyan"
Write-Color "[stack] awesome-agentic-stack - Smart Windows Installer (v2)" "White"
Write-Color "======================================================================" "Cyan"
Write-Host ""

# ---------------------------------------------------------------------------
# Load manifest
# ---------------------------------------------------------------------------
$ManifestPath = Join-Path $PSScriptRoot "scripts\manifest.json"
if (-not (Test-Path $ManifestPath)) {
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $ManifestPath = Join-Path $TempDir "manifest.json"
    Write-Color "  [+] Fetching repository manifest.json..." "Yellow"
    $fetched = $false
    for ($i = 1; $i -le 3; $i++) {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AkashPriyadarshii/awesome-agentic-stack/main/scripts/manifest.json" -OutFile $ManifestPath -TimeoutSec 10
        if ($?) { $fetched = $true; break }
        Write-Color "  [!] Download failed. Retrying... ($i/3)" "Yellow"
        Start-Sleep -Seconds 2
    }
    if (-not $fetched) { Write-Color "  [-] Network error: Failed to fetch manifest.json. Verify network." "Red"; exit 1 }
} else {
    Write-Color "  [+] Using local manifest.json" "Gray"
}
$Manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json
Validate-Manifest $Manifest

# List mode
if ($List) {
    Write-Color "=== CURATED TOOL LIST ($($Manifest.cli_binaries.Count + $Manifest.skills.Count + $Manifest.references.Count) repos) ===" "White"
    Write-Host ""; Write-Color "[CLI Binaries]" "Yellow"
    foreach ($cli in $Manifest.cli_binaries) { Write-Host ("  - " + $cli.name + " (bin: " + $cli.binary + ")") }
    Write-Host ""; Write-Color "[Agent Skill Repos]" "Yellow"
    foreach ($skill in $Manifest.skills) { Write-Host ("  - " + $skill.name + " (repo: " + $skill.repo + ")") }
    Write-Host ""; Write-Color "[Reference Blueprints]" "Yellow"
    foreach ($ref in $Manifest.references) { Write-Host ("  - " + $ref.name + ": " + $ref.url) }
    exit 0
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
Write-Color "[1/5] Running Pre-Flight checks..." "White"

$WingetAvailable = [bool](Get-Command "winget" -ErrorAction SilentlyContinue)
$HasPip  = [bool](Get-Command "pip" -ErrorAction SilentlyContinue)
$HasGo   = [bool](Get-Command "go" -ErrorAction SilentlyContinue)
$HasCargo= [bool](Get-Command "cargo" -ErrorAction SilentlyContinue)
$HasCurl = [bool](Get-Command "curl" -ErrorAction SilentlyContinue)

$Deps = @("git","node","npm"); $MissingDeps = @()
foreach ($dep in $Deps) {
    if (Get-Command $dep -ErrorAction SilentlyContinue) {
        Write-Color ("  [+] Dependency ${dep}: Installed") "Green"
    } else {
        Write-Color ("  [-] Dependency ${dep}: Missing") "Red"; $MissingDeps += $dep
    }
}

$AvailableMethods = @()
if ($WingetAvailable) { $AvailableMethods += "winget" }
if ($HasPip)  { $AvailableMethods += "pip" }
if ($HasGo)   { $AvailableMethods += "go" }
if ($HasCargo){ $AvailableMethods += "cargo" }
if ($HasCurl) { $AvailableMethods += "curl" }
$AvailableMethods += "npm"; $AvailableMethods += "git"
Write-Color "  [+] Available methods: $($AvailableMethods -join ', ')" "Gray"

if ($MissingDeps.Count -gt 0) {
    Write-Host ""; Write-Color "[!] SYSTEM READINESS REPORT:" "Yellow"
    foreach ($m in $MissingDeps) {
        switch ($m) {
            "git"  { Write-Color "    git  -> https://git-scm.com/download/win" "Cyan" }
            "node" { Write-Color "    node -> https://nodejs.org (includes npm)" "Cyan" }
            "npm"  { Write-Color "    npm  -> bundled with Node.js" "Cyan" }
        }
    }
}

# Load or create state
$State = if ($Resume) { Read-State } else { $null }
if (-not $State) { $State = New-State }

# ---------------------------------------------------------------------------
# Setup directories
# ---------------------------------------------------------------------------
Write-Host ""; Write-Color "[2/5] Structuring global agent skill environments..." "White"
foreach ($path in $SkillPaths) {
    if ($DryRun) { Write-Color "  [dry-run] mkdir -p $path" "Gray"; continue }
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
    Write-Color "  [+] Path: $path" "Gray"
}

# ---------------------------------------------------------------------------
# CLI Installer
# ---------------------------------------------------------------------------
Write-Host ""; Write-Color "[3/5] Starting curation compilation..." "White"

function Install-CLI {
    param(
        [string]$name, [string]$binary,
        [string]$winget_pkg, [string]$npm_pkg, [string]$pip_pkg,
        [string]$go_pkg, [string]$cargo_pkg, [string]$zip_windows,
        [string]$check_winget_list, [string]$platform_skip
    )
    if ($DryRun) { Write-Color "  [dry-run] Installing CLI: $name" "Gray"; return $true }

    # Platform skip
    if ($platform_skip -and $platform_skip.Contains("win32")) {
        Write-Color "  [/] $name is not available on Windows. Skipping." "Yellow"
        $global:SkipList += $name; return $true
    }
    # Already installed
    if (Get-Command $binary -ErrorAction SilentlyContinue) {
        Write-Color "  [+] $name is already installed." "Gray"
        return $true
    }
    # winget list pre-check
    if ($check_winget_list -eq "true" -and $WingetAvailable) {
        $wl = winget list --name $name --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and $wl -match $name) {
            Write-Color "  [+] $name already installed (winget list confirms)." "Gray"; return $true
        }
    }

    $attempted = @()

    # 1) winget
    if ($WingetAvailable -and $winget_pkg -and $winget_pkg -ne "") {
        $attempted += "winget"
        Write-Color "  [+] Installing via winget: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            winget install --id $winget_pkg --silent --accept-source-agreements --accept-package-agreements 2>$null
            if ($?) { return $true }
            if ($i -lt 3) { Write-Color "  [!] winget install failed. Retrying... ($i/3)" "Yellow"; Backoff-Sleep $i }
        }
    }
    # 2) npm
    if ($npm_pkg -and $npm_pkg -ne "" -and $npm_pkg -ne "null") {
        $attempted += "npm"
        Write-Color "  [+] Installing via npm: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            npm install -g $npm_pkg --silent 2>$null
            if ($?) { return $true }
            if ($i -lt 3) { Write-Color "  [!] npm install failed. Retrying... ($i/3)" "Yellow"; Backoff-Sleep $i }
        }
    }
    # 3) pip
    if ($pip_pkg -and $pip_pkg -ne "" -and $pip_pkg -ne "null" -and $HasPip) {
        $attempted += "pip"
        Write-Color "  [+] Installing via pip: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            pip install --user $pip_pkg 2>$null
            if ($?) { return $true }
            if ($i -lt 3) { Write-Color "  [!] pip install failed. Retrying... ($i/3)" "Yellow"; Backoff-Sleep $i }
        }
    }
    # 4) go install
    if ($go_pkg -and $go_pkg -ne "" -and $HasGo) {
        $attempted += "go"
        Write-Color "  [+] Installing via go install: $name" "Yellow"
        go install $go_pkg 2>$null
        if ($?) {
            $goBin = "$env:USERPROFILE\go\bin\$binary.exe"
            if (Test-Path $goBin) {
                $localBin = "$env:USERPROFILE\.local\bin"
                if (-not (Test-Path $localBin)) { New-Item -ItemType Directory -Path $localBin -Force | Out-Null }
                Copy-Item -Path $goBin -Destination "$localBin\$binary.exe" -Force
            }
            return $true
        }
        Write-Color "  [!] go install failed." "Yellow"
    }
    # 5) cargo
    if ($cargo_pkg -and $cargo_pkg -ne "" -and $HasCargo) {
        $attempted += "cargo"
        Write-Color "  [+] Installing via cargo: $name" "Yellow"
        cargo install $cargo_pkg 2>$null
        if ($?) { return $true }
        Write-Color "  [!] cargo install failed." "Yellow"
    }
    # 6) zip download
    if ($zip_windows -and $zip_windows -ne "" -and $HasCurl) {
        $attempted += "zip"
        Write-Color "  [+] Attempting direct download for $name..." "Yellow"
        $z = "$TempDir\$name.zip"; $ex = "$TempDir\${name}_extracted"
        for ($i = 1; $i -le 3; $i++) {
            Invoke-WebRequest -Uri $zip_windows -OutFile $z -TimeoutSec 15 2>$null
            if ($?) { break }
            if ($i -lt 3) { Write-Color "  [!] Download failed. Retrying... ($i/3)" "Yellow"; Backoff-Sleep $i }
        }
        if (Test-Path $z) {
            Expand-Archive -Path $z -DestinationPath $ex -Force 2>$null
            $found = Get-ChildItem -Path $ex -Recurse -Filter "$binary.exe" | Select-Object -First 1
            if (-not $found) { $found = Get-ChildItem -Path $ex -Recurse -Filter "*.exe" | Select-Object -First 1 }
            if ($found) {
                $lb = "$env:USERPROFILE\.local\bin"
                if (-not (Test-Path $lb)) { New-Item -ItemType Directory -Path $lb -Force | Out-Null }
                Copy-Item -Path $found.FullName -Destination "$lb\$binary.exe" -Force
                return $true
            }
        }
    }

    Write-Color "  [-] Failed to install: $name" "Red"
    $global:FailList += @{name=$name; attempted=$attempted}
    return $false
}

# Resolve dependency order for CLI binaries
$cliOrder = Resolve-Order -Items $Manifest.cli_binaries -NameField "name"
$cliMap = @{}; foreach ($c in $Manifest.cli_binaries) { $cliMap[$c.name] = $c }

foreach ($name in $cliOrder) {
    $cli = $cliMap[$name]; if (-not $cli) { continue }
    if ($Essential -and -not $cli.essential) { $SkipList += $name; continue }
    if ($Interactive) { if (-not (Ask-Confirm "CLI component $name")) { $SkipList += $name; continue } }

    # Check state (resume support)
    if ($Resume -and $State.cli_completed -contains $name) { continue }
    if ($Resume -and $State.cli_skipped -contains $name) { $SkipList += $name; continue }

    $ok = Install-CLI -name $name -binary $cli.binary -winget_pkg $cli.winget -npm_pkg $cli.npm -pip_pkg $cli.pip -go_pkg $cli.go_install -cargo_pkg $cli.cargo_install -zip_windows $cli.zip_url_windows -check_winget_list $cli.check_winget_list -platform_skip $cli.platform_skip
    if ($ok) { $State.cli_completed += $name } else { $State.cli_failed += $name }
    Write-State $State
}

# ---------------------------------------------------------------------------
# Skill Repository Cloner (Parallel)
# ---------------------------------------------------------------------------
Write-Host ""; Write-Color "[4/5] Syncing agent skill blueprints..." "White"

function Clone-Skill {
    param([string]$repo, [string]$name, [string[]]$skillPaths, [bool]$isDryRun)
    if ($isDryRun) { return $true }

    # Idempotency: check if already deployed to any skill path
    $repoDir = $repo -replace '^([^/]+)/(.+)$', '$2'
    $found = $false
    foreach ($p in $skillPaths) {
        if ((Test-Path (Join-Path $p $repoDir)) -or (Test-Path (Join-Path $p $name))) { $found = $true; break }
    }
    if ($found) { return $true }

    Write-Host "  [+] Syncing skill: $name..."
    $localTmp = "$env:TEMP\awesome-agentic-stack-install"
    $dest_dir = "$localTmp\skills\$name"
    if (Test-Path $dest_dir) { Remove-Item -Recurse -Force -LiteralPath $dest_dir }

    $cloned = $false; $repo_url = "https://github.com/$repo.git"
    for ($i = 1; $i -le 3; $i++) {
        git clone --depth 1 $repo_url $dest_dir --quiet
        if ($?) { $cloned = $true; break }
        if ($i -lt 3) { Write-Host "  [!] git clone failed. Retrying... ($i/3)"; Start-Sleep -Seconds $([Math]::Min([Math]::Pow(2,$i),30)) }
    }

    if ($cloned -and (Test-Path $dest_dir)) {
        foreach ($p in $skillPaths) {
            if (Test-Path $p) { Copy-Item -Path "$dest_dir\*" -Destination $p -Recurse -Force -ErrorAction SilentlyContinue }
        }
        return $true
    }

    # Zip fallback
    Write-Host "    [!] Git clone failed. Attempting zip fallback..."
    $z = "$localTmp\$name.zip"; $zx = "$localTmp\${name}_extracted"
    for ($i = 1; $i -le 3; $i++) {
        Invoke-WebRequest -Uri "https://github.com/$repo/archive/refs/heads/main.zip" -OutFile $z -TimeoutSec 10
        if ($?) { break }
        if ($i -lt 3) { Write-Host "  [!] Zip download failed. Retrying... ($i/3)"; Start-Sleep -Seconds $([Math]::Min([Math]::Pow(2,$i),30)) }
    }
    if (Test-Path $z) {
        Expand-Archive -Path $z -DestinationPath $zx -Force
        $sub = Get-ChildItem -Path $zx | Select-Object -First 1
        if ($sub) {
            foreach ($p in $skillPaths) {
                if (Test-Path $p) { Copy-Item -Path "$($sub.FullName)\*" -Destination $p -Recurse -Force -ErrorAction SilentlyContinue }
            }
            return $true
        }
    }
    return $false
}

# Run skill clones in parallel with max 4 concurrency
$skillQueue = New-Object System.Collections.Queue
$skillFiltered = @()
foreach ($skill in $Manifest.skills) {
    if ($Essential -and -not $skill.essential) { $State.skills_skipped += $skill.name; continue }
    if ($Interactive) { if (-not (Ask-Confirm "Skill clone $($skill.name)")) { $State.skills_skipped += $skill.name; continue } }
    if ($Resume) {
        if ($State.skills_completed -contains $skill.name) { continue }
        if ($State.skills_skipped -contains $skill.name) { continue }
    }
    $skillFiltered += $skill
}

# Idempotency pre-check: add to completed if already deployed
$stillNeed = @()
foreach ($sk in $skillFiltered) {
    $rd = $sk.repo -replace '^([^/]+)/(.+)$', '$2'
    $found = $false
    foreach ($p in $SkillPaths) {
        if ((Test-Path (Join-Path $p $rd)) -or (Test-Path (Join-Path $p $sk.name))) { $found = $true; break }
    }
    if ($found) {
        $State.skills_completed += $sk.name
        Write-Color "  [+] $($sk.name) already deployed. Skipping." "Gray"
    } else {
        $stillNeed += $sk
    }
}
Write-State $State

$maxConcurrency = 4
$running = @{}
$idx = 0
while ($idx -lt $stillNeed.Count -or $running.Count -gt 0) {
    while ($running.Count -lt $maxConcurrency -and $idx -lt $stillNeed.Count) {
        $sk = $stillNeed[$idx]; $idx++
        $job = Start-Job -ScriptBlock ${function:Clone-Skill} -ArgumentList @($sk.repo, $sk.name, $SkillPaths, $DryRun)
        $running[$job.Id] = $sk
    }
    if ($running.Count -gt 0) {
        $done = Wait-Job -Job ($running.Keys | ForEach-Object { Get-Job -Id $_ }) -Timeout 300 2>$null
        foreach ($job in $done) {
            $sk = $running[$job.Id]; $running.Remove($job.Id)
            $ok = Receive-Job -Job $job
            if ($ok) { $State.skills_completed += $sk.name } else { $State.skills_failed += $sk.name }
            Remove-Job -Job $job -Force
            Write-State $State
        }
    }
}

# ---------------------------------------------------------------------------
# Config templates
# ---------------------------------------------------------------------------
Write-Host ""; Write-Color "[5/5] Deploying context template files..." "White"
$TemplateDir = "$env:USERPROFILE\.config\awesome-agentic-stack\templates"
if ($DryRun) {
    Write-Color "  [dry-run] mkdir -p $TemplateDir" "Gray"
} else {
    if (-not (Test-Path $TemplateDir)) { New-Item -ItemType Directory -Path $TemplateDir -Force | Out-Null }
    foreach ($tmpl in $Manifest.templates) {
        $src = Join-Path $PSScriptRoot $tmpl
        if (Test-Path $src) { Copy-Item -Path $src -Destination $TemplateDir -Force }
    }
}

# ---------------------------------------------------------------------------
# PATH Self-Heal
# ---------------------------------------------------------------------------
$PathsNeeded = @(
    "$env:USERPROFILE\.local\bin",
    "$env:USERPROFILE\AppData\Roaming\Python\Python314\Scripts",
    "$env:USERPROFILE\AppData\Roaming\npm",
    "$env:USERPROFILE\go\bin"
)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$changed = $false
foreach ($p in $PathsNeeded) {
    if (Test-Path $p -and $currentPath -notlike "*$p*") {
        $currentPath = "$p;$currentPath"
        $changed = $true
    }
}
if ($changed) {
    [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
    $env:Path = "$currentPath;$env:Path"
    Write-Color "  [+] PATH updated with tool directories (no restart needed)." "Green"
}

# ---------------------------------------------------------------------------
# Final Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Color "======================================================================" "Cyan"
Write-Color "[REPORT] COMPILATION COMPLETED - SYSTEM VERIFICATION REPORT" "White"
Write-Color "======================================================================" "Cyan"
Write-Host ""

$success = ($State.cli_completed | Select-Object -Unique).Count + ($State.skills_completed | Select-Object -Unique).Count
$skipped = ($State.cli_skipped | Select-Object -Unique).Count + ($State.skills_skipped | Select-Object -Unique).Count
$failed = ($State.cli_failed | Select-Object -Unique).Count + ($State.skills_failed | Select-Object -Unique).Count

Write-Color "Curation Summary:" "White"
Write-Color "  Installed successfully: $success" "Green"
Write-Color "  Skipped/Declined:       $skipped" "Yellow"
Write-Color "  Failed installations:   $failed" "Red"
Write-Host ""

if ($State.cli_failed.Count -gt 0 -or $State.skills_failed.Count -gt 0) {
    Write-Color "Failed Components (Requires Manual Review):" "Red"
    foreach ($n in ($State.cli_failed + $State.skills_failed | Select-Object -Unique)) { Write-Color "  - $n" "Red" }
    Write-Host ""
    Write-Color "[*] HOW TO FIX FAILED COMPONENTS:" "Yellow"

    # Data-driven failure advice from manifest
    foreach ($f in ($State.cli_failed | Select-Object -Unique)) {
        $entry = $Manifest.cli_binaries | Where-Object { $_.name -eq $f }
        if ($entry -and $entry.fail_advice) {
            Write-Color "  $($entry.name) ($($entry.binary)):" "White"
            foreach ($a in $entry.fail_advice) { Write-Color "    $a" "Cyan" }
        }
    }
    foreach ($f in ($State.skills_failed | Select-Object -Unique)) {
        Write-Color ("  ${f}:") "White"
        Write-Color "    git clone the repo manually and copy SKILL.md to your skills dir" "Cyan"
    }
    Write-Host ""
}

# Save final state
$State.phase = "done"
Write-State $State

# Path check
Write-Color "Checking Path Integration..." "White"
$CheckCLIs = @("repomix", "openskills", "rg", "gitleaks")
$pathOK = $true
foreach ($cli in $CheckCLIs) {
    if (Get-Command $cli -ErrorAction SilentlyContinue) {
        Write-Color "  [yes] $cli : Functional" "Green"
    } else {
        Write-Color "  [no]  $cli : Missing or requires shell restart" "Red"; $pathOK = $false
    }
}
if (-not $pathOK) {
    Write-Host ""
    Write-Color "Action Required to Complete Setup:" "Yellow"
    Write-Color "Some binaries were installed but are not yet loaded in your shell path."
    Write-Color "Please close this PowerShell window and open a new one to refresh PATH." "Yellow"
}

Write-Host ""
Write-Color "[*] REFERENCE BLUEPRINTS (Bookmark These!):" "White"
foreach ($ref in $Manifest.references) {
    Write-Color "  - $($ref.name): $($ref.url)" "Cyan"
}
Write-Host ""
Write-Color "[+] Setup complete! Your workspace has been compiled." "Green"
Write-Color "======================================================================" "Cyan"
