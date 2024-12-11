# Specifikus Licenckulcs Ellenőrző Script
# Ez a script egy megadott licenckulcsot keres és ellenőriz

param (
    [Parameter(Mandatory=$false)]
    [string]$KeresettKulcs
)

# Adminisztrátori jogok ellenőrzése
$adminJogok = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminJogok) {
    Write-Host "Hiba: A script futtatásához adminisztrátori jogok szükségesek!" -ForegroundColor Red
    exit
}

function Test-SpecificKey {
    param (
        [string]$targetKey
    )

    if ([string]::IsNullOrEmpty($targetKey)) {
        $targetKey = Read-Host "Kérem adja meg az ellenőrizendő licenckulcsot"
    }

    Write-Host "`nKeresett kulcs: $targetKey" -ForegroundColor Cyan
    Write-Host "Ellenőrzés folyamatban..." -ForegroundColor Yellow

    try {
        # Windows licenc információk lekérése
        $licencek = Get-CimInstance -ClassName SoftwareLicensingProduct | 
            Where-Object { $null -ne $_.PartialProductKey }

        $talalat = $false

        foreach ($licenc in $licencek) {
            $aktualKulcs = $null
            
            try {
                # Aktuális kulcs lekérése
                $aktualKulcs = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey
                
                if ($aktualKulcs -eq $targetKey) {
                    Write-Host "`nTalálat!" -ForegroundColor Green
                    Write-Host "Termék: $($licenc.Name)" -ForegroundColor Green
                    Write-Host "A keresett kulcs aktív ezen a gépen." -ForegroundColor Green
                    
                    # Részletes információk megjelenítése
                    $aktivalasiAllapot = switch ($licenc.LicenseStatus) {
                        0 { "Nem aktivált" }
                        1 { "Aktivált" }
                        2 { "OOB Grace" }
                        3 { "OOT Grace" }
                        4 { "Non-Genuine Grace" }
                        5 { "Notification" }
                        6 { "Extended Grace" }
                        default { "Ismeretlen" }
                    }
                    
                    Write-Host "Aktiválási állapot: $aktivalasiAllapot"
                    Write-Host "Termék azonosító: $($licenc.ProductKeyID)"
                    Write-Host "Termék leírás: $($licenc.Description)"
                    
                    $talalat = $true
                }
            }
            catch {
                Write-Host "Figyelmeztetés: Nem sikerült lekérni az aktuális kulcsot" -ForegroundColor Yellow
                continue
            }
        }

        if (-not $talalat) {
            Write-Host "`nA keresett kulcs nem található ezen a gépen." -ForegroundColor Red
            
            # KMS szerver információk megjelenítése
            Write-Host "`nAktuális KMS konfiguráció:" -ForegroundColor Yellow
            $kmsInfo = cscript //nologo C:\Windows\System32\slmgr.vbs /dlv
            $kmsInfo | Where-Object { $_ -match "KMS" } | ForEach-Object { Write-Host $_ }
        }
    }
    catch {
        Write-Host "Hiba történt az ellenőrzés során: $_" -ForegroundColor Red
    }
}

# Főprogram
Clear-Host
Write-Host "Specifikus Licenckulcs Ellenőrző" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green

Test-SpecificKey -targetKey $KeresettKulcs

Write-Host "`nEllenőrzés befejezve." -ForegroundColor Green
Write-Host "Nyomjon meg egy billentyűt a kilépéshez..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
