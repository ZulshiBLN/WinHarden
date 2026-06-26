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

        AfterEach {
            Remove-Item -Path 'env:LOG_LEVEL' -ErrorAction SilentlyContinue
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

        It "returns false for Verbose level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Verbose'
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

        It "allows Verbose level when LOG_LEVEL is Verbose" {
            $env:LOG_LEVEL = 'Verbose'
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Verbose'
                $result | Should -Be $true
            }
        }
    }

    Context "Parameter validation" {
        AfterEach {
            Remove-Item -Path 'env:LOG_LEVEL' -ErrorAction SilentlyContinue
        }

        It "rejects invalid log level" {
            InModuleScope Core {
                { _TestLogLevel -Level 'InvalidLevel' } | Should -Throw
            }
        }

        It "requires Level parameter" {
            InModuleScope Core {
                { _TestLogLevel } | Should -Throw
            }
        }
    }

    Context "Default behavior when LOG_LEVEL not set" {
        BeforeEach {
            Remove-Item -Path 'env:LOG_LEVEL' -ErrorAction SilentlyContinue
        }

        AfterEach {
            Remove-Item -Path 'env:LOG_LEVEL' -ErrorAction SilentlyContinue
        }

        It "defaults to Info level" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Info'
                $result | Should -Be $true
            }
        }

        It "filters Debug when LOG_LEVEL not set" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Debug'
                $result | Should -Be $false
            }
        }
    }
}
