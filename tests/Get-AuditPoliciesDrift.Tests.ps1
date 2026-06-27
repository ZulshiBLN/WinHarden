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
            Mock -CommandName 'Write-Log'
        }

        It "returns empty array when audit policies are compliant" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -BeNullOrEmpty
        }

        It "returns PSCustomObject when audit policy drift detected" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Not Configured'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            $result[0] -is [System.Management.Automation.PSCustomObject] | Should -Be $true
        }

        It "includes required properties in drift objects" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Not Configured'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result[0].PSObject.Properties.Name | Should -Contain 'Category'
            $result[0].PSObject.Properties.Name | Should -Contain 'Setting'
            $result[0].PSObject.Properties.Name | Should -Contain 'Expected'
            $result[0].PSObject.Properties.Name | Should -Contain 'Actual'
            $result[0].PSObject.Properties.Name | Should -Contain 'Status'
            $result[0].PSObject.Properties.Name | Should -Contain 'Severity'
        }
    }

    Context "Audit Policy Drift Detection" {
        BeforeEach {
            Mock -CommandName 'Write-Log'
        }

        It "detects drift when Logon audit policy not configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Not Configured'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            ($result | Where-Object Setting -eq 'Logon Auditing').Status | Should -Be 'DRIFT'
        }

        It "detects drift when audit policy only has Success configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Success'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            ($result | Where-Object Setting -eq 'Logon Auditing').Status | Should -Be 'DRIFT'
        }

        It "detects drift when Sensitive Privilege Use audit policy not configured" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Success and Failure'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Not Configured'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -Not -BeNullOrEmpty
            ($result | Where-Object Setting -eq 'Sensitive Privilege Use Auditing').Status | Should -Be 'DRIFT'
        }

        It "detects drift in both Logon and Sensitive Privilege Use when both misconfigured" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Success'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result.Count | Should -Be 2
            $result[0].Status | Should -Be 'DRIFT'
            $result[1].Status | Should -Be 'DRIFT'
        }

        It "marks compliant audit policies as having no drift" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                return 'Success and Failure'
            }

            $result = Get-AuditPoliciesDrift
            $result | Should -BeNullOrEmpty
        }

        It "sets severity level to MEDIUM for audit policy drift" {
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Logon'
            } -MockWith {
                return 'Logon,Not Configured'
            }
            Mock -CommandName '_GetAuditPolicyOutput' -ParameterFilter {
                $SubcategoryName -eq 'Sensitive Privilege Use'
            } -MockWith {
                return 'Sensitive Privilege Use,Success and Failure'
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

        It "logs error when audit policy check fails" {
            Mock -CommandName '_GetAuditPolicyOutput' -MockWith {
                throw 'Error'
            }

            Get-AuditPoliciesDrift | Out-Null
            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq 'Error'
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
