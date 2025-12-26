# update_ipset.ps1
Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$domainsFile = Join-Path $workingDir "domains_ru.txt"
$outputFile = Join-Path $workingDir "ip_map_ru.txt"

if (-not (Test-Path $domainsFile)) { exit 1 }

$domains = Get-Content $domainsFile | Where-Object { $_ -match '\.' }

# Запускаем задачи
$jobs = foreach ($domain in $domains) {
    Write-Host ('Starting ip-range resolve for:', $domain);
    Start-Job -ScriptBlock {
        param($d)
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($d) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            $output = @()
            foreach ($ip in $ips) {
                $ipStr = $ip.IPAddressToString
                try {
                    $rdap = Invoke-RestMethod -Uri "rdap.org" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                    if ($rdap.cidr0_cidrs) {
                        $range = "$($rdap.cidr0_cidrs.v4prefix)/$($rdap.cidr0_cidrs.length)"
                    } else { $range = "$($ipStr.Substring(0, $ipStr.LastIndexOf('.'))).0/24" }
                } catch { $range = "$($ipStr.Substring(0, $ipStr.LastIndexOf('.'))).0/24" }
                
                # ИСПРАВЛЕНО: используем ${d} чтобы избежать ошибки диска
                $output += "${d}:$range"
            }
            return $output
        } catch { return $null }
    } -ArgumentList $domain
}

# Ждем завершения (максимум 15 сек)
Wait-Job $jobs -Timeout 15 | Out-Null

# Собираем данные
$resultsRaw = Receive-Job $jobs

# КРИТИЧЕСКИ ВАЖНО: Очистка памяти и завершение процессов
$jobs | Stop-Job
$jobs | Remove-Job -Force

if ($resultsRaw) {
    $resultsRaw | Where-Object { $_ -ne $null } | Select-Object -Unique | Out-File $outputFile -Encoding ascii
}
