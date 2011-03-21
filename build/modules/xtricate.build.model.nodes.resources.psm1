function Remoting {
	param (
            [Parameter(Position=0,Mandatory=1)]
			[string] $id = "remotingid",
			[Parameter(Position=1,Mandatory=1)]
			[string] $identityref,
			[Parameter(Position=2,Mandatory=0)]
			[string] $sharename,
            [Parameter(Position=3,Mandatory=1)]
			[string] $localdirectory,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $true,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $true,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $identityref, $sharename, $localdirectory, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $identityref, $sharename, $localdirectory, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "remoting"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
        
        function Install {
            if(!($skipinstall)){
                Write-Host "$($type): [$id]" 
            }
		}
		
		function Uninstall {
            if(!($skipuninstall)){
                Write-Host "$($type): [$id]"
            }
		}

        function SmokeTest{
            param(
                [string] $node
            )
            Write-Host "$($type): $node [$id]" 
            $session = createsession -node $node -identity (Get-NodeResource $this.identityref)
            if($session){ Remove-PSSession $session }
            Write-Host "" 
        }

        function Documentation {
        }
        
		function ToString(){
			"`n    | $type [$id]"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){ $setting.tostring() }
            }
		}
		Export-ModuleMember -Function SmokeTest, Documentation, ToString, Install, Uninstall, Exists, Settings -Variable id, type, identityref, sharename, localdirectory, description, skipinstall, skipuninstall, dependson, tags, _settings
	}
}

function LocalIdentity {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id,
			[Parameter(Position=1,Mandatory=1)]
			[string] $name,
            [Parameter(Mandatory=0)]
			[string] $password,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $password, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $password, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "identity"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
        
        function Exists {
            $computer = [ADSI]"WinNT://$env:COMPUTERNAME"
            $users = $computer.psbase.children | where{$_.psbase.schemaclassname -eq "User"}
            foreach ($user in $users.psbase.syncroot){
                if ($user.name -eq $name){
                    return $true
                }
            }
            return $false
        }
        
        function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id]" 
                if(!(Exists)){
                    $computer = [ADSI]"WinNT://$env:COMPUTERNAME"
                    $user = $computer.Create("user", $name)
                    $user.SetPassword($password)
                    $user.SetInfo()
                }
            }
		}
		
		function Uninstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id]"
                if(Exists){
                    $computer = [ADSI]"WinNT://$env:COMPUTERNAME"
                    $computer.Delete("user", $name)
                }
            }
		}
        
        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | name | $($name) |
                                            | password| $($password) |"
            "## resource - $($type) '$($name)' [$($id)]
            $($settingstable)
            <p>install account $($name) on node.install account $($name) on node.install account $($name) on node.
            install account $($name) on node.install account $($name) on node.
            install account $($name) on node.install account $($name) on node.
            <br/>
            install account $($name) on node.install account $($name) on node.</p>"
        }

		function ToString(){
			"`n    | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Install, Uninstall, Exists, Settings -Variable type, id, name, password, description, skipinstall, skipuninstall, dependson, tags, _settings
	}
}

function Certificate {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id,
			[Parameter(Position=1,Mandatory=1)]
			[string] $name,
            [Parameter(Position=2,Mandatory=0)]
			[string] $path,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [string] $password = $null,
            [Parameter(Mandatory=0)]
            [string] $thumbprint = $null,
            [switch] $localMachine = $true,
		    [switch] $currentUser = $false,
            [Parameter(Mandatory=0)]
            [string[]] $storenames = @("My"),
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $path, $description, $password, $thumbprint, $localMachine, $currentUser, $storenames, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $path, $description, $password, $thumbprint, $localMachine, $currentUser, $storenames, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "certificate"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
		
		function List {
		}
        
		function Install {
            if(!($skipinstall)){
                Write-Host "$($type): $name [$id]"
                if(Test-Path $path){
                    Import-Certificate -certfile (Get-Item $path) -storenames $storenames -certpassword $password -localmachine:$localMachine -currentuser:$currentUser
                }
                else{
                    Write-Warning "certificate $name [$id] not found: $path"
                }
            }
        }
		
		function UnInstall {
            if(!($skipuninstall)){
                Write-Host "$($type): $name [$id]"
                # todo, not implemented yet
            }
		}
        
        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | identity resource | ""$($identityref)"":$($identityref) |
                                            | classic| $classic |"
            "## resource - $($type) '$($name)' [$($id)]
            $($settingstable)<br>"
        }
        
		function ToString(){
			"`n    | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, path, description, password, thumbprint, localMachine, currentUser, storenames, skipinstall, skipuninstall, dependson, tags, _settings
	}
}

