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
        [string] $version
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
        Write-Host "assemblyinfo: $_ [$($version)]"
        Write-Output $asmInfo > $_
    }
}
New-Alias -Name AssemblyInfo -value Core-AssemblyInfo -Description "" -Force

function Core-CleanSolution{
    param(
        [string[]] $solutions = $(throw "solutions to build is a required parameter."),
        [string] $framework = '4.0',
        [string] $errormessage = "Build failed!",
        [string] $verbosity = "minimal"
    )
    $solutions | foreach {
        Write-Host "clean solution: $_"
        Assert (test-path $_) ("Error: Solution to build {0} was not found" -f $_)
        exec { &msbuild $_ /verbosity:$verbosity /target:Clean /p:DefineConstants=net40 /p:TargetFrameworkVersion=$framework /p:ToolsVersion=$framework /nologo } $errormessage
    }
}
New-Alias -Name CleanSolution -value Core-CleanSolution -Description "" -Force

function Core-FirstSolutionFile{
    param(
        [string] $path = $(throw "path is a required parameter.")
    )
    if(Test-Path $path){ dir "$path\*" -include "*.sln" -recurse | select -first 1}
    else{ throw "$path does not exist, cannot find solution."}
}
New-Alias -Name FirstSolution -value Core-FirstSolutionFile -Description "" -Force

function Core-BuildSolution{
    param(
        [string[]] $solutions = $(throw "solutions to build is a required parameter."),
        [string] $buildconfig = "Debug",
        [string] $outdir = ".\bin\$buildconfig",
        [string] $framework = '4.0',
        [string] $errormessage = "Build failed!",
        [string] $verbosity = "minimal"
    )
    $solutions | foreach {
        Write-Host "Building $buildconfig/$framework $solution"
        # exec { &"$base_dir\tools\pscx\echoargs.exe" $solution /verbosity:minimal "/p:OutDir=$build_dir\\" /p:Configuration=$buildconfig /p:DefineConstants=net40 /p:TargetFrameworkVersion=$framework /p:ToolsVersion=$framework /nologo } "TEST"
        Assert (test-path $_) ("Error: Solution to build {0} was not found" -f $_)
        exec { &msbuild $_ /verbosity:$verbosity "/p:OutDir=$outdir\\" /p:Configuration=$buildconfig /p:DefineConstants=net40 /p:TargetFrameworkVersion=$framework /p:ToolsVersion=$framework /nologo } $errormessage
    }
}
New-Alias -Name BuildSolution -value Core-BuildSolution -Description "" -Force

Export-Modulemember -alias * -Function *