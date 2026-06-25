@{
    Severity = @('Error', 'Warning')

    IncludeRules = @(
        # PowerShell Best Practices
        'PSUseApprovedVerbs'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSAvoidUsingCmdletAliases'
        'PSPlaceCloseBrace'
        'PSPlaceOpenBrace'
        'PSProvideCommentHelp'
        'PSMeasureBasicParseCount'
        'PSAvoidDefaultValueForMandatoryParameter'
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidGlobalVars'
        'PSAvoidInvokingEmptyMembers'
        'PSAvoidNullReferenceException'
        'PSAvoidPositionalParameters'
        'PSAvoidShouldContinueWithoutForce'
        'PSAvoidUsingComputerNameHardcoded'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingDeprecatedManifestFields'
        'PSAvoidUsingDoubleQuotesForHere Documents'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingOldCmdletSyntax'
        'PSAvoidUsingWriteHost'
        'PSMissingModuleManifestField'
        'PSReservedCmdletChar'
        'PSReservedParams'
        'PSUseApprovedVerbs'
        'PSUseBOMForUnicodeEncodedFile'
        'PSUsePSCredentialType'
        'PSUseSingularNouns'
        'PSUseToExportFieldsInManifest'
        'PSUseUtf8EncodingForHelpFile'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationLength'
            Kind = 'space'
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
            IgnoreOneLineBlock = $true
        }

        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = 'begin'
        }

        PSAvoidUsingWriteHost = @{
            Enable = $true
            CheckForFormatter = $false
        }
    }
}
