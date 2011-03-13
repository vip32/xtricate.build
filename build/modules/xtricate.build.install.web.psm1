function Load-WebAdmin {
	# http://learn.iis.net/page.aspx/447/managing-iis-with-the-iis-70-powershell-snap-in/
	# http://learn.iis.net/page.aspx/492/powershell-snap-in-using-the-task-based-cmdlets-of-the-iis-powershell-snap-in/
  	# http://learningpcs.blogspot.com/2010/08/powershell-iis-7-webadministration.html
    # http://serverfault.com/questions/201787/iis-administration-using-powershell-2-and-modules-on-windows-2008-r1
  	$webAdminModule = get-module -ListAvailable | ? { $_.Name -eq "webadministration" }
  	If ($webAdminModule -ne $null) {
	    import-module WebAdministration -Force -Global -DisableNameChecking
        #Write-Host "module loaded: iis powershell module"
  	}
}

