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

        # EXCEPTION: Disable PSUseSingularNouns for Test-WinOpsKitDependencies
        # Reason: Plural "Dependencies" is semantically correct because:
        # - Function validates MULTIPLE dependencies (PowerShell version + modules)
        # - Returns MULTIPLE result entries (hash with multiple keys)
        # - Accepts MULTIPLE modules (array parameter)
        # - Follows PowerShell precedent: Get-ChildItem, Get-Module (plural nouns)
        # Status: This is a documented exception to the naming rule
        PSUseSingularNouns = @{
            Enable = $false
        }
    }
}
