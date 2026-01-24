#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code Completion Module for PowerShell

.DESCRIPTION
    Provides intelligent tab-completion for Claude Code commands, skills, and plugins.
    Uses the completion-engine.js for multi-source ranked completions.

.EXAMPLE
    # Add to your $PROFILE:
    Import-Module "$HOME\.claude\shell\ClaudeComplete.psm1"

    # Then use tab completion:
    claude /debug<TAB>     # Completes to /systematic-debugging
    claude /nav<TAB>       # Shows nav-init, nav-start, etc.
#>

$script:CompletionEngine = "$HOME\.claude\engine\completion-engine.js"

function Get-ClaudeCompletions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [int]$MaxResults = 10
    )

    if (-not (Test-Path $script:CompletionEngine)) {
        Write-Warning "Completion engine not found at $script:CompletionEngine"
        return @()
    }

    try {
        $output = & node $script:CompletionEngine complete $Query json 2>$null
        $completions = $output | ConvertFrom-Json

        return $completions | ForEach-Object {
            [PSCustomObject]@{
                Display     = $_.display
                Type        = $_.type
                Description = $_.description
                Score       = $_.score
            }
        }
    }
    catch {
        return @()
    }
}

function Register-ClaudeArgumentCompleter {
    <#
    .SYNOPSIS
        Registers tab completion for the 'claude' command
    #>

    # Completer for claude command
    $completer = {
        param(
            $commandName,
            $wordToComplete,
            $cursorPosition
        )

        # Get the word being completed
        $prefix = $wordToComplete -replace '^/', ''

        # Get completions from engine
        $completions = Get-ClaudeCompletions -Query $prefix -MaxResults 15

        foreach ($c in $completions) {
            $tooltip = "[$($c.Type)] $($c.Description)"

            [System.Management.Automation.CompletionResult]::new(
                $c.Display,           # completionText
                $c.Display,           # listItemText
                'ParameterValue',     # resultType
                $tooltip              # toolTip
            )
        }
    }

    Register-ArgumentCompleter -CommandName 'claude' -Native -ScriptBlock $completer
}

function Invoke-ClaudeWithCompletion {
    <#
    .SYNOPSIS
        Wrapper for claude command that records usage for better completions
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    # Record command for history
    $cmd = $Arguments -join ' '
    if ($cmd -match '^/\w+') {
        & node $script:CompletionEngine record $Matches[0] 2>$null
    }

    # Execute claude
    & claude @Arguments
}

function Show-ClaudeCompletions {
    <#
    .SYNOPSIS
        Interactive completion browser using fzf if available
    #>
    [CmdletBinding()]
    param(
        [string]$Query = ''
    )

    $completions = Get-ClaudeCompletions -Query $Query -MaxResults 50

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        # Use fzf for interactive selection
        $selected = $completions |
            ForEach-Object { "$($_.Display)`t$($_.Type)`t$($_.Description)" } |
            fzf --header="Claude Completions" --preview="echo {1}" |
            ForEach-Object { ($_ -split "`t")[0] }

        if ($selected) {
            Write-Output $selected
        }
    }
    else {
        # Simple table output
        $completions | Format-Table -Property Display, Type, Description, Score -AutoSize
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ClaudeCompletions',
    'Register-ClaudeArgumentCompleter',
    'Invoke-ClaudeWithCompletion',
    'Show-ClaudeCompletions'
)

# Auto-register completer on module import
Register-ClaudeArgumentCompleter

Write-Host "Claude Code completions loaded. Use Tab after 'claude /' for suggestions." -ForegroundColor Cyan
