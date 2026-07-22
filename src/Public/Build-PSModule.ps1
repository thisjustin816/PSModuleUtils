<#
.SYNOPSIS
Builds a PowerShell module from a source tree using ModuleBuilder.

.DESCRIPTION
Compiles a module's public and private function files into a single versioned module under the output
directory with ModuleBuilder's Build-Module, then stamps git-derived metadata (author, company,
copyright, project URI, release notes) onto the built manifest with Update-Metadata.

Files and directories that must remain separate in the published module, such as assemblies, schemas,
templates, settings, and localized content, can be copied with CopyPaths. Copy paths retain their source
names beneath the module output directory and are never concatenated into the generated .psm1.

The source directory must contain a hand-authored manifest template named "<Name>.psd1" and the
function folders it references. ModuleBuilder derives FunctionsToExport from the public filter and
AliasesToExport from [Alias()], New-Alias, and Set-Alias declarations, so those keys are never authored
by hand. Tests must live outside the source folders (ModuleBuilder inlines every .ps1 it finds in them).

To allow the version, prerelease, and release notes to be stamped, the manifest template must
pre-declare PrivateData.PSData.Prerelease and PrivateData.PSData.ReleaseNotes (empty strings are fine).
Run New-PSModuleManifest to generate a compatible manifest template for a module that does not have one.

.PARAMETER Name
The name of the module. The source manifest is expected at "<SourceDirectory>/<Name>.psd1".

.PARAMETER Version
The module version, optionally with a SemVer prerelease label (e.g. "2.0.0-alpha"). When omitted, the
version already declared in the source manifest is used.

.PARAMETER SourceDirectory
The directory containing the source manifest and the canonical Public/Private function folders.

.PARAMETER OutputDirectory
The directory to build into. The module is written to "<OutputDirectory>/<Name>/<Version>".

.PARAMETER SourceDirectories
The source subfolders, in load order, that ModuleBuilder concatenates into the built module.

.PARAMETER PublicFilter
The filter identifying public (exported) function files, relative to the source directory.

.PARAMETER CopyPaths
Files or directories to copy recursively into the built module without compilation. Paths are relative
to the source directory unless absolute. Use purpose-specific directories such as Assemblies, bin,
Settings, Schemas, Templates, Resources, or culture names such as en-US.

.PARAMETER SkipGitMetadata
Skips stamping git-derived metadata onto the built manifest. Useful when building outside a git tree.

.OUTPUTS
System.IO.FileInfo for the built module manifest.

.EXAMPLE
Build-PSModule -Name 'MyModule' -Version '2.0.0' -SourceDirectory "$PWD/src"

.NOTES
Requires the ModuleBuilder and Metadata modules.
#>
function Build-PSModule {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [String]$Name = 'PSModule',
        [String]$Version,
        [String]$SourceDirectory = "$PWD/src",
        [String]$OutputDirectory = "$PWD/out",
        [String[]]$SourceDirectories = @('Enum', 'Classes', 'Private', 'Public'),
        [String]$PublicFilter = 'Public/*.ps1',
        [String[]]$CopyPaths = @(),
        [Switch]$SkipGitMetadata
    )

    $ErrorActionPreference = 'Stop'

    $sourceManifest = Join-Path -Path $SourceDirectory -ChildPath "$Name.psd1"
    if (-not (Test-Path -Path $sourceManifest)) {
        throw "Source manifest not found at '$sourceManifest'. Run New-PSModuleManifest to create one."
    }

    $canonicalSourceDirectories = @('Enum', 'Classes', 'Private', 'Public')
    foreach ($requestedDirectory in $SourceDirectories) {
        $canonicalName = $canonicalSourceDirectories |
            Where-Object { $_ -ieq $requestedDirectory } |
            Select-Object -First 1
        if ($canonicalName -and $requestedDirectory -cne $canonicalName) {
            throw "Source directory '$requestedDirectory' must be named '$canonicalName'."
        }
    }

    foreach ($sourceChild in Get-ChildItem -LiteralPath $SourceDirectory -Directory) {
        $canonicalName = $canonicalSourceDirectories |
            Where-Object { $_ -ieq $sourceChild.Name } |
            Select-Object -First 1
        if ($canonicalName -and $sourceChild.Name -cne $canonicalName) {
            throw "Source directory '$($sourceChild.Name)' must be named '$canonicalName'."
        }
    }

    $moduleOutputRoot = Join-Path -Path $OutputDirectory -ChildPath $Name
    Remove-Item -Path $moduleOutputRoot -Recurse -Force -ErrorAction SilentlyContinue

    $buildModule = @{
        SourcePath               = $sourceManifest
        OutputDirectory          = $OutputDirectory
        SourceDirectories        = $SourceDirectories
        PublicFilter             = $PublicFilter
        VersionedOutputDirectory = $true
        Passthru                 = $true
    }

    if ($CopyPaths.Count -gt 0) {
        $buildModule['CopyPaths'] = $CopyPaths
    }

    if ($Version) {
        $moduleVersion, $modulePrerelease = $Version -split '-', 2
        $buildModule['Version'] = $moduleVersion
        if ($modulePrerelease) {
            $buildModule['Prerelease'] = $modulePrerelease
        }
    }

    Write-Host -Object "Building module '$Name'..."
    $builtModule = Build-Module @buildModule
    $manifestPath = Join-Path -Path $builtModule.ModuleBase -ChildPath "$Name.psd1"

    if (-not $SkipGitMetadata) {
        $gitMetadata = Get-PSModuleGitMetadata -Path $SourceDirectory
        if ($gitMetadata) {
            $metadataMap = [ordered]@{
                'Author'                          = $gitMetadata.Author
                'CompanyName'                     = $gitMetadata.CompanyName
                'Copyright'                       = $gitMetadata.Copyright
                'PrivateData.PSData.ProjectUri'   = $gitMetadata.ProjectUri
                'PrivateData.PSData.ReleaseNotes' = $gitMetadata.ReleaseNotes
            }
            foreach ($property in $metadataMap.Keys) {
                $value = $metadataMap[$property]
                if (-not $value) {
                    continue
                }
                try {
                    Update-Metadata -Path $manifestPath -PropertyName $property -Value $value -ErrorAction Stop
                }
                catch {
                    $updateError = $_
                    Write-Warning -Message (
                        "Could not set '$property' in '$manifestPath': $( $updateError.Exception.Message )"
                    )
                }
            }
        }
    }

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $null = Import-Module -Name $manifestPath -Force -PassThru -ErrorAction Stop
    Get-Item -Path $manifestPath
}
