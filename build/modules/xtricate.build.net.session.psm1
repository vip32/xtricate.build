function Create-Session{
    param(
        [Parameter(Position=0,Mandatory=1)]
        [string] $node,
        [Parameter(Position=0,Mandatory=1)]
        [object] $identity
    )

    Write-Progress -Activity "connection: $node" -Status "testing"
    if(Test-Connection -ComputerName $node -Quiet -ErrorAction SilentlyContinue){ Write-Host "connection test: node was found" }
    else{ Write-Warning "could not find the node $node" }
    
    if($($identity.type) -eq "identity"){ $username = "$($node)\$($identity.name)" } # todo : should check for localidentity
    else{ $username = "$($_.domain)\$($identity.name)" }
    Write-Host "network credential: $username"
    
    Write-Host "create session: node $node with credential $username"
    $credential = Get-NetworkCredential -username $username -password $identity.password
    Write-Progress -Activity "connection: $node" -Status "connecting" -PercentComplete 33
    $session = New-PSSession -ComputerName $node -Credential $credential -Verbose  
    Write-Progress -Activity "connection: $node" -Status "connecting" -PercentComplete 66
    
    if($session -eq $null){ Write-Warning "cannot create new session for $node with credential $username"}
    
    if($session -ne $null){
        Invoke-Command -Session $session -ScriptBlock { 
            $os =  Get-WmiObject -Class win32_OperatingSystem -namespace "root\CIMV2" -ComputerName .
            Write-Host "operating system: $($os.caption)"
            Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName . | Where-Object {$_.ipenabled} | ForEach-Object { 
                Write-Host "network adapter: ip=$($_.ipaddress), gateway=$($_.defaultipgateway), dnsdomain=$($_.dnsdomain), dhcp=$($_.dhcpenabled), description=$($_.description)"}
            Get-WMIObject Win32_LogicalDisk -filter "DriveType=3" -Computer . | 
                Select SystemName,DeviceID,VolumeName,@{Name="SizeGB";Expression={‘{0:N1}’ -f($_.size/1gb)}},@{Name="FreeSpaceGB";Expression={‘{0:N1}’ -f($_.freespace/1gb)}},@{Name="FreeSpacePercentage";Expression={‘{0:P2}’ -f(($_.freespace/1gb) / ($_.size/1gb))}} | 
                ForEach-Object { Write-Host "drive space $($_.deviceid) [$($_.volumename)]: size=$($_.sizegb)gb, free=$($_.freespacegb)gb [$($_.freespacepercentage)], "}
        }
    }
    Write-Progress -Activity "connection: $node" -Status "connecting" -PercentComplete 100 -Completed
    return $session
}
New-Alias -Name CreateSession -value Create-Session -Description "" -Force

function Copy-Session{
    param(
        [Parameter(Mandatory=1)]
        [string] $source,
        [Parameter(Mandatory=1)]
        [string] $target,
        [Parameter(Mandatory=1)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        [Parameter(Mandatory=0)]
        [int] $maxsizemb = 1024
    )
    $fullsource = Full-Path $source
    Write-Host "copy: $fullsource > $target on $($session.computername)"
    
    # todo : gives access denied 
    #Invoke-Command -Session $session -ArgumentList $maxsizemb -ScriptBlock{
        #param($maxsizemb)
        #set-item wsman:localhost\Shell\MaxMemoryPerShellMB 1024
        #Set-PSSessionConfiguration -name microsoft.powershell -MaximumReceivedObjectSizeMB 1024 -Force -Confirm:$false
        #Set-PSSessionConfiguration -name microsoft.powershell -MaximumReceivedObjectSizeMB $maxsizemb -Force -Confirm:$false
        #$max = Get-PSSessionConfiguration | select psmaximumreceivedobjectsizemb
        #Write-Host "max filesize allowed: $($max)MB"
    #}
    
    # remove remote location firsts
    Invoke-Command -Session $session -ArgumentList $target -ScriptBlock{
        param($target)
        if(Test-Path $target){ 
            Write-Verbose "remove: $target on $($env:computername)"
            Remove-Item -Path $target -Recurse -Force -Confirm:$false }
    }
    # copy source items to remote target location
    Get-ChildItem $source -Recurse | foreach {
                $t = Join-Path $target $_.FullName.Substring($fullsource.length)
                Write-Verbose "copy: $($_.FullName) > $t on $($session.computername)"
                Send-file -source $_.fullname -destination $t -session $session 
            }
    Write-Progress -Completed -Activity "dummy" -Status "dummy"
}
New-Alias -Name CopySession -value Copy-Session -Description "" -Force

function Send-File{
    param(
        [Parameter(Mandatory = $true)]
        $Source,
        [Parameter(Mandatory = $true)]
        $Destination,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )
    Set-StrictMode -Version Latest
    $send = $true
    $sourcePath = (Resolve-Path $source).Path

    Get-Item $sourcePath | % { if($_.psiscontainer){
        Invoke-Command -Session $session -ArgumentList $source,$Destination `
            -ScriptBlock {
                param($source,$destination)
                Write-Verbose "create directory: $destination on $($env:computername)"
                Write-Progress -Activity "directory: $source" -Status "creating" -PercentComplete 0 -CurrentOperation "on [$($env:computername)]: $destination"
                $null = New-Item -Path $destination -ItemType Directory -Confirm:$false -Force
                #Write-Progress -Activity "directory: $source" -Status "creating" -Completed 
            }
        $send = $false
        }
    }

    if($send){
        $sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
        $streamChunks = @()
        Write-Progress -Activity "copy: $Source" -Status "preparing" -PercentComplete 0 -CurrentOperation "to [$($session.computername)]: $destination"
        $streamSize = 1MB
        for($position = 0; $position -lt $sourceBytes.Length;
            $position += $streamSize){
            $remaining = $sourceBytes.Length - $position
            $remaining = [Math]::Min($remaining, $streamSize)
            $nextChunk = New-Object byte[] $remaining
            [Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
            $streamChunks += ,$nextChunk
        }
        #Write-Progress -Activity "copy: $Source" -Status "preparing" -Completed
        
        $remoteScript = {
            param($destination, $length, $source)
            ## Convert the destination path to a full filesytem path (to support
            ## relative paths)
            $Destination = $executionContext.SessionState.`
                Path.GetUnresolvedProviderPathFromPSPath($Destination)
            ## Create a new array to hold the file content
            $destBytes = New-Object byte[] $length
            $position = 0
            ## Go through the input, and fill in the new array of file content
            foreach($chunk in $input){
                Write-Progress -Activity "copy: $source" `
                    -Status "sending" `
                    -PercentComplete ($position / $length * 100) `
                    -CurrentOperation "to [$($env:computername)]: $destination"

                [GC]::Collect()
                [Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
                $position += $chunk.Length
            }
            ## Write the content to the new file
            [IO.File]::WriteAllBytes($destination, $destBytes)
            ## Show the result
            #Get-Item $destination
            [GC]::Collect()
            #Write-Progress -Completed -Activity "copy: $source" -Status "sending"
        }

        ## Stream the chunks into the remote script
        $streamChunks | Invoke-Command -Session $session $remoteScript `
           -ArgumentList $destination,$sourceBytes.Length,$source
    }
}
New-Alias -Name SendFile -value Send-File -Description "" -Force

Export-Modulemember -alias * -Function *