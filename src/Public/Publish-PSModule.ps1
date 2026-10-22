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

    $versionedFolder = Get-ChildItem -LiteralPath "$OutputDirectory/$Name" -Directory |
        Where-Object { Test-Path -LiteralPath "$($_.FullName)/$Name.psd1" -PathType Leaf } |
        Sort-Object -Property { [Version]$_.Name } -Descending |
        Select-Object -First 1
    if (-not $versionedFolder) {
        Write-Warning -Message "No module named $Name found to publish."
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$Name $($versionedFolder.Name) in $Repository", 'Publish module')) {
        return
    }

    Get-Module -Name $Name -All | Remove-Module -Force -Confirm:$false -ErrorAction SilentlyContinue
    Import-Module -Name "$($versionedFolder.FullName)/$Name.psd1" -Force -Global -ErrorAction Stop
    Publish-PSResource `
        -Path $versionedFolder.FullName `
        -ApiKey $ApiKey `
        -Repository $Repository `
        -ErrorAction Stop

    $delayIntervals = 1, 2, 3, 5
    for ($attempt = 0; $attempt -le $delayIntervals.Count; $attempt++) {
        $publishedModule = $null
        try {
            $publishedModule = Find-PSResource `
                -Name $Name `
                -Version $versionedFolder.BaseName `
                -Prerelease `
                -Repository $Repository `
                -ErrorAction Stop
        }
        catch {
            if ($attempt -eq $delayIntervals.Count) {
                throw
            }
        }
        if ($publishedModule) {
            break
        }
        if ($attempt -eq $delayIntervals.Count) {
            throw (
                "Published module '$Name $($versionedFolder.Name)' was not found in '$Repository' after five attempts."
            )
        }
        Write-Warning -Message "Couldn't find published module. Retrying after $($delayIntervals[$attempt]) seconds."
        Start-Sleep -Seconds $delayIntervals[$attempt]
    }
}
