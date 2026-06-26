BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "_MaskSensitiveData" {
    Context "Basic masking" {
        It "masks password parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Not -Match "secret123"
            }
        }

        It "masks token parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "token=abc123xyz"
                $result | Should -Match "token=\*\*\*"
            }
        }

        It "masks apikey parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "apikey=key123456"
                $result | Should -Match "apikey=\*\*\*"
            }
        }

        It "masks secret parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "secret=data123"
                $result | Should -Match "secret=\*\*\*"
            }
        }
    }

    Context "Multiple and mixed patterns" {
        It "masks multiple parameters in single string" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "user=admin password=pass123 token=token456"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
                $result | Should -Match "user=admin"
            }
        }

        It "masks all sensitive keyword variations" {
            InModuleScope Core {
                $input = "password=p1 token=t1 secret=s1 apikey=a1 api_key=ak1 private_key=pk1 auth=au1 credential=c1"
                $result = _MaskSensitiveData -InputString $input
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
                $result | Should -Match "secret=\*\*\*"
                $result | Should -Match "apikey=\*\*\*"
                $result | Should -Match "api_key=\*\*\*"
                $result | Should -Match "private_key=\*\*\*"
                $result | Should -Match "auth=\*\*\*"
                $result | Should -Match "credential=\*\*\*"
            }
        }
    }

    Context "Case-insensitive matching" {
        It "masks uppercase password" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "PASSWORD=secret123"
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "masks mixed case token" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "ToKeN=token456"
                $result | Should -Match "token=\*\*\*"
            }
        }

        It "handles mixed case in entire string" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "PASSWORD=secret123 Token=token123 ApiKey=key789"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
                $result | Should -Match "apikey=\*\*\*"
            }
        }
    }

    Context "Different delimiter styles" {
        It "masks with equals sign" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=mypassword"
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "masks with colon" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password:mypassword"
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "masks with whitespace around delimiter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password  =  secret"
                $result | Should -Match "password=\*\*\*"
            }
        }
    }

    Context "Value boundaries" {
        It "stops at whitespace" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123 otherstuff"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "otherstuff"
            }
        }

        It "stops at comma" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123,other=value"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "other=value"
            }
        }

        It "stops at semicolon" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123;other=value"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "other=value"
            }
        }

        It "stops at double quote" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString 'password=secret123"other'
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "stops at single quote" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123'other"
                $result | Should -Match "password=\*\*\*"
            }
        }
    }

    Context "Edge cases" {
        It "rejects empty input string" {
            InModuleScope Core {
                { _MaskSensitiveData -InputString "" } | Should -Throw
            }
        }

        It "preserves non-sensitive data" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "username=admin hostname=server01"
                $result | Should -Match "username=admin"
                $result | Should -Match "hostname=server01"
            }
        }

        It "handles parameter without value" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password="
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "masks value with numbers and special chars" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=P@ssw0rd!#$%"
                # Should stop at first special char outside alphanumeric
                $result | Should -Match "password=\*\*\*"
            }
        }

        It "handles consecutive sensitive parameters" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=pass1 token=tok1 secret=sec1"
                $result | Should -Match "password=\*\*\*.*token=\*\*\*.*secret=\*\*\*"
            }
        }
    }

    Context "Real-world scenarios" {
        It "masks connection string with password" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "Server=db01;User=admin;Password=P@ss123"
                $result | Should -Match "Server=db01"
                $result | Should -Match "User=admin"
                $result | Should -Match "Password=\*\*\*"
            }
        }

        It "masks API configuration" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "api_key=sk-12345abc endpoint=https://api.example.com"
                $result | Should -Match "api_key=\*\*\*"
                $result | Should -Match "endpoint=https://api.example.com"
            }
        }

        It "masks credential object representation" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "credential=System.Management.Automation.PSCredential"
                $result | Should -Match "credential=\*\*\*"
            }
        }
    }
}
