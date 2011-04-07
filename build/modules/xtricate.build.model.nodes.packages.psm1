function GenericPackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=0)]
			[string] $path = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
			[Parameter(Mandatory=0)]
			[scriptblock] $permissions = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags )
		$type = "genericpackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id] $path" 
                # execute all sql scripts in the versioned order
                # set new db version as metadata on sql db
				
				if($permissions -ne $null){ 
					$_permissions = &$permissions
					$_permissions | foreach{ $_.Install($path) }
				}
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id] $path" 
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
                                             | ""$($path)"":$($path) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name, path=$path"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, path, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function WebAppPackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=0)]
			[string] $path = "",
            [Parameter(Position=3,Mandatory=1)]
			[string] $websiteref,
            [Parameter(Mandatory=0)]
			[string] $virtualdir, 
			[Parameter(Mandatory=0)]
			[switch] $isapplication,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
			[Parameter(Mandatory=0)]
			[scriptblock] $permissions = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $websiteref, $virtualdir, $isapplication, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $websiteref, $virtualdir, $isapplication, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags )
		$type = "webapppackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
		function List {
			# Get-WebVirtualDirectory -Name $name
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id] $path" 
                Load-WebAdmin
                $website = Get-NodeResource $websiteref
                
                if($virtualdir -ne $null){
                    
                    if($isapplication){ 
                        if(!(notnullorempty($website.apppoolref))){ 
                            Write-Warning "cannot create application '$($website.name)\$($virtualdir)', no apppool specified on website with id $($website.id)"
                            return
                        }
                        $apppool = Get-NodeResource $website.apppoolref
                        #Write-Host "IIS:\AppPools\$($apppool.name)"
                        #ConvertTo-WebApplication "IIS:\Sites\Default Web Site\$($virtualdir)" -ApplicationPool $apppool.name
                        New-WebApplication -Site $website.name -Name $virtualdir -PhysicalPath (fullpath $path) -ApplicationPool $apppool.name
                    }
                    else{
                        New-WebVirtualDirectory -Name $virtualdir -PhysicalPath (fullpath $path) -Site $website.name -Force | Out-Null
                    }
                    
                    # todo : add sslbinding > http://forums.iis.net/p/1174121/1965063.aspx
                }
                else{
                    # todo : update path of allready created website
                }
				
				if($permissions -ne $null){ 
					$_permissions = &$permissions
					$_permissions | foreach{ $_.Install($path) }
				}
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id] $path" 
                Load-WebAdmin
                if($virtualdir -ne $null){
                    #Remove-WebVirtualDirectory -Name $name > ask allways for confirmation
                    $website = Get-NodeResource $websiteref
                    
                    if(Test-Path "IIS:\Sites\$($website.name)\$virtualdir"){
                        Remove-Item "IIS:\Sites\$($website.name)\$virtualdir" -Recurse -Force
                    }
                }
                # websites are removed by node uninstall
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

        function FullUrl{
            $website = Get-NodeResource $websiteref
            $url = $website.fullurl()
            if($virtualdir -ne $null){
                return "$($url)/$($virtualdir)"
            }
            return $url
        }
        
        function SmokeTest{
			param(
                [string] $node
            )
            $website = Get-NodeResource $websiteref
            Write-Host "$($type): $name [$id] $($website.hostheader)/$($virtualdir)" 
 
            if($virtualdir){ $http = "GET /$($virtualdir)/ HTTP/1.1`nHost: $($website.hostheader)`n`n`n" }
            else{ $http = "GET / HTTP/1.1`nHost: $($website.hostheader)`n`n`n" }
            Write-Host "tcprequest: " ($http -replace "`n"," ") 
            
            if(!$website.ssl){ $result=Send-TcpRequest $website.hostheader $website.port -inputobject $http -ErrorVariable $e}
            else{ $result=Send-TcpRequest $website.hostheader $website.sslport -usessl -inputobject $http -ErrorVariable $e}
        
            if($result){
                $firstline = $true
                foreach($line in $result -split "\n",0,"multiline"){
                    if(notnullorempty($line.trim())){ 
                        if($firstline){ 
                            $code = $line -split " " | select -Index 1
                            #$codedescr = $line -split " " | select -Skip 2
                            # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
                            if(($code -like "4*") -or ($code -like "5*")){ Write-Warning "$line" }
                            else{ Write-Host "$line" }
                        }
                        else{ Write-Host "$line"}
                        $firstline=$false
                    }
                    else{ 
                        Write-Host ""
                        break 
                    }
                }
            }
        }

        function Documentation{
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | path | ""$($path)"":$($path) |
                                            | url | ""$($this.fullurl())"":$($this.fullurl()) |
                                            | website resource | ""$($websiteref)"":$($websiteref) | 
                                            | virtual directory | $($virtualdir) |
                                            | application | $($isapplication) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name, path=$path"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, SmokeTest, Documentation, ToString, Settings, FullUrl, List, Install, UnInstall -Variable type, id, name, path, websiteref, virtualdir, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function WindowsServicePackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=0)]
			[string] $path = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
			[Parameter(Mandatory=0)]
			[scriptblock] $permissions = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags )
		$type = "windowsservicepackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id] $path" 
            }
			
			if($permissions -ne $null){ 
					$_permissions = &$permissions
					$_permissions | foreach{ $_.Install($path) }
				}
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id] $path" 
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
                                            |_. setting |_. value |
                                            | ""$($path)"":$($path) |"
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
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, path, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function DatabasePackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
			[Parameter(Position=2,Mandatory=0)]
			[string] $path = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $permissions = $null,
			[Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags )
		$type = "databasepackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id] $path" 
                # invoke-sqlcmd : sql server 2008 powershell cmndlets
                # http://stackoverflow.com/questions/156044/how-do-you-manage-database-revisions-on-a-medium-sized-project-with-branches
                # http://michielvoo.net/blog/configuring-migrator-net-as-an-external-tool-in-visual-studio-using-msbuild/
                # dbdeploy.com
				
				if($permissions -ne $null){ 
					$_permissions = &$permissions
					$_permissions | foreach{ $_.Install($path) }
				}
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id] $path" 
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
                                            |_. setting |_. value |"
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
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, path, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function SystemTestPackage {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=0)]
			[string] $path = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipinstallcopy = $true,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
			[Parameter(Mandatory=0)]
			[scriptblock] $permissions = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $description, $skipinstall, $skipinstallcopy, $skipuninstall, $permissions, $settings, $dependson, $tags )
		$type = "systemtestpackage"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id] $path"  
            }
			
			if($permissions -ne $null){ 
					$_permissions = &$permissions
					$_permissions | foreach{ $_.Install($path) }
				}
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id] $path" 
            }
		}
        
		function Export(){
            param (
                [Parameter(Position=0,Mandatory=1)]
                [string] $source = $(throw "source is a required parameter."),
                [Parameter(Position=1,Mandatory=1)]
                [string] $target = $(throw "target is a required parameter.")
            )
            # copy app.config.template as dll.config.template > needed for systemtests and dll-like named configs in bin fold            
            $template = Join-Path $source "app.config.template"
            if(Test-Path $template){
                $templateconfigfile = Get-ChildItem -Path ($template) -Recurse
                if(Test-Path $templateconfigfile){
                    Get-ChildItem -Path $source -Include "*.dll.config" -Recurse | 
                        foreach { 
                            Copy-Item -Path $templateconfigfile -Destination "$($_.fullname).template" 
                        }
                }
            }
            Copy-Package $source $target
            
		}

        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                             |_<. setting |_<. value |
                                             | path | ""$($path)"":$($path) |"
            "## $($type) - '$($name)' [$($id)]
             $($settingstable)
             <br>"
        }

		function ToString(){
			"`n  | $type [$id]: name=$name, path=$path"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Export, Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, path, description, skipinstall, skipinstallcopy, skipuninstall, dependson, tags, _settings
	}
}

