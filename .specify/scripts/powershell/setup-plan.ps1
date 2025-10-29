#!/usr/bin/env pwsh

# Setup plan script (PowerShell)
#
# This script sets up the implementation plan for a feature based on its spec.
# It creates plan.md and related files based on the spec and templates.

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: setup-plan.ps1 [OPTIONS]

Set up implementation plan for the current feature.

OPTIONS:
  -Json           Output paths in JSON format
  -Help, -h      Show this help message

EXAMPLES:
  # Setup plan and get output paths
  .\setup-plan.ps1 -Json
  
  # Setup plan with text output
  .\setup-plan.ps1

"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Get feature paths
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { 
    exit 1 
}

# Verify required files exist
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Output "Run /speckit.specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.FEATURE_SPEC -PathType Leaf)) {
    Write-Output "ERROR: spec.md not found: $($paths.FEATURE_SPEC)"
    Write-Output "Run /speckit.specify first to create the feature specification."
    exit 1
}

# Create plan directory if it doesn't exist (same as feature directory)
$planDir = $paths.FEATURE_DIR

# Create plan.md if it doesn't exist
if (-not (Test-Path $paths.IMPL_PLAN)) {
    # Use the plan template
    $templatePath = Join-Path $paths.REPO_ROOT ".specify/templates/plan-template.md"
    if (Test-Path $templatePath) {
        $templateContent = Get-Content $templatePath -Raw
        
        # Extract feature name from directory
        $featureName = Split-Path $paths.FEATURE_DIR -Leaf
        $featureName = $featureName -replace '^\d+-', ''  # Remove number prefix
        
        # Replace placeholders
        $templateContent = $templateContent -replace '\[FEATURE\]', $featureName
        $templateContent = $templateContent -replace '\[DATE\]', (Get-Date -Format "yyyy-MM-dd")
        
        # Extract link to spec
        $specLink = "link"
        if ($paths.HAS_GIT) {
            try {
                $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $specLink = "../spec.md"
                }
            } catch { }
        }
        
        $templateContent = $templateContent -replace '\[link\]', $specLink
        
        Set-Content -Path $paths.IMPL_PLAN -Value $templateContent
    } else {
        # Create basic plan file if template not found
        $basicPlan = @"
# Implementation Plan: $($featureName)

**Branch**: `[$($featureName)]` | **Date**: $(Get-Date -Format "yyyy-MM-dd") | **Spec**: [spec link]
**Input**: Feature specification from `/specs/$($featureName)/spec.md`

## Summary

[Extract from feature spec: primary requirement + technical approach]

## Technical Context

**Language/Version**: [e.g., Python 3.11 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL or N/A]  
**Testing**: [e.g., pytest or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server or NEEDS CLARIFICATION]

## Constitution Check

[Gates determined based on constitution file]

## Project Structure

[Project structure based on plan]
"@
        Set-Content -Path $paths.IMPL_PLAN -Value $basicPlan
    }
}

# Create placeholder files that will be generated in later phases
$researchFile = Join-Path $paths.FEATURE_DIR "research.md"
if (-not (Test-Path $researchFile)) {
    Set-Content -Path $researchFile -Value "# Research for $($featureName)`n`n## Decisions`n- [Decision 1]: [Rationale]`n- [Decision 2]: [Rationale]`n`n## Alternatives Considered`n- [Alternative 1]: [Why not chosen]`n- [Alternative 2]: [Why not chosen]`n"
}

$dataModelFile = Join-Path $paths.FEATURE_DIR "data-model.md"
if (-not (Test-Path $dataModelFile)) {
    Set-Content -Path $dataModelFile -Value "# Data Model for $($featureName)`n`n## Entities`n- **[Entity1]**: [Description]`n  - [Attribute1]: [Type]`n  - [Attribute2]: [Type]`n`n## Relationships`n- [Relationship1]: [Description]`n"
}

$quickstartFile = Join-Path $paths.FEATURE_DIR "quickstart.md"
if (-not (Test-Path $quickstartFile)) {
    Set-Content -Path $quickstartFile -Value "# Quickstart for $($featureName)`n`n## Setup`n1. [Step 1]`n2. [Step 2]`n3. [Step 3]`n`n## Running`n1. [Run step 1]`n2. [Run step 2]`n`n## Testing`n- [Test command]`n"
}

# Create contracts directory if it doesn't exist
$contractsDir = Join-Path $paths.FEATURE_DIR "contracts"
if (-not (Test-Path $contractsDir)) {
    New-Item -ItemType Directory -Path $contractsDir -Force | Out-Null
}

# Output results
if ($Json) {
    [PSCustomObject]@{
        FEATURE_DIR = $paths.FEATURE_DIR
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        REPO_ROOT = $paths.REPO_ROOT
        BRANCH = $paths.CURRENT_BRANCH
    } | ConvertTo-Json -Compress
} else {
    Write-Output "Plan setup completed for: $($featureName)"
    Write-Output "Plan file: $($paths.IMPL_PLAN)"
    Write-Output "Created placeholder files:"
    Write-Output "  - $($researchFile)"
    Write-Output "  - $($dataModelFile)"
    Write-Output "  - $($quickstartFile)"
    Write-Output "  - $($contractsDir) directory"
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Review and update $($paths.IMPL_PLAN) with technical details"
    Write-Output "2. Run '/speckit.tasks' to generate task list"
    Write-Output "3. Run '/speckit.implement' to execute implementation"
}