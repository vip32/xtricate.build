function Install-Environment {
	param (
		[Parameter(Position=0,Mandatory=1)]
		[object] $environment = $(throw "environment is a required parameter."),
        [Parameter(Position=0,Mandatory=1)]
		[object] $path = $(throw "path file is a required parameter."),
		[Parameter(Position=0,Mandatory=0)]
		[string[]]$tags = $null
	)
    Write-Host "$($environment.type): $($environment.name) [$($environment.id)]"
	foreach($node in $environment.nodes()){
		if(comparenodes $env:COMPUTERNAME $($node.name)){ 
            if(!($node.skipinstall)){
                Write-Host "`n$($node.type): $env:COMPUTERNAME [$($node.id)] $($node.name), $($node.ip)"
                foreach($package in $node.packages()){
                    if(!($package.skipinstall)){
						if(!($package.skipinstallcopy) -and ($package.path -ne $null) -and (comparetags $tags $package.tags)){
	                        Write-Host "copy $($package.type): $($package.name) [$($package.id)] > $($package.path)"
                            $exportlocation = "$($path)\$($package.id)"
                            if(Test-Path $exportlocation){
	                            $fullexportlocation = Resolve-Path -Path $exportlocation
								EnsureFolder $package.path
	                            Get-ChildItem $exportlocation -Recurse | 
	                                Copy-Item -Force -Destination { Join-Path $($package.path) $_.FullName.Substring($($fullexportlocation.path).length) }
	                        }
	                        else { New-Item -Path $package.path -Force -Type Directory | Out-Null }
						}
                    }
                }
                $node.Install($tags)
                Write-Host "`n"
            }
		}
	}
}
New-Alias -Name InstallEnvironment -value Install-Environment -Description "" -Force

function Uninstall-Environment {
	param (
		[Parameter(Position=0,Mandatory=1)]
		[object] $environment = $(throw "environment file is a required parameter."),
        [Parameter(Position=0,Mandatory=1)]
		[object] $path = $(throw "path file is a required parameter."),
		[Parameter(Position=0,Mandatory=0)]
		[string[]]$tags = $null
	)
    Write-Host "$($environment.type): $($environment.name) [$($environment.id)]"
	foreach($node in $environment.nodes()){
		if(comparenodes $env:COMPUTERNAME $($node.name)){ 
            if(!($node.skipuninstall)){
                Write-Host "`n$($node.type): $env:COMPUTERNAME [$($node.id)] $($node.name), $($node.ip)"
                $node.UnInstall($tags)
                foreach($package in $node.packages()){
                    if(!($package.skipuninstall) -and !($package.skipinstallcopy) -and ($package.path -ne $null) -and (comparetags $tags $package.tags)){
                        Write-Host "remove $($package.type): $($package.name) [$($package.id)] > $($package.path)"
                        if(Test-Path $package.path){ Remove-Item -Path $package.path -Force -Recurse }
                    }
                }
                Write-Host "`n"
            }
        }
	}
}
New-Alias -Name UninstallEnvironment -value Uninstall-Environment -Description "" -Force

function Install-RemoteEnvironment{
    param (
        [Parameter(Position=0,Mandatory=1)]
		[object] $environment = $(throw "environment is a required parameter."),
        [Parameter(Position=1,Mandatory=1)]
		[string[]] $nodes = $(throw "nodes is a required parameter."),
        [Parameter(Mandatory=0)]
        [string] $name = "",
		[Parameter(Mandatory=0)]
		[string[]]$tags = $null,
        [Parameter(Mandatory=0)]
        [switch] $skipinstall=$false,
        [Parameter(Mandatory=0)]
        [switch] $skipcopy=$false
    )
    #if($nodes -eq $null) { throw  "Error: no nodes to install on are specified."}
    Write-Host "environment: $($environment.id)"
    foreach($node in $nodes){
        $environment.Nodes() | foreach {
			if((comparenodes $node $($_.name)) -or (comparenodes $node $($_.ip))){ 
            #if(($node -like $($_.name)) -or ($node -like $($_.ip))){
                $resources = Get-NodeResources $_.id "remoting" # warning : can return multiple resources, depending on 1 for now
                Write-Host "`nnode: $node [$($_.id)] $($_.name), $($_.ip)"
                if($resources -ne $null){
                    try{
                        if(!$skipcopy -or !$skipinstall){ $session = Create-Session -node $node -identity (Get-NodeResource $resources.identityref) -verbose }
                        
                        # copy
                        if(!$skipcopy){
                            if(NotNullOrEmpty($($resources.sharename))){
                                Copy-NetworkShare -source (Core-BuildDir) -share "\\$node\$($resources.sharename)" -directory "$($name)" `
                                                -username $username -password $identity.password
                            }
                            else{
                                if($session -ne $null){ Copy-Session -source (Core-BuildDir) -target (Join-Path $($resources.localdirectory) "$($name)") -session $session -maxsizemb 1024}
                            }
                            # todo : ftp copy?
                        }
                        
                        if(!($skipinstall)){
							if($session -ne $null){
	                            Write-Host "*** ready to execute 'install' task in $($psake.build_script_file) for environment $environment ***" -ForegroundColor Yellow
	                            Invoke-Command -Session $session -ArgumentList $environment.id,$node,$name,$tags -ScriptBlock { 
	                                param($environment,$node,$name,$tags)
	                                Write-Host "hello from $env:computername [node:$($node), env:$($environment)]" # todo : pass some needed params in session , $node is empty now
	                            }
							}
                        }
                    }
                    finally{    
                        # close
                        if($session -ne $null){ 
                            Write-Host "close session: node $node"
                            Remove-PSSession $session 
                        }
                    }
                }
                else { Write-Warning "skipped remote installation on node $node [$($_.id)] $($_.name), $($_.ip), no node resource of type remoting could be found in the model." }
            }
        }
    }
}
New-Alias -Name InstallRemoteEnvironment -value Install-RemoteEnvironment -Description "" -Force

Export-Modulemember -alias * -Function *