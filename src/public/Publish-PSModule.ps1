<#
.SYNOPSIS
Publishes a PowerShell module to a repository.

.DESCRIPTION
Publishes a PowerShell module to a repository. Defaults to PSGallery.

.PARAMETER Name
The name of the module.

.PARAMETER OutputDirectory
The build output directory used in Build-PSModule.

.PARAMETER Repository
The repository to publish to. Defaults to PSGallery.

.PARAMETER ApiKey
The API key to use for publishing. Defaults to $env:PSGALLERYAPIKEY.

.EXAMPLE
Publish-PSModule -Name 'MyModule' -OutputDirectory "$PWD/out" -Repository 'PSGallery'

.NOTES
N/A
#>
function Publish-PSModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [String]$Name = 'PSModule',
        [String]$OutputDirectory = "$PWD/out",
        [String]$Repository = 'PSGallery',
        [String]$ApiKey = $env:PSGALLERYAPIKEY
    )

    Get-Module -Name $Name -All | Remove-Module -Force -Confirm:$false -ErrorAction SilentlyContinue

    $versionedFolder = Get-ChildItem -Path "$OutputDirectory/$Name" | Select-Object -Last 1
    if ($versionedFolder) {
        Import-Module -Name "$($versionedFolder.FullName)/$Name.psd1" -Force -PassThru
        Publish-PSResource `
            -Path $versionedFolder.FullName `
            -ApiKey $ApiKey `
            -Repository $Repository

        $maxRetries = 5
        $attempt = 0
        $delayIntervals = 1, 2, 3, 5, 8
        do {
            try {
                $publishedModule = Find-PSResource `
                    -Name $Name `
                    -Version $versionedFolder.BaseName `
                    -Prerelease `
                    -Repository $Repository
                break
            }
            catch {
                Write-Verbose -Message (
                    "Couldn't find published module. Retrying after $($delayInterval[$attempt]) seconds."
                )
                Start-Sleep -Seconds $delayIntervals[$attempt]
                $attempt++
                if ($attempt -ge $maxRetries) {
                    throw $_
                }
            }
        }
        while (-not $publishedModule -and $attempt -lt $maxRetries)
    }
    else {
        Write-Warning -Message "No module named $Name found to publish."
    }
}
