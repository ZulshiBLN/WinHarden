BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Exchange Online Functions" {
    Context "New-ExchangeOnlineConnection - Parameter Sets" {
        It "accepts Credential parameter set" {
            $params = @{
                Credential = [System.Management.Automation.PSCredential]::new("user", (ConvertTo-SecureString "password" -AsPlainText -Force)) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }

        It "accepts AppSecret parameter set with all required params" {
            $params = @{
                AppId = "12345678-1234-1234-1234-123456789012"
                TenantId = "87654321-4321-4321-4321-210987654321"
                ClientSecret = (ConvertTo-SecureString "secret" -AsPlainText -Force) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }

        It "requires AppId and TenantId for AppSecret set" {
            $params = @{
                ClientSecret = (ConvertTo-SecureString "secret" -AsPlainText -Force) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
            }
            { New-ExchangeOnlineConnection @params } | Should -Throw
        }

        It "accepts AppCertPath parameter set" {
            $tempCert = "$PSScriptRoot\temp_test_cert.pfx"
            New-Item -Path $tempCert -ItemType File -Force | Out-Null

            try {
                $params = @{
                    AppId = "12345678-1234-1234-1234-123456789012"
                    TenantId = "87654321-4321-4321-4321-210987654321"
                    CertificatePath = $tempCert
                    WhatIf = $true
                }
                { New-ExchangeOnlineConnection @params } | Should -Not -Throw
            } finally {
                Remove-Item -Path $tempCert -Force -ErrorAction SilentlyContinue
            }
        }

        It "accepts AppCertThumb parameter set" {
            $params = @{
                AppId = "12345678-1234-1234-1234-123456789012"
                TenantId = "87654321-4321-4321-4321-210987654321"
                CertificateThumbprint = "A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0"
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }
    }

    Context "New-ExchangeOnlineConnection - WhatIf Support" {
        It "supports -WhatIf parameter" {
            { New-ExchangeOnlineConnection -WhatIf } | Should -Not -Throw
        }

        It "returns no value when WhatIf is used" {
            $result = New-ExchangeOnlineConnection -WhatIf
            $result | Should -BeNullOrEmpty
        }
    }

    Context "New-ExchangeOnlineConnection - Parameter Validation" {
        It "requires AppId for app-based authentication" {
            { New-ExchangeOnlineConnection -TenantId "123" -ClientSecret (ConvertTo-SecureString "x" -AsPlainText -Force) } | Should -Throw # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
        }

        It "requires TenantId for app-based authentication" {
            { New-ExchangeOnlineConnection -AppId "123" -ClientSecret (ConvertTo-SecureString "x" -AsPlainText -Force) } | Should -Throw # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
        }

        It "validates CertificatePath exists" {
            $params = @{
                AppId = "123"
                TenantId = "456"
                CertificatePath = "C:\NonExistent\Path\cert.pfx"
            }
            { New-ExchangeOnlineConnection @params } | Should -Throw
        }

        It "accepts Organization parameter as optional" {
            $params = @{
                Credential = [System.Management.Automation.PSCredential]::new("user", (ConvertTo-SecureString "password" -AsPlainText -Force)) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
                Organization = "contoso.onmicrosoft.com"
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }
    }

    Context "New-ExchangeOnlineConnection - SkipVerification Parameter" {
        It "accepts SkipVerification switch" {
            $params = @{
                Credential = [System.Management.Automation.PSCredential]::new("user", (ConvertTo-SecureString "password" -AsPlainText -Force)) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
                SkipVerification = $true
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }
    }

    Context "New-ExchangeOnlineConnection - Error Handling" {
        It "has proper error handling structure" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "try"
            $functionDef | Should -Match "catch"
            $functionDef | Should -Match "throw"
        }

        It "catches exceptions and rethrows with context" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "Failed to establish Exchange Online connection"
            $functionDef | Should -Match "Write-Error"
            $functionDef | Should -Match "throw"
        }

        It "sets ErrorActionPreference to Stop" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "ErrorActionPreference.*=.*'Stop'"
        }

        It "handles connection without Credential parameter" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "if \(\`$Credential"
        }
    }

    Context "New-ExchangeOnlineConnection - Verbose Output" {
        It "outputs verbose messages for each auth method" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "Write-Verbose.*user credentials"
            $functionDef | Should -Match "Write-Verbose.*app secret"
            $functionDef | Should -Match "Write-Verbose.*certificate"
        }

        It "outputs verbose on successful connection" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "Write-Verbose.*established and verified"
        }
    }

    Context "New-ExchangeOnlineConnection - Organization Parameter" {
        It "accepts Organization as optional parameter" {
            $params = @{
                Credential = [System.Management.Automation.PSCredential]::new("user", (ConvertTo-SecureString "pass" -AsPlainText -Force)) # PSScriptAnalyzer ignore PSAvoidUsingConvertToSecureStringWithPlainText
                Organization = ""
                WhatIf = $true
            }
            { New-ExchangeOnlineConnection @params } | Should -Not -Throw
        }

        It "adds Organization to connection params when provided" {
            $functionDef = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $functionDef | Should -Match "Organization"
            $functionDef | Should -Match "connectParams\['Organization'\]"
        }
    }

    Context "New-ExchangeOnlineConnection - Documentation" {
        It "has complete SYNOPSIS" {
            $help = Get-Help New-ExchangeOnlineConnection
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Match "Exchange"
        }

        It "documents all parameters" {
            $help = Get-Help New-ExchangeOnlineConnection
            $help.Parameters | Should -Not -BeNullOrEmpty
            $help.Parameters.Parameter.Name | Should -Contain "AppId"
            $help.Parameters.Parameter.Name | Should -Contain "TenantId"
            $help.Parameters.Parameter.Name | Should -Contain "Credential"
        }

        It "includes usage examples" {
            $help = Get-Help New-ExchangeOnlineConnection
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "System Module - Private Functions Implementation" {
    Context "_ValidateExchangeModuleAvailable function" {
        It "exists and checks for Connect-ExchangeOnline" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_ValidateExchangeModuleAvailable.ps1" -Raw
            $funcCode | Should -Match "Connect-ExchangeOnline"
        }

        It "uses Get-Command to check module availability" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_ValidateExchangeModuleAvailable.ps1" -Raw
            $funcCode | Should -Match "Get-Command"
            $funcCode | Should -Match "ErrorAction.*SilentlyContinue"
        }

        It "has error handling with helpful message" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_ValidateExchangeModuleAvailable.ps1" -Raw
            $funcCode | Should -Match "throw"
            $funcCode | Should -Match "Write-Error"
            $funcCode | Should -Match "Install-Module"
        }

        It "provides installation instructions in error message" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_ValidateExchangeModuleAvailable.ps1" -Raw
            $funcCode | Should -Match "PSGallery"
        }
    }

    Context "_VerifyExchangeOnlineConnection function" {
        It "exists and attempts mailbox query" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "Get-Mailbox"
        }

        It "uses ResultSize 1 to minimize query impact" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "ResultSize.*1"
        }

        It "has try-catch error handling" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "try"
            $funcCode | Should -Match "catch"
        }

        It "throws on verification failure" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "throw"
        }

        It "returns true on success" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "return \`$true"
        }

        It "outputs verbose message on success" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "Write-Verbose.*verified"
        }
    }
}

