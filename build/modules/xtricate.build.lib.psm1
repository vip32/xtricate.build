$default_source = "http://go.microsoft.com/fwlink/?LinkID=206669"
$default_toolsdir = $pwd

function source
{
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string] $source
	)
	$script:default_source = $source
}

function toolsdir
{
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string] $path
	)
	$script:default_toolsdir = $path
}

function installto
{
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string] $path = $null
	)
	ensurefolder $path
	push-location $path -stackname 'lib_nuget'
}

function package 
{
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string] $name = $null,
		[Parameter(Position=1,Mandatory=$false)]
		[alias("v")]
		[string] $version = "",
		[Parameter(Position=2,Mandatory=$false)]
		[alias("s")]
		[string] $source = "",
        [Parameter(Position=3,Mandatory=$false)]
		[alias("f")]
		[switch] $force
	)
    $fileName = Join-Path $script:default_toolsdir "nuget.exe"
	$toolexists = Test-Path $filename  
    if(!$toolexists) {throw "tool not found $filename"}
	$command = ""
	if($toolexists){$command += "$filename install $name"} else {$command += "install-package $name"}
	if($version -ne ""){
        $command += " -v $version"
        $msgversion = $version
    }
    else { $msgversion = "latest"}
	if($source -eq "" -and $script:default_source -ne ""){$source = $script:default_source}
	if($source -ne ""){$command += " -s $source"}
	Write-Host "package: $name [$($msgversion)] $source"
    if((!$force) -and ($version -ne "") -and (Test-Path "$($name).$($version)")){ return }
	invoke-expression $command
}

function Invoke-Lib
{
    param(
        [Parameter(Position=0,Mandatory=$false)]
		[scriptblock] $block
    )
    if(!$block){ Get-Content $pwd\.libfile | Foreach-Object { $block = [scriptblock]::Create($_.ToString()); % $block;}}
    else{ &$block; }
	if((Get-Location -stackname 'lib_nuget').count -gt 0) { pop-location -stackname 'lib_nuget' }
}
New-Alias -Name Lib -value Invoke-Lib -Description "" -Force

function Lib-Init
{
	if(!(test-path $pwd\.libfile))
	{
		new-item -path $pwd -name .libfile -itemtype file
		add-content $pwd\.libfile "installto 'lib'"
		add-content $pwd\.libfile "package 'machine.specifications'"
	}
}

Export-Modulemember -alias * -Function *