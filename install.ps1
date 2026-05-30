# ==============================================================================
# awesome-agentic-stack -- Robust Windows 11 PowerShell Installer
# Curated by Akash Priyadarshi (Mac M5 + GT7 Windows Curation Stack)
# ==============================================================================

param (
    [switch]$Essential,
    [switch]$Interactive,
    [switch]$Yes,
    [switch]$List,
    [switch]$DryRun,
    [switch]$Resume
)

$ErrorActionPreference = "SilentlyContinue"

# Text Colors helper
function Write-Color {
    param(
        [string]$Text,
        [string]$Color
    )
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "======================================================================" "Cyan"
Write-Color "[stack] awesome-agentic-stack - Robust Windows 11 Installer" "White"
Write-Color "======================================================================" "Cyan"
Write-Host ""

# System paths
$TempDir = "$env:TEMP\awesome-agentic-stack-install"
$SkillPaths = @(
    "$env:USERPROFILE\.claude\skills",
    "$env:USERPROFILE\.config\opencode\skills",
    "$env:USERPROFILE\.gemini\antigravity\skills",
    "$env:USERPROFILE\.agent\skills"
)

$SuccessList = @()
$FailList = @()  # Array of hashtables: @{name="x"; attempted=@("winget","npm")}
$SkipList = @()

# ------------------------------------------------------------------------------
# Robust Helper Utilities
# ------------------------------------------------------------------------------
function Check-Command {
    param(
        [string]$cmd
    )
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Ask-Confirm {
    param(
        [string]$name
    )
    if ($Yes) { return $true }
    $choice = Read-Host "  [?] Proceed with $name? (y/n)"
    return ($choice -eq "y" -or $choice -eq "Y")
}

# ------------------------------------------------------------------------------
# Pre-Flight OS & Dependency Checks
# ------------------------------------------------------------------------------
Write-Color "[1/5] Running Pre-Flight checks..." "White"

# Load local manifest or fetch it
$ManifestPath = $PSScriptRoot + "\scripts\manifest.json"
if (-not (Test-Path $ManifestPath)) {
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $ManifestPath = $TempDir + "\manifest.json"
    Write-Color "  [+] Fetching repository manifest.json..." "Yellow"
    $ManifestUrl = "https://raw.githubusercontent.com/AkashPriyadarshii/awesome-agentic-stack/main/scripts/manifest.json"
    
    # Inline retry for manifest download
    $fetched = $false
    for ($i = 1; $i -le 3; $i++) {
        Invoke-WebRequest -Uri $ManifestUrl -OutFile $ManifestPath -TimeoutSec 10
        if ($?) {
            $fetched = $true
            break
        }
        Write-Color "  [!] Download failed. Retrying... ($i/3)" "Yellow"
        Start-Sleep -Seconds 2
    }

    if (-not $fetched) {
        Write-Color "  [-] Network error: Failed to fetch manifest.json. Verify network." "Red"
        exit 1
    }
} else {
    Write-Color "  [+] Using local manifest.json" "Gray"
}

# Parse manifest json safely
$Manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json

# If -List is requested, print the manifest and exit
if ($List) {
    Write-Color "=== CURATED TOOL LIST (96 repos) ===" "White"
    Write-Host ""
    Write-Color "[CLI Binaries]" "Yellow"
    foreach ($cli in $Manifest.cli_binaries) {
        Write-Host ("  - " + $cli.name + " (bin: " + $cli.binary + ")")
    }
    Write-Host ""
    Write-Color "[Agent Skill Repos]" "Yellow"
    foreach ($skill in $Manifest.skills) {
        Write-Host ("  - " + $skill.name + " (repo: " + $skill.repo + ")")
    }
    Write-Host ""
    Write-Color "[Always-Open Reference Blueprints]" "Yellow"
    foreach ($ref in $Manifest.references) {
        Write-Host ("  - " + $ref.name + ": " + $ref.url)
    }
    Write-Host ""
    exit 0
}

# Package Manager check
$WingetAvailable = Check-Command -cmd "winget"
if ($WingetAvailable) {
    Write-Color "  [+] winget package manager detected." "Green"
} else {
    Write-Color "  [-] winget not found. Installer will fallback to npm and direct downloads." "Yellow"
}

# Verify Core Deps
$Deps = @("git", "node", "npm")
$MissingDeps = @()
foreach ($dep in $Deps) {
    if (Check-Command -cmd $dep) {
        Write-Color ("  [+] Dependency " + $dep + ": Installed") "Green"
    } else {
        Write-Color ("  [-] Dependency " + $dep + ": Missing") "Red"
        $MissingDeps += $dep
        if ($WingetAvailable) {
            Write-Color ("  [+] Auto-installing " + $dep + " via winget...") "Yellow"
            if ($dep -eq "git") {
                winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements | Out-Null
            } elseif ($dep -eq "node") {
                winget install --id OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements | Out-Null
            }
        }
    }
}

# Also check additional tooling availability
$HasPip = Check-Command -cmd "pip"
$HasGo = Check-Command -cmd "go"
$HasCargo = Check-Command -cmd "cargo"
$HasCurl = Check-Command -cmd "curl"

# Bootstrap: if core deps are missing, show advice before continuing
if ($MissingDeps.Count -gt 0) {
    Write-Host ""
    Write-Color "[!] SYSTEM READINESS REPORT:" "Yellow"
    Write-Color "  The following core dependencies are missing:" "Yellow"
    foreach ($m in $MissingDeps) {
        switch ($m) {
            "git" { Write-Color "    git  → https://git-scm.com/download/win" "Cyan" }
            "node" { Write-Color "    node → https://nodejs.org (includes npm)" "Cyan" }
            "npm" { Write-Color "    npm  → bundled with Node.js above" "Cyan" }
        }
    }
    Write-Color "  Install missing deps, close this shell, open a new one, and re-run." "Yellow"
    Write-Color "  The installer will continue but some components will likely fail." "Yellow"
    Write-Host ""
}

# Check what install methods we have available
$AvailableMethods = @()
if ($WingetAvailable) { $AvailableMethods += "winget" }
if ($HasPip) { $AvailableMethods += "pip" }
if ($HasGo) { $AvailableMethods += "go" }
if ($HasCargo) { $AvailableMethods += "cargo" }
if ($HasCurl) { $AvailableMethods += "curl" }
$AvailableMethods += "npm"
$AvailableMethods += "git"
Write-Color ("  [+] Available methods: " + ($AvailableMethods -join ", ")) "Gray"

# Setup directories
Write-Host ""
Write-Color "[2/5] Structuring global agent skill environments..." "White"
foreach ($path in $SkillPaths) {
    if ($DryRun) {
        Write-Color "  [dry-run] mkdir -p $path" "Gray"
    } else {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Color "  [+] Created Path: $path" "Green"
        } else {
            Write-Color "  [+] Path Exists: $path" "Gray"
        }
    }
}

# ------------------------------------------------------------------------------
# Installation Phase
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "[3/5] Starting curation compilation..." "White"

function Install-CLI {
    param(
        [string]$name,
        [string]$binary,
        [string]$winget_pkg,
        [string]$npm_pkg,
        [string]$pip_pkg,
        [string]$go_pkg,
        [string]$cargo_pkg,
        [string]$zip_windows,
        [string]$check_winget_list,
        [string]$platform_skip
    )

    if ($DryRun) {
        Write-Color "  [dry-run] Installing CLI: $name" "Gray"
        return $true
    }

    # Platform skip check
    if ($platform_skip -and $platform_skip.Contains("win32")) {
        Write-Color "  [/] $name is not available on Windows. Skipping." "Yellow"
        $global:SkipList += $name
        return $true
    }

    # Check if already installed via binary in PATH
    if (Check-Command -cmd $binary) {
        Write-Color "  [+] $name is already installed." "Gray"
        $global:SuccessList += $name
        return $true
    }

    # Check winget list first (for packages like localsend that may already be installed via other sources)
    if ($check_winget_list -eq "true" -and $WingetAvailable) {
        $wingetListCheck = winget list --name $name --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and $wingetListCheck -match $name) {
            Write-Color "  [+] $name already installed (winget list confirms)." "Gray"
            $global:SuccessList += $name
            return $true
        }
    }

    $attempted = @()

    # 1) Try winget
    if ($WingetAvailable -and $winget_pkg -and $winget_pkg -ne "") {
        $attempted += "winget"
        Write-Color "  [+] Installing via winget: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            winget install --id $winget_pkg --silent --accept-source-agreements --accept-package-agreements 2>$null
            if ($?) {
                Start-Sleep -Seconds 1
                if (Check-Command -cmd $binary) {
                    $global:SuccessList += $name; return $true
                }
            }
            Write-Color "  [!] winget install failed. Retrying... ($i/3)" "Yellow"
            Start-Sleep -Seconds 2
        }
    }

    # 2) Try npm
    if ($npm_pkg -and $npm_pkg -ne "" -and $npm_pkg -ne "null") {
        $attempted += "npm"
        Write-Color "  [+] Installing via npm: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            npm install -g $npm_pkg --silent 2>$null
            if ($?) {
                if (Check-Command -cmd $binary) {
                    $global:SuccessList += $name; return $true
                }
            }
            Write-Color "  [!] npm install failed. Retrying... ($i/3)" "Yellow"
            Start-Sleep -Seconds 2
        }
    }

    # 3) Try pip
    if ($pip_pkg -and $pip_pkg -ne "" -and $pip_pkg -ne "null" -and $HasPip) {
        $attempted += "pip"
        Write-Color "  [+] Installing via pip: $name" "Yellow"
        for ($i = 1; $i -le 3; $i++) {
            pip install --user $pip_pkg 2>$null
            if ($?) {
                if (Check-Command -cmd $binary) {
                    $global:SuccessList += $name; return $true
                }
            }
            Write-Color "  [!] pip install failed. Retrying... ($i/3)" "Yellow"
            Start-Sleep -Seconds 2
        }
    }

    # 4) Try go install
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
                if (Check-Command -cmd $binary) {
                    $global:SuccessList += $name; return $true
                }
            }
        }
        Write-Color "  [!] go install failed." "Yellow"
    }

    # 5) Try cargo install
    if ($cargo_pkg -and $cargo_pkg -ne "" -and $HasCargo) {
        $attempted += "cargo"
        Write-Color "  [+] Installing via cargo: $name" "Yellow"
        cargo install $cargo_pkg 2>$null
        if ($?) {
            if (Check-Command -cmd $binary) {
                $global:SuccessList += $name; return $true
            }
        }
        Write-Color "  [!] cargo install failed." "Yellow"
    }

    # 6) Try direct zip download (Windows fallback)
    if ($zip_windows -and $zip_windows -ne "" -and $HasCurl) {
        $attempted += "zip"
        Write-Color "  [+] Attempting direct download for $name..." "Yellow"
        $zip_dest = "$TempDir\$name.zip"
        $extract_dest = "$TempDir\$name" + "_extracted"
        for ($i = 1; $i -le 3; $i++) {
            Invoke-WebRequest -Uri $zip_windows -OutFile $zip_dest -TimeoutSec 15 2>$null
            if ($?) { break }
            Write-Color "  [!] Download failed. Retrying... ($i/3)" "Yellow"
            Start-Sleep -Seconds 3
        }
        if (Test-Path $zip_dest) {
            Expand-Archive -Path $zip_dest -DestinationPath $extract_dest -Force 2>$null
            $exe = Get-ChildItem -Path $extract_dest -Recurse -Filter "$binary.exe" | Select-Object -First 1
            if (-not $exe) { $exe = Get-ChildItem -Path $extract_dest -Recurse -Filter "*.exe" | Select-Object -First 1 }
            if ($exe) {
                $localBin = "$env:USERPROFILE\.local\bin"
                if (-not (Test-Path $localBin)) { New-Item -ItemType Directory -Path $localBin -Force | Out-Null }
                Copy-Item -Path $exe.FullName -Destination "$localBin\$binary.exe" -Force
                if (Check-Command -cmd $binary) {
                    $global:SuccessList += $name; return $true
                }
            }
        }
    }

    # All methods exhausted - record failure with advice
    Write-Color "  [-] Failed to install: $name" "Red"
    $global:FailList += @{name=$name; attempted=$attempted}
    return $false
}

