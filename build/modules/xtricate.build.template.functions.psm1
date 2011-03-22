function Get-Setting {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $settingname,
        [Parameter(Position=1,Mandatory=0)]
        [string] $defaultValue
    )

    foreach($setting in $psake.build_configuration_environment._settings){
        $result = Get-SettingValue $setting $settingname
        if($result -ne $null){ return $result }        
    }
    
    # then try to get the setting from the global settings
    if($result -eq $null) {
        foreach($setting in $psake.build_configuration_settings) {
            $result = Get-SettingValue $setting $settingname
            if($result -ne $null){ return $result }
        }
    }

    # if still not found return the default value
    if($result -eq $null) {
        return $defaultValue
    }
}
New-Alias -Name GetSetting -value Get-Setting -Description "" -Force

function Get-Environment {
    return $psake.build_configuration_environment
}
New-Alias -Name GetEnvironment -value Get-Environment -Description "" -Force

function Get-NodeResource {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $resourceid,
		[switch] $throwerror = $true,
        [switch] $returnnode = $false,
        [switch] $returnenvironment = $false
    )
    Write-Verbose "getting node resource with id $resourceid"
    foreach($node in $psake.build_configuration_environment._nodes){
        foreach($resource in $node._resources){
            if($resource.id -eq $resourceid){ 
                if($returnnode) { return $node }
                return $resource 
            }
        }
    }
    if($throwerror){ throw "Cannot find resource with id $resourceid on any node in environment" }
}
New-Alias -Name GetNodeResource -value Get-NodeResource -Description "" -Force

function Get-NodeResources {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $nodeid,
        [Parameter(Position=1,Mandatory=1)]
        [string] $type
    )
    Write-Verbose "getting resources on node $nodeid with type $type"
    foreach($node in $psake.build_configuration_environment._nodes){
        if($node.id -eq $nodeid){
            foreach($resource in $node._resources){
                if($resource.type -eq $type){ $resources += $resource }
            }
        }
    }
    return $resources
}
New-Alias -Name GetNodeResources -value Get-NodeResources -Description "" -Force

function Get-NodePackage {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid,
		[switch] $throwerror = $true
    )
    Write-Verbose "getting node package with id $packageid"
    foreach($node in $psake.build_configuration_environment._nodes){
        foreach($package in $node._packages){
            if($package.id -eq $packageid){ return $package }
        }
    }
	if($throwerror) { throw "Cannot find package with id $packageid on any node in environment" }
}
New-Alias -Name GetNodePackage -value Get-NodePackage -Description "" -Force

function Get-NodePackageName {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid,
		[switch] $throwerror = $true
    )
    return (Get-NodePackage $packageid -throwerror:$throwerror).name
}
New-Alias -Name GetNodePackageName -value Get-NodePackageName -Description "" -Force

# get the node for the specified package
function Get-NodePackage-Node {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid
    )
    Write-Verbose "getting node package with id $packageid"
    foreach($node in $psake.build_configuration_environment._nodes){
        foreach($package in $node._packages){
            if($package.id -eq $packageid){ return $node }
        }
    }
    throw "Cannot find package with id $packageid on any node in environment" 
}
New-Alias -Name GetNodePackageNode -value Get-NodePackage-Node -Description "" -Force

# get the name of the node for the specified package
function Get-NodePackage-Node-Name {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid
    )
    $node = Get-NodePackage-Node $packageid
    return $node.name
}
New-Alias -Name GetNodePackageNodeName -value Get-NodePackage-Node-Name -Description "" -Force

function Get-NodePackage-Name { 
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid
    )
    $package = Get-NodePackage $packageid
    return $package.name
}
New-Alias -Name GetNodePackageName -value Get-NodePackage-Name -Description "" -Force

function Get-NodePackage-Url { 
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid
    )
    $package = Get-NodePackage $packageid
    if($package.websiteref -eq $null){ throw "Cannot get url for package with id $($package.id), package is not associated with any website" }
    $resource = Get-NodeResource $package.websiteref
    # todo : check if resource has fullurl method
    if($package.virtualdir -eq $null){ return $resource.fullurl }
    return "$($resource.fullurl())/$($package.virtualdir)"
}
New-Alias -Name GetNodePackageUrl -value Get-NodePackage-Url -Description "" -Force

function Get-NodeResource-Path { 
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $resourceid
    )
    $resource = Get-NodeResource $resourceid
	if($resource.path -like ".\*"){
    	Full-Path -Path "..\$($resource.path)" # relative path specified, make full path from project root > currently .\build
	}
	else{
		$resource.path
	}
}
New-Alias -Name GetNodeResourcePath -value Get-NodeResource-Path -Description "" -Force

function Get-NodePackage-Path { 
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageid
    )
    $package = Get-NodePackage $packageid
    if($package.path -like ".\*"){
    	Full-Path -Path "..\$($package.path)" # relative path specified, make full path from project root > currently .\build
	}
	else{
		$package.path
	}
}
New-Alias -Name GetNodePackagePath -value Get-NodePackage-Path -Description "" -Force

# helper function to get the right setting value
function Get-SettingValue {
   param(
        [Parameter(Position=0,Mandatory=1)]
        $setting,
        [Parameter(Position=1,Mandatory=1)]
        [string] $settingname
    )
    if($setting.name -eq $settingname){
        if($setting.type -eq "setting"){ return $setting.value }
        if($setting.type -eq "dynamicsetting"){ return $setting._value }
    }
}
Export-Modulemember -alias * -Function *

# Setting exists function

# Ip/HostName function (input: package name) : takes into account that node might have be part of a loadbalancer

# Url function (input: package name) : package must be webpackage

# Connectionstring function : package must be databasepackage

