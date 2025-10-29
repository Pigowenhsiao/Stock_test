# Common PowerShell functions for Speckit scripts

function Get-FeaturePathsEnv {
    # Determine the repository root (where .specify is located)
    $repoRoot = (Get-Location).Path
    while ($repoRoot -ne [System.IO.Path]::GetPathRoot($repoRoot)) {
        if (Test-Path "$repoRoot\.specify" -PathType Container) {
            break
        }
        $repoRoot = Split-Path $repoRoot -Parent
    }
    
    # Check if git repo exists
    $hasGit = $false
    $currentBranch = $null
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -eq 0) {
            $hasGit = $true
            $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
        }
    } catch {
        # Not a git repo or git not available
    }
    
    # Attempt to find feature directory from current branch name
    $featureDir = $null
    $featureSpec = $null
    $implPlan = $null
    $tasks = $null
    $research = $null
    $dataModel = $null
    $contractsDir = $null
    $quickstart = $null
    
    # Look for feature directory under specs/
    $specsPath = Join-Path $repoRoot "specs"
    if (Test-Path $specsPath) {
        # Try to find a directory matching current branch pattern
        if ($currentBranch -and $currentBranch -match '^\d{1,3}-') {
            $branchSuffix = $currentBranch.Substring($currentBranch.IndexOf('-') + 1)
            $featureDir = Get-ChildItem -Path $specsPath -Directory | 
                         Where-Object { $_.Name -like "*$branchSuffix*" } | 
                         Select-Object -First 1
        }
        
        # If not found via branch, look for the most recent feature directory
        if (-not $featureDir) {
            $featureDir = Get-ChildItem -Path $specsPath -Directory | 
                         Sort-Object LastWriteTime -Descending | 
                         Select-Object -First 1
        }
        
        if ($featureDir) {
            $featureDir = $featureDir.FullName
            $featureSpec = Join-Path $featureDir "spec.md"
            $implPlan = Join-Path $featureDir "plan.md"
            $tasks = Join-Path $featureDir "tasks.md"
            $research = Join-Path $featureDir "research.md"
            $dataModel = Join-Path $featureDir "data-model.md"
            $contractsDir = Join-Path $featureDir "contracts"
            $quickstart = Join-Path $featureDir "quickstart.md"
        }
    }
    
    return @{
        REPO_ROOT = $repoRoot
        HAS_GIT = $hasGit
        CURRENT_BRANCH = $currentBranch
        FEATURE_DIR = $featureDir
        FEATURE_SPEC = $featureSpec
        IMPL_PLAN = $implPlan
        TASKS = $tasks
        RESEARCH = $research
        DATA_MODEL = $dataModel
        CONTRACTS_DIR = $contractsDir
        QUICKSTART = $quickstart
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit
    )
    
    if (-not $HasGit) {
        Write-Output "WARNING: Not in a git repository"
        return $true
    }
    
    if (-not $Branch) {
        Write-Output "ERROR: Could not determine current branch"
        return $false
    }
    
    return $true
}

function Test-FileExists {
    param(
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Output "  $Description: $($Path) (exists)"
        return $true
    } else {
        Write-Output "  $Description: $($Path) (missing)"
        return $false
    }
}

function Test-DirHasFiles {
    param(
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        $files = Get-ChildItem -Path $Path -File
        if ($files.Count -gt 0) {
            Write-Output "  $Description: $($Path) (exists with $($files.Count) files)"
            return $true
        } else {
            Write-Output "  $Description: $($Path) (exists but empty)"
            return $false
        }
    } else {
        Write-Output "  $Description: $($Path) (missing)"
        return $false
    }
}