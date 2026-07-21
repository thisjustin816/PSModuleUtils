<#
.SYNOPSIS
Generates or migrates a hand-authored source module manifest template for use with Build-PSModule.

.DESCRIPTION
Writes a source manifest template ("<Name>.psd1") in the shape Build-PSModule expects: pinned
identity fields (GUID, Description, RequiredModules, Tags, LicenseUri), empty export lists (populated
by ModuleBuilder at build time), and pre-declared PrivateData.PSData.Prerelease/ReleaseNotes keys so
Update-Metadata can patch them on a later build.

When the module has already been published, its GUID is reused automatically (unless -Guid or
-SkipRepositoryLookup is given) so the module's identity survives the migration to this build model.
Refuses to overwrite an existing manifest unless -Force is given.

.PARAMETER Name
The name of the module.

.PARAMETER SourceDirectory
The directory to write "<Name>.psd1" into.

.PARAMETER Description
The module description.

.PARAMETER ModuleVersion
The initial module version written to the source manifest.

.PARAMETER Guid
The module GUID. When omitted, the GUID is reused from a previously published version of the module
(see -Repository), or a new one is generated if none is found.

.PARAMETER Tags
The module tags, including PSGallery filtering tags such as "PSEdition_Core".

.PARAMETER LicenseUri
The URL for the module's license.

.PARAMETER PowerShellVersion
The minimum PowerShell version the module requires.

.PARAMETER CompatiblePSEditions
The PowerShell editions the module supports.

.PARAMETER RequiredModules
The module's runtime dependencies, in the same form accepted by a manifest's RequiredModules key
(module names or hashtables with ModuleName/ModuleVersion/MaximumVersion).

.PARAMETER Repository
The repository to search for a previously published version of the module. Defaults to PSGallery.

.PARAMETER SkipRepositoryLookup
Skips looking up a previously published version of the module.

.PARAMETER Force
Overwrites an existing source manifest at the target path.

.OUTPUTS
System.IO.FileInfo for the written manifest.

.EXAMPLE
New-PSModuleManifest -Name 'MyModule' -Description 'A PowerShell module.' -SourceDirectory "$PWD/src"

.NOTES
Requires the JBUtils module (ConvertTo-Psd1).
#>
function New-PSModuleManifest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [String]$Name,

        [String]$SourceDirectory = "$PWD/src",

        [String]$Description = 'A PowerShell module.',

        [Version]$ModuleVersion = '0.0.1',

        [String]$Guid,

        [String[]]$Tags = @('PSEdition_Core'),

        [String]$LicenseUri = 'https://opensource.org/licenses/MIT',

        [String]$PowerShellVersion = '7.4',

        [String[]]$CompatiblePSEditions = @('Core'),

        [Object[]]$RequiredModules = @(),

        [String]$Repository = 'PSGallery',

        [Switch]$SkipRepositoryLookup,

        [Switch]$Force
    )

    $ErrorActionPreference = 'Stop'

    $manifestPath = Join-Path -Path $SourceDirectory -ChildPath "$Name.psd1"
    if ((Test-Path -Path $manifestPath) -and -not $Force) {
        throw "A source manifest already exists at '$manifestPath'. Use -Force to overwrite it."
    }

    $resolvedGuid = $Guid
    if (-not $resolvedGuid -and -not $SkipRepositoryLookup) {
        $published = Get-PSModulePublishedManifest -Name $Name -Repository $Repository
        if ($published) {
            $resolvedGuid = $published.Guid
            Write-Verbose -Message "Reusing the GUID from the previously published '$Name' module."
        }
    }
    if (-not $resolvedGuid) {
        $resolvedGuid = ( New-Guid ).Guid
    }

    $manifestContent = [ordered]@{
        RootModule           = "$Name.psm1"
        ModuleVersion        = $ModuleVersion.ToString()
        GUID                 = $resolvedGuid
        Author               = ''
        CompanyName          = ''
        Copyright            = ''
        Description          = $Description
        PowerShellVersion    = $PowerShellVersion
        CompatiblePSEditions = $CompatiblePSEditions
        FunctionsToExport    = @()
        CmdletsToExport      = @()
        VariablesToExport    = @()
        AliasesToExport      = @()
    }
    if ($RequiredModules.Count -gt 0) {
        $manifestContent['RequiredModules'] = $RequiredModules
    }
    $manifestContent['PrivateData'] = @{
        PSData = @{
            Tags         = $Tags
            ProjectUri   = ''
            LicenseUri   = $LicenseUri
            ReleaseNotes = ''
            Prerelease   = ''
        }
    }

    if ($PSCmdlet.ShouldProcess($manifestPath, 'Create source module manifest')) {
        $null = New-Item -ItemType Directory -Path $SourceDirectory -Force
        $serialized = ConvertTo-Psd1 -InputObject $manifestContent
        # ConvertTo-Psd1 joins lines with a bare LF; -NoNewline stops Set-Content from appending the
        # platform's native terminator on top of that, which would otherwise leave the file LF-bodied
        # but CRLF-terminated and trip PSScriptAnalyzer's "mixed line endings" detection.
        Set-Content -Path $manifestPath -Value "$serialized`n" -Encoding utf8NoBOM -NoNewline
        Get-Item -Path $manifestPath
    }
}