function PermissionRule {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $filter = "*.*",
			[Parameter(Position=1,Mandatory=1)]
			[string[]] $groups = "",
            [Parameter(Position=2,Mandatory=0)]
			[string[]] $rights = @("Read", "Write"),
			[switch] $allow = $true,
			[switch] $deny = $false
	)
	New-Module -ArgumentList $filter, $groups, $rights -AsCustomObject {
		param ( $filter, $groups, $rights )
		$type = "permissionrule"
        
		function Install() {
			param (
                [string] $path = $null
            )
            if(!($skipinstall)){
                Write-Host "$($type): $filter $groups [$rights] $path" 
				Get-ChildItem -path (FullPath $path) -filter $filter -recurse | foreach {
					foreach($group in $groups){
						foreach($right in $rights){
							# http://blogs.technet.com/b/josebda/archive/2010/11/09/how-to-handle-ntfs-folder-permissions-security-descriptors-and-acls-in-powershell.aspx
							$action = "Allow"
							if($deny){ $action = "Deny"}
							$acl = Get-Acl $_.FullName
							$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, $right, $action)
							# $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, $right, "ContainerInherit, ObjectInherit", "None", $action) # use this for folders
							$acl.AddAccessRule($rule)
							Set-Acl $_.FullName $acl
						}
					}
				}
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
            }
		}
        
        function Documentation {
        }

		function ToString(){
		}
		Export-ModuleMember -Function Documentation, Install, uNInstall, ToString -Variable type, filter, groups, permissions
	}
}


Export-Modulemember -alias * -Function *