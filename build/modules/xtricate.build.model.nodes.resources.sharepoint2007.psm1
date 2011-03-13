function SharePoint2007WebApplication {
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
	New-Module -ArgumentList $id, $name, $apppoolref, $path, $hostheader, $port, $sslport, $ssl, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $apppoolref, $path, $hostheader, $port, $sslport, $ssl, $description, $skipinstall, $skipuninstall, $settings, $dependson, $tags )
		$type = "sharepoint2007webapplication"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings { 
			&$settings
		}
        
		function List {
		}
		
		function Install {
            if(!($skipinstall)){
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
            }
		}
		
        function FullUrl {
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

        function Documentation {
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
		Export-ModuleMember -Function Documentation, ToString, Settings, FullUrl, List, Install, UnInstall -Variable type, id, apppoolref, path, hostheader, name, ip, port, sslport, description, skipinstall, skipuninstall, dependson, tags, _settings
	}
}

Export-Modulemember -alias * -Function *