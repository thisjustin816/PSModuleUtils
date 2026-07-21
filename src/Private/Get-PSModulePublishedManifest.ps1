<#
.SYNOPSIS
Internal: retrieves a previously published module's manifest from a repository.

.DESCRIPTION
Saves a module from the given repository into a temporary directory and returns its manifest as a
hashtable, so callers can reuse identity fields (most importantly GUID) when generating or migrating
a source manifest template for a module that has already been published. Returns nothing (with a
verbose message, not a warning) when no published version is found, since this is an expected
outcome for a module that has never been published.

.PARAMETER Name
The name of the module to look up.

.PARAMETER Repository
The repository to search. Defaults to PSGallery.

.OUTPUTS
System.Collections.Hashtable of the published manifest, or nothing if none was found.

.EXAMPLE
Get-PSModulePublishedManifest -Name 'MyModule' -Repository 'PSGallery'
#>
function Get-PSModulePublishedManifest {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String]$Name,

        [String]$Repository = 'PSGallery'
    )

    $lookupPath = Join-Path `
        -Path ([IO.Path]::GetTempPath()) `
        -ChildPath "psmodule-manifest-lookup-$( (New-Guid).Guid )"
    try {
        $null = New-Item -ItemType Directory -Path $lookupPath -Force
        Save-PSResource `
            -Name $Name `
            -Repository $Repository `
            -Path $lookupPath `
            -TrustRepository `
            -ErrorAction SilentlyContinue
        $publishedManifest = Get-ChildItem -Path $lookupPath -Filter "$Name.psd1" -Recurse | Select-Object -First 1
        if ($publishedManifest) {
            Import-PowerShellDataFile -Path $publishedManifest.FullName
        }
        else {
            Write-Verbose -Message "No published version of '$Name' was found in repository '$Repository'."
        }
    }
    finally {
        Remove-Item -Path $lookupPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
