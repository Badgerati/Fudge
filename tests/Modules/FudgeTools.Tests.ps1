if ((Get-Module -Name FudgeTools | Measure-Object).Count -ne 0)
{
    Remove-Module -Name FudgeTools
}

$path = $MyInvocation.MyCommand.Path
$src = (Split-Path -Parent -Path $path) -ireplace '\\tests\\', '\src\'
$sut = ((Split-Path -Leaf -Path $path) -ireplace '\.Tests\.', '.') -ireplace '\.ps1', '.psm1'
Import-Module "$($src)\$($sut)"

Describe 'Write-Success' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Success -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Success -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Success -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Information' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Information -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Information -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Information -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Details' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Details -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Details -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Details -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Notice' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Notice -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Notice -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Notice -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Fail' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Fail -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Fail -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Fail -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-Levenshtein' {
    Context 'With no values passed' {
        It 'Should return 0' {
            Get-Levenshtein | Should Be 0
        }
    }

    Context 'With only one value passed' {
        It 'Should return 5 for value1' {
            Get-Levenshtein -Value1 'Hello' | Should Be 5
        }

        It 'Should return 8 for value1' {
            Get-Levenshtein -Value2 'Potatoes' | Should Be 8
        }
    }

    Context 'With both values being passed' {
        It 'Should be 0 when they are the same' {
            Get-Levenshtein -Value1 'Hello' -Value2 'Hello' | Should Be 0
        }

        It 'Should be 7 when values are Hello/Potatoes' {
            Get-Levenshtein -Value1 'Hello' -Value2 'Potatoes' | Should Be 7
        }
    }
}


