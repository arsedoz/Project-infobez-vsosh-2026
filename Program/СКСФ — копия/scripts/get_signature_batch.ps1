param([string]$InputFile)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $InputFile)) { exit 1 }

Get-Content -LiteralPath $InputFile -Encoding UTF8 | ForEach-Object {
    $rawPath = $_
    if (-not [string]::IsNullOrWhiteSpace($rawPath)) {
        $path = "$rawPath".Trim()
        
        if (Test-Path -LiteralPath $path) {
            try {
                # 1. Сначала пробуем встроенную подпись
                $sig = Get-AuthenticodeSignature -LiteralPath $path -ErrorAction SilentlyContinue
                
                $finalStatus = "Unknown"
                $finalSubject = ""
                $finalIssuer = ""
                $finalThumb = ""

                if ($sig) {
                    $finalStatus = $sig.Status.ToString()
                    if ($sig.SignerCertificate) {
                        $finalSubject = $sig.SignerCertificate.Subject
                        $finalIssuer = $sig.SignerCertificate.Issuer
                        $finalThumb = $sig.SignerCertificate.Thumbprint
                    }
                }

                # 2. ЕСЛИ НЕ ПОДПИСАНО -> Ищем в Каталогах (AppLocker)
                if ($finalStatus -ne "Valid") {
                    try {
                        $appLocker = Get-AppLockerFileInformation -Path $path -EventType Auditing -ErrorAction SilentlyContinue
                        if ($appLocker -and $appLocker.Publisher) {
                            $finalStatus = "Valid" # Считаем валидным!
                            $finalSubject = $appLocker.Publisher.SubjectName
                            $finalIssuer = $appLocker.Publisher.IssuerName
                            if ([string]::IsNullOrEmpty($finalThumb)) { $finalThumb = "CATALOG_SIGNED" }
                        }
                    } catch {}
                }

                # Вывод результата
                [PSCustomObject]@{
                    Path = "$path"
                    Status = $finalStatus
                    StatusMessage = ""
                    Subject = $finalSubject
                    Issuer = $finalIssuer
                    Thumbprint = $finalThumb
                } | ConvertTo-Json -Compress -Depth 1

            } catch {
                [PSCustomObject]@{ Path = "$path"; Status = "Error"; } | ConvertTo-Json -Compress -Depth 1
            }
        }
    }
}