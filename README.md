# KMS Licenc Ellenőrző Eszközök / KMS License Checking Tools

## Magyar leírás

### Áttekintés
Ez a projekt három PowerShell scriptet tartalmaz Windows KMS licencek ellenőrzéséhez:

1. `kms.ps1` - Hálózati KMS licenc ellenőrző
2. `local_kms_check.ps1` - Hálózati KMS aktiválás ellenőrző
3. `check_specific_key.ps1` - Specifikus licenckulcs kereső

### Script leírások

#### 1. kms.ps1
- **Funkció**: Hálózaton található számítógépek Windows aktiválási állapotának ellenőrzése
- **Használat**: 
```powershell
powershell -ExecutionPolicy Bypass -File .\kms.ps1
```

#### 2. local_kms_check.ps1
- **Funkció**: KMS aktiválások és licenckulcsok ellenőrzése a hálózaton
- **Használat**:
```powershell
# Alapértelmezett hálózati beállításokkal:
powershell -ExecutionPolicy Bypass -File .\local_kms_check.ps1

# Konkrét licenckulcs keresése:
powershell -ExecutionPolicy Bypass -File .\local_kms_check.ps1 -LicencKulcs "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
```

#### 3. check_specific_key.ps1
- **Funkció**: Megadott licenckulcs keresése és ellenőrzése
- **Használat**:
```powershell
# Paraméterrel:
powershell -ExecutionPolicy Bypass -File .\check_specific_key.ps1 -KeresettKulcs "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

# vagy interaktív módon:
powershell -ExecutionPolicy Bypass -File .\check_specific_key.ps1
```

### Hálózati Beállítások

#### Egyedi Hálózat Konfigurálása
A `local_kms_check.ps1` script testreszabása különböző hálózatokhoz:

1. **Subnet módosítása**:
   - Nyissa meg a scriptet szerkesztésre
   - Keresse meg a `$subnet = "192.168.1"` sort
   - Módosítsa a saját hálózatának megfelelően (pl. "10.0.0" vagy "172.16.1")

2. **IP tartomány módosítása**:
   - Alapértelmezetten az 1-254 IP címeket ellenőrzi
   - A tartomány módosításához változtassa meg: `1..254` értéket
   - Például nagyobb hálózathoz: `1..500`

3. **Időtúllépési beállítások**:
   - Nagy hálózatoknál növelje a timeout értéket
   - Keresse meg a `Test-Connection` parancsot
   - Adja hozzá a `-Timeout 1000` paramétert

#### Példák Különböző Hálózati Környezetekhez

1. **Kis irodai hálózat (192.168.1.x)**:
```powershell
$subnet = "192.168.1"
1..254 | ForEach-Object {
    $ip = "$subnet.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        # további kód...
    }
}
```

2. **Nagyobb vállalati hálózat (10.0.x.x)**:
```powershell
$subnet = "10.0"
0..255 | ForEach-Object {
    $secondOctet = $_
    1..254 | ForEach-Object {
        $ip = "$subnet.$secondOctet.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -Timeout 1000) {
            # további kód...
        }
    }
}
```

3. **Egyedi tartomány**:
```powershell
$startIP = "192.168.1.50"
$endIP = "192.168.1.100"
$startOctet = [int]($startIP.Split('.')[-1])
$endOctet = [int]($endIP.Split('.')[-1])
$subnet = $startIP.Substring(0, $startIP.LastIndexOf('.'))

$startOctet..$endOctet | ForEach-Object {
    $ip = "$subnet.$_"
    # további kód...
}
```

### Rendszerkövetelmények
- Windows 10 vagy újabb
- PowerShell 5.1 vagy újabb
- Adminisztrátori jogosultság
- Active Directory környezet (opcionális)
- Hálózati hozzáférés a célgépekhez

### Telepítés
1. Töltse le az összes .ps1 fájlt
2. Helyezze egy tetszőleges mappába
3. Futtassa PowerShell adminisztrátorként
4. Navigáljon a scriptek mappájába
5. Szükség esetén módosítsa a hálózati beállításokat
6. Futtassa a kívánt scriptet a fenti parancsok egyikével

### Hibaelhárítás
- Ha ExecutionPolicy hibát kap, futtassa: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`
- Ellenőrizze az adminisztrátori jogosultságokat
- Hálózati ellenőrzésnél győződjön meg a megfelelő hálózati hozzáférésről
- Tűzfal beállítások ellenőrzése (WMI és RPC portok)
- Nagy hálózatoknál növelje a timeout értékeket

---

## English Description

[Previous English content remains the same...]

### Network Configuration

#### Customizing for Specific Networks
To customize `local_kms_check.ps1` for different networks:

1. **Modify Subnet**:
   - Open the script for editing
   - Locate the line `$subnet = "192.168.1"`
   - Change it to match your network (e.g., "10.0.0" or "172.16.1")

2. **Modify IP Range**:
   - Default checks IPs 1-254
   - Change the `1..254` range as needed
   - For larger networks: `1..500`

3. **Timeout Settings**:
   - For large networks, increase timeout
   - Find the `Test-Connection` command
   - Add `-Timeout 1000` parameter

#### Examples for Different Network Environments

1. **Small Office Network (192.168.1.x)**:
```powershell
$subnet = "192.168.1"
1..254 | ForEach-Object {
    $ip = "$subnet.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        # rest of code...
    }
}
```

2. **Large Corporate Network (10.0.x.x)**:
```powershell
$subnet = "10.0"
0..255 | ForEach-Object {
    $secondOctet = $_
    1..254 | ForEach-Object {
        $ip = "$subnet.$secondOctet.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -Timeout 1000) {
            # rest of code...
        }
    }
}
```

3. **Custom Range**:
```powershell
$startIP = "192.168.1.50"
$endIP = "192.168.1.100"
$startOctet = [int]($startIP.Split('.')[-1])
$endOctet = [int]($endIP.Split('.')[-1])
$subnet = $startIP.Substring(0, $startIP.LastIndexOf('.'))

$startOctet..$endOctet | ForEach-Object {
    $ip = "$subnet.$_"
    # rest of code...
}
```

### System Requirements
- Windows 10 or newer
- PowerShell 5.1 or newer
- Administrator privileges
- Active Directory environment (optional)
- Network access to target machines

### Security Note
All scripts require administrator privileges to access license information. Always verify script contents before execution.
