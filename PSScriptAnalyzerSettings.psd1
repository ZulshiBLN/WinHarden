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
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $false
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
            IgnoreOneLineBlock = $false
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckComma = $true
        }

        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = 'begin'
        }

        # POLICY: Private functions (prefix _) require only .SYNOPSIS, not full help
        # REASON: Private functions are internal helpers, not public API (STRUCTURE.md Regel 3.1)
        # Note: ExportedOnly = $true means only functions exported from modules get full help enforcement
        # Private functions should have at least .SYNOPSIS or inline comments for clarity

        PSAvoidUsingWriteHost = @{
            Enable = $true
            CheckForFormatter = $false
        }

        # EXCEPTION: PSAvoidUsingInvokeExpression (Test-HardeningCompliance.ps1, line 249)
        # Reason: Invoke-Expression used ONLY with trusted, static profile data (.psd1 files)
        # - Profile commands are not user input (loaded from codebase)
        # - This is an approved exception per ADR-004 and CLAUDE.md Regel 1.4
        # - Alternative refactors (scriptblock objects) would require large profile changes
        # Status: Documented exception with clear reasoning and scope limitation
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }

        # EXCEPTION: Disable PSUseSingularNouns for Test-WinHardenDependencies
        # Reason: Plural "Dependencies" is semantically correct because:
        # - Function validates MULTIPLE dependencies (PowerShell version + modules)
        # - Returns MULTIPLE result entries (hash with multiple keys)
        # - Accepts MULTIPLE modules (array parameter)
        # - Follows PowerShell precedent: Get-ChildItem, Get-Module (plural nouns)
        # Status: This is a documented exception to the naming rule
        PSUseSingularNouns = @{
            Enable = $false
        }

        # EXCEPTION: Is-Prefix for Boolean Functions (ADR-007, STRUCTURE.md Regel 8.7)
        # Boolean functions use 'Is' prefix instead of official Approved Verbs (Get, Test, etc.)
        # - 'Is' is more idiomatically correct for status checks: Is-Healthy, Is-Valid, Is-Installed
        # - Compare: Is-Healthy (more intuitive) vs. Test-Health or Get-HealthStatus (verbose)
        # - This follows common programming conventions: Python has .is_valid(), C# has IsValid property
        # Reason: 'Is' is semantically clearer for boolean-returning functions
        # Note: PSUseApprovedVerbs still enforces other approved verbs; only 'Is' is allowed for boolean functions
        # Status: Documented exception, allowed in codebase (ADR-007, Zeile 360-361)
    }
}
