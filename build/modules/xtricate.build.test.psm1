function Test-Nunit-Simple
{
    param(
		[Parameter(Position=0,Mandatory=1)]
        [string]$toolsdir = $(throw "$toolsdir is a required parameter."),
	    [Parameter(Position=0,Mandatory=1)]
        [string]$assembly = $(throw "assembly is a required parameter.")
    )	
	Write-Host "running tests in $assembly"
    $testrunner = Join-Path $toolsdir "nunit\nunit-console.exe"
    Assert (test-path $testrunner) ("Error: Test runner {0} was not found" -f $testrunner)
    Assert (test-path $assembly) ("Error: Assembly to test {0} was not found" -f $assembly)
	exec {&$testrunner /nologo $assembly /framework:4.0.30319} "Tests in $assembly failed!"
}
New-Alias -Name Nunit-Simple -value Test-Nunit-Simple -Description ""

function Test-Nunit 
{
    param(
		[Parameter(Position=0,Mandatory=1)]
        [string]$toolsdir = $(throw "toolsdir is a required parameter."),
        [Parameter(Position=0,Mandatory=1)]
        [string]
        $assembly,
        [Parameter(Position=1,Mandatory=0)]
        [string[]]
        $Include = @(),
        [Parameter(Position=2,Mandatory=0)]
        [string[]]
        $Exclude = @(),
        [Parameter()]
        [switch]
        $silent,
        [Parameter()]
        [switch]
        $NoShadow
    )
    Write-Host "running tests in $assembly"
    $testrunner = Join-Path $toolsdir "nunit\nunit-console.exe"
    Assert (test-path $testrunner) ("Error: Test runner {0} was not found" -f $testrunner)
    Assert (test-path $assembly) ("Error: Assembly to test {0} was not found" -f $assembly)
    $tempFile = "$env:TEMP\psake-nunit.xml"
    if (test-path $tempFile) { Get-Item $tempFile | Remove-Item  } #Remove-Item $tempFile doesn't work because my temp is C:\Users\J34EF~1.STE\AppData\Local\Temp
    
    $param = @()
    if ($Include.Count -gt 0) { $param += '/include:'+($Include -join ',') }
    if ($Exclude.Count -gt 0) { $param += '/exclude:'+($Exclude -join ',') }
    if ($NoShadow)            { $param += '/noshadow' }
    
    Write-Debug "output xml file: $tempFile"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & $testrunner $assembly /nologo /framework:4.0.30319 /xml:$tempFile @param
    if (!$silent) {
        $output | Out-Host
    }
    $stopwatch.stop()
    
    $ret = new-Object PsObject -prop @{
        Assembly   = $assembly
        Failed     = $false
        Total      = 0
        Failures   = 0
        Errors     = 0
        NotRun     = 0
        FailedTestCases = @()
        Duration   = $stopwatch.Elapsed
        Error      = ''
    }
    if ($lastExitCode -ne 0) {
        $ret.Failed = $true
        if (!(Test-Path $tempFile)) {
            if ($silent) { $output | Out-Host }               # give him chance to see at least something
            $ret.Error = 'no output file was created'
            return $ret
        }
        # when silent, normal output is not written, but then it is not clear what caused the error 
        # so we will parse the xml and show the failing test
        $res = [xml](gc $tempFile)
        $failed = $res | 
            Select-Xml -XPath '//test-case' | 
            Select-Object -ExpandProperty Node |
            ? { $_.success -eq "false" } |
            % { $ret.FailedTestCases += new-Object PsObject -prop @{
                    Name = $_.Name
                    Messsage = $_.failure.Message.InnerText
                    StackTrace = $_.failure.'stack-trace'.InnerText
                 }
              }
        $ret.Failures = $res.'test-results'.Failures
        $ret.Errors = $res.'test-results'.Errors
    }
    else {
        $res = ([xml](gc $tempFile)).'test-results'
        $ret.Total = $res.Total
        $ret.Failures = $res.Failures # should be 0
        $ret.Errors = $res.Errors # should be 0
        $ret.NotRun = $res.'Not-Run' 
    }
    $ret
}
New-Alias -Name Nunit -value Test-Nunit -Description ""

function Write-NunitRes
{
    param([Parameter(Mandatory=$true)][PsObject]$res)
    
    if ($res.Failed) {
        Write-ScriptError "some Nunit tests failed:"
        $res.FailedTestCases | 
            % { Write-Host "------------------------------------"
                Write-Host Name:`n $_.Name 
                Write-Host Statk trace:`n $_.StackTrace
                Write-Host Message:`n $_.Messsage
                Write-Host
              }
    }
    Write-Host "Total:         " $res.Total 
    Write-Host "Errors         " $res.Errors
    Write-Host "Failures       " $res.Failures
    Write-Host "NotRun:        " $res.NotRun
    Write-Host "Duration:      " $res.Duration
    Write-Host
}

function Run-TestPackages{
	param(
		[Parameter(Position=0,Mandatory=1)]
        [string]$toolsdir = $(throw "$toolsdir is a required parameter."),
		[Parameter(Position=1,Mandatory=1)]
		[string]$outdir = $(throw "$outdir is a required parameter."),
		[Parameter(Position=2,Mandatory=1)]
		[string]$assemblypattern = $(throw "$assemblypattern is a required parameter."),
		[Parameter(Position=2,Mandatory=0)]
		[string]$sourcesdir
	)
	if($sourcesdir){
		get-childitem $sourcesdir -include $outdir_dir -Recurse | 
            foreach ($_) { 
                foreach($assembly in Get-ChildItem $_.FullName -Include $assemblypattern -Recurse){
                    try{
                        if($assembly.Fullname -notmatch "\\obj"){
                            Write-Host "*** $($assembly.FullName)"
                            $count += 1
                            nunit-simple `
                                -toolsdir $toolsdir `
                                -assembly $assembly.FullName
                            }
                    }
                    catch{ Write-Warning "some tests failed in $($assembly.Fullname)" }
                }
            }
		    return
	}
	else{
		$count = 0
		foreach($solutionpackage in $psake.build_solution_packages){
	        $package = GetNodePackage -packageid $solutionpackage.packageid
	        if(($package.type -eq "systemtestpackage") -and (comparetags $tags $package.tags)){
	            get-childitem $($solutionpackage.location) -include $outdir -Recurse | 
                    foreach ($_) { 
	                foreach($assembly in Get-ChildItem $_.FullName -Include $assemblypattern -Recurse) {
                        try{
                            Write-Host "test $($package.type): $($package.name) [$($package.id)] $($solutionpackage.location)"
                            $count += 1
                            if($assembly.Fullname -notmatch "\\obj"){
                                nunit-simple `
                                    -toolsdir $toolsdir `
                                    -assembly $assembly.FullName
                            }
                         }
                         catch{ Write-Warning "some tests failed in $($assembly.Fullname)" }
	                }
	            }
	        }
	    }
	}
	if($count -eq 0){ Write-Warning "no packages with assemblies matching '$($assemblypattern)' were found" }
}
New-Alias -Name RunTestPackages -value Run-TestPackages -Description ""

Export-Modulemember -alias * -Function *
