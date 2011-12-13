function Load-SqlAdmin() {
    try {
        # Add the required snap-ins for SQL Server, http://blog.webtechy.co.uk/blog/_archives/2010/7/7/4572685.html
        Add-Pssnapin SqlServerProviderSnapin100 -ErrorAction Stop
        Add-Pssnapin SqlServerCmdletSnapin100 -ErrorAction Stop
        #Add-Pssnapin SqlServerProviderSnapin100 -ErrorAction SilentlyContinue
        #Add-Pssnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
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
