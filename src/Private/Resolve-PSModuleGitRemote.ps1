<#
.SYNOPSIS
Internal: resolves a Git remote into module project metadata.

.DESCRIPTION
Normalizes HTTPS, SSH, SCP-style SSH, and Git-protocol remote URLs into a browser-friendly project
URI and derives the repository organization or workspace. Includes explicit Azure DevOps handling
and works generically for GitHub, Bitbucket, GitLab, and self-hosted Git services.

.PARAMETER RepositoryUrl
Git remote URL to normalize.

.OUTPUTS
PSCustomObject with ProjectUri and Organization properties.

.EXAMPLE
Resolve-PSModuleGitRemote -RepositoryUrl 'git@github.com:owner/module.git'
#>
function Resolve-PSModuleGitRemote {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$RepositoryUrl
    )

    $remoteUrl = $RepositoryUrl.Trim()
    $parsedUri = $null
    $scheme = $null
    $hostName = $null
    $authority = $null
    $repositoryPath = $null

    if (
        [Uri]::TryCreate($remoteUrl, [UriKind]::Absolute, [ref]$parsedUri) -and
        $parsedUri.Scheme -in @('http', 'https', 'ssh', 'git')
    ) {
        $scheme = $parsedUri.Scheme.ToLowerInvariant()
        $hostName = $parsedUri.Host.ToLowerInvariant()
        $authority = if ($scheme -in @('http', 'https') -and -not $parsedUri.IsDefaultPort) {
            $parsedUri.Authority
        }
        else {
            $hostName
        }
        $repositoryPath = $parsedUri.AbsolutePath.Trim('/')
    }
    elseif ($remoteUrl -match '^(?:[^@/:]+@)?(?<host>[^:/]+):(?<path>.+)$') {
        $matchedHost = $Matches['host']
        $matchedPath = $Matches['path']
        if (-not ($remoteUrl.Contains('@') -or $matchedHost.Contains('.'))) {
            throw "Unsupported Git remote URL format: $RepositoryUrl"
        }

        $scheme = 'ssh'
        $hostName = $matchedHost.ToLowerInvariant()
        $authority = $hostName
        $repositoryPath = $matchedPath.Trim('/')
    }
    else {
        throw "Unsupported Git remote URL format: $RepositoryUrl"
    }

    $repositoryPath = $repositoryPath -replace '(?i)\.git$', ''
    $pathSegments = @(
        $repositoryPath.Split(
            '/',
            [StringSplitOptions]::RemoveEmptyEntries
        )
    )
    if ($pathSegments.Count -eq 0) {
        throw "Git remote URL has no repository path: $RepositoryUrl"
    }

    $organization = $pathSegments[0]
    $projectUri = $null
    if (
        $hostName -in @('ssh.dev.azure.com', 'vs-ssh.visualstudio.com') -and
        $pathSegments.Count -ge 4 -and
        $pathSegments[0] -eq 'v3'
    ) {
        $organization = $pathSegments[1]
        $project = $pathSegments[2]
        $repository = ($pathSegments[3..($pathSegments.Count - 1)] -join '/')
        $projectUri = "https://dev.azure.com/$organization/$project/_git/$repository"
    }
    elseif ($hostName -eq 'dev.azure.com' -and $pathSegments.Count -ge 2) {
        $organization = $pathSegments[0]
        $projectUri = "https://dev.azure.com/$repositoryPath"
    }
    elseif ($hostName -like '*.visualstudio.com') {
        $organization = $hostName.Split('.')[0]
        $projectUri = "https://$hostName/$repositoryPath"
    }
    else {
        $webScheme = if ($scheme -in @('http', 'https')) {
            $scheme
        }
        else {
            'https'
        }
        $projectUri = "$($webScheme)://$authority/$repositoryPath"
    }

    [PSCustomObject]@{
        ProjectUri   = $projectUri
        Organization = $organization
    }
}
