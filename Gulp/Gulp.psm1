$script:taskDeps = @{}
$script:taskBlocks = New-Object -TypeName PSObject

function Add-Task {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $name,
        [string[]]
        $deps = @(),
        [ScriptBlock]
        $action = {}
    )
    process {
        $script:taskDeps[$name] = $deps
        $script:taskBlocks |
            Add-Member `
                -MemberType ScriptMethod `
                -Name $name `
                -Value $action `
                -Force
    }
}

function Export-Tasks(){
    $script:taskDeps | ConvertTo-Json -Compress
}

function Invoke-Task($name){
    $originalVerbosePreference = $global:VerbosePreference
    try {
        $global:VerbosePreference = "Continue"
        $(Invoke-Command -Verbose $script:taskBlocks.$name.Script) *>&1 | %{
            $record = $_
            switch ($record.GetType().Name)
            {
                "InformationRecord" { "$record" }
                "String" { "$record" }
                "WarningRecord" { "$record" }
                "ErrorRecord" { "$record"  }
                "VerboseRecord" { "$record"  }
                default {"unknown: $_"}
            }
        } | %{
            ConvertTo-Json $_
        }
    } finally {
        $global:VerbosePreference = $originalVerbosePreference
    }
}

function Publish-Tasks{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]] $execute
    )
    process {
        if ($execute) {
            Invoke-Task $execute[0]
        } else {
            Export-Tasks
        }
    }
}

Export-ModuleMember -Function Add-Task, Publish-Tasks