param(
    [string]$Action,
    [string]$Password,
    [string]$FilePath = "comandos_anitgraviti_para_subir_a_produccion_b64.md"
)

$EncPath = "encrypt.enc"
$HintPath = "encrypt.hint"

function Invoke-AesEncryption {
    param($Path, $EncPath, $Password, $ActionMode)
    
    $salt = [System.Text.Encoding]::UTF8.GetBytes("NiidoAtardeceresSalt!")
    $rfc2898 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 10000)
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $rfc2898.GetBytes($aes.KeySize / 8)
    $aes.IV = $rfc2898.GetBytes($aes.BlockSize / 8)
    
    if ($ActionMode -eq 'Encrypt') {
        if (-not (Test-Path $Path)) {
            Write-Host "[ERROR] No se encontro el archivo origen ($Path) para encriptar." -ForegroundColor Red
            return $false
        }

        $outPath = $EncPath
        try {
            $fsOut = New-Object System.IO.FileStream($outPath, [System.IO.FileMode]::Create)
            $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($fsOut, $aes.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
            $fsIn = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open)
            
            $fsIn.CopyTo($cryptoStream)
            Write-Host "[OK] Archivo '$outPath' encriptado exitosamente." -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[ERROR] Ocurrio un error al encriptar: $_" -ForegroundColor Red
            return $false
        } finally {
            if ($fsIn) { $fsIn.Close() }
            if ($cryptoStream) { $cryptoStream.Close() }
            if ($fsOut) { $fsOut.Close() }
        }
        
    } elseif ($ActionMode -eq 'Decrypt') {
        $inPath = $EncPath
        if (-not (Test-Path $inPath)) {
            Write-Host "[ERROR] No se encontro el archivo encriptado ($inPath)." -ForegroundColor Red
            return $false
        }
        
        try {
            $fsIn = New-Object System.IO.FileStream($inPath, [System.IO.FileMode]::Open)
            $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($fsIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read)
            $fsOut = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Create)
            
            $cryptoStream.CopyTo($fsOut)
            Write-Host "[OK] Archivo '$Path' desencriptado exitosamente." -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[ERROR] Error al desencriptar. Contrasena incorrecta o archivo danado." -ForegroundColor Red
            if ($fsOut) { $fsOut.Close() }
            if (Test-Path $Path) { Remove-Item $Path -Force }
            return $false
        } finally {
            if ($fsOut -and $fsOut.CanWrite) { $fsOut.Close() }
            if ($cryptoStream) { $cryptoStream.Close() }
            if ($fsIn) { $fsIn.Close() }
        }
    }
}

# Ejecución por parámetros (si se usa desde terminal directo sin menú)
if ($Action -and $Password) {
    if ($Action -in @('Encrypt', 'Decrypt')) {
        $success = Invoke-AesEncryption -Path $FilePath -EncPath $EncPath -Password $Password -ActionMode $Action
        if ($success -and $Action -eq 'Encrypt') {
            Remove-Item $FilePath -Force
            Write-Host "[OK] Archivo original eliminado." -ForegroundColor Green
            Write-Host "[!] ADVERTENCIA: Usaste el modo directo, no se configuro ningun indicio de contraseña. Usa el menu interactivo para agregarlo." -ForegroundColor Yellow
        }
    } else {
        Write-Host "La accion debe ser 'Encrypt' o 'Decrypt'." -ForegroundColor Red
    }
    return
}

