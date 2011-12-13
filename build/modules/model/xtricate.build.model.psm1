function Configuration {
	param (
        [Parameter(Position=0,Mandatory=0)]
		[scriptblock] $settings = $null,
		[Parameter(Position=1,Mandatory=1)]
		[scriptblock] $environments = $null
	)
	New-Module -ArgumentList $settings, $environments -AsCustomObject {
		param ( $settings, $environments )
		$type = "configuration"
        
        if($settings -ne $null){ $_settings = &$settings }
        if($environments -ne $null){ $_environments = &$environments }
        
        $psake.build_configuration_settings = @($_settings)
		$psake.build_configuration_environments = @($_environments)
        $psake.build_solution_packages = @()
	}
}

function Environment {
	param (
		[Parameter(Position=0,Mandatory=1)]
		[string] $id = $null,
		[Parameter(Position=1,Mandatory=1)]
		[string] $name =  $null,
		[Parameter(Position=2,Mandatory=0)]
		[string] $description = $null,
		[Parameter(Mandatory=0)]
        [scriptblock] $settings = $null,
        [Parameter(Mandatory=0)]
		[scriptblock] $nodes = $null
	)
	New-Module -ArgumentList $id, $name, $description, $nodes, $settings -AsCustomObject {
		param ( $id, $name, $description, $nodes, $settings )
		$type = "environment"
        
        if($nodes -ne $null){ $_nodes = &$nodes }
        if($settings -ne $null){ $_settings = &$settings }

		function Nodes {
			&$nodes
		}
  
        function Settings {
			&$settings
		}

        function Documentation {
            param (
                [String[]] $tags = $null
            )
            if($nodes -ne $null){ &$nodes | foreach { $nodestext += "$($_.documentation($tags))`n" }}
            if($psake.build_solution_packages -ne $null){ 
                $psake.build_solution_packages | 
                foreach { $media += "| [$($_.packageid)] | $($_.location) |`n"} # todo : check package tags, not easy because only solution package known here
            }
            Format-Textile `
@"
h1. environment: $($name) [$($id)]
$($description)`n
h2. installation packages locations
$($media)
$($nodestext)
"@
        }

        function ToString {
			"`n| $type [$id]: name=$name"
            
            if($settings -ne $null){
                foreach($setting in &$settings){ $setting.tostring() }
            }
		}
		Export-ModuleMember -Function Nodes, Settings, Documentation, ToString -Variable type, id, name, description, _nodes, _settings
	}
}
#New-Alias -Name environment -value New-Environment -Description "" -Force

function DomainIdentity {
                # AD users : http://technet.microsoft.com/en-us/library/ee617195.aspx
}

function Solution-Package{
	param (
			[Parameter(Position=0, Mandatory=1)]
			[string] $packageid = "",
            [Parameter(Position=1, Mandatory=0)]
			[string] $name,
			[Parameter(Position=2,Mandatory=0)]
			[string] $location,
			[Parameter(Mandatory=0)]
			[scriptblock] $settings = $null
	)
	New-Module -ArgumentList $packageid, $name, $location, $settings -AsCustomObject {
		param ( $packageid, $name, $location, $settings )
		$type = "configurationpackage"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
       	#construct the new solution package
        $psake.build_solution_packages += new-object psobject -property @{
            packageid=$packageid;
            name=$name;
            location=$location;
            fulllocation=$null; # not needed
            settings=$_settings;
        }
 
		Export-ModuleMember -Function Settings -Variable type, packageid, location, name, _settings
	}
}
New-Alias -Name SolutionPackage -value Solution-Package -Description "" -Force

Export-Modulemember -alias * -Function *