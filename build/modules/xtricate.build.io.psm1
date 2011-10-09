function Core-NotNullOrEmpty{
    param(
        [string] $str
    )
    if ($str) {$true} 
    else {$false}
}
New-Alias -Name NotNullOrEmpty -value Core-NotNullOrEmpty -Description "" -Force

function Core-ArrayNotNullOrEmpty{
    param(
        [string[]] $str
    )
    if (($str) -and ($str.count -gt 0)) {$true} 
    else {$false}
}
New-Alias -Name ArrayNotNullOrEmpty -value Core-ArrayNotNullOrEmpty -Description "" -Force

function Get-RelativePath {
    <#
    .SYNOPSIS
    Get a path to a file (or folder) relative to another folder
    .DESCRIPTION
    Converts the FilePath to a relative path rooted in the specified Folder
    .PARAMETER Folder
    The folder to build a relative path from
    .PARAMETER FilePath
    The File (or folder) to build a relative path TO
    .PARAMETER Resolve
    If true, the file and folder paths must exist
    .Example
    Get-RelativePath ~\Documents\WindowsPowerShell\Logs\ ~\Documents\WindowsPowershell\Modules\Logger\log4net.xslt
    
    ..\Modules\Logger\log4net.xslt
    
    Returns a path to log4net.xslt relative to the Logs folder
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=1, Position=0)]
        [string]$Folder, 
        [Parameter(Mandatory=1, Position=1, ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")]
        [string]$FilePath,
        [switch]$Resolve
    )
    process {
        Write-Verbose "Resolving paths relative to '$Folder'"
        $from = $Folder = split-path $Folder -NoQualifier -Resolve:$Resolve
        $to = $filePath = split-path $filePath -NoQualifier -Resolve:$Resolve

        while($from -and $to -and ($from -ne $to)) {
            if($from.Length -gt $to.Length) {
                $from = split-path $from
            } else {
                $to = split-path $to
            }
        }

        $filepath = $filepath -replace "^"+[regex]::Escape($to)+"\\"
        $from = $Folder
        while($from -and $to -and $from -gt $to ) {
            $from = split-path $from
            $filepath = join-path ".." $filepath
        }
        if(($filepath -like ".\*") -or ($filepath -like "..\*") ) { Write-Output "$filepath" }
        else { Write-Output ".\$filepath" }
    }
}

# like test-path but takes $env:path into account
Function Find-Path($Path, [switch]$All=$false, [Microsoft.PowerShell.Commands.TestPathType]$type="Any"){
   if($(Test-Path $Path -Type $type)) {
      return $path
   } else {
      [string[]]$paths = @($pwd); 
      $paths += "$pwd;$env:path".split(";")
      
      $paths = Join-Path $paths $(Split-Path $Path -leaf) | ? { Test-Path $_ -Type $type }
      if($paths.Length -gt 0) {
         if($All) {
            return $paths;
         } else {
            return $paths[0]
         }
      }
   }
   throw "Couldn't find a matching path of type $type"
}
New-Alias -Name FindPath -value Find-Path -Description "" -Force


function Full-Path{
   param(
        [string]$path = $(throw "path is a required parameter.")
    )
    return [system.io.path]::GetFullPath($path)
}
New-Alias -Name FullPath -value Full-Path -Description "" -Force

function Join-Path2{
   param(
        [string]$path1, 
        [string]$path2 
    )
    if($path1 -and $path2){ return Join-Path $path1 $path2 }
    if($path1 -and !$path2){ return $path1 }
    if(!$path1 -and $path2){ return $path2 }
}
New-Alias -Name JoinPath -value Join-Path2 -Description "" -Force

function Core-EnsureFolder {
	param (
		[string] $path = $(throw "path is a required parameter.")
	)
    $path = Full-Path $path
	if(!(Test-Path $path)){
		$path -split "\\" | foreach { 
			if($newpath -eq $null) { $newpath = $_ }
	        else { $newpath = Join-Path -Path $newpath -ChildPath $_}
            if(!(Test-Path $_)) {  $null = New-Item -Type Directory -Confirm:$false -Force -Path $newpath }
		}
	}
}
New-Alias -Name EnsureFolder -value Core-EnsureFolder -Description "" -Force

function Core-RemoveFolder{
    param(
        [string] $path = $(throw "path is a required parameter."),
		[string] $root = ".",
		[switch] $recurse # searches for all path occurances
    )
	if($recurse){
		get-childitem $root -include $path -Recurse | foreach ($_) { Core-RemoveFolder $_.fullname }
	}
	else{
		if(test-path $path){
			write-host "remove: $(Get-RelativePath (fullpath .) $path)" 
			remove-item -force -recurse $path -ErrorAction SilentlyContinue | Out-Null
		}
	}
}
New-Alias -Name RemoveFolder -value Core-RemoveFolder -Description "" -Force 

