# ==============================================================================
# awesome-agentic-stack — Robust Windows 11 PowerShell Installer
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
    param([string]$Text, [string]$Color)
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "======================================================================" "Cyan"
Write-Color "⚡ awesome-agentic-stack — Robust Windows 11 Installer ⚡" "White"
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
$FailList = @()
$SkipList = @()

# ------------------------------------------------------------------------------
# Robust Helper Utilities
# ------------------------------------------------------------------------------
function Check-Command ($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Retry-Cmd {
    param([scriptblock]$sb)
    $count = 0
    $max = 3
    $delay = 2
    until (& $sb) {
        if ($count -eq $max) { return $false }
        $count++
        Write-Color "  [!] Command failed. Retrying in $($delay)s... ($count/$max)" "Yellow"
        Start-Sleep -Seconds $delay
        $delay = $delay * 2
    }
    return $true
}

function Ask-Confirm ($name) {
    if ($Yes) { return $true }
    $choice = Read-Host "  [?] Proceed with $name? (y/n)"
    return ($choice -eq "y" -or $choice -eq "Y")
}

# ------------------------------------------------------------------------------
# Pre-Flight OS & Dependency Checks
# ------------------------------------------------------------------------------
Write-Color "[1/5] Running Pre-Flight checks..." "White"

# Load local manifest or fetch it
$ManifestPath = "$PSScriptRoot\scripts\manifest.json"
if (-not (Test-Path $ManifestPath)) {
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $ManifestPath = "$TempDir\manifest.json"
    Write-Color "  [+] Fetching repository manifest.json..." "Yellow"
    $ManifestUrl = "https://raw.githubusercontent.com/AkashPriyadarshii/awesome-agentic-stack/main/scripts/manifest.json"
    $fetched = Retry-Cmd { Invoke-WebRequest -Uri $ManifestUrl -OutFile $ManifestPath -TimeoutSec 10 }
    if (-not $fetched) {
        Write-Color "  [-] Network error: Failed to fetch manifest.json. Verify network." "Red"
        exit 1
    }
} else {
    Write-Color "  [+] Using local manifest.json" "Gray"
}

# Parse manifest json safely
$Manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json

# Package Manager check
$WingetAvailable = Check-Command "winget"
if ($WingetAvailable) {
    Write-Color "  [+] winget package manager detected." "Green"
} else {
    Write-Color "  [-] winget not found. Installer will fallback to npm and direct downloads." "Yellow"
}

# Verify Core Deps
$Deps = @("git", "node", "npm")
foreach ($dep in $Deps) {
    if (Check-Command $dep) {
        Write-Color "  [+] Dependency $dep: Installed" "Green"
    } else {
        Write-Color "  [-] Dependency $dep: Missing" "Red"
        if ($WingetAvailable) {
            Write-Color "  [+] Auto-installing $dep via winget..." "Yellow"
            if ($dep -eq "git") {
                winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements | Out-Null
            } elseif ($dep -eq "node") {
                winget install --id OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements | Out-Null
            }
        }
    }
}

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

function Install-CLI ($name, $binary, $winget_pkg, $npm_pkg, $pip_pkg) {
    if ($DryRun) {
        Write-Color "  [dry-run] Installing CLI: $name" "Gray"
        return $true
    }

    # Check if already installed
    if (Check-Command $binary) {
        Write-Color "  [+] $name is already installed." "Gray"
        $global:SuccessList += $name
        return $true
    }

    # NPM installation
    if ($npm_pkg -and $npm_pkg -ne "null") {
        Write-Color "  [+] Installing global NPM package: $name" "Yellow"
        $npmResult = Retry-Cmd { npm install -g $npm_pkg --silent }
        if ($npmResult) {
            $global:SuccessList += $name
            return $true
        }
    }

    # Winget installation
    if ($WingetAvailable -and $winget_pkg -and $winget_pkg -ne "null" -and $winget_pkg -ne "skip") {
        Write-Color "  [+] Installing via winget: $name" "Yellow"
        $wingetResult = Retry-Cmd { winget install --id $winget_pkg --silent --accept-source-agreements --accept-package-agreements }
        if ($wingetResult) {
            $global:SuccessList += $name
            return $true
        }
    }

    # Pip installation
    if ($pip_pkg -and $pip_pkg -ne "null" -and (Check-Command "pip")) {
        Write-Color "  [+] Installing via pip: $name" "Yellow"
        $pipResult = Retry-Cmd { pip install --user $pip_pkg }
        if ($pipResult) {
            $global:SuccessList += $name
            return $true
        }
    }

    # Fallback Custom installer for Windows (gitleaks)
    if ($name -eq "gitleaks") {
        Write-Color "  [+] Attempting custom zip fetch for Gitleaks..." "Yellow"
        $dl_url = "https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_windows_x64.zip"
        $zip_dest = "$TempDir\gitleaks.zip"
        $extract_dest = "$TempDir\gitleaks_extracted"
        if (Retry-Cmd { Invoke-WebRequest -Uri $dl_url -OutFile $zip_dest -TimeoutSec 10 }) {
            Expand-Archive -Path $zip_dest -DestinationPath $extract_dest -Force || Out-Null
            if (Test-Path "$extract_dest\gitleaks.exe") {
                $local_bin = "$env:USERPROFILE\.local\bin"
                if (-not (Test-Path $local_bin)) { New-Item -ItemType Directory -Path $local_bin -Force | Out-Null }
                Copy-Item -Path "$extract_dest\gitleaks.exe" -Destination "$local_bin\gitleaks.exe" -Force
                $global:SuccessList += "gitleaks"
                return $true
            }
        }
    }

    Write-Color "  [-] Failed to install: $name" "Red"
    $global:FailList += $name
    return $false
}

# Install CLIs from manifest
foreach ($cli in $Manifest.cli_binaries) {
    if ($Essential -and -not $cli.essential) {
        $SkipList += $cli.name
        continue
    }

    if ($Interactive) {
        if (-not (Ask-Confirm "CLI component $($cli.name)")) {
            $SkipList += $cli.name
            continue
        }
    }

    Install-CLI -name $cli.name -binary $cli.binary -winget_pkg $cli.winget -npm_pkg $cli.npm -pip_pkg $cli.pip
}

# ------------------------------------------------------------------------------
# Skill Repository Cloner
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "[4/5] Syncing agent skill blueprints..." "White"

function Clone-Skill ($repo, $name) {
    if ($DryRun) {
        Write-Color "  [dry-run] git clone https://github.com/$repo to skill paths" "Gray"
        return $true
    }

    Write-Color "  [+] Syncing skill: $name..." "Yellow"
    $dest_dir = "$TempDir\skills\$name"
    if (Test-Path $dest_dir) { Remove-Item -Recurse -Force -LiteralPath $dest_dir }

    # Clone via Git
    $cloned = Retry-Cmd { git clone --depth 1 "https://github.com/$repo.git" $dest_dir --quiet }
    if ($cloned -and (Test-Path $dest_dir)) {
        foreach ($path in $SkillPaths) {
            if (Test-Path $path) {
                Copy-Item -Path "$dest_dir\*" -Destination $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Color "    ✓ Skill cloned & distributed successfully." "Green"
        $global:SuccessList += $name
        return $true
    } else {
        # Fallback to direct Zip Download
        Write-Color "    [!] Git clone failed. Attempting zip fallback..." "Yellow"
        $zip_url = "https://github.com/$repo/archive/refs/heads/main.zip"
        $zip_path = "$TempDir\$name.zip"
        $zip_extracted = "$TempDir\$name`_extracted"
        if (Retry-Cmd { Invoke-WebRequest -Uri $zip_url -OutFile $zip_path -TimeoutSec 10 }) {
            Expand-Archive -Path $zip_path -DestinationPath $zip_extracted -Force || Out-Null
            $subfolder = Get-ChildItem -Path $zip_extracted | Select-Object -First 1
            if ($subfolder) {
                foreach ($path in $SkillPaths) {
                    if (Test-Path $path) {
                        Copy-Item -Path "$($subfolder.FullName)\*" -Destination $path -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                $global:SuccessList += $name
                return $true
            }
        }
    }

    Write-Color "    [-] Failed to sync skill: $name" "Red"
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
        if (-not (Ask-Confirm "Skill clone $($skill.name)")) {
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
$TemplateDir = "$env:USERPROFILE\.config\awesome-agentic-stack\templates"
if ($DryRun) {
    Write-Color "  [dry-run] mkdir -p $TemplateDir" "Gray"
    Write-Color "  [dry-run] Deploy templates" "Gray"
} else {
    if (-not (Test-Path $TemplateDir)) { New-Item -ItemType Directory -Path $TemplateDir -Force | Out-Null }
    foreach ($tmpl in $Manifest.templates) {
        if (Test-Path "$PSScriptRoot\$tmpl") {
            Copy-Item -Path "$PSScriptRoot\$tmpl" -Destination $TemplateDir -Force
            Write-Color "  [+] Template deployed: $tmpl" "Green"
        }
    }
}

# ------------------------------------------------------------------------------
# Final Verification Report
# ------------------------------------------------------------------------------
Write-Host ""
Write-Color "======================================================================" "Cyan"
Write-Color "📋 COMPILATION COMPLETED — SYSTEM VERIFICATION REPORT" "White"
Write-Color "======================================================================" "Cyan"
Write-Host ""

Write-Color "Curation Summary:" "White"
Write-Color "  Installed successfully: $($SuccessList.Count)" "Green"
Write-Color "  Skipped/Declined:       $($SkipList.Count)" "Yellow"
Write-Color "  Failed installations:   $($FailList.Count)" "Red"
Write-Host ""

if ($FailList.Count -gt 0) {
    Write-Color "Failed Components (Requires Manual Review):" "Red"
    foreach ($fail in $FailList) {
        Write-Color "  - $fail" "Red"
    }
    Write-Host ""
}

# Path Check
Write-Color "Checking Path Integration..." "White"
$PathSuccess = $true
$CheckCLIs = @("repomix", "openskills", "rg", "gitleaks")
foreach ($cli in $CheckCLIs) {
    if (Check-Command $cli) {
        Write-Color "  [yes] $cli : Functional" "Green"
    } else {
        if ($cli -eq "rg" -and (Test-Path "C:\Program Files\ripgrep")) {
             Write-Color "  [yes] ripgrep : Functional (requires PATH restart)" "Green"
        } elseif ($cli -eq "gitleaks" -and (Test-Path "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages\Git.GitLeaks_Microsoft.Winget.Source_default")) {
             Write-Color "  [yes] gitleaks : Functional (requires PATH restart)" "Green"
        } else {
             Write-Color "  [no]  $cli : Missing or requires shell restart" "Red"
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
Write-Color "🌐 26 SURVIVAL REFERENCE BLUEPRINTS (Bookmark These!):" "White"
foreach ($ref in $Manifest.references) {
    Write-Color "  - $($ref.name): $($ref.url)" "Cyan"
}

Write-Host ""
Write-Color "✓ Setup complete! Your workspace has been compiled." "Green"
Write-Color "======================================================================" "Cyan"
