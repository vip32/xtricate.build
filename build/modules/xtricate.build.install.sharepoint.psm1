# http://technet.microsoft.com/en-us/library/ee806878.aspx
# http://technet.microsoft.com/en-us/library/ff678226.aspx
# http://blog.fpweb.net/sharepoint-2010-web-application-installation/

function Load-SharepointAdmin() {
    try {
        # Add the required snap-ins for sharepoint 2010
        Add-Pssnapin Microsoft.SharePoint.PowerShell -Verbose -ErrorAction Stop
        #Write-Host "snapin loaded: sharepoint powershell"
        return $true
    } catch {
        # E.g. System.Management.Automation : The Windows PowerShell snap-in 'SqlServerProviderSnapin' is not installed on this machine.
        # E.g. System.Management.Automation : Cannot add Windows PowerShell snap-in SqlServerProviderSnapin100 because it is already added. Verify the name of the snap-in and try again.
        [string]$ErrorString = [string]$_.Exception.Message
        if ($ErrorString.contains("already added")) {
            return $true
        } else {
            Write-Host $_.Exception.Source,":", $ErrorString
            return $false
        }
    }
}