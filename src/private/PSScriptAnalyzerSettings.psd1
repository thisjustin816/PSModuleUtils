@{
    Rules = @{
        PSAlignAssignmentStatement       = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSAvoidLongLines                 = @{
            Enable            = $true
            MaximumLineLength = 120
        }
        PSAvoidOverwritingBuiltInCmdlets = @{
            PowerShellVersion = @('core-6.1.0-windows')
        }
        PSAvoidUsingCmdletAliases        = @{
            allowlist = @()
        }
        PSAvoidUsingWriteHost            = @{
            Enable = $false
        }
        PSPlaceCloseBrace                = @{
            Enable             = $true
            NoEmptyLineBefore  = $true
            IgnoreOneLineBlock = $true
            NewLineAfter       = $true
        }
        PSPlaceOpenBrace                 = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSProvideCommentHelp             = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $true
            Placement               = 'before'
        }
        PSReviewUnusedParameter          = @{
            CommandsToTraverse = @()
        }
        PSUseCompatibleCmdlets           = @{
            compatibility = @('core-6.1.0-windows')
        }
        PSUseCompatibleSyntax            = @{
            Enable         = $true
            TargetVersions = @(
                '6.0',
                '5.1'
            )
        }
        PSUseConsistentIndentation       = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace        = @{
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
        PSUseCorrectCasing               = @{
            Enable = $true
        }
        PSUseSingularNouns               = @{
            Enable        = $true
            NounAllowList = 'Data', 'Windows'
        }
    }
}