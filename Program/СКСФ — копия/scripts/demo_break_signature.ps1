# scripts/demo_break_signature.ps1
$DemoDir = "C:\Users\Public\wsi_demo"
$Source = "C:\Windows\System32\notepad.exe"
$Target = "$DemoDir\notepad_copy.exe"

# 1. Создаем папку
if (-not (Test-Path $DemoDir)) { New-Item -ItemType Directory -Path $DemoDir | Out-Null }

# 2. Копируем легитимный файл
Copy-Item -Path $Source -Destination $Target -Force
Write-Host "Copied $Source to $Target"

# 3. Ломаем подпись (меняем 1 байт в конце файла)
$bytes = [System.IO.File]::ReadAllBytes($Target)
# Меняем последний байт (или любой другой, чтобы хэш изменился)
if ($bytes.Length -gt 0) {
    $bytes[$bytes.Length - 1] = $bytes[$bytes.Length - 1] -bxor 0xFF
}
[System.IO.File]::WriteAllBytes($Target, $bytes)

Write-Host "Modified 1 byte in $Target. Signature should now be invalid."
Write-Host "Please add '$DemoDir' to targets in config/fast.json to detect this."
