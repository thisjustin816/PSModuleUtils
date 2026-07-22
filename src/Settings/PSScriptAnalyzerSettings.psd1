# https://github.com/PowerShell/vscode-powershell/blob/main/examples/PSScriptAnalyzerSettings.psd1
#
# Use the PowerShell extension setting `powershell.scriptAnalysis.settingsPath` to get the current workspace
# to use this PSScriptAnalyzerSettings.psd1 file to configure code analysis in Visual Studio Code.
# This setting is configured in the workspace's `.vscode/settings.json`.
#
# For more information on PSScriptAnalyzer settings see:
# https://github.com/PowerShell/PSScriptAnalyzer/blob/master/README.md#settings-support-in-scriptanalyzer
#
# You can see the predefined PSScriptAnalyzer settings here:
# https://github.com/PowerShell/PSScriptAnalyzer/tree/master/Engine/Settings
@{
    # Only diagnostic records of the specified severity will be generated.
    # Uncomment the following line if you only want Errors and Warnings but
    # not Information diagnostic records.

    # Severity = @('Error', 'Warning')

    # Optional custom rule settings. Uncomment and adjust these when loading
    # rules that are not bundled with PSScriptAnalyzer.

    # CustomRulePath = @('/path/to/custom/rules')
    # IncludeDefaultRules = $true
    # RecurseCustomRulePath = $true

    # Analyze **only** the following rules. Use IncludeRules when you want
    # to invoke only a small subset of the default rules.

    # IncludeRules = @(
    #     'PSAvoidDefaultValueSwitchParameter',
    #     'PSMisleadingBacktick',
    #     'PSMissingModuleManifestField',
    #     'PSReservedCmdletChar',
    #     'PSReservedParams',
    #     'PSShouldProcess',
    #     'PSUseApprovedVerbs',
    #     'PSAvoidUsingCmdletAliases',
    #     'PSUseDeclaredVarsMoreThanAssignments'
    # )

    # Do not analyze the following rules. Use ExcludeRules when you have
    # commented out the IncludeRules settings above and want to include all
    # the default rules except for those you exclude below.
    # Note that if a rule is in both IncludeRules and ExcludeRules, the rule
    # will be excluded.

    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )

    # You can use rule configuration to configure rules that support it:

    Rules        = @{
        PSAlignAssignmentStatement                 = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSAvoidLongLines                           = @{
            Enable            = $true
            MaximumLineLength = 120
        }
        PSAvoidExclaimOperator                     = @{
            Enable = $true
        }
        PSAvoidMultipleTypeAttributes              = @{
            Enable = $true
        }
        PSAvoidOverwritingBuiltInCmdlets           = @{
            PowerShellVersion = @(
                'desktop-5.1.14393.206-windows'
                'core-6.1.0-windows'
            )
        }
        PSAvoidSemicolonsAsLineTerminators         = @{
            Enable = $true
        }
        PSAvoidUsingAllowUnencryptedAuthentication = @{
            Enable = $true
        }
        PSAvoidUsingBrokenHashAlgorithms           = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases                  = @{
            allowlist = @()
        }
        PSAvoidUsingPositionalParameters           = @{
            CommandAllowList = @(
                'ForEach-Object'
                'Join-Path'
                'Where-Object'
                'Write-Debug'
                'Write-Error'
                'Write-Host'
                'Write-Information'
                'Write-Output'
                'Write-Progress'
                'Write-Verbose'
                'Write-Warning'
            )
        }
        PSAvoidUsingDoubleQuotesForConstantString  = @{
            Enable = $true
        }
        PSPlaceCloseBrace                          = @{
            Enable             = $true
            NoEmptyLineBefore  = $true
            IgnoreOneLineBlock = $true
            NewLineAfter       = $true
        }
        PSPlaceOpenBrace                           = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSProvideCommentHelp                       = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $true
            Placement               = 'before'
        }
        PSReviewUnusedParameter                    = @{
            CommandsToTraverse = @()
        }
        PSUseCompatibleCmdlets                     = @{
            compatibility = @(
                'desktop-5.1.14393.206-windows'
                'core-6.1.0-windows'
            )
        }
        PSUseCompatibleCommands                    = @{
            Enable         = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
            )
            # ProfileDirPath = '/path/to/compatibility/profiles'
            # Pester is a required module, so its version is controlled by each consuming module.
            IgnoreCommands = @('Invoke-Pester')
        }
        PSUseCompatibleSyntax                      = @{
            Enable         = $true
            TargetVersions = @(
                '7.0',
                '5.1'
            )
        }
        PSUseCompatibleTypes                       = @{
            Enable         = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
            )
            # ProfileDirPath = '/path/to/compatibility/profiles'
            IgnoreTypes    = @()
        }
        PSUseConstrainedLanguageMode               = @{
            Enable           = $false
            IgnoreSignatures = @()
        }
        PSUseConsistentParameterSetName            = @{
            Enable = $true
        }
        PSUseConsistentParametersKind              = @{
            Enable = $true
        }
        PSUseConsistentIndentation                 = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace                  = @{
            Enable                                  = $true
            CheckInnerBrace                         = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $true
            CheckSeparator                          = $true
            CheckParameter                          = $true
            IgnoreAssignmentOperatorInsideHashTable = $true
        }
        PSUseCorrectCasing                         = @{
            Enable        = $true
            CheckCommands = $true
            CheckKeyword  = $true
            CheckOperator = $true
        }
        PSUseSingleValueFromPipelineParameter      = @{
            Enable = $true
        }
        PSUseSingularNouns                         = @{
            Enable        = $true
            NounAllowList = 'Data', 'Metadata', 'Settings', 'Windows'
        }
    }
}
