function Export-Package {
	param (
        [Parameter(Position=0,Mandatory=1)]
		[string] $path = $(throw "path file is a required parameter."),
		[Parameter(Position=1,Mandatory=1)]
		[object] $package = $(throw "package file is a required parameter.")
	)
    if(!(Test-Path $path)){ new-item $path -itemType directory -ErrorAction SilentlyContinue | Out-Null }
#    try{
        $configurationpackage = Get-EnvironmentsPackage -packageId $package.packageid
        $target = "$($path)\$($configurationpackage.id)"
        write-host "export $($configurationpackage.type): $($configurationpackage.name) [$($configurationpackage.id)] to $target" #from $($package.location)
        $configurationpackage.Export($package.location, $target)
#    }
#    catch{ # todo : check for specific error thrown by Get-EnvironmentsPackage, all errors handled now (access denied?)
#        Write-Warning "solution package with id $($package.packageid) not found in any environment in the model. the export of this package was skipped."
#    }
}
New-Alias -Name ExportPackage -value Export-Package -Description "" -Force

function Export-Packages {
	param (
        [Parameter(Position=0,Mandatory=1)]
		[object] $path = $(throw "path file is a required parameter."),
		[Parameter(Position=1,Mandatory=1)]
		[object] $packages = $(throw "packages file is a required parameter.")
	)
    $packages | foreach { Export-Package $path $_ }
}
New-Alias -Name ExportPackages -value Export-Packages -Description "" -Force

function Copy-Package(){ # todo : add optional exclude parameters
    param (
        [Parameter(Position=0,Mandatory=1)]
        [string] $source = $(throw "source is a required parameter."),
        [Parameter(Position=1,Mandatory=1)]
        [string] $target = $(throw "target is a required parameter.")
    )
    if(Test-Path $source){
        # get the allready expanded templates from the solution folder
        # these files should not be exported to the package
        $source = Full-Path $source
        $expandedtemplates = Get-ChildItem $source -Recurse -Include "*.template" | 
                                foreach { 
                                        # escape single \ characters in filename, 
                                        # replace .template part with $ (end of string) so the expanded filename will match
                                        $_.FullName -replace "\\","\\" `
                                                    -replace ".template", "$" }  
        # all files and folders which should not be exported to the package
        $excludefiles = "*.cs", "*.user", "*.suo", "*.csproj", "packages.config", "*.vs10x" # "*.pdb",
        $excludefolders = "\\obj", "\\properties", "\\_PublishedWebsites" -join '|'
        if($expandedtemplates -ne $null){ $expandedtemplates | foreach { $excludefolders = $excludefolders, $_ -join '|'}}
        Write-verbose "exclude from export: $excludefolders"
        
        if(!(Test-Path $target)){ New-Item -Path $target -ItemType Directory -Force | Out-Null }
        Get-ChildItem $source -Recurse -Exclude $excludefiles | #ft directory, name
            where {$_.FullName -notmatch $excludefolders} | 
            Copy-Item -Force -Destination { 
                $file = $_.FullName.Substring($source.length)
                Write-Verbose "copy: $file > $target"
                Join-Path $target $file}
        # todo : skip empty folders switch? 
    }
}
New-Alias -Name CopyPackage -value Copy-Package -Description "" -Force

function Export-Nuget-Packages {
    param (
        [Parameter(Position=0,Mandatory=1)]
		[string] $path = $(throw "$path file is a required parameter."),
        [Parameter(Position=1,Mandatory=0)]
		[string] $targetpath = $(throw "targetpath file is a required parameter."),
        [Parameter(Position=2,Mandatory=1)]
        [string]$toolsdir = $(throw "toolsdir is a required parameter.")
	)
    # process templated nuspec files first
    $templatednuspecfiles = Get-ChildItem $path -Include "*.nuspec.template" -Recurse
    if($templatednuspecfiles -ne $null){
        $templatednuspecfiles | foreach {
            expandtemplate $_
        }
    }
    
    $nuspecfiles = Get-ChildItem $path -Include "*.nuspec" -Recurse
    if($nuspecfiles -ne $null){
        $nuspecfiles | foreach {
            Write-Host "export nugetpackage: $($_.name) to $targetpath"
            $nugetclienttool = Join-Path $toolsdir "nuget.exe"
            Assert (test-path $nugetclienttool) ("Error: Nuget clienttool {0} was not found" -f $nugetclienttool)
	        exec {&$nugetclienttool pack $($_.fullname) -o $targetpath} "Nuget package $($_.fullname) failed!"
        }
    }
    # http://haacked.com/archive/2011/01/12/uploading-packages-to-the-nuget-gallery.aspx
}
New-Alias -Name ExportNugetPackages -value Export-Nuget-Packages -Description "" -Force

function Push-Nuget-Packages {
    param (
        [Parameter(Position=0,Mandatory=0)]
		[string] $path = $(throw "path file is a required parameter."),
        [Parameter(Position=1,Mandatory=0)]
		[string] $accesskey = $(throw "accesskey file is a required parameter."),
        [Parameter(Position=2,Mandatory=1)]
        [string]$toolsdir = $(throw "toolsdir is a required parameter."),
        [Parameter(Mandatory=0)]
        [switch]$publish=$false
	)
    $source = "http://packages.nuget.org/v1/"
    $packages = Get-ChildItem $nuspecpath -Include "*.nupkg" -Recurse
    if($packages -ne $null){
        $packages | foreach {
            Write-Host "push nugetpackage: $($_.name) to $source"
            $nugetclienttool = Join-Path $toolsdir "nuget.exe"
            Assert (test-path $nugetclienttool) ("Error: Nuget clienttool {0} was not found" -f $nugetclienttool)
            if($publish) {
	            exec {&$nugetclienttool push -source $source $($_.fullname) $accesskey } "Nuget push $($package.fullname) failed!"
            }
            else{
                exec {&$nugetclienttool push -source $source $($_.fullname) $accesskey -createonly} "Nuget push $($package.fullname) failed!"
            }
        }
    }
    # http://haacked.com/archive/2011/01/12/uploading-packages-to-the-nuget-gallery.aspx
}
New-Alias -Name PushNugetPackages -value Push-Nuget-Packages -Description "" -Force

Export-Modulemember -alias * -Function *