function Core-ClearFolder{
    param(
        [string] $path = ".",
        [int] $days = 14
    )
    
    dir $path | where {$_.CreationTime -lt (get-date).AddDays(-$($days))} | del -Force
}

function Core-BuildDir{
    $scriptfile = Get-Item -Path $psake.build_script_file
    $scriptfile.directory
}
New-Alias -Name BuildDir -value Core-BuildDir -Description "" -Force

function Core-BuildName{
    [System.IO.Path]::GetFileNameWithoutExtension($psake.build_script_file)
}
New-Alias -Name BuildName -value Core-BuildName -Description "" -Force

function Core-ResolveDefaultModel{
	param(
		[string] $environment
	)
    $scriptfile = Get-Item -Path $psake.build_script_file
	if($environment){ $model = "$($scriptfile.directory)\$(Core-BuildName).$($environment).model.psm1"}
	else{ $model = "$($scriptfile.directory)\$(Core-BuildName).model.psm1"}
    Assert (test-path $model) ("Error: Expected model {0} was not found" -f $model)
    return $model
}
New-Alias -Name ResolveDefaultModel -value Core-ResolveDefaultModel -Description "" -Force

function Core-CheckFolderAcl{
    param(
        [string] $path,
        [string] $checkType = "",
        [switch] $recurse = $false
    )

    dir $path -Recurse:$recurse | ? {$_.PSIsContainer} | % {
        $folderName = $_.FullName
        try{
            $acl = Get-Acl $folderName -ErrorAction SilentlyContinue

            $acl.Access | % {
                if (($checkType -eq "") -or ($checkType -eq $_.IdentityReference)){
                    "'$folderName' has $($_.IdentityReference) access at level: $($_.FileSystemRights)"
                }
            }
        }
        catch{
            # do nothing, check more specific
        }
    }
}
New-Alias -Name CheckFolderAcl -value Core-CheckFolderAcl -Description "" -Force

function Import-Certificate
{
	param
	(
		[IO.FileInfo] $CertFile = $(throw "Paramerter -CertFile [System.IO.FileInfo] is required."),
		[string[]] $StoreNames = $(throw "Paramerter -StoreNames [System.String] is required."),
		[switch] $LocalMachine,
		[switch] $CurrentUser,
		[string] $CertPassword,
		[switch] $Verbose
	)
	
	begin
	{
		[void][System.Reflection.Assembly]::LoadWithPartialName("System.Security")
	}
	
	process 
	{
        if ($Verbose)
		{
            $VerbosePreference = 'Continue'
        }
    
		if (-not $LocalMachine -and -not $CurrentUser)
		{
			Write-Warning "One or both of the following parameters are required: '-LocalMachine' '-CurrentUser'. Skipping certificate '$CertFile'."
		}

		try
		{
			if ($_)
            {
                $certfile = $_
            }
            # http://www.orcsweb.com/blog/james/powershell-ing-on-windows-server-how-to-import-certificates-using-powershell/
			$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
			$cert.import($CertFile,$CertPassword,"Exportable,PersistKeySet") # specifying Exportable is a security, needed otherwise error when assigning in iis (logon session does not exist)
		}
		catch
		{
			Write-Error ("Error importing '$certfile': $_ .") -ErrorAction:Continue
		}
			
		if ($cert -and $LocalMachine)
		{
			$StoreScope = "LocalMachine"
			$StoreNames | ForEach-Object {
				$StoreName = $_
				if (Test-Path "cert:\$StoreScope\$StoreName")
				{
					try
					{
						$store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreScope
						$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
						$store.Add($cert)
						$store.Close()
						Write-Verbose "Successfully added '$certfile' to 'cert:\$StoreScope\$StoreName'."
					}
					catch
					{
						Write-Error ("Error adding '$certfile' to 'cert:\$StoreScope\$StoreName': $_ .") -ErrorAction:Continue
					}
				}
				else
				{
					Write-Warning "Certificate store '$StoreName' does not exist. Skipping..."
				}
			}
		}
		
		if ($cert -and $CurrentUser)
		{
			$StoreScope = "CurrentUser"
			$StoreNames | ForEach-Object {
				$StoreName = $_
				if (Test-Path "cert:\$StoreScope\$StoreName")
				{
					try
					{
						$store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreScope
						$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
						$store.Add($cert)
						$store.Close()
						Write-Verbose "Successfully added '$certfile' to 'cert:\$StoreScope\$StoreName'."
					}
					catch
					{
						Write-Error ("Error adding '$certfile' to 'cert:\$StoreScope\$StoreName': $_ .") -ErrorAction:Continue
					}
				}
				else
				{
					Write-Warning "Certificate store '$StoreName' does not exist. Skipping..."
				}
			}
		}
	}
	
	end
	{ }
}
New-Alias -Name ImportCertificate -value Import-Certificate -Description "" -Force

Export-Modulemember -alias * -Function *