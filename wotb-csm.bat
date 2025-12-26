@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

set adm_arg=%1
if "%adm_arg%" == "admin" (
title wotb-csm (admin^)
) else (
    echo [93m[powershell] Requesting admin rights . . .
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/k \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

:ask
endlocal
setlocal EnableDelayedExpansion

set pls-enter-comm=[31m[ Пожалуйста, введите команду ][0m
set incorrect-command=[31m[ Некорректная команда ][0m
set rule-n-f=[31m[ОШИБКА]: Правило кластера не найдено, пожалуйста введите: "c" или "create"[0m
set clasters-rls-nf=[31m[ОШИБКА]: Правила кластеров не найдены, пожалуйста введите: "c" или "create"[0m

cls
echo [101;93mМеню настройки кластеров СНГ сервера Tanks Blitz[0m
echo.
echo [93mВыберите команду:[0m
echo [96mb - открыть меню блокировки кластеров[0m
echo [96mub - открыть меню разблокировки кластеров[0m
echo.
echo [96m1 - Создать / обновить правила для блокировки кластеров[0m
echo [96m2 - Удалить все правила для блокировки кластеров[0m
echo [96m3 - Обновить диапазоны ip-адресов для блокировки[0m
echo.
echo [96mba - Заблокировать все кластера[0m
echo [96muba - Разблокировать все кластера[0m
echo.
echo [93mДругие опции:[0m
echo [96md / diag - Провести диагностику сети[0m
echo [96mp / ping - Измерить задержку до кластеров[0m
echo [96ms / stat / status - Узнать состояние правил[0m
echo [96mwf / firewall - Открыть монитор Windows Defender[0m
echo [96mh / help - Перейти на страницу GitHub[0m
echo.
echo [96mr - [93mПерезапустить этот пакет[0m
echo [96mx -[0m [31mЗавершить работу[0m


::Вопрос от функции
echo.
set select=
set /p select="[92mВвод:[0m "

if "%select%"=="b"  set act=block& call :cluster-manager
if "%select%"=="ub" set act=unblock& call :cluster-manager

if "%select%"=="ba"  cls & call :block-all & goto :endfunc
if "%select%"=="uba" cls & call :unblock-all & goto :endfunc

if "%select%"=="1" goto create-rules
if "%select%"=="2" goto rules-remove-confirm
if "%select%"=="3" goto update-ipset

if "%select%"=="p"    goto check-ping
if "%select%"=="ping" goto check-ping

if "%select%"=="d"    cls & call :network-diagnostics & goto endfunc
if "%select%"=="diag" cls & call :network-diagnostics & goto endfunc

if "%select%"=="s" goto :rules-status
if "%select%"=="stat" goto :rules-status
if "%select%"=="status" goto :rules-status

::controls
if "%select%"=="x"     goto close
if "%select%"=="end"   goto close
if "%select%"=="close" goto close

if "%select%"=="r"       goto restart
if "%select%"=="restart" goto restart

:: open github
if "%select%"=="h"    goto github
if "%select%"=="help" goto github

::   open Windows Firewall
if "%select%"=="wf"       goto :wf
if "%select%"=="firewall" goto :wf

goto ask


:update-ipset
cls
echo [96m[ Обновление списка диапазонов, пожалуйста подождите... ][0m

call :remove-rules

cd /d "%~dp0"
echo [36m
:: Запуск обновления данных (можно вынести в отдельный пункт меню "Обновить IP")
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0pwsh\update_ipset.ps1"

echo.
echo [0mГотово^^!

echo.
echo [0mСписок найденных активных доменов и их диапазонов:[0m
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [36m%%a [%%b][0m
)
echo.
echo Найденные домены сохранены (в [96m"%ranges_file%"[0m) и теперь вы можете просто создать новые правила, в брандмауэре, в главном меню^^![0m
goto endfunc



:create-rules
cls
echo.
choice /C "10" /m "[93mПодтвердите [36mСОЗДАНИЕ [93mправил в брандмауэре[0m"
if "%errorlevel%"=="1" (goto create-rules-y)
if "%errorlevel%"=="2" (goto ask)


:create-rules-y
set rule_description="Правило для блокирования кластеров СНГ сервера игры Tanks Blitz (created in wotb-csm)"

:: Удаляем все старые правила
call :remove-rules

echo.
echo [0mПытаюсь создать правила...[0m
:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    
    :: Добавляем новое правило
    netsh advfirewall firewall add rule name="%%a_block" description=%rule_description% dir=out action=block remoteip=%%b >nul 2>&1
    if !errorlevel! neq 0 (
        echo [91mОшибка создания правила[0m
    ) else (
        echo [92m[+] [93mСоздано правило: %%a [%%b][0m
    )
)
echo Готово
goto endfunc


:rules-remove-confirm
cls
echo.
choice /C "10" /m "[93mПодтвердите [91mУДАЛЕНИЕ [93mправил из брандмауэра[0m"
if "%errorlevel%"=="1" (call :remove-rules & goto endfunc)
if "%errorlevel%"=="2" (goto ask)


:remove-rules
echo.
echo Пытаюсь удалить правила tanksblitz в брандмауэре...
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-NetFirewallRule | Where-Object { $_.DisplayName -like '*tanksblitz*' } | Remove-NetFirewallRule -PassThru | ForEach-Object { Write-Host ('[91m[-] [93mУдалено правило: {0} [0m' -f $_.DisplayName) }"
echo Готово
exit /b


:block-all
:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [0mБлокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=yes >nul 2>&1
)
echo Все кластера заблокированы^^!
exit /b


:unblock-all
:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [0mРазблокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=no >nul 2>&1
)
echo Все кластера разблокированы^^!
exit /b



:cluster-manager
cls
echo.
if "%act%"=="block" (
    echo [96m[ [91m- - - БЛОКИРОВКА КЛАСТЕРА - - -[96m ][0m
    echo.
    set rule_state=yes
) else (
    echo [96m[ [92m- - - РАЗБЛОКИРОВКА КЛАСТЕРА - - -[96m ][0m
    echo.
    set rule_state=no
)

:: Проверка наличия файла данных
set "ranges_file=%~dp0pwsh\ip_map_ru.txt"

if not exist "%ranges_file%" (
    echo [91mОшибка: Сначала обновите базу IP диапазонов^^![0m
    goto endfunc
)

set "ps_cmd=$r=@{}; [Microsoft.Management.Infrastructure.CimInstance[]](Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter 'DisplayName like \"%%tanksblitz%%\"') | ForEach-Object { $r[$_.DisplayName] = $_.Enabled }; $lines = [System.IO.File]::ReadAllLines('%ranges_file%'); foreach($l in $lines){ $d=$l.Split(':')[0]; $st='NotExist'; if($r.ContainsKey($d + '_block')){ $st = if($r[$d + '_block'] -eq 1){'Enabled'}else{'Disabled'} }; [Console]::WriteLine($d+':'+$st) }"
set count=0
for /f "tokens=1 delims==" %%v in ('set cluster[ 2^>nul') do set "%%v="

:: Парсим вывод PS. %%a - домен, %%b - статус (Enabled / Disabled / NotExist)
for /f "usebackq tokens=1,2 delims=:" %%a in (`powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "%ps_cmd%"`) do (
    set /a count+=1
    set "cluster[!count!]=%%a"
    set "status[!count!]=%%b"
    
    if "%%b"=="Enabled" (
        echo [!count!] %%a [[91mБЛОКИРОВАН[0m]
    ) else if "%%b"=="Disabled" (
        echo [!count!] %%a [[92mДОСТУПЕН[0m]
    ) else (
        echo [!count!] %%a [[90mПРАВИЛО НЕ НАЙДЕНО[0m]
    )
)

if %count%==0 (
    echo [91mПравила еще не созданы. Запустите создание правил[0m
    goto endfunc
)

echo.
:cluster-manager-choice
set "c_choice="
set /p c_choice="Выберите номер (0 для отмены): "

if "%c_choice%"=="0" goto ask

if not defined cluster[%c_choice%] (
    echo [91m[ Неверный выбор ][0m
    echo.
    goto :cluster-manager-choice
)

set "sel_domain=!cluster[%c_choice%]!"
set "sel_status=!status[%c_choice%]!"

:: ПРОВЕРКА: Если правила не существует, не пытаемся его менять
if "%sel_status%"=="NotExist" (
    echo.
    echo [91mОшибка: Правило для !sel_domain! не найдено в Брандмауэре.[0m
    echo [93mСначала создайте правила через соответствующий пункт меню.[0m
    goto endfunc
)

:: Изменяем правило
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=out new enable=%rule_state% >nul 2>&1

if %errorlevel% neq 0 (
    echo [91mОшибка при применении правила netsh для !sel_domain![0m
) else (
    echo.
    if "%act%"=="block" (
        echo [96mКластер !sel_domain! заблокирован![0m
    ) else (
        echo [96mКластер !sel_domain! разблокирован![0m
    )
)
goto endfunc



:restart
cls
endlocal
cmd /c "%~f0" :
exit


:wf
Echo [93m[ Запуск Windows Firewall... ][0m
start WF.msc
Echo [92m[ Windows Firewall Запущен! ][0m
goto ask


:github
echo [93m^^! github
explorer "https://github.com/N3M1X10/wotb-csm"
goto ask



:close
endlocal
exit



:rules-status
cls
echo [96m[ [93m- - - СТАТУС ПРАВИЛ БЛОКИРОВКИ - - - [96m][0m
echo.

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like '*tanksblitz*'} | Select-Object DisplayName, Enabled;" ^
    "if (-not $rules) {" ^
        "Write-Host '[91mПравила не найдены :([0m';" ^
        "Write-Host '[0mМожете создать их в главном меню^![0m';" ^
    "} else {" ^
        "foreach ($r in $rules) {" ^
            "$name = $r.DisplayName.PadRight(1);" ^
            "if ($r.Enabled -eq 'True') {" ^
                "Write-Host ('{0} [[92mВКЛЮЧЕНО[0m]' -f $name);" ^
            "} else {" ^
                "Write-Host ('{0} [[91mВЫКЛЮЧЕНО[0m]' -f $name);" ^
            "}" ^
        "}" ^
    "}"
goto endfunc


:check-ping
cls
echo.
echo [96m[ - - - ПРОВЕРКА ЗАДЕРЖКИ КЛАСТЕРОВ (PING) - - - ] [0m

set "domains_file=%~dp0pwsh\domains_ru.txt"
if not exist "%domains_file%" (
    echo [91mОшибка: Файл доменов не найден! [0m
    goto endfunc
)

echo.
call :unblock-all

echo.
echo [96mПожалуйста, подождите. Идет опрос серверов... [0m
echo.

:: Однострочник PowerShell: читает файл, пингует каждый домен и выводит результат
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$domains = Get-Content '%domains_file%' | Where-Object { $_ -match '\.' };" ^
    "$jobs = foreach ($d in $domains) {" ^
        "Start-Job -ScriptBlock {" ^
            "param($d);" ^
            "$res = Test-Connection -ComputerName $d -Count 5 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average;" ^
            "if ($res.Average) {" ^
                "$ms = [Math]::Round($res.Average);" ^
                "if ($ms -lt 25) { $c = '[92m' } elseif ($ms -lt 50) { $c = '[93m' } else { $c = '[91m' };" ^
                "return '{0} {1}{2}ms[0m' -f $d.PadRight(25), $c, $ms" ^
            "} else {" ^
                "return '{0} [91mНЕДОСТУПЕН[0m' -f $d.PadRight(25)" ^
            "}" ^
        "} -ArgumentList $d" ^
    "};" ^
    "$results = $jobs | Wait-Job -Timeout 10 | Receive-Job;" ^
    "$results | ForEach-Object { Write-Host $_ -ForegroundColor Cyan };" ^
    "$jobs | Remove-Job -Force"

echo.
echo [92mПроверка завершена
echo [36mТеперь вы можете использовать эти данные для выбора ваших оптимальных кластеров[0m
goto endfunc



:check-ranges-file
set "ranges_file=%~dp0pwsh\ip_map_ru.txt"
if not exist "%ranges_file%" (
    echo [91mОшибка: Не удалось получить данные об IP[0m
    goto endfunc
)
exit /b



:network-diagnostics
echo [93m[ - - - Запуск сетевой диагностики - - - ][0m
echo [36m[^^!] Это может занять некоторое время[0m
echo.

:: VPN
echo [0m
sc query | findstr /I "VPN">nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружены службы VPN. [93mМогут влиять на пинг, если они в активном состоянии
    sc query | findstr /I "VPN"
) else (
    echo [ok] VPN
)

:: WARP
echo [0m
sc query | findstr /I "WARP">nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружен WARP. [93mОн может повлиять на пинг, если он в активном состоянии[0m
) else (
    echo [ok] WARP
)

:: Проверка наличия драйвера cFosSpeed / ASUS GameFirst
echo.
sc query cFosSpeed >nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружен драйвер cFosSpeed (GameFirst^). [93mОн может конфликтовать с брандмауэром и вызывать статтеры[0m
) else (
    echo [ok] traffic optimizer (cFosSpeed^)
)

:: System Proxy
echo.
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable | findstr "0x1" >nul
if !errorlevel!==0 (
    echo [91m[^^!] Включен системный прокси-сервер. [93mЭто может исказить пинг[0m
) else (
    echo [ok] system proxy
)

:: Killer Network
echo.
tasklist /FI "IMAGENAME eq KillerNetwork.exe" 2>nul | findstr /I "KillerNetwork" >nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружено ПО Killer Network. Это может влиять на приоритет трафика[0m
) else (
    echo [ok] killer network
)

:: Ethernet
echo.
powershell -Command "if ((Get-NetAdapter | Where-Object {$Status -eq 'Up'}).MediaConnectionState -contains 'Wireless') { exit 1 } else { exit 0 }"
if !errorlevel!==1 (
    echo [93m[^^!] Вы используете Wi-Fi. Для минимальной задержки рекомендуется Ethernet[0m
) else (
    echo [ok] ethernet
)

:: Проверка MTU активного интерфейса
echo.
powershell -NoProfile -Command ^
 "$iface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' -and $_.InterfaceMetric -lt 100 } | Select-Object -First 1;" ^
 "if ($iface.NlMtu -lt 1500) {" ^
     "Write-Host ('[91m[!] Низкий MTU: {0} (норма 1500). Возможна фрагментация пакетов.[0m' -f $iface.NlMtu);" ^
 "} else {" ^
     "Write-Host ('[0m[ok] MTU в норме: {0}[0m' -f $iface.NlMtu);" ^
 "}"

:: Проверка задержки DNS-сервера
echo.
powershell -NoProfile -Command ^
 "$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null } | Select-Object -ExpandProperty ServerAddresses -First 1;" ^
 "Write-Host ('[*] Тестируем DNS-сервер: {0}' -f $dns);" ^
 "$t = Measure-Command { $res = Resolve-DnsName google.com -Server $dns -ErrorAction SilentlyContinue };" ^
 "if ($t.TotalMilliseconds -gt 150) {" ^
    "Write-Host ('[91m[^!] Медленный DNS: {0:N0} мс. Рекомендуется сменить ^(например 8.8.8.8 или 1.1.1.1^)[0m' -f $t.TotalMilliseconds)" ^
 "} else {" ^
    "Write-Host ('[0m[ok] DNS Response: {0:N0} ms[0m' -f $t.TotalMilliseconds)" ^
 "}"

:: Проверка на подмену DNS (Hijacking)
echo.
powershell -NoProfile -Command ^
 "$testDomain = 'check-dns-hijack-' + (Get-Random) + '.com';" ^
 "try { $res = Resolve-DnsName $testDomain -ErrorAction SilentlyContinue; " ^
 "if ($res) { Write-Host '[91m[^!] Обнаружена подмена DNS (DNS Hijacking)^! Ваш провайдер перехватывает запросы. Это может вызвать неполадки со стороны сетевых утилит[0m' }" ^
 "else { Write-Host '[0m[ok] DNS Hijacking check: Clean[0m' } } catch { Write-Host '[0m[ok] DNS Hijacking check: Clean[0m' }"

:: Проверка наличия IPv6 (предупреждение, если он может мешать)
echo.
powershell -NoProfile -Command ^
 "$ipv6 = Get-NetAdapterBinding | Where-Object {$_.ComponentID -eq 'ms_tcpip6' -and $_.Enabled -eq $true};" ^
 "if ($ipv6) { Write-Host '[0m[*] IPv6 включен. Если есть проблемы с входом в игру, попробуйте его отключить.[0m' }"

:: Проверка количества основных шлюзов
echo.
powershell -NoProfile -Command ^
 "$gateways = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object {$_.NextHop -ne '0.0.0.0'}).Count;" ^
 "if ($gateways -gt 1) { Write-Host ('[91m[!] Найдено несколько шлюзов ({0}). Это вызывает конфликты маршрутов![0m' -f $gateways) }" ^
 "else { Write-Host '[0m[ok] Gateway count: 1[0m' }"

:: Проверка RSS (Глобальный + Аппаратный)
echo.
powershell -NoProfile -Command ^
 "$active = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1;" ^
 "$netshRSS = (netsh int tcp show global | Select-String 'Receive-Side Scaling' | Select-String 'enabled');" ^
 "$hwRSS = Get-NetAdapterRss -Name $active.Name -ErrorAction SilentlyContinue;" ^
 "if ($netshRSS -and $hwRSS.Enabled) {" ^
    "Write-Host '[0m[ok] Network RSS: Fully Enabled[0m'" ^
 "} else {" ^
    "Write-Host ('[93m[^!] RSS ограничен. Netsh: {0}, Hardware: {1}[0m' -f ([bool]$netshRSS), ([bool]$hwRSS.Enabled));" ^
    "Write-Host ('[93mТакже есть вероятность что RSS на самом деле - активен, как - в системе, так - и на адаптере. Просьба детально диагностировать работоспособность вручную')" ^
 "}"

:: Проверка модерации прерываний
echo.
powershell -NoProfile -Command ^
 "$active = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1;" ^
 "$prop = Get-NetAdapterAdvancedProperty -Name $active.Name | Where-Object { $_.RegistryKeyword -match 'ITR|InterruptModeration' };" ^
 "if ($prop.RegistryValue -ne '0' -and $prop -ne $null) {" ^
    "Write-Host ('[93m[^!] Модерация прерываний активна ({0}). Для игр лучше: Disabled[0m' -f $prop.DisplayValue)" ^
 "} else {" ^
    "Write-Host '[0m[ok] Interrupt Moderation: Disabled[0m'" ^
 "}"

:: Проверка таблицы маршрутизации
echo.
powershell -NoProfile -Command ^
 "$routes = (Get-NetRoute).Count;" ^
 "if ($routes -gt 150) {" ^
    "Write-Host ('[91m[^!] Перегружена таблица маршрутов ({0}). Рекомендуется: netsh int ip reset[0m' -f $routes)" ^
 "} else {" ^
    "Write-Host ('[0m[ok] Route Table: {0} entries[0m' -f $routes)" ^
 "}"

:: Проверка автоподстройки TCP
echo.
powershell -NoProfile -Command ^
 "$tcp = Get-NetTCPSetting -SettingName InternetCustom, Internet | Select-Object -First 1 -ExpandProperty AutoTuningLevelLocal;" ^
 "if ($tcp -eq 'Normal') {" ^
    "Write-Host '[0m[ok] TCP Auto-Tuning: Normal[0m'" ^
 "} else {" ^
    "Write-Host ('[93m[^!] Автоподстройка TCP: {0}. Рекомендуется Normal.[0m' -f $tcp);" ^
    "Write-Host '[93m[^!] Команда: netsh int tcp set global autotuninglevel=normal[0m'" ^
 "}"

:: Проверка оптимизации задержки TCP (NoDelay)
echo.
powershell -NoProfile -Command ^
 "$reg = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*' -Name TcpAckFrequency, TcpNoDelay -ErrorAction SilentlyContinue;" ^
 "if ($reg) { Write-Host '[0m[ok] TCP NoDelay: Optimized[0m' } " ^
 "else { Write-Host '[93m[^!] Алгоритм Нагла активен. Для игр рекомендуется отключить (TcpNoDelay)[0m' }"

:: Проверка Chimney Offload
echo.
netsh int tcp show global | findstr /I "chimney" | findstr /I "enabled" >nul
if !errorlevel!==0 (
    echo [91m[^^!] Включен Chimney Offload. Это часто вызывает десинхрон^^![0m
    echo [93m[^^!] Рекомендуется: netsh int tcp set global chimney=disabled[0m
) else (
    echo [ok] TCP Chimney Offload
)



:: долгие проверки

:: Проверка фоновых закачек (BITS)
echo.
powershell -NoProfile -Command ^
 "if (Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue|Where-Object {$_.State -eq 'Transferring'}) {" ^
    "Write-Host '[91m[^!] Идет фоновая загрузка обновлений/файлов^![0m'" ^
    "} else {" ^
        "Write-Host '[0m[ok] Канал не занят системными загрузками[0m'"^
    "}"

:: Проверка загрузки CPU (если проц загружен на 100%, пинг тоже будет скакать)
echo.
powershell -NoProfile -Command ^
 "$c = Get-Counter '\Processor(_Total)\%% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue;" ^
 "$v = [Math]::Round(($c.CounterSamples | Select-Object -ExpandProperty CookedValue));" ^
 "if ($v -gt 80) { Write-Host ('[91m[^!] CPU Load: {0}%% - High[0m' -f $v) } else { Write-Host ('[0m[ok] CPU Load: {0}%%[0m' -f $v) }"

:: Проверка текущей нагрузки на сеть (входящий трафик)
echo.
powershell -NoProfile -Command ^
 "$sec = Get-NetAdapterStatistics | Where-Object {$_.InterfaceDescription -notmatch 'Virtual|Pseudo'} | Select-Object -First 1;" ^
 "$val1 = $sec.ReceivedBytes; Start-Sleep -Seconds 1; $val2 = (Get-NetAdapterStatistics | Where-Object {$_.InterfaceDescription -notmatch 'Virtual|Pseudo'} | Select-Object -First 1).ReceivedBytes;" ^
 "$speed = [Math]::Round(($val2 - $val1) * 8 / 1Mb, 2);" ^
 "if ($speed -gt 10) { Write-Host ('[91m[^!] Текущая загрузка сети: {0} Мбит/с. Канал чем-то занят^![0m' -f $speed) }" ^
 "else { Write-Host ('[0m[ok] Network Load: {0} Mbps[0m' -f $speed) }"

:: Проверка потерь и стабильности задержки (Jitter)
echo.
echo [*] Тестирование стабильности канала (10 пакетов)...
powershell -NoProfile -Command ^
 "$p = Test-Connection -ComputerName 8.8.8.8 -Count 10 -ErrorAction SilentlyContinue;" ^
 "$loss = ((10 - $p.Count) / 10) * 100;" ^
 "$times = $p.ResponseTime;" ^
 "$avg = ($times | Measure-Object -Average).Average;" ^
 "$jitter = 0; if ($p.Count -gt 1) { for($i=1; $i -lt $p.Count; $i++) { $jitter += [Math]::Abs($times[$i] - $times[$i-1]) }; $jitter = $jitter / ($p.Count - 1) };" ^
 "if ($loss -gt 0) { Write-Host ('[91m[^!] Потери пакетов: {0}%%^![0m' -f $loss) -ForegroundColor Red } else { Write-Host '[0m[ok] Packet Loss: 0%%[0m' };" ^
 "if ($jitter -gt 15) { Write-Host ('[93m[^!] Высокий джиттер (нестабильность): {0:N1} мс. Возможны телепорты. [0m' -f $jitter) } else { Write-Host ('[0m[ok] Jitter: {0:N1} ms[0m' -f $jitter) }"

echo.
echo [92mДиагностика завершена[0m
echo [36m [^^!] Каждый пункт без "ok" означает - предупреждение. Это означает, что вы можете воспользоваться поиском в интернете, для детального решения каждой сетевой проблемы со стороны вашей системы[0m
exit /b



:: end of a function
:endfunc
echo.&echo [36m[!time!] Выполнение завершено^^!
if !exaf!==1 (endlocal&exit/b)
echo Нажмите любую кнопку чтобы вернуться в главное меню...[0m
pause>nul&endlocal&cls
goto :ask