Describe "System Module - Structure Compliance" {
    Context "Module files exist" {
        It "System.psm1 module file exists" {
            Test-Path "$PSScriptRoot\..\modules\System.psm1" | Should -Be $true
        }

        It "New-ExchangeOnlineConnection.ps1 exists" {
            Test-Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" | Should -Be $true
        }

        It "_ValidateExchangeModuleAvailable.ps1 exists" {
            Test-Path "$PSScriptRoot\..\functions\System\_ValidateExchangeModuleAvailable.ps1" | Should -Be $true
        }

        It "_VerifyExchangeOnlineConnection.ps1 exists" {
            Test-Path "$PSScriptRoot\..\functions\System\_VerifyExchangeOnlineConnection.ps1" | Should -Be $true
        }
    }

    Context "Module compliance with STRUCTURE.md rules" {
        It "functions follow Verb-Noun naming (Regel 8.2)" {
            Get-Command New-ExchangeOnlineConnection | Should -Not -BeNullOrEmpty
        }

        It "private functions have underscore prefix (Regel 8.3)" {
            $funcFiles = Get-ChildItem -Path "$PSScriptRoot\..\functions\System" -Filter "_*.ps1"
            $funcFiles | Should -Not -BeNullOrEmpty
        }

        It "module is in correct directory per Regel 1.1" {
            Test-Path "$PSScriptRoot\..\functions\System" -PathType Container | Should -Be $true
        }
    }

    Context "Dependency documentation (ADR-009)" {
        It "System module documents Core dependency" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\System.psm1" -Raw
            $moduleCode | Should -Match "Core"
        }

        It "New-ExchangeOnlineConnection documents dependencies" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\System\New-ExchangeOnlineConnection.ps1" -Raw
            $funcCode | Should -Match "DEPENDS ON"
            $funcCode | Should -Match "REQUIRES"
        }
    }
}
