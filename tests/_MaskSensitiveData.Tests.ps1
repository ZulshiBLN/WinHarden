BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "_MaskSensitiveData" {
    Context "Private function masking" {
        It "masks password parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Not -Match "secret123"
            }
        }

        It "masks multiple parameters" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "user=admin password=pass123 token=token456"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
            }
        }

        It "is case-insensitive" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "PASSWORD=secret123 Token=token123"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
            }
        }
    }
}
