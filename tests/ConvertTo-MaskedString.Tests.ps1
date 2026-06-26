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

    Context "Case-insensitive masking" {
        It "masks PASSWORD in uppercase" {
            $testInput = "PASSWORD=MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "PASSWORD=\*\*\*"
            $output | Should -Not -Match "MySecret123"
        }

        It "masks Password with mixed case" {
            $testInput = "Password=MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "Password=\*\*\*"
        }

        It "masks TOKEN in uppercase" {
            $testInput = "TOKEN=abc123xyz"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "TOKEN=\*\*\*"
        }
    }

    Context "Delimiter variations" {
        It "masks with colon delimiter" {
            $testInput = "password:MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password:\*\*\*"
        }

        It "masks with space delimiter" {
            $testInput = "password MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password \*\*\*"
        }

        It "masks with extra spaces" {
            $testInput = "password   MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password\s+\*\*\*"
        }
    }

    Context "Special pattern variants" {
        It "masks api_key (underscore variant)" {
            $testInput = "api_key=sk-1234567890"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "api_key=\*\*\*"
        }

        It "masks apikey (no underscore)" {
            $testInput = "apikey=sk-1234567890"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "apikey=\*\*\*"
        }

        It "masks credential (singular)" {
            $testInput = "credential=secret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "credential=\*\*\*"
        }

        It "masks credentials (plural)" {
            $testInput = "credentials=secret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "credentials=\*\*\*"
        }
    }

    Context "Custom patterns" {
        It "masks custom pattern" {
            $testInput = "username=admin"
            $output = ConvertTo-MaskedString -InputString $testInput -Pattern "username"
            $output | Should -Match "username=\*\*\*"
        }

        It "combines default and custom patterns" {
            $testInput = "password=secret1 username=admin"
            $output = ConvertTo-MaskedString -InputString $testInput -Pattern "username"
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "username=\*\*\*"
        }
    }

    Context "Edge cases" {
        It "handles empty string" {
            $testInput = ""
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Be ""
        }

        It "handles value with special characters" {
            $testInput = "password=p@ssw0rd!#$%"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Not -Match "p@ssw0rd"
        }

        It "handles multiple spaces in value (stops at first space)" {
            $testInput = "password=secret123 followed by text"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\* followed by text"
        }

        It "handles URL-like value" {
            $testInput = "token=https://api.example.com/path"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "token=\*\*\*"
            $output | Should -Not -Match "https"
        }

        It "handles very long value" {
            $longValue = "x" * 500
            $testInput = "password=$longValue"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Not -Match $longValue
        }
    }
}
