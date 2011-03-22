function Node {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = $null,
			[Parameter(Position=1,Mandatory=1)]
			[string[]] $name =  $null,
			[Parameter(Position=2,Mandatory=0)]
			[string[]] $ip = $null,
			[Parameter(Position=3,Mandatory=0)]
			[string[]] $domain = $null,
            [Parameter(Mandatory=0)]
		    [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $resources = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $packages = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null
	)
	New-Module -ArgumentList $id, $name, $ip, $domain, $description, $skipinstall, $skipuninstall, $resources, $packages, $settings -AsCustomObject {
		param ( $id, $name, $ip, $domain, $description, $skipinstall, $skipuninstall, $resources, $packages, $settings )	
		$type = "node"

        if($resources -ne $null){ $_resources = &$resources }
        if($packages -ne $null){ $_packages = &$packages }
        if($settings -ne $null){ $_settings = &$settings }
		
        function Resources {
			if($resources -ne $null){ &$resources }
		}
        function Packages {
			if($packages -ne $null){ &$packages }
		}
        function Settings {
            if($settings -ne $null){ &$settings }
		}
        
        function Install {
            param (
                [String[]] $tags = $null
            )
            if(!($skipinstall)){
                if($_resources){
                    Get-Resources-TopologicalSort $_resources | foreach {
                        foreach($resource in $_resources) { 
                            if($resource.type -eq $_){ 
                                if(comparetags $tags $resource.tags){ $resource.Install() }
                            }
                        }
                    }
                }
                if($_packages){
                    Get-Packages-TopologicalSort $_packages | foreach {
                        foreach($package in $_packages) { 
                            if($package.id -eq $_){ 
                            if(comparetags $tags $package.tags){ $package.Install() }
                            }
                        }
                    }
                }
            }
        }
        
        function Uninstall {
            param (
                [String[]] $tags = $null
            )
            if(!($skipuninstall)){
                if($_packages){
                    Get-Packages-TopologicalSort $_packages -reverse | foreach {
                        foreach($package in $_packages) { 
                            if($package.id -eq $_){ 
                                if(comparetags $tags $package.tags){ $package.Uninstall() }
                            }
                        }
                    }
                }
                if($_resources){
                    Get-Resources-TopologicalSort $_resources -reverse | foreach {
                        foreach($resource in $_resources) {
                            if($resource.type -eq $_){ 
                                if(comparetags $tags $resource.tags){ $resource.Uninstall() }
                            }
                        }
                    }
                }
            }
        }
		
		function SmokeTest{
			param(
                [string] $node
            )
			Write-Host "connection test: $node [$($id)] $($name)"
			if(!(Test-Connection -ComputerName $node -Quiet -Count 1)){
				Write-Warning "could not contact node $node [$($id)] $($name)"
			}
		}
		
        function Documentation {
            param (
                [String[]] $tags = $null
            )
            if($_resources -ne $null){
                Get-Resources-TopologicalSort $_resources | foreach {
                    foreach($resource in $_resources) {
                        if(($resource.type -eq $_) -and ($resource.documentation() -ne $null) -and (comparetags $tags $resource.tags)){ 
                            $resourcestext += "$($resource.documentation())`n" 
                        }
                    }
                }
            }
            if($packages -ne $null){ 
                Get-Packages-TopologicalSort $_packages | foreach {
                    foreach($package in $_packages) {
                        if(($package.id -eq $_) -and ($package.documentation() -ne $null) -and (comparetags $tags $package.tags)){ 
                            $packagestext += "$($package.documentation())`n" 
                        }
                    }
                }
            }
            @"
h2. node: $($type) $($name) [$($id)]
$description
* <strong>resources</strong>:
$($resourcestext)
* <strong>packages</strong>:
$($packagestext)
"@
        }
        
		function ToString {
			"`n  | $type [$id]: name=$name, ip=$ip, domain=$domain"
            if($resources -ne $null){ foreach($resource in &$resources){ $resource.tostring() }}
            if($packages -ne $null){ foreach($package in &$packages){ $package.tostring() }}
            if($settings -ne $null){ foreach($setting in &$settings){ $setting.tostring() }}
		}
		Export-ModuleMember -Function Packages, Install, UnInstall, Resources, Settings, SmokeTest, Documentation, ToString -Variable type, id, name, description, ip, domain, skipinstall, skipuninstall, _resources, _packages, _settings
	}
}

