# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Resolve-PSModuleGitRemote.ps1
    }

    It 'should normalize <Name>' -ForEach @(
        @{
            Name         = 'GitHub HTTPS'
            Repository   = 'https://github.com/example-org/module.git'
            ProjectUri   = 'https://github.com/example-org/module'
            Organization = 'example-org'
        }
        @{
            Name         = 'GitHub SCP-style SSH'
            Repository   = 'git@github.com:example-org/module.git'
            ProjectUri   = 'https://github.com/example-org/module'
            Organization = 'example-org'
        }
        @{
            Name         = 'credentialed Bitbucket HTTPS'
            Repository   = 'https://developer@bitbucket.org/example-workspace/module.git'
            ProjectUri   = 'https://bitbucket.org/example-workspace/module'
            Organization = 'example-workspace'
        }
        @{
            Name         = 'Bitbucket SCP-style SSH'
            Repository   = 'git@bitbucket.org:example-workspace/module.git'
            ProjectUri   = 'https://bitbucket.org/example-workspace/module'
            Organization = 'example-workspace'
        }
        @{
            Name         = 'GitLab subgroup HTTPS'
            Repository   = 'https://gitlab.com/example-group/platform/module.git'
            ProjectUri   = 'https://gitlab.com/example-group/platform/module'
            Organization = 'example-group'
        }
        @{
            Name         = 'Azure DevOps HTTPS'
            Repository   = 'https://developer@dev.azure.com/example-org/platform/_git/module'
            ProjectUri   = 'https://dev.azure.com/example-org/platform/_git/module'
            Organization = 'example-org'
        }
        @{
            Name         = 'Azure DevOps SSH'
            Repository   = 'git@ssh.dev.azure.com:v3/example-org/platform/module'
            ProjectUri   = 'https://dev.azure.com/example-org/platform/_git/module'
            Organization = 'example-org'
        }
        @{
            Name         = 'legacy Azure DevOps HTTPS'
            Repository   = 'https://example-org.visualstudio.com/platform/_git/module'
            ProjectUri   = 'https://example-org.visualstudio.com/platform/_git/module'
            Organization = 'example-org'
        }
        @{
            Name         = 'self-hosted SSH with a non-web port'
            Repository   = 'ssh://git@git.example.com:2222/platform/module.git'
            ProjectUri   = 'https://git.example.com/platform/module'
            Organization = 'platform'
        }
        @{
            Name         = 'self-hosted HTTP'
            Repository   = 'http://git.example.net/platform/module.git'
            ProjectUri   = 'http://git.example.net/platform/module'
            Organization = 'platform'
        }
    ) {
        $result = Resolve-PSModuleGitRemote -RepositoryUrl $Repository

        $result.ProjectUri | Should -Be $ProjectUri
        $result.Organization | Should -Be $Organization
    }

    It 'should reject an unsupported local-path remote' {
        {
            Resolve-PSModuleGitRemote -RepositoryUrl 'C:/repos/module'
        } | Should -Throw '*Unsupported Git remote URL format*'
    }
}