# Install CLIs from manifest
foreach ($cli in $Manifest.cli_binaries) {
    if ($Essential -and -not $cli.essential) {
        $SkipList += $cli.name
        continue
    }

    if ($Interactive) {
        if (-not (Ask-Confirm -name ("CLI component " + $cli.name))) {
            $SkipList += $cli.name
            continue
        }
    }

    Install-CLI -name $cli.name -binary $cli.binary -winget_pkg $cli.winget -npm_pkg $cli.npm -pip_pkg $cli.pip -go_pkg $cli.go_install -cargo_pkg $cli.cargo_install -zip_windows $cli.zip_url_windows -check_winget_list $cli.check_winget_list -platform_skip $cli.platform_skip
}

# ------------------------------------------------------------------------------
# Skill Repository Cloner
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "[4/5] Syncing agent skill blueprints..." "White"

function Clone-Skill {
    param(
        [string]$repo,
        [string]$name
    )

    if ($DryRun) {
        Write-Color ("  [dry-run] git clone https://github.com/" + $repo + " to skill paths") "Gray"
        return $true
    }

    Write-Color ("  [+] Syncing skill: " + $name + "...") "Yellow"
    $dest_dir = $TempDir + "\skills\" + $name
    if (Test-Path $dest_dir) { Remove-Item -Recurse -Force -LiteralPath $dest_dir }

    # Clone via Git
    $cloned = $false
    $repo_url = "https://github.com/" + $repo + ".git"
    for ($i = 1; $i -le 3; $i++) {
        git clone --depth 1 $repo_url $dest_dir --quiet
        if ($?) {
            $cloned = $true
            break
        }
        Write-Color "  [!] git clone failed. Retrying... ($i/3)" "Yellow"
        Start-Sleep -Seconds 2
    }

    if ($cloned -and (Test-Path $dest_dir)) {
        foreach ($path in $SkillPaths) {
            if (Test-Path $path) {
                Copy-Item -Path ($dest_dir + "\*") -Destination $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Color "    [+] Skill cloned & distributed successfully." "Green"
        $global:SuccessList += $name
        return $true
    } else {
        # Fallback to direct Zip Download
        Write-Color "    [!] Git clone failed. Attempting zip fallback..." "Yellow"
        $zip_url = "https://github.com/" + $repo + "/archive/refs/heads/main.zip"
        $zip_path = $TempDir + "\" + $name + ".zip"
        $zip_extracted = $TempDir + "\" + $name + "_extracted"
        
        $dlResult = $false
        for ($i = 1; $i -le 3; $i++) {
            Invoke-WebRequest -Uri $zip_url -OutFile $zip_path -TimeoutSec 10
            if ($?) {
                $dlResult = $true
                break
            }
            Write-Color "  [!] Zip download failed. Retrying... ($i/3)" "Yellow"
            Start-Sleep -Seconds 2
        }

        if ($dlResult) {
            Expand-Archive -Path $zip_path -DestinationPath $zip_extracted -Force
            $subfolder = Get-ChildItem -Path $zip_extracted | Select-Object -First 1
            if ($subfolder) {
                foreach ($path in $SkillPaths) {
                    if (Test-Path $path) {
                        Copy-Item -Path ($subfolder.FullName + "\*") -Destination $path -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                $global:SuccessList += $name
                return $true
            }
        }
    }

    Write-Color ("    [-] Failed to sync skill: " + $name) "Red"
    $global:FailList += $name
    return $false
}

# Clone skills
foreach ($skill in $Manifest.skills) {
    if ($Essential -and -not $skill.essential) {
        $SkipList += $skill.name
        continue
    }

    if ($Interactive) {
        if (-not (Ask-Confirm -name ("Skill clone " + $skill.name))) {
            $SkipList += $skill.name
            continue
        }
    }

    Clone-Skill -repo $skill.repo -name $skill.name
}

# ------------------------------------------------------------------------------
# Config templates copy
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "[5/5] Deploying context template files..." "White"
$TemplateDir = $env:USERPROFILE + "\.config\awesome-agentic-stack\templates"
if ($DryRun) {
    Write-Color ("  [dry-run] mkdir -p " + $TemplateDir) "Gray"
    Write-Color "  [dry-run] Deploy templates" "Gray"
} else {
    if (-not (Test-Path $TemplateDir)) { New-Item -ItemType Directory -Path $TemplateDir -Force | Out-Null }
    foreach ($tmpl in $Manifest.templates) {
        if (Test-Path ($PSScriptRoot + "\" + $tmpl)) {
            Copy-Item -Path ($PSScriptRoot + "\" + $tmpl) -Destination $TemplateDir -Force
            Write-Color ("  [+] Template deployed: " + $tmpl) "Green"
        }
    }
}

# ------------------------------------------------------------------------------
# Final Verification Report
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "======================================================================" "Cyan"
Write-Color "[REPORT] COMPILATION COMPLETED - SYSTEM VERIFICATION REPORT" "White"
Write-Color "======================================================================" "Cyan"
Write-Host ""

Write-Color "Curation Summary:" "White"
Write-Color "  Installed successfully: $($SuccessList.Count)" "Green"
Write-Color "  Skipped/Declined:       $($SkipList.Count)" "Yellow"
Write-Color "  Failed installations:   $($FailList.Count)" "Red"
Write-Host ""

if ($FailList.Count -gt 0) {
    Write-Color "Failed Components (Requires Manual Review):" "Red"
    foreach ($failObj in $FailList) {
        $failName = if ($failObj -is [hashtable]) { $failObj.name } else { $failObj }
        Write-Color ("  - " + $failName) "Red"
    }
    Write-Host ""

    Write-Color "[*] HOW TO FIX FAILED COMPONENTS:" "Yellow"
    foreach ($failObj in $FailList) {
        $failName = if ($failObj -is [hashtable]) { $failObj.name } else { $failObj }
        switch ($failName) {
            "ripgrep" {
                Write-Color "  rg (ripgrep):" "White"
                Write-Color "    Download from https://github.com/BurntSushi/ripgrep/releases" "Cyan"
            }
            "gitleaks" {
                Write-Color "  gitleaks:" "White"
                Write-Color "    go install github.com/gitleaks/gitleaks/v8@latest" "Cyan"
                Write-Color "    Download from https://github.com/gitleaks/gitleaks/releases" "Cyan"
            }
            "trufflehog" {
                Write-Color "  trufflehog:" "White"
                Write-Color "    Option A: pip install trufflehog" "Cyan"
                Write-Color "    Option B: go install github.com/trufflesecurity/trufflehog/v3@latest" "Cyan"
            }
            "tmux" {
                Write-Color "  tmux:" "White"
                Write-Color "    Native Windows: Not available. Use WSL:" "Cyan"
                Write-Color "    wsl sudo apt install tmux" "Cyan"
            }
            "localsend" {
                Write-Color "  localsend:" "White"
                Write-Color "    Already installed or download from https://github.com/localsend/localsend/releases" "Cyan"
            }
            "sniffnet" {
                Write-Color "  sniffnet:" "White"
                Write-Color "    Option A: cargo install sniffnet" "Cyan"
                Write-Color "    Option B: Download from https://github.com/GyulyVGC/sniffnet/releases" "Cyan"
            }
            default {
                Write-Color ("  " + $failName + ": Check https://github.com/AkashPriyadarshii/awesome-agentic-stack for manual install instructions") "Cyan"
            }
        }
    }
    Write-Host ""
}

# Path Check
Write-Color "Checking Path Integration..." "White"
$PathSuccess = $true
$CheckCLIs = @("repomix", "openskills", "rg", "gitleaks")
foreach ($cli in $CheckCLIs) {
    if (Check-Command -cmd $cli) {
        Write-Color ("  [yes] " + $cli + " : Functional") "Green"
    } else {
        if ($cli -eq "rg" -and (Test-Path "C:\Program Files\ripgrep")) {
             Write-Color "  [yes] ripgrep : Functional (requires PATH restart)" "Green"
        } elseif ($cli -eq "gitleaks" -and (Test-Path ($env:USERPROFILE + "\AppData\Local\Microsoft\WinGet\Packages\Git.GitLeaks_Microsoft.Winget.Source_default"))) {
             Write-Color "  [yes] gitleaks : Functional (requires PATH restart)" "Green"
        } else {
             Write-Color ("  [no]  " + $cli + " : Missing or requires shell restart") "Red"
             $PathSuccess = $false
        }
    }
}

if (-not $PathSuccess) {
    Write-Host ""
    Write-Color "⚠️ Action Required to Complete Setup:" "Yellow"
    Write-Color "Some binaries were installed but are not yet loaded in your shell path."
    Write-Color "Please close this PowerShell window and open a new one to refresh PATH." "Yellow"
}

# References to open
Write-Host ""
Write-Color "[*] 26 SURVIVER BLUEPRINTS (Bookmark These!):" "White"
foreach ($ref in $Manifest.references) {
    Write-Color ("  - " + $ref.name + ": " + $ref.url) "Cyan"
}

Write-Host ""
Write-Color "[+] Setup complete! Your workspace has been compiled." "Green"
Write-Color "======================================================================" "Cyan"