Describe 'Test-NuspecPath' {
    Context 'With no path passed' {
        It 'Should return false with no path' {
            Test-NuspecPath | Should Be $false
        }

        It 'Should return false with null path' {
            Test-NuspecPath -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-NuspecPath -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'With a path passed' {
        It 'Should fail when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-NuspecPath -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }
        
        It 'Should fail when path is a directory' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $true } -ModuleName FudgeTools

            Test-NuspecPath -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass when path is a file' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $false } -ModuleName FudgeTools

            Test-NuspecPath -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-XmlContent' {
    Context 'With no path passed' {
        It 'Should return false with no path' {
            Test-XmlContent | Should Be $false
        }

        It 'Should return false with null path' {
            Test-XmlContent -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-XmlContent -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'With a path passed' {
        It 'Should fail when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-XmlContent -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail when content is invalid XML' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return 'invalid xml' } -ModuleName FudgeTools

            Test-XmlContent -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass when content is valid XML' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return '<root><value>something</value></root>' } -ModuleName FudgeTools

            Test-XmlContent -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-NuspecContent' {
    Context 'With no content passed' {
        It 'Should fail with no content' {
            Test-NuspecContent | Should Be $false
        }
        
        It 'Should fail with null content' {
            Test-NuspecContent -Content $null | Should Be $false
        }
    }

    Context 'With content passed' {
        It 'Should fail when no package section' {
            Test-NuspecContent -Content ([xml]'<root></root>') | Should Be $false
        }
        
        It 'Should fail when no metadata section' {
            Test-NuspecContent -Content ([xml]'<package></package>') | Should Be $false
        }
        
        It 'Should pass with right sections' {
            Test-NuspecContent -Content ([xml]'<package><metadata></metadata></package>') | Should Be $true
        }
    }
}


Describe 'Get-XmlContent' {
    Context 'When path doesn not exist or XML is invalid' {
        Mock Test-XmlContent { return $false } -ModuleName FudgeTools

        It 'Should return null with no path' {
            Get-XmlContent | Should Be $null
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return null with a path' {
            Get-XmlContent -Path 'fake' | Should Be $null
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When path exists with valid XML' {
        Mock Test-XmlContent { return $true } -ModuleName FudgeTools
        Mock Get-Content { return '<root><value>something</value></root>' } -ModuleName FudgeTools

        It 'Should return the XML content' {
            Get-XmlContent -Path 'fake' | Should BeOfType System.Xml.XmlDocument
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-PathDirectory' {
    Context 'When no path is passed' {
        It 'Should return false with no path' {
            Test-PathDirectory | Should Be $false
        }

        It 'Should return false with null path' {
            Test-PathDirectory -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-PathDirectory -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'When a path is passed' {
        It 'Should return false when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-PathDirectory -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return false when path is a file' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Item { return (New-Object -TypeName 'System.IO.FileInfo' -ArgumentList 'fake') } -ModuleName FudgeTools

            Test-PathDirectory -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Item -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return true when path is a directory' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Item { return (New-Object -TypeName 'System.IO.DirectoryInfo' -ArgumentList 'fake') } -ModuleName FudgeTools

            Test-PathDirectory -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Item -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-FudgefilePath' {
    Context 'When no path is passed' {
        It 'Should return the root Fudgefile with no path' {
            Get-FudgefilePath | Should Be './Fudgefile'
        }

        It 'Should return the root Fudgefile with null path' {
            Get-FudgefilePath -Path $null | Should Be './Fudgefile'
        }

        It 'Should return the root Fudgefile with empty path' {
            Get-FudgefilePath -Path ([string]::Empty) | Should Be './Fudgefile'
        }
    }

    Context 'When a directory path is passed' {
        It 'Should return the path if is does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Get-FudgefilePath -Path 'some/fake/path' | Should Be 'some/fake/path'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return the default Fudgefile at that path' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $true } -ModuleName FudgeTools
            Mock Join-Path { return 'some/fake/path/Fudgefile' } -ModuleName FudgeTools

            Get-FudgefilePath -Path 'some/fake/path' | Should Be 'some/fake/path/Fudgefile'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Join-Path -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When a file path is passed' {
        It 'Should return the path if is does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Get-FudgefilePath -Path 'some/fake/path.json' | Should Be 'some/fake/path.json'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return the path' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $false } -ModuleName FudgeTools

            Get-FudgefilePath -Path 'some/fake/path.json' | Should Be 'some/fake/path.json'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-FudgefileContent' {
    Context 'When no path is passed' {
        It 'Should fail parameter validation for null' {
            { Get-FudgefileContent -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Get-FudgefileContent -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When a path is passed' {
        It 'Should fail because the path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            { Get-FudgefileContent -Path 'fake' } | Should Throw 'Path to Fudgefile does not exist'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail because content is not JSON' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return 'invalid json' } -ModuleName FudgeTools

            { Get-FudgefileContent -Path 'fake' } | Should Throw 'Invalid JSON'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
        

        It 'Should pass because content is valid JSON' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return "{""key"":""value""}" } -ModuleName FudgeTools

            Get-FudgefileContent -Path 'fake' | Should BeOfType PSCustomObject

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Remove-Fudgefile' {
    Mock Write-Information { } -ModuleName FudgeTools
    Mock Write-Success { } -ModuleName FudgeTools
    Mock Write-Details { } -ModuleName FudgeTools

    Context 'When no path is passed' {
        It 'Should fail parameter validation for null' {
            { Remove-Fudgefile -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Remove-Fudgefile -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When a path is passed' {
        It 'Should fail because the path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            { Remove-Fudgefile -Path 'fake' } | Should Throw 'Path to Fudgefile does not exist'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass because the path exists' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Remove-Item { } -ModuleName FudgeTools

            { Remove-Fudgefile -Path 'fake' } | Should Not Throw

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Remove-Item -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When a path is passed with uninstall flag' {
        It 'Should pass because the path exists' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-FudgefileContent { return ('{"key":"value"}' | ConvertFrom-Json) } -ModuleName FudgeTools
            Mock Invoke-ChocolateyAction { } -ModuleName FudgeTools -ParameterFilter { $Action -ieq 'uninstall' }
            Mock Remove-Item { } -ModuleName FudgeTools

            { Remove-Fudgefile -Path 'fake' -Uninstall } | Should Not Throw

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Remove-Item -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-FudgefileContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 1 -Scope It -ModuleName FudgeTools  -ParameterFilter { $Action -ieq 'uninstall' }
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}




Describe 'Test-Chocolatey' {
    Context 'When testing if Chocolatey is installed' {
        It 'Should return false when not installed' {
            Mock Invoke-Expression { throw 'choco not found' } -ModuleName FudgeTools
            Test-Chocolatey | Should Be $false
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return true when installed' {
            Mock Invoke-Expression { return '0.10.3' } -ModuleName FudgeTools
            Mock Write-Details { } -ModuleName FudgeTools

            Test-Chocolatey | Should Be $true
            
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Install-Chocolatey' {
    Mock Write-Notice { } -ModuleName FudgeTools
    Mock Write-Success { } -ModuleName FudgeTools

    Context 'When installing Chocolatey' {
        Mock Invoke-Expression { } -ModuleName FudgeTools

        It 'Should set the execution policy when invalid' {
            Mock Get-ExecutionPolicy { return 'Restricted' } -ModuleName FudgeTools
            Mock Set-ExecutionPolicy { } -ModuleName FudgeTools

            { Install-Chocolatey } | Should Not Throw
            
            Assert-MockCalled Get-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Set-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Notice -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should not set execution policy' {
            Mock Get-ExecutionPolicy { return 'Unrestricted' } -ModuleName FudgeTools
            Mock Set-ExecutionPolicy { } -ModuleName FudgeTools

            { Install-Chocolatey } | Should Not Throw
            
            Assert-MockCalled Get-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Set-ExecutionPolicy -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Notice -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}