function AppPool {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id,
			[Parameter(Position=1,Mandatory=1)]
			[string] $name,
            [Parameter(Position=2,Mandatory=0)]
			[string] $identityref,
			[Parameter(Mandatory=0)]
			[switch] $classic,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @("identity"),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $identityref, $classic, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $identityref, $classic, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "apppool"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
		
		function List {
			#Get-WebAppPoolState -Name "$name*" -ErrorAction SilentlyContinue 
		}
        
		function Install {
            if(!($skipinstall)){
                Load-WebAdmin
                Write-Host "$($type): $name [$id]"
                if(!(Test-Path "IIS:\AppPools\$name")){
                    New-WebAppPool -Name $name -Force | Out-Null 
                    if(NotNullOrEmpty $identityref){ # http://learn.iis.net/page.aspx/434/powershell-snap-in-making-simple-configuration-changes-to-web-sites-and-application-pools/
                        $identity = Get-NodeResource $identityref
                        $appppool = Get-Item "IIS:\AppPools\$name"
                        $appppool.processModel.userName = $($identity.account)
                        $appppool.processModel.password = $($identity.password)
                        $appppool.processModel.identityType = 3
                        $appppool | Set-Item
                        
                    }
                    Start-WebAppPool -Name $name
                    #$state = Get-WebAppPoolState -Name $name
                    #Write-Host "    state: $($state.Value)"
                }
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                Load-WebAdmin
                Write-Host "$($type): $name [$id]"
                if(Test-Path "IIS:\AppPools\$name"){
                    Stop-WebAppPool -Name $name 
                    Remove-WebAppPool -Name $name 
                }
            }
		}
        
        function Documentation {
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | identity resource | ""$($identityref)"":$($identityref) |
                                            | classic| $classic |"
            "## resource - $($type) '$($name)' [$($id)]
            $($settingstable)<br>"
        }
        
		function ToString(){
			"`n    | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Settings, List, Install, UnInstall -Variable type, id, name, identityref, classic, description, skipinstall, skipuninstall, dependson, tags, _settings
	}
}

function WebSite {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id,
			[Parameter(Position=1,Mandatory=1)]
			[string] $name,
			[Parameter(Position=2,Mandatory=0)]
			[string] $path,
            [Parameter(Mandatory=0)]
			[string] $apppoolref = $null,
			[Parameter(Mandatory=0)]
			[string] $hostheader = "",
			[Parameter(Mandatory=0)]
			[string] $port = "80",
			[Parameter(Mandatory=0)]
			[string] $sslport = "443",
			[Parameter(Mandatory=0)]
			[switch] $ssl,
            [Parameter(Mandatory=0)]
			[string] $certificateref = $null,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @("apppool","certificate"),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $apppoolref, $path, $hostheader, $port, $sslport, $ssl, $certificateref, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $apppoolref, $path, $hostheader, $port, $sslport, $ssl, $certificateref, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "website"
        
        if(!($apppoolref)){ $dependson = @()} # todo : remove only apppool dependson
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings{ 
			&$settings
		}
        
		function List{
		}
		
		function Install{
            if(!($skipinstall)){
                Load-WebAdmin
                $url = FullUrl
                Write-Host "$($type): $name, $url [$id]"
                EnsureFolder $path
                if(NotNullOrEmpty $apppoolref){
                    $apppool = Get-NodeResource $apppoolref
                    $apppoolname = $($apppool.name)
                }
                New-Website -Name $name -PhysicalPath (fullpath $path) -Hostheader $hostheader -Port $port -ApplicationPool $apppoolname -Force | Out-Null
                
                if($certificateref){
                    $certificate = Get-NodeResource $certificateref
                    $thumbprint = $certificate.thumbprint
                    New-WebBinding -Name $name -IP "*" -Port 443 -Protocol https
                    Set-Location IIS:\SslBindings
                    if(Test-Path 0.0.0.0!443){ Remove-Item 0.0.0.0!443 }
                    Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.ThumbPrint -eq $thumbprint} | Select-Object -First 1 | New-Item 0.0.0.0!443
                }
                
                Start-Website -Name $name 
                #$state = Get-WebURL -PSPath "IIS:\Sites\$name" 
                #Write-Host "    state: $state"
            }
		}
		
		function UnInstall{
            if(!($skipuninstall)){
                Load-WebAdmin
                Write-Host "$($type): $name [$id]"
                if(Test-Path "IIS:\Sites\$name"){
                Stop-Website -Name $name
                Remove-Website -Name $name
                }
            }
		}
		
        function FullUrl{
            if($ssl){
                $protocol = "https://"
                if($sslport -ne $null -and $sslport -ne "443"){ $urlport = ":$($sslport)" }
            }
            else{
                $protocol = "http://"
                if($port -ne $null -and $port -ne "80"){ $urlport = ":$($port)" } 
            }
            return "$($protocol)$($hostheader)$($urlport)" 
        }

        function Documentation{
            $settingstable = Format-Textile "table{border:1px solid black}.
                                            |_<. setting |_<. value |
                                            | path | ""$($path)"":$($path) |
                                            | url | ""$($this.fullurl())"":$($this.fullurl()) |
                                            | apppool resource | ""$($apppoolref)"":$($apppoolref) |
                                            | hostheader| $($hostheader) |
                                            | port| $($port) |
                                            | sslport| $($sslport) |
                                            | usessl| $($ssl) |"
            "## resource - $($type) '$($name)' [$($id)]
            $($settingstable)<br>"
        }

		function ToString(){
			"`n    | $type [$id]: name=$name"
       
            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Settings, FullUrl, List, Install, UnInstall -Variable type, id, apppoolref, path, hostheader, name, ip, port, sslport, certificateref, description, skipinstall, skipuninstall, dependson, tags, _settings
	}
}
#New-Alias -Name website -value New-WebSite -Description "" -Force

Export-Modulemember -alias * -Function *