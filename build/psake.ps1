# Helper script for those who want to run psake without importing the module.
# Example:
# .\psake.ps1 "default.ps1" "BuildHelloWord" "4.0x64" 

# Must match parameter definitions for psake.psm1/invoke-psake 
# otherwise named parameter binding fails
param(
  [Parameter(Position=0,Mandatory=0)]
  [string]$buildFile, #  = 'default.ps1'
  [Parameter(Position=1,Mandatory=0)]
  [string[]]$tasks = @(),
  [Parameter(Position=2,Mandatory=0)]
  [string]$framework = '4.0',
  [Parameter(Position=3,Mandatory=0)]
  [switch]$docs = $false,
  [Parameter(Position=4,Mandatory=0)]
  [string]$buildconfig = 'Debug',
  [Parameter(Position=5,Mandatory=0)]
  [string]$environment = 'LOCAL',
  [Parameter(Position=6,Mandatory=0)]
  [string[]]$nodes = $env:COMPUTERNAME,
  [Parameter(Position=7,Mandatory=0)]
  [string[]]$tags = $null,
  [Parameter(Position=8,Mandatory=0)]
  [string]$scriptPath = (Get-Location -PSProvider FileSystem).ProviderPath,
  [Parameter(Position=9,Mandatory=0)]
  [string[]]$skiptasks = @(),
  [Parameter(Position=10,Mandatory=0)]
  [System.Collections.Hashtable]$parameters = @{ },
  [Parameter(Position=11, Mandatory=0)]
  [System.Collections.Hashtable]$properties = @{ buildconfig=$buildconfig;environment=$environment;nodes=$nodes;tags=$tags }
)
#Add-Pssnapin Microsoft.SharePoint.PowerShell -Verbose -ErrorAction Continue # todo : remove ....
remove-module psake -ea 'SilentlyContinue'
import-module (join-path $scriptPath psake.psm1) -Force
invoke-psake $buildFile $tasks $skiptasks $framework $docs $parameters $properties
#exit $lastexitcode