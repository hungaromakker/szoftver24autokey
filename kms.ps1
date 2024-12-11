$logPath = "C:\KMSLogs\kms_activations.log"
$logFolder = Split-Path $logPath -Parent

if (!(Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder
}

function Write-ToLog {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $logPath
}

Write-ToLog "KMS Activation monitoring started"

Register-WmiEvent -Query "SELECT * FROM Win32_NTLogEvent WHERE LogFile='System' AND (EventCode='12288' OR EventCode='12289')" -Action {
    $eventData = $args[0]
    $eventXML = [xml]$eventData.SourceEventArgs.NewEvent.Message
    
    $computerName = $env:COMPUTERNAME
    $clientIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*"}).IPAddress
    
    try {
        $eventDescription = $eventXML.Event.EventData.Data | Out-String
        Write-ToLog "Event Details: $eventDescription"
        
        $slmgr = cscript //nologo c:\windows\system32\slmgr.vbs /dlv
        $kmsHost = ($slmgr | Select-String "KMS machine IP address:").ToString().Split(":")[1].Trim()
        $productKey = ($slmgr | Select-String "Partial Product Key:").ToString().Split(":")[1].Trim()
        
        $logMessage = "KMS Activation Event - Computer: $computerName, IP: $clientIP, KMS Host: $kmsHost, Product Key: $productKey"
        Write-ToLog $logMessage
        
        $installedKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
        if ($installedKey) {
            Write-ToLog "Installed Product Key: $installedKey"
        }
    }
    catch {
        Write-ToLog "Error getting KMS details: $_"
    }
}

Register-WmiEvent -Query "SELECT * FROM Win32_NTLogEvent WHERE LogFile='Security' AND EventCode='4624'" -Action {
    $eventData = $args[0]
    $eventXML = [xml]$eventData.SourceEventArgs.NewEvent.Message
    
    $sourceIP = $eventXML.SelectSingleNode("//Data[@Name='IpAddress']").'#text'
    $userName = $eventXML.SelectSingleNode("//Data[@Name='TargetUserName']").'#text'
    $workstation = $eventXML.SelectSingleNode("//Data[@Name='WorkstationName']").'#text'
    $logonType = $eventXML.SelectSingleNode("//Data[@Name='LogonType']").'#text'
    
    if ($logonType -eq 3) {
        $logMessage = "New KMS connection from: IP=$sourceIP, Computer=$workstation, User=$userName"
        Write-ToLog $logMessage
    }
}

while ($true) {
    Start-Sleep -Seconds 60
}