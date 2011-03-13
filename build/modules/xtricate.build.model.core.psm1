function Load-Model { #conflicts with psake load-configuration
	param (
		[Parameter(Position=0,Mandatory=1)]
		[string] $modelfile = $(throw "model file is a required parameter."),
        [Parameter(Position=1,Mandatory=1)]
		[string] $environment = $(throw "environment is a required parameter."),
        [Parameter(Position=2,Mandatory=0)]
		[string] $packagesPath = $null,
		[Parameter(Mandatory=0)]
		[scriptblock] $solutionpackages = $null
	)
	Write-Host "load model: $modelfile"
	import-module $modelfile -force -DisableNameChecking
    
	Write-Host "load solutionpackages: $packagespath"
    if($packagesPath -ne $null){ Load-Solution-Packages $packagesPath }
	if($solutionpackages -ne $null){ 
			Write-Host "load solutionpackages: custom"
			&$solutionpackages | Out-Null
	}
	
	# write and validate locations
	$psake.build_solution_packages | foreach { 
		Write-Host "solutionpackage: $($_.name) [$($_.packageid)] $($_.location)"
		if(!(Test-Path $_.location )){ Write-Warning "solutionpackage $($_.name) [$($_.packageid)] not found at specified location $($_.location)" }
	}
	
    foreach($env in $psake.build_configuration_environments){
        if($env.id -eq $environment){ $psake.build_configuration_environment = $env }
    }
    
    if($psake.build_configuration_environment -eq $null){ throw "environment '$environment' not found in model $file" }
}
New-Alias -Name LoadModel -value Load-Model -Description "" -Force

function Load-Solution-Packages {
	param (
        [Parameter(Position=0,Mandatory=1)]
		[string] $packagespath = $null
	)
    if(Test-Path $packagesPath){
	    $modules = Get-ChildItem $packagespath -recurse -Include "solution.package.psm1" # todo : make psm1 configurable
	    if ($modules)
	    {
	        $modules | % { 
	                $module = import-module $_ -passthru -Force -DisableNameChecking; 
	                if (!$module){ throw ("error loading package" -f $_.Name)} 
	                $solutionpackage = $psake.build_solution_packages[-1];
	                $solutionpackage.name = $_.directory.name;
	                $solutionpackage.location = RelativePath -path $_.directoryname -basepath $packagespath -combine
	                $solutionpackage.fulllocation = $_.fullname
	                #Write-Host "solution package: $($solutionpackage.name) [$($solutionpackage.packageid)] $($solutionpackage.location)";
	            }
	    }
	    else {
	        Write-Warning "skipped loading packages, none found in: $packagesPath"
	    }
	}
	else {
	    Write-Warning "skipped loading packages, directory not found: $packagesPath"
	}
}
New-Alias -Name LoadSolutionPackages -value Load-Solution-Packages -Description "" -Force

function Get-EnvironmentsPackage {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageId
    )
    foreach($environment in $psake.build_configuration_environments){
        foreach($node in $environment._nodes){
            foreach($package in $node._packages)     {
                if($package.id -eq $packageId){
                    $result = $package
                }
            }
        }
    }
    
    if($result -eq $null){
        throw "Package '$packageId' not found"
    }
    $result
}
New-Alias -Name GetEnvironmentsPackage -value Get-EnvironmentsPackage -Description "" -Force

function Get-Package {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $packageId
    )
    foreach($node in $psake.build_configuration_environment._nodes){
        foreach($package in $node._packages)     {
            if($package.id -eq $packageId){
                $result = $package
            }
        }
    }
    
    if($result -eq $null){
        throw "Package '$packageId' not found"
    }
    $result
}
New-Alias -Name GetPackage -value Get-Package -Description "" -Force

# ==========================================================================================================
Add-Type -Path ".\modules\textile.dll" # todo : make \modules directory configurable 
function Format-Textile {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $text = $(throw "text is a required parameter.")
    )
    $formatter = New-Object Textile.StringBuilderTextileFormatter
    $target = New-Object Textile.TextileFormatter -ArgumentList $formatter
    $target.Format($text)
    return $formatter.GetFormattedText() -replace "\n"
}
New-Alias -Name FormatTextile -value Format-Textile -Description "" -Force

# ==========================================================================================================
Add-Type -Path ".\modules\xtricate.core.build.dll" # todo : make \modules directory configurable 

function  Get-TopologicalSort {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string[]] $sortstring = $(throw "sortstring is a required parameter."),
        [Parameter(Position=1,Mandatory=0)]
        [switch] $reverse = $false
    )
    [Xtricate.Core.Build.TopologicalSorter]::Sort($sortstring, $reverse) 
}
New-Alias -Name TopologicalSort -value Get-TopologicalSort -Description "" -Force

function Get-Resources-TopologicalSort {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [object[]] $resources = $(throw "resources is a required parameter."), # = "A:C", "B", "D:C", "C"
        [Parameter(Position=1,Mandatory=0)]
        [switch] $reverse = $false
    )
    $resourcesarray = @()
    $resources | where { $_ -ne $null } | 
                    foreach { $resourcesarray += "$($_.type):$($_.dependson -join ",")" } 
    #Write-Host "sorting resources: $resourcesarray"
    if(arraynotnullorempty($resourcesarray)){ Get-TopologicalSort $resourcesarray $reverse }
}
New-Alias -Name GetResourcesTopologicalSort -value Get-Resources-TopologicalSort -Description "" -Force

function Get-Packages-TopologicalSort {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [object[]] $packages = $(throw "packages is a required parameter."), # = "A:C", "B", "D:C", "C"
        [Parameter(Position=1,Mandatory=0)]
        [switch] $reverse = $false
    )
    $packagessarray = @()
    $packages | where { $_ -ne $null } | 
                    foreach { $packagessarray += "$($_.id):$($_.dependson -join ",")" } 
    #Write-Host "sorting resources: $packagessarray"
    if(arraynotnullorempty($packagessarray)){ Get-TopologicalSort $packagessarray $reverse }
}
New-Alias -Name GetPackagesTopologicalSort -value Get-Packages-TopologicalSort -Description "" -Force

function Compare-Tags {
    param(
        [string[]] $modeltags,
        [string[]] $tags
    )
    if(!$modeltags) { return $true}
    if(!$tags) { return $true}
    
    $result = Compare-Object $modeltags $tags -IncludeEqual -ExcludeDifferent
    if($result){ return $true }
    else{ return $false }
}
New-Alias -Name CompareTags -value Compare-Tags -Description "" -Force

function Compare-Nodes {
    param(
		[Parameter(Position=0,Mandatory=1)]
        [string[]] $nodes,
		[Parameter(Position=1,Mandatory=0)]
        [string[]] $wildcardnodes = ""
    )
	$result=$false
    $wildcardnodes | foreach {
		foreach($node in $nodes){
			if($node -like $_) {
				$result=$true
			}
		}
	}
	return $result
}
New-Alias -Name CompareNodes -value Compare-Nodes
# ==========================================================================================================
function CurrentDate
{
	return Get-Date
}

function GeneratePassword
{
    [void][Reflection.Assembly]::LoadWithPartialName(“System.Web”)
    $result =[System.Web.Security.Membership]::GeneratePassword(10,0)
    $result.ToString()
} 

Export-Modulemember -alias * -Function *