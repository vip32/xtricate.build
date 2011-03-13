function FilePackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=1)]
			[string[]] $webappref,
            [Parameter(Position=3,Mandatory=0)]
			[string[]] $items = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $webappref, $items, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $webappref, $items, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags )
		$type = "filepackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id]" 
                 # todo : template and copy to website path
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id]" 
            }
		}
        
		function Export(){
            param (
                [Parameter(Position=0,Mandatory=1)]
                [string] $source = $(throw "source is a required parameter."),
                [Parameter(Position=1,Mandatory=1)]
                [string] $target = $(throw "target is a required parameter.")
            )
            Copy-Package $source $target
		}

        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                             |_<. setting |_<. value |
                                             | website resource |  ""$($webappref)"":$($webappref) |
                                             | items | $($items) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, webappref, items, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function SharePoint2007Site {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=0)]
			[string] $identityref = "",
            [Parameter(Position=3,Mandatory=1)]
			[string[]] $webappref,
            [Parameter(Mandatory=0)]
			[string[]] $importitems, 
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $identityref, $webappref, $importitems, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $identityref, $webappref, $importitems, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags )
		$type = "sharepoint2007site"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
		function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id]" 
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id]" 
            }
		}
		
		function Export(){
            param (
                [Parameter(Position=0,Mandatory=1)]
                [string] $source = $(throw "source is a required parameter."),
                [Parameter(Position=1,Mandatory=1)]
                [string] $target = $(throw "target is a required parameter.")
            )
            Copy-Package $source $target
		}

        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | identityref | ""$($identityref)"":$($identityref) |
                                            | webapp resource | ""$($webappref)"":$($webappref) | 
                                            | importitems | $($importitems) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, identityref, webappref, importitems, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function SharePoint2007Solution {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=1)]
			[string[]] $webappref,
            [Parameter(Mandatory=0)]
			[string[]] $filenames, 
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $webappref, $filenames, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $webappref, $filenames, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $settings, $dependson, $tags )
		$type = "sharepoint2007solution"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
		function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id]" 
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id]" 
            }
		}
		
		function Export(){
            param (
                [Parameter(Position=0,Mandatory=1)]
                [string] $source = $(throw "source is a required parameter."),
                [Parameter(Position=1,Mandatory=1)]
                [string] $target = $(throw "target is a required parameter.")
            )
            Copy-Package $source $target
		}

        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | webapp resource | ""$($webappref)"":$($webappref) | 
                                            | filenames | $($filenames) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, webappref, filenames, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

Export-Modulemember -alias * -Function *