#!/usr/bin/env pwsh

# Create new feature script
#
# This script creates a new feature branch and initializes the spec file.
# It handles branch numbering and ensures unique branch names.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$FeatureDescription,
    
    [int]$Number,
    
    [string]$ShortName,
    
    [switch]$Json,
    
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: create-new-feature.ps1 [OPTIONS] <feature-description>

Create a new feature branch and initialize specification.

OPTIONS:
  -Number <int>         Explicit feature number to use
  -ShortName <string>   Explicit short name to use
  -Json                 Output paths in JSON format
  -Help, -h            Show this help message

EXAMPLES:
  # Create feature with auto-detected number and name
  .\create-new-feature.ps1 "Add user authentication"
  
  # Create feature with explicit number and name
  .\create-new-feature.ps1 -Number 5 -ShortName "user-auth" "Add user authentication"

"@
    exit 0
}

# Combine feature description parts
$featureDesc = ($FeatureDescription -join ' ').Trim()

if ([string]::IsNullOrEmpty($featureDesc)) {
    Write-Output "ERROR: Feature description is required"
    exit 1
}

# Determine short name if not provided
if ([string]::IsNullOrEmpty($ShortName)) {
    # Extract keywords from feature description
    $words = $featureDesc -split '\s+' | Where-Object { $_.Length -gt 0 }
    $shortNameParts = @()
    
    foreach ($word in $words) {
        # Skip common articles/prepositions
        if ($word -in @('a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by')) {
            continue
        }
        
        # Take first 2-3 meaningful words
        if ($shortNameParts.Count -lt 4) {
            # Convert to lowercase and replace non-alphanumeric with hyphens
            $cleanWord = $word -replace '[^a-zA-Z0-9]', '-'
            $cleanWord = $cleanWord -replace '-+', '-' -replace '^-' -replace '-$'
            if ($cleanWord.Length -gt 0) {
                $shortNameParts += $cleanWord.ToLower()
            }
        }
    }
    
    $ShortName = ($shortNameParts -join '-').Substring(0, [Math]::Min(20, ($shortNameParts -join '-').Length))
}

if ([string]::IsNullOrEmpty($ShortName)) {
    Write-Output "ERROR: Could not generate a valid short name"
    exit 1
}

# Determine number if not provided
if ($Number -le 0) {
    # Find the highest existing number
    $highestNum = 0
    
    # Check remote branches
    try {
        $remoteBranches = git ls-remote --heads origin 2>$null | ForEach-Object { ($_ -split '/')[2] }
        foreach ($branch in $remoteBranches) {
            if ($branch -match '^(\d+)-' -and $matches[1] -match '^\d+$') {
                $branchNum = [int]$matches[1]
                if ($branchNum -gt $highestNum) { $highestNum = $branchNum }
            }
        }
    } catch { }
    
    # Check local branches
    try {
        $localBranches = git branch --list 2>$null | ForEach-Object { $_.Trim() }
        foreach ($branch in $localBranches) {
            if ($branch -match '^(\d+)-' -and $matches[1] -match '^\d+$') {
                $branchNum = [int]$matches[1]
                if ($branchNum -gt $highestNum) { $highestNum = $branchNum }
            }
        }
    } catch { }
    
    # Check spec directories
    $specsPath = Join-Path (git rev-parse --show-toplevel 2>$null) "specs"
    if (Test-Path $specsPath) {
        $specDirs = Get-ChildItem -Path $specsPath -Directory
        foreach ($dir in $specDirs) {
            if ($dir.Name -match '^(\d+)-' -and $matches[1] -match '^\d+$') {
                $dirNum = [int]$matches[1]
                if ($dirNum -gt $highestNum) { $highestNum = $dirNum }
            }
        }
    }
    
    $Number = $highestNum + 1
}

# Verify git availability
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "ERROR: Not in a git repository"
        exit 1
    }
} catch {
    Write-Output "ERROR: Git is not available or not in a git repository"
    exit 1
}

# Create branch name
$branchName = "${Number}-${ShortName}"

# Create spec directory if it doesn't exist
$specsDir = Join-Path $repoRoot "specs"
if (-not (Test-Path $specsDir)) {
    New-Item -ItemType Directory -Path $specsDir -Force | Out-Null
}

# Create feature directory
$featureDir = Join-Path $specsDir "${Number}-${ShortName}"
if (-not (Test-Path $featureDir)) {
    New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
}

# Create spec file if it doesn't exist
$specFile = Join-Path $featureDir "spec.md"
if (-not (Test-Path $specFile)) {
    # Use the spec template
    $templatePath = Join-Path $repoRoot ".specify/templates/spec-template.md"
    if (Test-Path $templatePath) {
        $templateContent = Get-Content $templatePath -Raw
        $templateContent = $templateContent -replace '\[FEATURE NAME\]', $ShortName
        $templateContent = $templateContent -replace '\[DATE\]', (Get-Date -Format "yyyy-MM-dd")
        $templateContent = $templateContent -replace '\$ARGUMENTS', $featureDesc
        Set-Content -Path $specFile -Value $templateContent
    } else {
        # Create basic spec file if template not found
        $basicSpec = @"
# Feature Specification: $ShortName

**Feature Branch**: `[$Number-$ShortName]`  
**Created**: $(Get-Date -Format "yyyy-MM-dd")  
**Status**: Draft  
**Input**: User description: "$featureDesc"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### Edge Cases

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability]
- **FR-002**: System MUST [specific capability]
- **FR-003**: Users MUST be able to [key interaction]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents]
- **[Entity 2]**: [What it represents]

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable metric]
- **SC-002**: [Measurable metric]
"@
        Set-Content -Path $specFile -Value $basicSpec
    }
}

# Output results
if ($Json) {
    [PSCustomObject]@{
        BRANCH_NAME = $branchName
        FEATURE_DIR = $featureDir
        SPEC_FILE = $specFile
        REPO_ROOT = $repoRoot
    } | ConvertTo-Json -Compress
} else {
    Write-Output "Feature created successfully!"
    Write-Output "Branch: $branchName"
    Write-Output "Directory: $featureDir"
    Write-Output "Spec file: $specFile"
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Review and update $specFile with detailed requirements"
    Write-Output "2. Run '/speckit.clarify' to resolve ambiguities"
    Write-Output "3. Run '/speckit.plan' to create implementation plan"
    Write-Output "4. Run '/speckit.tasks' to generate task list"
    Write-Output "5. Run '/speckit.implement' to execute implementation"
}