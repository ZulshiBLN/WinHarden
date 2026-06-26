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

        It "masks secret" {
            $testInput = "secret=mySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "secret=\*\*\*"
            $output | Should -Not -Match "mySecret123"
        }

        It "masks authorization" {
            $testInput = "authorization=Bearer token123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "authorization=\*\*\*"
            $output | Should -Not -Match "Bearer"
        }

        It "masks bearer" {
            $testInput = "bearer=xyz789"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "bearer=\*\*\*"
            $output | Should -Not -Match "xyz789"
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

        It "handles null pattern" {
            $testInput = "password=secret1 token=xyz"
            $output = ConvertTo-MaskedString -InputString $testInput -Pattern $null
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "token=\*\*\*"
        }

        It "handles empty pattern array" {
            $testInput = "password=secret1 apikey=key123"
            $output = ConvertTo-MaskedString -InputString $testInput -Pattern @()
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "apikey=\*\*\*"
        }

        It "filters out empty strings in pattern array" {
            $testInput = "password=secret1 username=admin"
            $output = ConvertTo-MaskedString -InputString $testInput -Pattern @("", "username", $null)
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "username=\*\*\*"
        }
    }

    Context "Multiple occurrences" {
        It "masks multiple occurrences of same pattern in one line" {
            $testInput = "password=secret1 and password=secret2"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\* and password=\*\*\*"
            $output | Should -Not -Match "secret1"
            $output | Should -Not -Match "secret2"
        }

        It "masks multiple different patterns with multiple occurrences each" {
            $testInput = "password=pass1 password=pass2 token=tok1 token=tok2"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*.*password=\*\*\*"
            $output | Should -Match "token=\*\*\*.*token=\*\*\*"
            $output | Should -Not -Match "pass1"
            $output | Should -Not -Match "pass2"
            $output | Should -Not -Match "tok1"
            $output | Should -Not -Match "tok2"
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