# Bucle principal del Menú Interactivo
while ($true) {
    Write-Host "`n===============================================" -ForegroundColor Cyan
    Write-Host "   GESTOR DE SEGURIDAD - ARCHIVOS A PRODUCCION   " -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "1. Encriptar archivo (Ocultarlo)"
    Write-Host "2. Desencriptar archivo (Revelarlo)"
    Write-Host "3. Cambiar contrasena e indicio"
    Write-Host "4. Salir"
    Write-Host "===============================================" -ForegroundColor Cyan
    
    $opcion = Read-Host "Elige una opcion (1-4)"
    
    switch ($opcion) {
        '1' {
            if (-not (Test-Path $FilePath)) {
                Write-Host "`n[!] El archivo original ya no existe o ya esta encriptado." -ForegroundColor Yellow
            } else {
                $rawPass = Read-Host "Ingresa la contrasena para encriptar"
                $pass = $rawPass.Trim()
                
                $hint = Read-Host "Escribe un indicio p/ pista para recordar esta contrasena en el futuro"
                
                $success = Invoke-AesEncryption -Path $FilePath -EncPath $EncPath -Password $pass -ActionMode "Encrypt"
                if ($success) {
                    # Guardamos el indicio en un archivo .hint para recordarlo
                    $hint | Out-File -FilePath $HintPath -Encoding UTF8
                    Write-Host "[OK] Indicio guardado exitosamente." -ForegroundColor Green
                    
                    Write-Host "Deseas eliminar el archivo original ahora para protegerlo? (S/N)" -ForegroundColor Yellow
                    $del = Read-Host
                    if ($del -eq 'S' -or $del -eq 's') {
                        Remove-Item $FilePath -Force
                        Write-Host "[OK] Archivo original eliminado. Solo queda el .enc y tu .hint seguro!" -ForegroundColor Green
                    }
                }
            }
        }
        '2' {
            if (-not (Test-Path $EncPath)) {
                Write-Host "`n[!] No hay ningun archivo .enc para desencriptar." -ForegroundColor Yellow
            } else {
                # Mostrar el indicio si existe
                if (Test-Path $HintPath) {
                    $savedHint = Get-Content $HintPath -Raw
                    Write-Host "`n[AYUDA] Indicio de la contrasena: $savedHint" -ForegroundColor Magenta
                } else {
                    Write-Host "`n[!] No se encontro ningun indicio guardado para esta contrasena." -ForegroundColor DarkGray
                }

                $rawPass = Read-Host "Ingresa la contrasena para desencriptar"
                $pass = $rawPass.Trim()
                
                $null = Invoke-AesEncryption -Path $FilePath -EncPath $EncPath -Password $pass -ActionMode "Decrypt"
            }
        }
        '3' {
            Write-Host "`n--- PROCESO DE CAMBIO DE CONTRASENA E INDICIO ---" -ForegroundColor Cyan
            if (-not (Test-Path $EncPath)) {
                Write-Host "[!] Necesitas tener el archivo .enc para poder cambiarle la contrasena." -ForegroundColor Yellow
                continue
            }

            if (Test-Path $HintPath) {
                $savedHint = Get-Content $HintPath -Raw
                Write-Host "`n[AYUDA ACTUAL] Indicio actual: $savedHint" -ForegroundColor Magenta
            }

            $rawOldPass = Read-Host "1. Ingresa la contrasena ANTERIOR"
            $oldPass = $rawOldPass.Trim()
            
            Write-Host "Verificando contrasena anterior y desencriptando..." -ForegroundColor Gray
            $decrypted = Invoke-AesEncryption -Path $FilePath -EncPath $EncPath -Password $oldPass -ActionMode "Decrypt"
            
            if ($decrypted) {
                Write-Host "[OK] Contrasena anterior correcta." -ForegroundColor Green
                
                $rawNewPass = Read-Host "2. Ingresa la NUEVA contrasena"
                $newPass = $rawNewPass.Trim()
                
                $newHint = Read-Host "3. Escribe el NUEVO indicio p/ pista para esta contrasena"
                
                Write-Host "Encriptando con la NUEVA contrasena..." -ForegroundColor Gray
                $encrypted = Invoke-AesEncryption -Path $FilePath -EncPath $EncPath -Password $newPass -ActionMode "Encrypt"
                
                if ($encrypted) {
                    $newHint | Out-File -FilePath $HintPath -Encoding UTF8
                    Write-Host "Limpiando archivos temporales..." -ForegroundColor Gray
                    Remove-Item $FilePath -Force
                    Write-Host "[OK] CAMBIO DE CONTRASENA Y NUEVO INDICIO EXITOSO." -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Fallo la encriptacion con la nueva contrasena! Tu archivo desencriptado aun esta en la carpeta por seguridad." -ForegroundColor Red
                }
            } else {
                Write-Host "[ERROR] CAMBIO CANCELADO: La contrasena anterior es incorrecta." -ForegroundColor Red
            }
        }
        '4' {
            Write-Host "Saliendo del programa..." -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Opcion invalida. Intenta nuevamente." -ForegroundColor Red
        }
    }
}
