<#
.SYNOPSIS
Internal: derives module manifest metadata from a git working tree.

.DESCRIPTION
Reads the git remote and history for the given path and returns the manifest metadata that should be
stamped onto a built module: author list, company name, copyright, project URI, and release notes.
Returns nothing (with a warning) when the path is not inside a git working tree, so callers can treat
git-derived metadata as best effort.

.PARAMETER Path
A path inside the git working tree to read metadata from. Defaults to the current location.

.OUTPUTS
PSCustomObject with Author, CompanyName, Copyright, ProjectUri, and ReleaseNotes properties.

.EXAMPLE
$metadata = Get-PSModuleGitMetadata -Path $SourceDirectory
#>
function Get-PSModuleGitMetadata {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [String]$Path = "$PWD"
    )

    $ErrorActionPreference = 'Stop'

    Push-Location -Path $Path
    try {
        $insideWorkTree = ( & git rev-parse --is-inside-work-tree 2>$null )
        if ($LASTEXITCODE -ne 0 -or $insideWorkTree -ne 'true') {
            Write-Warning -Message "'$Path' is not inside a git working tree; skipping git-derived metadata."
            return
        }

        $repoUrl = ( & git config --get remote.origin.url )
        if ($LASTEXITCODE -ne 0 -or [String]::IsNullOrWhiteSpace($repoUrl)) {
            Write-Warning -Message "'$Path' has no origin remote; skipping git-derived metadata."
            return
        }
        try {
            $remoteMetadata = Resolve-PSModuleGitRemote -RepositoryUrl $repoUrl
        }
        catch {
            Write-Warning -Message (
                'A company name was not provided and the Git remote URL could not be resolved; ' +
                'leaving CompanyName and ProjectUri blank.'
            )
            $remoteMetadata = [PSCustomObject]@{
                Organization = ''
                ProjectUri   = ''
            }
        }
        $companyName = $remoteMetadata.Organization
        $copyright = if ($companyName) {
            "(c) $( Get-Date -Format yyyy ) $companyName. All rights reserved."
        }
        else {
            ''
        }

        [PSCustomObject]@{
            Author       = (( & git log --format='%aN' -- . | Sort-Object -Unique ) -join ', ')
            CompanyName  = $companyName
            Copyright    = $copyright
            ProjectUri   = $remoteMetadata.ProjectUri
            ReleaseNotes = ( & git log -1 --pretty=%B )[0]
        }
    }
    finally {
        Pop-Location
    }
}
