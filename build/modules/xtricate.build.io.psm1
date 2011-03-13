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

function Relative-Path{
    param(
        [string] $path = $(throw "path is a required parameter."),
        [string] $basepath = $(throw "basepath is a required parameter."),
        [switch] $combine = $false
    )
    if(!($combine)){
        return [system.io.path]::GetFullPath($path).SubString([system.io.path]::GetFullPath($basepath).Length + 1)
    }
    else{
        $relativepath = [system.io.path]::GetFullPath($path).SubString([system.io.path]::GetFullPath($basepath).Length + 1)
        return "$basepath\$relativepath"
    }
}
New-Alias -Name RelativePath -value Relative-Path -Description "" -Force

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
			write-host "remove: $path" 
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
    $scriptfile = Get-Item -Path $psake.build_script_file
    $model = "$($scriptfile.directory)\$(Core-BuildName).model.psm1"
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

Export-Modulemember -alias * -Function *