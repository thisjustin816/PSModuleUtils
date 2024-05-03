function Publish-PSModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [String]$Name = 'PSModule',
        [String]$OutputDirectory = "$PWD/out",
        [String]$Repository = 'PSGallery',
        [String]$ApiKey = $env:PSGALLERYAPIKEY
    )

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue

    $versionedFolder = Get-ChildItem -Path "$OutputDirectory/$Name" | Select-Object -Last 1
    if ($versionedFolder) {
        Import-Module -Name "$($versionedFolder.FullName)/$Name.psd1" -Force -PassThru
        if ($PSCmdlet.ShouldProcess("$Name v$($versionedFolder.BaseName)", "Publish-Module")) {
            Publish-Module `
                -Path $versionedFolder.FullName `
                -NuGetApiKey $ApiKey `
                -Repository $Repository
        }
    }
    else {
        Write-Warning -Message "No module named $Name found to publish."
    }
}
