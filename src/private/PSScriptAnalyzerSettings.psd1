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
            # core-6.1.0-windows is the newest profile bundled with PSScriptAnalyzer.
            PowerShellVersion = @('core-6.1.0-windows')
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
            # core-6.1.0-windows is the newest profile bundled with PSScriptAnalyzer.
            compatibility = @('core-6.1.0-windows')
        }
        PSUseCompatibleSyntax                      = @{
            Enable         = $true
            TargetVersions = @(
                '7.0',
                '5.1'
            )
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
            # Throws when command discovery encounters some Crescendo-generated modules.
            # Disable until fixed.
            Enable = $false
        }
        PSUseSingleValueFromPipelineParameter      = @{
            Enable = $true
        }
        PSUseSingularNouns                         = @{
            Enable        = $true
            NounAllowList = 'Data', 'Windows'
        }
    }
}
