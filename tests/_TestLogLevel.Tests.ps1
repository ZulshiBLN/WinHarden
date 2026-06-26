BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "_TestLogLevel" {
    Context "Log level hierarchy checking" {
        BeforeEach {
            $env:LOG_LEVEL = 'Info'
        }

        It "returns true for Error level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Error'
                $result | Should -Be $true
            }
        }

        It "returns true for Info level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Info'
                $result | Should -Be $true
            }
        }

        It "returns false for Debug level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Debug'
                $result | Should -Be $false
            }
        }

        It "respects LOG_LEVEL env variable" {
            $env:LOG_LEVEL = 'Debug'
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Debug'
                $result | Should -Be $true
            }
        }
    }
}
