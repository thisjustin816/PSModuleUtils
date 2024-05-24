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

        Find-PSResource `
            -Name $Name `
            -Version $versionedFolder.BaseName `
            -Prerelease `
            -Repository $Repository
    }
    else {
        Write-Warning -Message "No module named $Name found to publish."
    }
}
