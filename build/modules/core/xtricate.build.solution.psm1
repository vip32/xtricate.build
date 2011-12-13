function Core-DateTimeVersion{
    param(
        [int]$major = "1",
        [int]$minor = "0",
        [int]$initialyear = "2010"
    )
    $now = [DateTime]::Now
    $year = $now.Year - $initialyear
    $day = $now.Day.ToString("00")
    $month = $now.Month.ToString("00")
    $build = "$($year)$($month)$($day)"
    
    $span = $now - [DateTime]::Today
    $elapsed = $span.TotalMinutes.ToString("0000")
    
    return "$($major).$($minor.ToString("00")).$($build).$($elapsed)"
}
New-Alias -Name DateTimeVersion -value Core-DateTimeVersion -Description "" -Force

function Core-AssemblyInfo{
    param(
        [string[]] $files = $(throw "file is a required parameter."),
        [string] $clsCompliant = "true",
        [string] $title,
        [string] $description,
        [string] $company,
        [string] $product,
        [string] $copyright,
        [string] $version,
		[string] $commit
    )
    $asmInfo = "using System;
    using System.Reflection;
    using System.Runtime.CompilerServices;
    using System.Runtime.InteropServices;

    [assembly: CLSCompliantAttribute($clsCompliant )]
    [assembly: ComVisibleAttribute(false)]
    [assembly: AssemblyTitleAttribute(""$title"")]
    [assembly: AssemblyDescriptionAttribute(""$description"")]
    [assembly: AssemblyCompanyAttribute(""$company"")]
    [assembly: AssemblyProductAttribute(""$product"")]
	[assembly: AssemblyTrademarkAttribute(""$commit"")]
    [assembly: AssemblyCopyrightAttribute(""$copyright"")]
    [assembly: AssemblyVersionAttribute(""$version"")]
    [assembly: AssemblyInformationalVersionAttribute(""$version"")]
    [assembly: AssemblyFileVersionAttribute(""$version"")]
    [assembly: AssemblyDelaySignAttribute(false)]
    "
    $files | foreach {
        $dir = [System.IO.Path]::GetDirectoryName($_)
        if ([System.IO.Directory]::Exists($dir) -eq $false) { # todo : use ensurefolder
            Write-Host "creating directory $dir"
            [System.IO.Directory]::CreateDirectory($dir)
        }
        Write-Host "assemblyinfo: $_ [$($version)] $commit"
        Write-Output $asmInfo > $_
    }
}
New-Alias -Name AssemblyInfo -value Core-AssemblyInfo -Description "" -Force

function Get-Solution-TopologicalSort {
    param(
        [Parameter(Position=0,Mandatory=1)]
        [object[]] $solutions = $(throw "solutions is a required parameter."), 
        [Parameter(Position=1,Mandatory=0)]
        [switch] $reverse = $false
    )
    $solutionsarray = @()
    $solutions | where { $_ -ne $null } | 
                 foreach { $solutionsarray += "$($_.id):$($_.dependson -join ",")" } 
    if(arraynotnullorempty($solutionsarray)){ Get-TopologicalSort $solutionsarray $reverse }
}

function Core-CleanSolutions{
	param(
		[object[]] $solutions = $(throw "solutions to build is a required parameter."),
		[string] $framework = '4.0',
		[string[]] $tags
	)
	Get-Solution-TopologicalSort $solutions | foreach {
		foreach($solution in $solutions) { 
			if($solution.id -eq $_){ 
				if(comparetags $tags $solution.tags){ cleansolution $solution.path -framework $framework }
			}
		}
	}
}
New-Alias -Name CleanSolutions -value Core-CleanSolutions -Description "" -Force

function Core-CleanSolution{
    param(
        [string[]] $solutions = $(throw "solutions to build is a required parameter."),
        [string] $errormessage = "Build failed!",
        [string] $verbosity = "minimal"
    )
    $solutions | foreach {
        Write-Host "clean solution: $_"
        Assert (test-path $_) ("Error: Solution to clean {0} was not found" -f $_)
        exec { &msbuild $_ /verbosity:$verbosity /target:Clean /nologo } $errormessage
    }
}
New-Alias -Name CleanSolution -value Core-CleanSolution -Description "" -Force

