
function SharepointWebApplication {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=1)]
			[string] $apppoolref,
			[Parameter(Position=3,Mandatory=1)]
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
			[string[]] $managedpaths,
            [Parameter(Mandatory=0)]
			[scriptblock] $sites = $null,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
            [Parameter(Mandatory=0)]
			[string[]] $dependson = @("apppool"),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $apppoolref, $hostheader, $port, $sslport, $ssl, $description, $skipinstall, $skipuninstall, $managedpaths, $sites, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $name, $apppoolref, $hostheader, $port, $sslport, $ssl, $description, $skipinstall, $skipuninstall, $managedpaths, $sites, $settings, $dependson, $tags )
		$type = "sharepointwebapplication"
        
        if($sites -ne $null){ $_sites = &$sites }
        if($settings -ne $null){ $_settings = &$settings }
        
        function Sites {
			if($sites -ne $null){
				&$sites
			}
		}
        
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            if(!($skipinstall)){
                $url = FullUrl
                Write-Host "$($type): $name, $url [$id]" 
                Assert (Get-SPFarm) ("Error: Computer is not part of a sharepoint farm")
                #Load-SharepointAdmin
                $app = Get-SPWebApplication -Identity $name -ErrorAction SilentlyContinue 
                if($app -eq $null){
                    if(NotNullOrEmpty $apppoolref){
                        $apppool = Get-NodeResource $apppoolref
                        $identity = Get-NodeResource $($apppool.identityref)
                        #install the spweb
                        New-SPWebApplication `
                            -Name $name `
                            -Port $port `
                            -HostHeader $hostheader `
                            -Url "http://$hostheader" `
                            -AllowAnonymousAccess `
                            -ApplicationPool $($apppool.name) `
                            -ApplicationPoolAccount $($identity.name)
                        # install the spsites
                        $managedpaths | foreach { Write-Host "managed path: $_"} # todo : implement with New-SPManagedPath > http://technet.microsoft.com/en-us/library/ff607693.aspx
                        if($this.Sites() -ne $null){ $this.Sites() | foreach { $_.Install($this) }}
                        
                        # set anonymous on all sub sites, does not work : access denied
                        # (Get-SPWebApplication $url | 
                        #         Get-SPSite | Get-SPWeb | 
                        #         Where {$_ -ne $null -and $_.HasUniqueRoleAssignments -eq $true } ) | 
                        #     ForEach-Object { $_.AnonymousState = [Microsoft.SharePoint.SPWeb+WebAnonymousState]::On; $_.Update(); }
                    }
                }
            }
		}
		
		function UnInstall {
            if(!($skipuninstall)){
                $url = FullUrl
                Write-Host "$($type): $name, $url [$id]" 
                Assert (Get-SPFarm) ("Error: Computer is not part of a sharepoint farm")
                #Load-SharepointAdmin
                $app = Get-SPWebApplication -Identity $name -ErrorAction SilentlyContinue 
                if($app -ne $null){
                    # remove the spsites
                    if($this.Sites() -ne $null){ $this.Sites() | foreach { $_.Uninstall($this) }}
                    # remove the spweb
                    Remove-SPWebApplication `
                        -Identity $name `
                        -RemoveContentDatabases -DeleteIISSite `
                        -Confirm:$false

                }
            }
		}
        
        function FullUrl {
            if($ssl){
                $protocol = "https://"
                if($sslport -ne $null -and $sslport -ne "443"){ $urlport = ":$sslport" }
            }
            else{
                $protocol = "http://"
                if($port -ne $null -and $port -ne "80"){ $urlport = ":$port" } 
            }
            return "$($protocol)$($hostheader)$($urlport)" 
        }
        
        function Documentation {
            "## resource - $($type) '$($name)' [$($id)]
            <br>"
        }

		function ToString(){
			"`n    | $type [$id]: name=$name"

            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Install, Uninstall, Sites, FullUrl, Settings -Variable type, id, hostheader, name, apppoolref, ip, port, sslport, ssl, description, skipinstall, skipuninstall, dependson, managedpaths, _settings, tags, _sites
	}
}
#New-Alias -Name sharepointsite -value New-SharepointSite -Description "" -Force

function SharepointSite {
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
			[Parameter(Position=1,Mandatory=1)]
			[string] $name = "",
            [Parameter(Position=2,Mandatory=1)]
			[string] $identityref,
            [Parameter(Mandatory=0)]
			[string] $url,
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipinstall = $false,
            [Parameter(Mandatory=0)]
            [switch] $skipuninstall = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $name, $url, $identityref, $description, $skipinstall, $skipuninstall, $settings, $tags -AsCustomObject {
		param ( $id, $name, $url, $identityref, $description, $skipinstall, $skipuninstall, $settings, $tags )
		$type = "sharepointsite"
        
        if($settings -ne $null){ $_settings = &$settings }
        
        function Settings {
			&$settings
		}
        
        function List {
		}
		
		function Install {
            param(
                [Parameter(Position=0,Mandatory=1)]
                [object] $sharepointwebapplication
            )
            if(!($skipinstall)){
                $siteurl = $sharepointwebapplication.FullUrl()
                if($url -ne $null){ $siteurl = "$($siteurl)/$($url)" }
                Write-Host "$($type): $name, $siteurl [$id]" 
                
                #Load-SharepointAdmin
                Assert (Get-SPFarm) ("Error: Computer is not part of a sharepoint farm")
                $identity = Get-NodeResource $identityref
                New-SPSite -Name $name -Url $siteurl -OwnerAlias $($identity.name) | Out-Null
            }
		}
		
		function UnInstall {
            param(
                [Parameter(Position=0,Mandatory=1)]
                [object] $sharepointwebapplication
            )
            if(!($skipuninstall)){
                $siteurl = $sharepointwebapplication.FullUrl()
                if($url -ne $null){ $siteurl = "$($siteurl)/$($url)" }
                Write-Host "$($type): $name, $siteurl [$id]" 
                
                #Load-SharepointAdmin
                Assert (Get-SPFarm) ("Error: Computer is not part of a sharepoint farm")
                #Remove-SPSite -Identity $name
            }
		}
        
        function FullUrl {
            # todo : parent + this url
        }

        function Documentation {
            "## resource - $($type) '$($name)' [$($id)]
            <br>"
        }

		function ToString(){
			"`n    | $type [$id]: name=$name"

            if($_settings -ne $null){
                foreach($setting in $_settings){
                    $setting.tostring() 
                }
            }
		}
		Export-ModuleMember -Function Documentation, ToString, Install, Uninstall, FullUrl, Settings -Variable type, id, name, url, identityref, description, skipinstall, skipuninstall, tags, _settings
	}
}
#New-Alias -Name sharepointsite -value New-SharepointSite -Description "" -Force

Export-Modulemember -alias * -Function *