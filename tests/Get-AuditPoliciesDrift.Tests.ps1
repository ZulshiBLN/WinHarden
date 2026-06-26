BeforeAll {
    # Import Core module (required for Write-Log)
    $corePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $corePath -Force

    # Load the function directly to avoid module import side effects
    $functionPath = (Resolve-Path "$PSScriptRoot\..\functions\System\Drift\Get-AuditPoliciesDrift.ps1").Path
    . $functionPath

    # Load test fixtures
    $script:fixtures = Get-Content "$PSScriptRoot\fixtures\AccountPoliciesScenarios.json" | ConvertFrom-Json
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-AuditPoliciesDrift" {
    Context "Output Structure & Return Values" {
        BeforeEach {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Success and Failure'
            }
            Mock -CommandName 'Write-Log'
        }

        It "returns empty array when audit policies are compliant" {
            $result = Get-AuditPoliciesDrift
            $result | Should -BeNullOrEmpty
        }

        It "returns PSCustomObject when audit policy drift detected" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            $result -is [System.Management.Automation.PSCustomObject] | Should -Be $true
        }

        It "includes required properties in drift objects" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            $result = Get-AuditPoliciesDrift
            $result.PSObject.Properties.Name | Should -Contain 'Category'
            $result.PSObject.Properties.Name | Should -Contain 'Setting'
            $result.PSObject.Properties.Name | Should -Contain 'Expected'
            $result.PSObject.Properties.Name | Should -Contain 'Actual'
            $result.PSObject.Properties.Name | Should -Contain 'Status'
            $result.PSObject.Properties.Name | Should -Contain 'Severity'
        }
    }

    Context "Audit Policy Drift Detection" {
        BeforeEach {
            Mock -CommandName 'Write-Log'
        }

        It "detects drift when Logon audit policy not configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be 'DRIFT'
            $result.Category | Should -Be 'Audit Policy'
        }

        It "detects drift when audit policy only has Success configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Success'
            }

            $result = Get-AuditPoliciesDrift
            $result.Status | Should -Be 'DRIFT'
        }

        It "detects drift when audit policy only has Failure configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result.Status | Should -Be 'DRIFT'
        }

        It "marks compliant audit policies as having no drift" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -BeNullOrEmpty
        }

        It "sets severity level to MEDIUM for audit policy drift" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            $result = Get-AuditPoliciesDrift
            $result.Severity | Should -Be 'MEDIUM'
        }
    }

    Context "Error Handling & Resilience" {
        BeforeEach {
            Mock -CommandName 'Write-Log'
        }

        It "handles auditpol execution errors gracefully" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                throw [System.ComponentModel.Win32Exception]'Access Denied'
            }

            # Should not throw, should continue and log
            { Get-AuditPoliciesDrift } | Should -Not -Throw
        }

        It "logs warning when audit policy check fails" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                throw 'Error'
            }

            Get-AuditPoliciesDrift | Out-Null
            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq 'Warning'
            } -Scope It
        }

        It "logs error message with descriptive context" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                throw 'Access Denied'
            }

            Get-AuditPoliciesDrift | Out-Null
            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match 'Error checking audit policies'
            } -Scope It
        }
    }

    Context "Logging Behavior" {
        It "logs audit policy drift finding to Write-Log" {
            Mock -CommandName 'Write-Log'
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            Get-AuditPoliciesDrift | Out-Null
            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq 'Warning' -and $Message -match 'Audit Policy drift'
            } -Scope It
        }

        It "includes function caller name in log messages" {
            Mock -CommandName 'Write-Log'
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }

            Get-AuditPoliciesDrift | Out-Null
            Assert-MockCalled Write-Log -ParameterFilter {
                $Caller -eq 'Get-AuditPoliciesDrift'
            } -Scope It
        }
    }

    Context "WhatIf Support" {
        BeforeEach {
            Mock -CommandName 'Write-Log'
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Logon,Not Configured'
            }
        }

        It "supports -WhatIf parameter without errors" {
            { Get-AuditPoliciesDrift -WhatIf } | Should -Not -Throw
        }
    }

    Context "Documentation Compliance" {
        It "function is properly defined and callable" {
            Get-Command Get-AuditPoliciesDrift | Should -Not -BeNullOrEmpty
            (Get-Command Get-AuditPoliciesDrift).CommandType | Should -Be 'Function'
        }

        It "has comment-based help with SYNOPSIS" {
            $functionSource = Get-Content $functionPath -Raw
            $functionSource | Should -Match '\.SYNOPSIS'
        }

        It "includes DEPENDENCIES in help documentation" {
            $functionSource = Get-Content $functionPath -Raw
            $functionSource | Should -Match 'DEPENDENCIES'
        }

        It "includes NOTES section in help" {
            $functionSource = Get-Content $functionPath -Raw
            $functionSource | Should -Match '\.NOTES'
        }
    }
}
