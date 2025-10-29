#!/usr/bin/env pwsh

# Update agent context script
#
# This script updates agent-specific context files with technology information
# from the current plan.

[CmdletBinding()]
param(
    [string]$AgentType = "gemini",  # Default to gemini, but can be other agents like "qwen", "claude", etc.
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: update-agent-context.ps1 [OPTIONS]

Update agent-specific context with current technology stack.

OPTIONS:
  -AgentType <string>   Agent type to update (default: gemini)
  -Help, -h            Show this help message

EXAMPLES:
  # Update gemini context
  .\update-agent-context.ps1 -AgentType gemini
  
  # Update qwen context
  .\update-agent-context.ps1 -AgentType qwen

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
if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found: $($paths.IMPL_PLAN)"
    Write-Output "Run /speckit.plan first to create the implementation plan."
    exit 1
}

# Read the plan to extract technology information
$planContent = Get-Content $paths.IMPL_PLAN -Raw

# Extract technology stack (this is a simplified approach)
$techMatches = @()
if ($planContent -match 'Language/Version.*?:\s*(.*?)(?:\s+|\n)') {
    $langInfo = $matches[1]
    if ($langInfo -notmatch 'NEEDS CLARIFICATION') {
        $techMatches += $langInfo
    }
}

if ($planContent -match 'Primary Dependencies.*?:\s*(.*?)(?:\s+|\n)') {
    $depInfo = $matches[1] 
    if ($depInfo -notmatch 'NEEDS CLARIFICATION') {
        $techMatches += $depInfo
    }
}

if ($planContent -match 'Target Platform.*?:\s*(.*?)(?:\s+|\n)') {
    $platformInfo = $matches[1]
    if ($platformInfo -notmatch 'NEEDS CLARIFICATION') {
        $techMatches += $platformInfo
    }
}

# Determine agent directory based on agent type
$agentDir = $null
switch ($AgentType.ToLower()) {
    "gemini" { $agentDir = Join-Path $paths.REPO_ROOT ".gemini" }
    "qwen" { $agentDir = Join-Path $paths.REPO_ROOT ".qwen" }
    "claude" { $agentDir = Join-Path $paths.REPO_ROOT ".claude" }
    default { 
        Write-Output "ERROR: Unsupported agent type: $AgentType"
        Write-Output "Supported types: gemini, qwen, claude"
        exit 1
    }
}

if (-not (Test-Path $agentDir)) {
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
}

# Create commands directory if it doesn't exist
$commandsDir = Join-Path $agentDir "commands"
if (-not (Test-Path $commandsDir)) {
    New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null
}

# Update agent file template
$agentFile = Join-Path $paths.REPO_ROOT ".specify/templates/agent-file-template.md"
$outputFile = Join-Path $agentDir "development-guidelines.md"

if (Test-Path $agentFile) {
    $templateContent = Get-Content $agentFile -Raw
    
    # Replace placeholders with actual values from plan
    $templateContent = $templateContent -replace '\[PROJECT NAME\]', "Speckit Project"
    $templateContent = $templateContent -replace '\[DATE\]', (Get-Date -Format "yyyy-MM-dd")
    
    # Extract technologies
    $techText = if ($techMatches.Count -gt 0) { $techMatches -join ", " } else { "No specific technologies defined yet" }
    $templateContent = $templateContent -replace '\[EXTRACTED FROM ALL PLAN.MD FILES\]', $techText
    
    # Extract project structure (simplified)
    $structureText = "Based on the implementation plan in $($paths.IMPL_PLAN)"
    $templateContent = $templateContent -replace '\[ACTUAL STRUCTURE FROM PLANS\]', $structureText
    
    # Extract commands (for now just list speckit commands)
    $commandsText = @(
        "speckit.specify - Create feature specification",
        "speckit.clarify - Clarify ambiguous requirements",
        "speckit.plan - Generate implementation plan",
        "speckit.tasks - Generate task list",
        "speckit.checklist - Generate validation checklist",
        "speckit.analyze - Analyze specification consistency",
        "speckit.implement - Execute implementation plan"
    ) -join "`n"
    $templateContent = $templateContent -replace '\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]', $commandsText
    
    # Extract code style (simplified)
    $styleText = "Follow the coding standards mentioned in the implementation plan"
    $templateContent = $templateContent -replace '\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]', $styleText
    
    # Extract recent changes (for now just the current feature)
    $changesText = "Feature: $(Split-Path $paths.FEATURE_DIR -Leaf) - Implementation based on plan"
    $templateContent = $templateContent -replace '\[LAST 3 FEATURES AND WHAT THEY ADDED\]', $changesText
    
    Set-Content -Path $outputFile -Value $templateContent
} else {
    # Create basic agent file if template not found
    $basicAgentFile = @"
# Speckit Project Development Guidelines

Auto-generated from all feature plans. Last updated: $(Get-Date -Format "yyyy-MM-dd")

## Active Technologies

$(if ($techMatches.Count -gt 0) { $techMatches -join ", " } else { "No specific technologies defined yet" })

## Project Structure

Based on the implementation plan in $($paths.IMPL_PLAN)

## Commands

- speckit.specify - Create feature specification
- speckit.clarify - Clarify ambiguous requirements
- speckit.plan - Generate implementation plan
- speckit.tasks - Generate task list
- speckit.checklist - Generate validation checklist
- speckit.analyze - Analyze specification consistency
- speckit.implement - Execute implementation plan

## Code Style

Follow the coding standards mentioned in the implementation plan

## Recent Changes

Feature: $(Split-Path $paths.FEATURE_DIR -Leaf) - Implementation based on plan

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
"@
    Set-Content -Path $outputFile -Value $basicAgentFile
}

Write-Output "Agent context updated for: $AgentType"
Write-Output "File: $outputFile"
Write-Output "Technologies identified: $(if ($techMatches.Count -gt 0) { $techMatches -join ", " } else { 'None' })"