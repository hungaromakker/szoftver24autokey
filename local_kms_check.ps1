# KMS Aktiválás Ellenőrző Script
# Ez a script ellenőrzi a KMS aktiválásokat és licenckulcsokat a hálózaton

param (
    [Parameter(Mandatory=$false)]
    [string]$LicencKulcs
)

# Adminisztrátori jogok ellenőrzése
$adminJogok = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminJogok) {
    Write-Host "Hiba: A script futtatásához adminisztrátori jogok szükségesek!" -ForegroundColor Red
    exit
}

function Get-KMSActivationStatus {
    param (
        [string]$computerName,
        [string]$targetKey
    )
    
    Write-Host "`nKMS Ellenőrzés: $computerName" -ForegroundColor Cyan
    
    try {
        # KMS információk lekérése
        $kmsInfo = Invoke-Command -ComputerName $computerName -ScriptBlock {
            param($key)
            
            # KMS szerver információk
            $kmsDetails = cscript //nologo C:\Windows\System32\slmgr.vbs /dlv
            
            # Licenc információk
            $licenses = Get-CimInstance -ClassName SoftwareLicensingProduct | 
                Where-Object { $null -ne $_.PartialProductKey }
            
            # KMS aktiválási állapot
            $kmsStatus = @{
                KMSHost = ($kmsDetails | Where-Object { $_ -match "KMS gép IP-címe" }) -replace "KMS gép IP-címe:", "" -replace "\s+", ""
                KMSPort = ($kmsDetails | Where-Object { $_ -match "KMS port" }) -replace "KMS port:", "" -replace "\s+", ""
                Licenses = @()
            }
            
            foreach ($license in $licenses) {
                $licenseInfo = @{
                    ProductName = $license.Name
                    Description = $license.Description
                    PartialProductKey = $license.PartialProductKey
                    LicenseStatus = $license.LicenseStatus
                    KeyManagementServiceMachine = $license.KeyManagementServiceMachine
                    KeyManagementServicePort = $license.KeyManagementServicePort
                    DiscoveredKeyManagementServiceMachineName = $license.DiscoveredKeyManagementServiceMachineName
                    ProductKeyID = $license.ProductKeyID
                }
                
                if ($key -and $license.ProductKeyID -like "*$key*") {
                    $licenseInfo.KeyMatch = $true
                }
                
                $kmsStatus.Licenses += $licenseInfo
            }
            
            return $kmsStatus
        } -ArgumentList $targetKey -ErrorAction Stop
        
        # Eredmények megjelenítése
        if ($kmsInfo.KMSHost) {
            Write-Host "`nKMS Szerver Információk:" -ForegroundColor Yellow
            Write-Host "KMS Host: $($kmsInfo.KMSHost)"
            Write-Host "KMS Port: $($kmsInfo.KMSPort)"
        }
        
        foreach ($license in $kmsInfo.Licenses) {
            $aktivalasiAllapot = switch ($license.LicenseStatus) {
                0 { "Nem aktivált" }
                1 { "Aktivált" }
                2 { "OOB Grace" }
                3 { "OOT Grace" }
                4 { "Non-Genuine Grace" }
                5 { "Notification" }
                6 { "Extended Grace" }
                default { "Ismeretlen" }
            }
            
            Write-Host "`nTermék Információk:" -ForegroundColor Green
            Write-Host "Név: $($license.ProductName)"
            Write-Host "Aktiválási állapot: $aktivalasiAllapot"
            Write-Host "Részleges termékkulcs: $($license.PartialProductKey)"
            Write-Host "Termék azonosító: $($license.ProductKeyID)"
            
            if ($targetKey -and $license.KeyMatch) {
                Write-Host "TALÁLAT: A keresett kulcs aktív ezen a gépen!" -ForegroundColor Green
            }
            
            if ($license.KeyManagementServiceMachine) {
                Write-Host "KMS Szerver: $($license.KeyManagementServiceMachine):$($license.KeyManagementServicePort)"
            }
        }
        
        return $true
    }
    catch {
        Write-Host "Hiba a(z) $computerName gépen: $_" -ForegroundColor Red
        return $false
    }
}

function Get-NetworkComputers {
    Write-Host "Hálózati számítógépek keresése..." -ForegroundColor Yellow
    try {
        # Active Directory lekérdezés
        $computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
        return $computers
    }
    catch {
        Write-Host "Active Directory nem elérhető, helyi hálózat ellenőrzése..." -ForegroundColor Yellow
        # Helyi hálózat ping alapú ellenőrzése
        $subnet = "192.168.1"
        $computers = @()
        1..254 | ForEach-Object {
            $ip = "$subnet.$_"
            if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
                try {
                    $hostname = [System.Net.Dns]::GetHostByAddress($ip).HostName
                    $computers += $hostname
                }
                catch {
                    $computers += $ip
                }
            }
        }
        return $computers
    }
}

# Főprogram
Clear-Host
Write-Host "KMS Aktiválás Ellenőrző" -ForegroundColor Green
Write-Host "----------------------" -ForegroundColor Green

if ([string]::IsNullOrEmpty($LicencKulcs)) {
    $LicencKulcs = Read-Host "Kérem adja meg az ellenőrizendő licenckulcsot (vagy hagyja üresen az összes kulcs ellenőrzéséhez)"
}

$computers = Get-NetworkComputers
$eredmenyek = @()

foreach ($computer in $computers) {
    $status = Get-KMSActivationStatus -computerName $computer -targetKey $LicencKulcs
    $eredmenyek += [PSCustomObject]@{
        Számítógép = $computer
        Státusz = if ($status) { "Sikeres ellenőrzés" } else { "Sikertelen ellenőrzés" }
    }
}

# Eredmények exportálása
$date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$exportPath = "kms_activation_status_$date.csv"
$eredmenyek | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Write-Host "`nEllenőrzés befejezve. Az eredmények exportálva: $exportPath" -ForegroundColor Green
Write-Host "Nyomjon meg egy billentyűt a kilépéshez..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