function Core-FirstSolutionFile{
    param(
        [string] $path = $(throw "path is a required parameter.")
    )
    if(Test-Path $path){ dir "$path\*" -include "*.sln" -recurse | select -first 1}
	# else{ throw "$path does not exist, cannot find solution."}
}
New-Alias -Name FirstSolution -value Core-FirstSolutionFile -Description "" -Force

function Core-BuildSolutions{
	param(
		[object[]] $solutions = $(throw "solutions to build is a required parameter."),
		[string] $buildconfig = "Debug",
        [string] $outdir = ".\bin\$buildconfig",
		[string[]] $tags
	)
	Get-Solution-TopologicalSort $solutions | foreach {
		foreach($solution in $solutions) { 
			if($solution.id -eq $_){ 
				if(comparetags $tags $solution.tags){ buildsolution $solution.path -buildconfig $buildconfig -outdir $outdir }
			}
		}
	}
}
New-Alias -Name BuildSolutions -value Core-BuildSolutions -Description "" -Force

function Core-BuildSolution{
    param(
        [string[]] $solutions = $(throw "solutions to build is a required parameter."),
        [string] $buildconfig = "Debug",
        [string] $outdir = ".\bin\$buildconfig",
        [string] $errormessage = "Build failed!",
        [string] $verbosity = "minimal"
    )
    $solutions | foreach {
        Write-Host "Building $($buildconfig)/$($framework) $($_)"
        # exec { &"$base_dir\tools\pscx\echoargs.exe" $solution /verbosity:minimal "/p:OutDir=$build_dir\\" /p:Configuration=$buildconfig /p:DefineConstants=net40 /p:TargetFrameworkVersion=$framework /p:ToolsVersion=$framework /nologo } "TEST"
        Assert (test-path $_) ("Error: Solution to build {0} was not found" -f $_)
        exec { &msbuild $_ /verbosity:$verbosity "/p:OutDir=$outdir\\" /p:Configuration=$buildconfig /nologo } $errormessage
    }
}
New-Alias -Name BuildSolution -value Core-BuildSolution -Description "" -Force

function Build{
	param(
		[Parameter(Position=0,Mandatory=1)]
		[scriptblock] $solutions
	)
	New-Module -ArgumentList $solutions -AsCustomObject {
		param ($solutions)
		
		if($solutions -ne $null){ $_solutions = &$solutions }
		function Solutions {
			&$solutions
		}
		
		Export-ModuleMember -Function Solutions -Variable _solutions
	}
}

function Solution{
	param (
			[Parameter(Position=0,Mandatory=1)]
			[string] $id = "",
            [Parameter(Position=1,Mandatory=1)]
			[string] $path = "",
			[Parameter(Position=2,Mandatory=0)]
			[string] $name = "",
            [Parameter(Mandatory=0)]
            [string] $description = $null,
            [Parameter(Mandatory=0)]
            [switch] $skipclean = $false,
			[Parameter(Mandatory=0)]
            [switch] $skipbuild = $false,
            [Parameter(Mandatory=0)]
			[scriptblock] $settings = $null,
			[Parameter(Mandatory=0)]
			[string[]] $dependson = @(),
			[Parameter(Mandatory=0)]
			[string[]] $tags = @()
	)
	New-Module -ArgumentList $id, $path, $name, $description, $skipclean, $skipbuild, $settings, $dependson, $tags -AsCustomObject {
		param ( $id, $path, $name, $description, $skipclean, $skipbuild, $settings, $dependson, $tags )
		$type = "vssolution"
        
        if($settings -ne $null){ $_settings = &$settings }
    
        function Settings {
			&$settings
		}
        
		Export-ModuleMember -Function Settings -Variable type, id, path, name, description, skipclean, skipbuild, dependson, tags, _settings
	}
}

Export-Modulemember -alias * -Function *