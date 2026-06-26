BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "ConvertTo-MaskedString" {
    Context "Single sensitive keyword masking" {
        It "masks password" {
            $testInput = "password=MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Not -Match "MySecret123"
        }
    }

    Context "Multiple sensitive keywords" {
        It "masks multiple sensitive keywords" {
            $testInput = "password=secret1 token=token2 apikey=key3"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "token=\*\*\*"
            $output | Should -Match "apikey=\*\*\*"
        }
    }

    Context "Non-sensitive content" {
        It "preserves non-sensitive content" {
            $testInput = "Server connection to SRV01 successful"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Be $testInput
        }
    }
}
