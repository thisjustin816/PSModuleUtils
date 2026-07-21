<#
.SYNOPSIS
Exports the bundled PSScriptAnalyzer settings for customization.

.DESCRIPTION
Copies the PSScriptAnalyzer settings bundled with PSModuleUtils to a user-selected path. The file is copied
verbatim so comments, disabled examples, ordering, and formatting remain available for customization.

.PARAMETER Path
The destination file path. Defaults to PSScriptAnalyzerSettings.psd1 in the current directory. The parent
directory must already exist.

.PARAMETER Force
Replaces an existing destination file.

.PARAMETER PassThru
Returns the exported file.

.OUTPUTS
System.IO.FileInfo when PassThru is specified. Otherwise, this command produces no output.

.EXAMPLE
Export-PSModuleAnalyzerSettings

.EXAMPLE
Export-PSModuleAnalyzerSettings -Path ./config/PSScriptAnalyzerSettings.psd1 -Force -PassThru
#>
function Export-PSModuleAnalyzerSettings {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path = (Join-Path -Path $PWD -ChildPath 'PSScriptAnalyzerSettings.psd1'),

        [Switch]$Force,

        [Switch]$PassThru
    )

    $sourcePath = Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $PSScriptRoot
    if ([String]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw 'The bundled PSScriptAnalyzer settings file could not be resolved.'
    }

    try {
        $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    } catch {
        $pathError = $_
        throw "Destination path '$Path' could not be resolved: $($pathError.Exception.Message)"
    }

    $parentPath = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        throw "The destination parent directory '$parentPath' does not exist."
    }

    if (Test-Path -LiteralPath $destinationPath) {
        if (Test-Path -LiteralPath $destinationPath -PathType Container) {
            throw "The destination path '$destinationPath' is a directory."
        }
        if (-not $Force) {
            throw "The destination file '$destinationPath' already exists. Specify -Force to replace it."
        }
    }

    if ($PSCmdlet.ShouldProcess($destinationPath, 'Export bundled PSScriptAnalyzer settings')) {
        $null = Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force:$Force -ErrorAction Stop
        if ($PassThru) {
            Get-Item -LiteralPath $destinationPath -ErrorAction Stop
        }
    }
}