function Computer {
    param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = $null,
			[Parameter(Position=1,Mandatory=1)]
			[string[]] $name =  $null,
			[Parameter(Position=2,Mandatory=0)]
			[string[]] $ip = $null,
			[Parameter(Position=3,Mandatory=0)]
			[string[]] $domain = $null,
            [Parameter(Mandatory=0)]
		    [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $resources = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $packages = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null
	)
    $node = Node -id $id -name $name -ip $ip -domain $domain -description $description -skipinstall:$skipinstall -skipuninstall:$skipuninstall -resource $resources -packages $packages -settings $settings
    $node.type = "computer"
    return $node
}

function LoadBalancer {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = $null,
			[Parameter(Position=1,Mandatory=1)]
			[string] $name,
            [Parameter(Mandatory=0)]
		    [string] $description = $null,
			[Parameter(Mandatory=0)]
			[string] $ip = $null,
			[Parameter(Mandatory=0)]
			[string] $url,
            [Parameter(Mandatory=0)]
			[string] $port = "80",
            [Parameter(Mandatory=0)]
			[string] $sslport = "443",
            [Parameter(Mandatory=0)]
			[switch] $ssl,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $resources = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null
	)
	New-Module -ArgumentList $id, $name, $description, $ip, $url, $port, $sslport, $ssl, $skipinstall, $skipuninstall, $resources, $settings -AsCustomObject {
		param ( $id, $name, $description, $ip, $url, $port, $sslport, $ssl, $skipinstall, $skipuninstall, $resources, $settings )	
		$type = "loadbalancer"

        if($resources -ne $null){ $_resources = &$resources }
        if($settings -ne $null){ $_settings = &$settings }
        
        function Resources {
			if($resources -ne $null){ &$resources }
		}
        function Settings {
            if($settings -ne $null){ &$settings }
		}
        
        function FullUrl {
            return "loadbalancerurl" # TODO
        }
        
        function Install {
            if(!($skipinstall)){
            }
        }
        
        function Uninstall {
            if(!($skipuninstall)){
            }
        }
        
        function Documentation {
            if($_resources -ne $null){
                Get-Resources-TopologicalSort $_resources | foreach {
                        foreach($resource in $_resources) {
                            if(($resource.type -eq $_) -and ($resource.documentation() -ne $null)){ $resourcestext += "$($resource.documentation())`n" }
                        }
                   }
            }
            if($packages -ne $null){ &$packages | foreach { $packagestext += "$($_.documentation())`n" }}
            @"
h2. node: $($type) $($name) [$($id)]
$description
* <strong>resources</strong>:
$($resourcestext)
* <strong>packages</strong>:
$($packagestext)
"@
        }
        
		function ToString {
			"`n  | $type [$id]: name=$name, ip=$ip, url=$url"
            if($resources -ne $null){ foreach($resource in &$resources){ $resource.tostring() }}
            if($settings -ne $null){ foreach($setting in &$settings){ $setting.tostring() }}
		}
		Export-ModuleMember -Function Install, UnInstall, Resources, Settings, Documentation, ToString -Variable type, id, name, description, ip, url, port, sslport, ssl, skipinstall, skipuninstall, _resources, _settings
	}
}

function get-lburl {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $lbid
	)
    return "BLaaaHHH"
}
New-Alias -Name lburl -value get-lburl -Description "" -Force

Export-Modulemember -alias * -Function *