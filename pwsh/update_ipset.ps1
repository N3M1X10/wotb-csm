# update_ipset.ps1
$ProgressPreference = 'SilentlyContinue'
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$domainsFile = Join-Path $workingDir "domains_ru.txt"
$outputFile = Join-Path $workingDir "ip_map_ru.txt"

if (-not (Test-Path $domainsFile)) { 
    Write-Error "Domains file not found"
    exit 1 
}

$domains = Get-Content $domainsFile
$results = New-Object System.Collections.Generic.List[string]

foreach ($domain in $domains) {
    if ([string]::IsNullOrWhiteSpace($domain)) { continue }
    Write-Host "Processing: $domain"
    
    try {
        $ips = Resolve-DnsName $domain -Type A -ErrorAction SilentlyContinue -TcpOnly:$false | Select-Object -ExpandProperty IPAddress
        if (-not $ips) { continue }

        foreach ($ip in $ips) {
            try {
                # Используем RDAP с жестким таймаутом
                $rdap = Invoke-RestMethod -Uri "rdap.org" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                if ($rdap.cidr0_cidrs) {
                    $range = "$($rdap.cidr0_cidrs[0].v4prefix)/$($rdap.cidr0_cidrs[0].length)"
                } else {
                    $range = "$($ip.Substring(0, $ip.LastIndexOf('.'))).0/24"
                }
            } catch {
                $range = "$($ip.Substring(0, $ip.LastIndexOf('.'))).0/24"
            }
            $results.Add("${domain}:$range")
        }
    } catch { }
}

$results | Select-Object -Unique | Out-File $outputFile -Encoding ascii
