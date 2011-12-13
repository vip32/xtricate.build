function Setting {
	param (
		[Parameter(Position=0,Mandatory=1)]
		[string] $name = $null,
        [Parameter(Position=1,Mandatory=1)]
		[string] $value = $null
	)
	New-Module -ArgumentList $name, $value -AsCustomObject {
		param ( $name, $value )
		$type = "setting"
        
        function ToString(){
			"| $type [$name]: value=$value"
		}
		Export-ModuleMember ToString -Variable type, name, value
	}
}

function DynamicSetting {
	param (
		[Parameter(Position=0,Mandatory=1)]
		[string] $name = $null,
        [Parameter(Position=1,Mandatory=1)]
		[scriptblock] $value = $null
	)
	New-Module -ArgumentList $name, $value -AsCustomObject {
		param ( $name, $value )
		$type = "dynamicsetting"
        
        if($value -ne $null){
            $_value = &$value
        }
        
        function ToString(){
			"| $type [$name]: value=$_value"
		}
		Export-ModuleMember -Function ToString -Variable type, name, _value
	}
}

