@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

set adm_arg=%1
if "%adm_arg%" == "admin" (
title wotb-csm (admin^)
) else (
    echo [93m[powershell] Requesting admin rights...
    powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Start-Process 'cmd.exe' -ArgumentList '/k \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

:ask
endlocal
setlocal EnableDelayedExpansion

cls
echo [101;93mМеню настройки кластеров WOTB[0m
echo.
echo [93mМеню управления статусом правил:[0m
echo [96m1 - Блокировка кластеров[0m
echo [96m2 - Разблокировка кластеров[0m
echo [93mРаботаем с пачкой правил:[0m
echo [96mba - Заблокировать все кластеры[0m
echo [96muba - Разблокировать все кластеры[0m
echo [93mСервисные операции с правилами:[0m
echo [96m3 - Создать / обновить правила для блокировки кластеров[0m
echo [96m4 - Удалить все правила для блокировки кластеров[0m
echo [96m5 - Обновить диапазоны ip-адресов для блокировки[0m
echo.
echo [93mПрочие опции:[0m
echo [96mp / play - [92mзапустить WOTB[0m
echo [96mk / kill - [91mЗакрыть всё связанное с WOTB[0m
echo [96mc / clean - Почистить файлы конфигурации[0m
echo [96mreset - сбросить данные WOTB[0m
echo [96mping - Измерить задержку до кластеров[0m
echo [96md / diag - Провести диагностику сети[0m
echo [96mnf / net-flush - Провести профилактику сети[0m
echo [96ms / stat - Узнать состояние правил[0m
echo [96mf / wf - Открыть монитор Windows Firewall[0m
echo [96mh / help / git - Перейти на страницу GitHub[0m
echo [96mr - [93mПерезапустить этот пакет[0m
echo [96mx - [91mЗавершить работу[0m


:: Вопрос от функции
echo.
set select=
set /p select="[92mВвод:[0m "

if "%select%"=="1" cls & set "act=block" & call :cluster-manager
if "%select%"=="2" cls & set "act=unblock" & call :cluster-manager

if "%select%"=="ba"  cls & call :block-all & goto :endfunc
if "%select%"=="uba" cls & call :unblock-all & goto :endfunc

if "%select%"=="3" goto create-rules
if "%select%"=="4" goto rules-remove-confirm
if "%select%"=="5" goto update-ipset

if "%select%"=="play" goto start-wotb
if "%select%"=="p"    goto start-wotb

if "%select%"=="kill" goto kill-wotb
if "%select%"=="k"    goto kill-wotb

if "%select%"=="c"     call :flush-wotb-config & goto endfunc
if "%select%"=="clean" call :flush-wotb-config & goto endfunc

if "%select%"=="reset" call :flush-wotb-config "entire" & goto endfunc

if "%select%"=="ping" goto check-ping

if "%select%"=="d"    cls & call :network-diagnostics & goto endfunc
if "%select%"=="diag" cls & call :network-diagnostics & goto endfunc

if "%select%"=="nf"        cls & call :net-flush & goto endfunc
if "%select%"=="net-flush" cls & call :net-flush & goto endfunc

if "%select%"=="s"    goto :rules-status
if "%select%"=="stat" goto :rules-status

if "%select%"=="f"  goto :wf
if "%select%"=="wf" goto :wf

if "%select%"=="h"    goto github
if "%select%"=="git"  goto github
if "%select%"=="help" goto github

if "%select%"=="r"       goto restart
if "%select%"=="restart" goto restart

if "%select%"=="x"     goto close
if "%select%"=="end"   goto close
if "%select%"=="close" goto close

goto ask


:: Поиск необходимых файлов
:check-ranges-file
set "ranges_file=%~dp0lists\ip_map.txt"
if not exist "%ranges_file%" (
    echo [91mОшибка: Файл IP диапазонов не найден^^![0m
    goto endfunc
)
exit /b

:check-domains-file
set "domains_file=%~dp0lists\domains.txt"
if not exist "%domains_file%" (
    echo [91mОшибка: Файл доменов не найден^^! [0m
    goto endfunc
)
exit /b



:update-ipset
cls
echo [96m[ [93m- - - Обновление списка диапазонов - - - [96m][0m
call :check-rules
if !rules_count! lss 1 (
    rem dn
) else (
    choice /C "10" /m "[93m[?] Подтвердите [91mвременную разблокировку [93mправил в брандмауэре[0m"
    if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
    if "!errorlevel!"=="2" (goto ask)

    rem call :unblock-all
)

:: Запуск обновления данных
echo [36m
call :check-ranges-file
call :check-domains-file

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue;" ^
    "$domainsFile = '%domains_file%';" ^
    "$outputFile = '%ranges_file%';" ^
    "if (-not (Test-Path $domainsFile)) { exit 1 };" ^
    "Write-Host 'Сохранение состояния и временное отключение правил брандмауэра...';" ^
    "$rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like '*tanksblitz*' };" ^
    "$backup = @{}; foreach($r in $rules) { $backup[$r.Name] = $r.Enabled };" ^
    "$rules | Set-NetFirewallRule -Enabled False;" ^
    "Write-Host 'Запускаю обновление...';" ^
    "try {" ^
        "$domains = Get-Content $domainsFile | Where-Object { $_ -match '\.' };" ^
        "$jobs = foreach ($domain_name in $domains) {" ^
            "Start-Job -ScriptBlock {" ^
                "param($d_param);" ^
                "$output = @();" ^
                "try {" ^
                    "$ips = [System.Net.Dns]::GetHostAddresses($d_param) | Where-Object { $_.AddressFamily -eq 'InterNetwork' };" ^
                    "foreach ($ip in $ips) {" ^
                        "$ipStr = $ip.IPAddressToString;" ^
                        "$range = $ipStr.Substring(0, $ipStr.LastIndexOf('.')) + '.0/24';" ^
                        "try {" ^
                            "$rdap = Invoke-RestMethod -Uri ('rdap.org' + $ipStr) -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop;" ^
                            "if ($rdap.cidr0_cidrs) { $range = $rdap.cidr0_cidrs[0].v4prefix + '/' + $rdap.cidr0_cidrs[0].length };" ^
                        "} catch { };" ^
                        "$output += $d_param + ':' + $range;" ^
                    "};" ^
                    "return $output;" ^
                "} catch { return $d_param + ':Error' }" ^
            "} -ArgumentList $domain_name" ^
        "};" ^
        "Wait-Job $jobs -Timeout 15 | Out-Null;" ^
        "$resultsRaw = Receive-Job $jobs;" ^
        "$jobs | Stop-Job; $jobs | Remove-Job -Force;" ^
        "if ($resultsRaw) {" ^
            "$resultsRaw | Where-Object { $_ -ne $null -and $_ -notmatch 'Error' } | Select-Object -Unique | Out-File $outputFile -Encoding ascii;" ^
        "}" ^
    "} finally {" ^
        "Write-Host 'Восстановление состояния правил брандмауэра...';" ^
        "foreach($id in $backup.Keys) { Set-NetFirewallRule -Name $id -Enabled $backup[$id] };" ^
    "}"

echo [0mГотово^^![0m

echo.
echo [93mСписок найденных активных доменов и их диапазонов:[0m
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [36m%%a [%%b][0m
)
echo.
echo Найденные домены сохранены (в [96m"%ranges_file%"[0m) и теперь вы можете просто создать новые правила, в брандмауэре, в главном меню^^![0m
goto endfunc



:create-rules
cls
choice /C "10" /m "[93m[?] Подтвердите [36mСОЗДАНИЕ [93mправил в брандмауэре[0m"
if "%errorlevel%"=="1" (goto create-rules-y)
if "%errorlevel%"=="2" (goto ask)

:create-rules-y
set rule_description="Правило для блокирования кластеров СНГ сервера игры Tanks Blitz (created in wotb-csm)"

:: Удаляем все старые правила
call :remove-rules

echo.
echo [90mПытаюсь создать правила...[0m
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
echo [90mГотово[0m

echo.
echo [101;93m[i] ПРОЧТИ МЕНЯ ^^!^^!^^![0m
echo [36m[*] Когда правила создадутся - они сразу заблокируют подключения по своим доменам[0m
echo [36m[*] Разблокируй их в главном меню[0m
goto endfunc



:rules-remove-confirm
cls
choice /C "10" /m "[93m[?] Подтвердите [91mУДАЛЕНИЕ [93mправил из брандмауэра[0m"
if "%errorlevel%"=="1" (call :remove-rules & goto endfunc)
if "%errorlevel%"=="2" (goto ask)

:remove-rules
echo.
echo [90mПытаюсь удалить правила tanksblitz в брандмауэре...[0m

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
$r = Get-NetFirewallRule ^| Where-Object { $_.DisplayName -like '*tanksblitz*' -or $_.DisplayName -like '*Tanks_Blitz*' -or $_.DisplayName -like '*wotblitz*' }; ^
if ($r) { ^
    $r ^| Remove-NetFirewallRule; ^
    foreach ($rule in $r) { ^
        Write-Host ('[91m[-] [93mУдалено правило: {0} [0m' -f $rule.DisplayName) ^
    } ^
} else { ^
    Write-Host '[91mПравила не найдены :([0m' ^
}

echo [90mГотово[0m
exit /b



:block-all
call :check-rules
if !rules_count! lss 1 (echo Правила блокировки не найдены& exit /b)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [90mБлокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=yes >nul 2>&1
)
echo Все кластеры заблокированы^^!
exit /b



:unblock-all
call :check-rules
if !rules_count! lss 1 (echo Правила блокировки не найдены& exit /b)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [90mРазблокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=no >nul 2>&1
)
echo Все кластеры разблокированы^^!
exit /b



:check-rules
set rules_count=0
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    netsh advfirewall firewall show rule name="%%a_block" >nul 2>&1
    if !errorlevel! equ 0 (
        set /a rules_count+=1
    )
)
if "!rules_count!" geq "1" (
    :: Правила найдены
    exit /b 1
) else (
    :: Правила не найдены
    exit /b 0
)



:cluster-manager
if "%act%"=="block" (
    set "func_title=[91m[ [93m- - - БЛОКИРОВКА КЛАСТЕРА - - -[91m ][0m"
    echo !func_title!
    echo.
    set rule_state=yes
) else (
    set "func_title=[92m[ [93m- - - РАЗБЛОКИРОВКА КЛАСТЕРА - - -[92m ][0m"
    echo !func_title!
    echo.
    set rule_state=no
)

call :check-ranges-file
call :draw-clusters-list

if %count%==0 (
    echo [91m[^^!] Правила еще не созданы. Запустите создание правил[0m
    goto endfunc
)

echo.
:: Формируем строку допустимых символов для choice
set "keys=0"
for /L %%i in (1,1,%count%) do (
    if %%i LSS 10 (
        set "keys=!keys!%%i"
    ) else (
        :: Вычисляем индекс для буквы (10->A, 11->B и т.д.)
        set /a idx=%%i-10
        for /f "delims=" %%a in ("!idx!") do (
            set "char=!map:~%%a,1!"
            set "keys=!keys!!char!"
        )
    )
)

:cluster-manager-choice
set "c_idx="
choice /C:%keys% /N /M "[93m[?] Выберите номер или букву [96m(0 для выхода)[93m: "
set /a c_idx=%ERRORLEVEL%

:: Если нажали 1-й символ (это '0') - выходим
if "%c_idx%"=="1" goto ask

:: Корректируем индекс для массива (ERRORLEVEL в choice начинается с 1)
:: Так как 0 — это 1-й символ, то для %%i=1 индекс ERRORLEVEL будет 2.
set /a c_choice=%c_idx%-1

:: Извлекаем данные по индексу
set "sel_domain=!cluster[%c_choice%]!"
set "sel_status=!status[%c_choice%]!"


:: ПРОВЕРКА: Если правило не существует
if "%sel_status%"=="NotExist" (
    echo.
    echo [91m[^^!^^!^^!] Ошибка: Правило для [96m!sel_domain! [91mне найдено в Брандмауэре.[0m
    echo [93m[i] Сначала создайте правила через соответствующий пункт меню.[0m
    goto endfunc
)

:: Изменяем правило
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=out new enable=%rule_state% >nul 2>&1
:: Проверка ошибок
if %errorlevel% neq 0 (
    echo [91mОшибка при применении правила netsh для !sel_domain![0m
) else (
    cls
    echo !func_title!
    echo.
    call :draw-clusters-list
    echo.
    if "%act%"=="block" (
        echo [92mКластер [96m!sel_domain! [92mзаблокирован^^![0m
    ) else (
        echo [92mКластер [96m!sel_domain! [92mразблокирован^^![0m
    )
    echo.
)
goto cluster-manager-choice


:draw-clusters-list
:: pwsh
set ps_cmd=^
$r_raw = Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter 'DisplayName like \"%%tanksblitz%%\" or DisplayName like \"%%wotblitz%%\"' -ErrorAction SilentlyContinue; ^
$r=@{}; if ($r_raw) { foreach($rule in $r_raw) { $r[$rule.DisplayName] = $rule.Enabled } }; ^
$lines = [System.IO.File]::ReadAllLines('%ranges_file%'); ^
foreach($l in $lines){ ^
  $d=$l.Split(':')[0]; ^
  $st='NotExist'; ^
  if($r.ContainsKey($d + '_block')){ ^
    $st = if($r[$d + '_block'] -eq 1){'Enabled'}else{'Disabled'} ^
  }; ^
  [Console]::WriteLine($d+':'+$st) ^
}

set count=0
set "map=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
:: Очистка массива перед заполнением
for /f "tokens=1 delims==" %%v in ('set cluster[ 2^>nul') do set "%%v="

for /f "usebackq tokens=1,2 delims=:" %%a in (`powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "%ps_cmd%" 2^>nul`) do (
    set /a count+=1
    set "cluster[!count!]=%%a"
    set "status[!count!]=%%b"
    
    :: Определяем, что выводить в квадратных скобках: цифру или букву
    if !count! LSS 10 (
        set "display_idx=!count!"
    ) else (
        set /a idx=!count!-10
        for /f "delims=" %%i in ("!idx!") do set "display_idx=!map:~%%i,1!"
    )
    
    :: Вывод строки меню
    if "%%b"=="Enabled" (
        echo [!display_idx!] %%a [[91mБЛОКИРОВАН[0m]
    ) else if "%%b"=="Disabled" (
        echo [!display_idx!] %%a [[92mДОСТУПЕН[0m]
    ) else (
        echo [!display_idx!] %%a [[90mПРАВИЛО НЕ НАЙДЕНО[0m]
    )
)
exit /b



:restart
cls
endlocal
cmd /c "%~f0" :
exit



:wf
:: Запуск Windows Firewall...
start WF.msc
goto ask



:github
:: opening github
explorer "https://github.com/N3M1X10/wotb-csm"
goto ask



:close
endlocal
exit



:rules-status
cls
echo [96m[ [93m- - - СТАТУС ПРАВИЛ БЛОКИРОВКИ - - - [96m][0m
echo.
call :check-ranges-file
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$r_raw = Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter 'DisplayName like \"%%tanksblitz%%\" or DisplayName like \"%%wotblitz%%\"' -ErrorAction SilentlyContinue;" ^
    "$r = @{}; if ($r_raw) { foreach($rule in $r_raw) { $r[$rule.DisplayName] = $rule.Enabled } };" ^
    "$lines = [System.IO.File]::ReadAllLines('%ranges_file%');" ^
    "foreach($l in $lines){" ^
        "$d = $l.Split(':')[0];" ^
        "$ruleName = $d + '_block';" ^
        "if($r.ContainsKey($ruleName)){" ^
            "$status = if($r[$ruleName] -eq 1){'[91mБЛОКИРУЕТСЯ[0m'}else{'[92mДОСТУПЕН[0m'};" ^
            "Write-Host ('{0} [{1}]' -f $d.PadRight(15), $status);" ^
        "} else {" ^
            "Write-Host ('{0} [[90mПРАВИЛО НЕ НАЙДЕНО[0m]' -f $d.PadRight(15));" ^
        "}" ^
    "}"
goto endfunc



:check-ping
cls
echo [96m[ [93m- - - ПРОВЕРКА ЗАДЕРЖКИ КЛАСТЕРОВ (PING) - - - [96m][0m

call :check-domains-file

echo.
echo [96mПожалуйста, подождите. Идет опрос серверов...[36m
echo.

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "Write-Host 'Сканирование и сохранение состояния правил...';" ^
    "$filter = \"DisplayName like '%%tanksblitz%%' or DisplayName like '%%wotblitz%%'\";" ^
    "$rules = Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter $filter -ErrorAction SilentlyContinue;" ^
    "$backup = @{}; foreach($r in $rules) { if($r.InstanceID) { $backup[$r.InstanceID] = $r.Enabled } };" ^
    "if ($rules) { $rules | Set-NetFirewallRule -Enabled False -ErrorAction SilentlyContinue };" ^
    "Write-Host 'Запуск опроса...';" ^
    "try {" ^
        "$domains = Get-Content '%domains_file%' | Where-Object { $_ -match '\.' };" ^
        "$instances = foreach ($d in $domains) {" ^
            "$ps = [PowerShell]::Create().AddScript({" ^
                "param($d);" ^
                "$p = Test-Connection -ComputerName $d -Count 2 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average;" ^
                "if ($p.Count -gt 0) {" ^
                    "$ms = [Math]::Round($p.Average);" ^
                    "$c = if ($ms -lt 25) { '[92m' } elseif ($ms -lt 100) { '[93m' } else { '[91m' };" ^
                    "return ('[90m[ [93m{0} [90m] {1}{2}msm' -f $d.PadRight(25), $c, $ms)" ^
                "} else { return ('[90m[ [93m{0} [90m] [90mНЕДОСТУПЕНm' -f $d.PadRight(25)) }" ^
            "}).AddArgument($d);" ^
            "@{ PS = $ps; Async = $ps.BeginInvoke() }" ^
        "};" ^
        "while ($instances.Async.IsCompleted -contains $false) { Start-Sleep -Milliseconds 50 };" ^
        "foreach ($i in $instances) { Write-Host ($i.PS.EndInvoke($i.Async)); $i.PS.Dispose() };" ^
    "} finally {" ^
        "Write-Host 'Возврат блокировок...';" ^
        "foreach($id in $backup.Keys) {" ^
            "if ($backup[$id] -eq 1) { Set-NetFirewallRule -Name $id -Enabled True -ErrorAction SilentlyContinue }" ^
        "};" ^
    "}"

echo.
echo [92mПроверка завершена
echo [0m[i] Теперь вы можете использовать эти данные для выбора ваших оптимальных кластеров[0m
goto endfunc



:flush-wotb-config
cls
if "%~1"=="entire" (
    echo [93m[ [91mСброс WOTB [93m][0m
    echo.
    choice /C "10" /m "[93m[?] Подтвердите [91mУДАЛЕНИЕ ВСЕХ[93m кэшированных данных обеих игр. Это приведёт к потере настроек[0m"
    if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
    if "!errorlevel!"=="2" (goto ask)

) else (
    echo [93m[ Деликатная стирка кэша WOTB ][0m
)


echo [90m&echo Завершаю игру, если она была открыта...
set "exeToStart="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$data = @('TanksBlitz;TanksBlitz.exe;*Tanks Blitz*', 'WoTBlitz;wotblitz.exe;*World_of_Tanks_Blitz*');" ^
    "foreach ($line in $data) {" ^
    "    $entry = $line.Split(';');" ^
    "    $n = $entry[0]; $e = $entry[1]; $s = $entry[2];" ^
    "    $proc = Get-Process $n -ErrorAction SilentlyContinue;" ^
    "    if ($proc) {" ^
    "        $path = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA 0 | Where-Object { $_.DisplayName -like $s -or $_.PSChildName -like $s } | Select-Object -ExpandProperty InstallLocation -EA 0;" ^
    "        if (-not $path) { $path = (Get-AppxPackage ('*' + $n + '*') -EA 0).InstallLocation };" ^
    "        if ($path) {" ^
    "            $full = Get-ChildItem -Path $path -Filter $e -Recurse -EA 0 | Select-Object -ExpandProperty FullName -First 1;" ^
    "            Stop-Process -Name $n -Force -EA 0;" ^
    "            $proc | Wait-Process -EA 0;" ^
    "            if ($full) { Write-Output $full; break; }" ^
    "        }" ^
    "    }" ^
    "}"`) do set "exeToStart=%%p"

echo [90m
echo Ищу папки с кэшем игр...
:: Извлекаем путь к Документам из реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal') do set "ActualDocs=%%b"
:: Разворачиваем переменные среды (если путь содержит %USERPROFILE%)
for /f "delims=" %%i in ('echo %ActualDocs%') do set "docs=%%i"

set "cis_wotb_path=!docs!\TanksBlitz\"
set "eu_wotb_path=%LOCALAPPDATA%\wotblitz\DAVAProject\"

echo.
echo [90mcis: "!cis_wotb_path!"[0m
echo [90meu: "!eu_wotb_path!"[0m

set title=Tanks Blitz
call :wotb-cleaner "%~1" "!cis_wotb_path!"
set title=WoT Blitz
call :wotb-cleaner "%~1" "!eu_wotb_path!"

if defined exeToStart (
    echo.
    echo [93m[ Перезапуск игры... ][0m
    start "" "!exeToStart!"
    set "exeToStart="
)
exit /b


:wotb-cleaner
echo.&echo [101;93m[ !title! ][0m
set "wotb_path=%~2"
if "%~1"=="entire" (
    rd /q /s "!wotb_path!"
    echo [90m
    echo Полный сброс завершён

) else (
    echo [90m
    echo удаляем кэш, в корне папки
    cd /d "!wotb_path!"

    echo [90m
    echo удалям файлики
    for %%f in (*.bin *.yaml *.bin.bk *.archive) do (
        del /f /q "%%f"
        echo [90m * файл : "%%f" - удалён[0m
    )

    rem echo.
    rem echo удаляем папки
    rem for %%f in (region_cache shader_cache) do (
    rem     if exist "%%f" (rd /q /s "%%f")
    rem     echo [90m * папка : "%%f" - удалена[0m
    rem )

    rem echo [90m
    rem echo чистим кэш внутри папок
    rem cd /d "cache"
    rem echo.
    rem echo удалям файлики
    rem for %%f in ("server_config_*_*.dat*") do (
    rem     del /f /q "%%f"
    rem     echo [90m * файл : "%%f" - удалён[0m
    rem )
)
exit /b



:start-wotb
cls
echo [93m[ Запуск WOTB ][0m
echo.
echo [90mПробую запустить игру...[0m
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
    "$apps = @(" ^
    "    @{ name='TanksBlitz'; exe='TanksBlitz.exe'; search='*Tanks Blitz*'; lName='Lesta Game Center'; lExe='lgc.exe'; lProc='lgc'; lTitle='Lesta Game Center' }," ^
    "    @{ name='WoTBlitz'; exe='wotblitz.exe'; search='*World of Tanks Blitz*'; lName='Wargaming.net Game Center'; lExe='wgc.exe'; lProc='wgc'; lTitle='Wargaming.net Game Center' }" ^
    ");" ^
    "function Get-LauncherPath($lName, $lExe) {" ^
    "    $regs = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\Lesta*', 'HKCU:\Software\Lesta*', 'HKLM:\SOFTWARE\Wargaming.net*');" ^
    "    $item = Get-ItemProperty $regs -ErrorAction SilentlyContinue | Where-Object { ($_.DisplayName -like \"*$lName*\" -or $_.PSChildName -like \"*$lName*\") } | Select-Object -First 1;" ^
    "    if ($item.InstallLocation) { $f = Join-Path $item.InstallLocation $lExe; if (Test-Path $f) { return $f } }" ^
    "    if ($item.DisplayIcon) { $f = Join-Path (Split-Path $item.DisplayIcon -Parent) $lExe; if (Test-Path $f) { return $f } }" ^
    "    $dirs = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:AppData, $env:LocalAppData, 'C:\Games', 'C:\ProgramData');" ^
    "    $subs = @('Lesta\GameCenter', 'Wargaming.net\GameCenter', 'Wargaming.net\WGC');" ^
    "    foreach ($d in $dirs) { foreach ($s in $subs) { $f = Join-Path (Join-Path $d $s) $lExe; if (Test-Path $f) { return $f } } }" ^
    "    return $null" ^
    "}" ^
    "function Wait-Launcher($proc, $title) {" ^
    "    $timer = [System.Diagnostics.Stopwatch]::StartNew();" ^
    "    while ($timer.Elapsed.TotalSeconds -lt 40) {" ^
    "        $p = Get-Process $proc -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 };" ^
    "        if ($p) { Start-Sleep -Seconds 2; return $true }" ^
    "        Start-Sleep -Seconds 1" ^
    "    }; return $false" ^
    "}" ^
    "function Show-ConsoleMenu([string]$Title, $Items) {" ^
    "    Write-Host '';" ^
    "    Write-Host $Title -ForegroundColor Yellow;" ^
    "    Write-Host '';" ^
    "    $startPos = $Host.UI.RawUI.CursorPosition;" ^
    "    $idx = 0;" ^
    "    while ($true) {" ^
    "        $Host.UI.RawUI.CursorPosition = $startPos;" ^
    "        for ($i = 0; $i -lt $Items.Count; $i++) {" ^
    "            $currentItem = $Items[$i]; $text = $currentItem.Game + ' (' + $currentItem.Path + ')';" ^
    "            if ($i -eq $idx) {" ^
    "                Write-Host '» ' -NoNewline -ForegroundColor Yellow;" ^
    "                Write-Host $text -ForegroundColor Cyan" ^
    "            } else {" ^
    "                Write-Host '  ' -NoNewline;" ^
    "                Write-Host $text -ForegroundColor DarkBlue" ^
    "            }" ^
    "        }" ^
    "        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');" ^
    "        if ($key.VirtualKeyCode -eq 38 -and $idx -gt 0) { $idx-- }" ^
    "        elseif ($key.VirtualKeyCode -eq 40 -and $idx -lt $Items.Count - 1) { $idx++ }" ^
    "        elseif ($key.VirtualKeyCode -eq 13) {" ^
    "            Write-Host ''; return $Items[$idx]" ^
    "        }" ^
    "    }" ^
    "}" ^
    "$foundPaths = @();" ^
    "$searchDirs = @('C:\Games', $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:AppData, $env:LocalAppData);" ^
    "foreach ($a in $apps) {" ^
    "    $path = $null;" ^
    "    foreach ($d in $searchDirs) {" ^
    "        if (Test-Path $d) {" ^
    "            $foundFile = Get-ChildItem -Path $d -Filter $a.exe -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1;" ^
    "            if ($foundFile) { $path = $foundFile; break; }" ^
    "        }" ^
    "    }" ^
    "    if ($path) {" ^
    "        if (-not ($foundPaths | Where-Object { $_.Path -eq $path })) {" ^
    "            $foundPaths += [PSCustomObject]@{ Game=$a.name; Path=$path; LName=$a.lName; LExe=$a.lExe; LProc=$a.lProc; LTitle=$a.lTitle };" ^
    "        }" ^
    "    }" ^
    "}" ^
    "if ($foundPaths.Count -eq 0) { Write-Host 'Игры не найдены.' -ForegroundColor Red; exit }" ^
    "$sel = if ($foundPaths.Count -eq 1) { $foundPaths[0] } else { Show-ConsoleMenu -Title 'Выберите версию игры стрелочками:' -Items $foundPaths };" ^
    "if ($sel) {" ^
    "    if (Get-Process $sel.Game -ErrorAction SilentlyContinue) { Write-Host 'Игра уже запущена.' -ForegroundColor Yellow; exit }" ^
    "    $lp = Get-LauncherPath $sel.LName $sel.LExe;" ^
    "    if (-not (Get-Process $sel.LProc -ErrorAction SilentlyContinue)) {" ^
    "        if ($lp) {" ^
    "            Write-Host ('Запуск лаунчера ' + $sel.LName + '...') -ForegroundColor Cyan;" ^
    "            Start-Process $lp;" ^
    "            if (Wait-Launcher $sel.LProc $sel.LTitle) { Write-Host 'Запуск игры...' -ForegroundColor Green; Start-Process $sel.Path }" ^
    "        } else { Write-Host 'Лаунчер не найден.' -ForegroundColor Red }" ^
    "    } else {" ^
    "        Write-Host 'Лаунчер активен. Запуск...' -ForegroundColor Green; Start-Process $sel.Path" ^
    "    }" ^
    "}"

rem >nul timeout /t 2
goto endfunc
goto ask



:kill-wotb
cls
echo [96m[ [93m- - - Чистим процессы (wotb/wgc/lgc) - - - [96m][0m

echo.
choice /C "10" /m "[93m[?] Подтвердите [91mЗАВЕРШЕНИЕ [93mвсех процессов игры и лаунчеров. Это может вызвать сбои^![0m"
if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
if "!errorlevel!"=="2" (goto ask)
:: Список процессов для завершения
set "procs=TanksBlitz.exe wotblitz.exe lgc.exe wgc.exe"

echo.
echo [90mЗавершаем процессы...[0m
for %%p in (%procs%) do (
    :: Проверяем, запущен ли процесс, чтобы не спамить ошибками
    tasklist /fi "ImageName eq %%p" 2>NUL | find /i "%%p" >NUL
    if not errorlevel 1 (
        taskkill /f /t /im %%p >nul 2>&1
        echo [90m * процесс : "%%p" - убит[0m
    )
)
goto endfunc



:network-diagnostics
echo [96m[ [93m- - - Сетевая диагностика - - - [96m][0m
echo.
echo [36m[i] Этот процесс может занять некоторое время[0m
echo.

:: VPN
echo.
sc query | findstr /I "VPN">nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружены службы VPN. [93mМогут влиять на пинг, если они в активном состоянии
    sc query | findstr /I "VPN"
) else (
    echo [ok] VPN
)

:: WARP
echo.
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
powershell -NoProfile -Command "if ((Get-NetAdapter | Where-Object {$Status -eq 'Up'}).MediaConnectionState -contains 'Wireless') { exit 1 } else { exit 0 }"
if !errorlevel!==1 (
    echo [93m[^^!] Вы используете Wi-Fi. Для минимальной задержки рекомендуется Ethernet[0m
) else (
    echo [ok] ethernet
)

:: Проверка MTU активного интерфейса
echo.
powershell -NoProfile -Command ^
 "$iface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' -and (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex).IPv4DefaultGateway } | Select-Object -First 1;" ^
 "if ($iface.NlMtu -lt 1500) {" ^
     "Write-Host ('[91m[^!] Низкий MTU: {0} (норма 1500). Возможна фрагментация пакетов.[0m' -f $iface.NlMtu);" ^
 "} else {" ^
     "Write-Host ('[0m[ok] MTU в норме: {0}[0m' -f $iface.NlMtu);" ^
 "}"

:: Проверка задержки DNS-сервера
echo.
powershell -NoProfile -Command ^
 "$dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null } | Select-Object -ExpandProperty ServerAddresses)[0];" ^
 "Write-Host ('[*] Тестируем DNS-сервер: {0}' -f $dns);" ^
 "$t = Measure-Command { $res = Resolve-DnsName google.com -Server $dns -ErrorAction SilentlyContinue -DnsOnly };" ^
 "if ($t.TotalMilliseconds -gt 150 -or $null -eq $res) {" ^
    "Write-Host ('[91m[^!] Медленный DNS или нет ответа: {0:N0} мс. Рекомендуется сменить ^(например 8.8.8.8 или 1.1.1.1^)[0m' -f $t.TotalMilliseconds)" ^
 "} else {" ^
    "Write-Host ('[0m[ok] DNS Response: {0:N0} ms[0m' -f $t.TotalMilliseconds)" ^
 "}"

:: Проверка на подмену DNS (Hijacking)
echo.
powershell -NoProfile -Command ^
 "$testDomain = 'check-dns-hijack-' + (Get-Random) + '.com';" ^
 "try { $res = Resolve-DnsName $testDomain -ErrorAction SilentlyContinue -DnsOnly; " ^
 "if ($res) { Write-Host '[91m[^!] Обнаружена подмена DNS (DNS Hijacking)^! Ваш провайдер перехватывает запросы. Это может вызвать неполадки со стороны сетевых утилит[0m' }" ^
 "else { Write-Host '[0m[ok] DNS Hijacking check: Clean[0m' } } catch { Write-Host '[0m[ok] DNS Hijacking check: Clean[0m' }"

:: Проверка наличия IPv6
echo.
powershell -NoProfile -Command ^
 "$ipv6 = Get-NetAdapterBinding | Where-Object {$_.ComponentID -eq 'ms_tcpip6' -and $_.Enabled -eq $true};" ^
 "if ($ipv6) { Write-Host '[0m[*] IPv6 включен. Если есть проблемы с входом в игру, попробуйте его отключить.[0m' }"

:: Проверка количества основных шлюзов
echo.
powershell -NoProfile -Command ^
 "$gateways = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object { $_.NextHop -ne '0.0.0.0' -and $_.RouteMetric -ne 256 }).Count;" ^
 "if ($gateways -gt 1) { Write-Host ('[91m[^!] Найдено несколько шлюзов ({0}). Это вызывает конфликты маршрутов^![0m' -f $gateways) }" ^
 "else { Write-Host '[0m[ok] Gateway count: 1[0m' }"

:: Проверка RSS (Глобальный + Аппаратный)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1;" ^
 "if (-not $adapter) { Write-Host 'Активный адаптер не найден' -ForegroundColor Red; exit };" ^
 "$isNetshEnabled = [bool](netsh int tcp show global | Select-String 'rss=enabled|enabled|включен');" ^
 "$hwRSS = Get-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue;" ^
 "$isHwEnabled = $false;" ^
 "if ($hwRSS -and $hwRSS.Enabled) { $isHwEnabled = $true } else {" ^
 "    $prop = Get-NetAdapterAdvancedProperty -Name $adapter.Name | Where-Object { $_.RegistryKeyword -eq '*NumRssQueues' };" ^
 "    if ($prop) { [int]$val = [int]($prop.RegistryValue[0]); if ($val -gt 1) { $isHwEnabled = $true } }" ^
 "};" ^
 "if ($isNetshEnabled -and $isHwEnabled) {" ^
 "    Write-Host '[ok] Network RSS: Fully Enabled' -ForegroundColor Gray" ^
 "} else {" ^
 "    $netshStatus = if ($isNetshEnabled) { 'Enabled' } else { 'Disabled' };" ^
 "    $hwStatus = if ($isHwEnabled) { 'Enabled (via Queues)' } else { 'Disabled' };" ^
 "    Write-Host ('[!/инфо] RSS ограничен. Система (Netsh): {0}, Адаптер (Hardware): {1}' -f $netshStatus, $hwStatus) -ForegroundColor Yellow;" ^
 "    if (-not $isHwEnabled) { Write-Host 'Рекомендуется включить RSS или увеличить количество очередей.' -ForegroundColor Gray }" ^
 "}"


:: Проверка модерации прерываний
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1;" ^
 "if (-not $adapter) { Write-Host 'Активный сетевой адаптер не найден.' -ForegroundColor Red; exit };" ^
 "$prop = Get-NetAdapterAdvancedProperty -Name $adapter.Name | Where-Object { $_.DisplayName -match 'Interrupt Moderation|Модерация прерываний' -or $_.RegistryKeyword -match '\*InterruptModeration' };" ^
 "if ($null -eq $prop) {" ^
 "    Write-Host '[?] Параметр не поддерживается драйвером.' -ForegroundColor Yellow" ^
 "} elseif ($prop.DisplayValue -match 'Disabled|Выкл' -or $prop.RegistryValue -eq '0') {" ^
 "    Write-Host '[ok] Interrupt Moderation: Disabled' -ForegroundColor Gray" ^
 "} else {" ^
 "    Write-Host ('[^!] Модерация прерываний активна ({0}). Для игр лучше: Disabled' -f $prop.DisplayValue) -ForegroundColor Yellow" ^
 "}"

:: Проверка таблицы маршрутизации
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$routes = (Get-NetRoute | Where-Object { $_.DestinationPrefix -ne '::/0' -and $_.DestinationPrefix -ne '0.0.0.0/0' -and $_.DestinationPrefix -notmatch 'loopback' }).Count;" ^
 "Write-Host ('[i] Записей маршрутизации: {0}' -f $routes) -ForegroundColor Gray;"

:: Проверка автоподстройки TCP
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$tcp = (Get-NetTCPSetting -SettingName Internet).AutoTuningLevelLocal;" ^
 "if ($tcp -eq 'Normal') {" ^
 "    Write-Host '[ok] TCP Auto-Tuning: Normal' -ForegroundColor Gray" ^
 "} else {" ^
 "    Write-Host ('[^!] Автоподстройка TCP: {0}. Рекомендуется Normal.' -f $tcp) -ForegroundColor Yellow;" ^
 "    Write-Host '[i] Команда для исправления: netsh int tcp set global autotuninglevel=normal' -ForegroundColor Gray" ^
 "}"

:: Проверка оптимизации задержки TCP (NoDelay)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\';" ^
 "$optimized = $false;" ^
 "Get-ItemProperty $regPath* -ErrorAction SilentlyContinue | ForEach-Object {" ^
 "    if ($_.TcpNoDelay -eq 1 -and $_.TcpAckFrequency -eq 1) { $optimized = $true }" ^
 "};" ^
 "if ($optimized) {" ^
 "    Write-Host '[ok] TCP NoDelay: Optimized' -ForegroundColor Gray" ^
 "} else {" ^
 "    Write-Host '[^!] Алгоритм Нагла активен. Для игр рекомендуется отключить (TcpNoDelay/TcpAckFrequency=1)' -ForegroundColor Yellow" ^
 "}"

:: Проверка Chimney Offload
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$chimney = (netsh int tcp show global | Select-String 'chimney|разгрузка' | Select-String 'enabled|включен');" ^
 "if ($chimney) {" ^
 "    Write-Host '[^!] Включен Chimney Offload. Это часто вызывает десинхрон^!' -ForegroundColor Red;" ^
 "    Write-Host '[i] Рекомендуется: netsh int tcp set global chimney=disabled' -ForegroundColor Gray" ^
 "} else {" ^
 "    Write-Host '[ok] TCP Chimney Offload: Disabled' -ForegroundColor Gray" ^
 "}"


:: долгие проверки

:: Проверка фоновых закачек (BITS)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$bits = Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.State -match 'Transferring|Connecting|Queued' };" ^
 "if ($bits) {" ^
 "    $totalSize = [Math]::Round(($bits | Measure-Object -Property BytesTotal -Sum).Sum / 1Mb, 2);" ^
 "    Write-Host ('[^!] Идет фоновая загрузка: {0} файлов ({1} МБ)' -f ($bits.Count), $totalSize) -ForegroundColor Yellow" ^
 "} else {" ^
 "    Write-Host '[ok] BITS: Системные загрузки не обнаружены' -ForegroundColor Gray" ^
 "}"

:: cpu check
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$load = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average;" ^
 "if ($load -gt 80) {" ^
 "    Write-Host ('[^!] CPU Load: {0}%% - High' -f $load) -ForegroundColor Red" ^
 "} else {" ^
 "    Write-Host ('[ok] CPU Load: {0}%%' -f $load) -ForegroundColor Gray" ^
 "}"

:: Проверка текущей нагрузки на сеть (входящий трафик)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1;" ^
 "if (-not $adapter) { Write-Host '[^!] Активный адаптер не найден' -ForegroundColor Red; exit };" ^
 "$stat1 = $adapter | Get-NetAdapterStatistics;" ^
 "$val1 = $stat1.ReceivedBytes + $stat1.SentBytes;" ^
 "Start-Sleep -Seconds 1;" ^
 "$stat2 = $adapter | Get-NetAdapterStatistics;" ^
 "$val2 = $stat2.ReceivedBytes + $stat2.SentBytes;" ^
 "$speed = [Math]::Round(($val2 - $val1) * 8 / 1Mb, 2);" ^
 "if ($speed -gt 10) {" ^
 "    Write-Host ('[^!] Текущая нагрузка сети: {0} Мбит/с. Канал чем-то занят^!' -f $speed) -ForegroundColor Yellow" ^
 "} else {" ^
 "    Write-Host ('[ok] Network Load: {0} Mbps' -f $speed) -ForegroundColor Gray" ^
 "}"

:: Проверка потерь и стабильности задержки (Jitter)
echo.
echo [*] Тестирование стабильности канала (10 пакетов)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$config = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null };" ^
 "$dns = $config.DNSServer.ServerAddresses | Where-Object { $_ -match '\.' } | Select-Object -First 1;" ^
 "if (-not $dns) { $dns = '1.1.1.1' };" ^
 "Write-Host ('[*] Цель: {0}' -f $dns) -ForegroundColor Gray;" ^
 "$p = Test-Connection -ComputerName $dns -Count 10 -ErrorAction SilentlyContinue;" ^
 "if (-not $p) { Write-Host '[^!] Нет связи с сервером.' -ForegroundColor Red; exit };" ^
 "$v = $p | Where-Object { $_.ResponseTime -ne $null } | ForEach-Object { [double]$_.ResponseTime };" ^
 "$c = $v.Count;" ^
 "$loss = [math]::Round(((10 - $c) / 10) * 100);" ^
 "$avg = if ($c -gt 0) { ($v | Measure-Object -Average).Average } else { 0 };" ^
 "$j = 0;" ^
 "if ($c -gt 1) {" ^
 "    $d = for($i=1; $i -lt $c; $i++) { [Math]::Abs($v[$i] - $v[$i-1]) };" ^
 "    $j = ($d | Measure-Object -Average).Average;" ^
 "};" ^
 "if ($loss -gt 0) {" ^
 "    Write-Host ('[^!] Потери пакетов: {0}%%' -f $loss) -ForegroundColor Red" ^
 "} else {" ^
 "    Write-Host '[ok] Packet Loss: 0%%' -ForegroundColor Gray" ^
 "};" ^
 "if ($j -gt 15) {" ^
 "    Write-Host ('[^!] Высокий джиттер: {0:N1} мс' -f $j) -ForegroundColor Yellow" ^
 "} else {" ^
 "    Write-Host ('[ok] Jitter: {0:N1} ms (Avg: {1:N0} ms)' -f $j, $avg) -ForegroundColor Gray" ^
 "}"


:end-of-net-diag
echo.
echo [92mДиагностика завершена[0m
echo [0m[i] Каждый пункт без "ok" означает - предупреждение. Это означает, что вы можете воспользоваться поиском в интернете, для детального решения каждой сетевой проблемы со стороны вашей системы[0m
exit /b



:net-flush
cls
echo [93m[ Сетевая профилактика ][0m
echo.

:: base reset
echo NETSH WINSOCK RESET...
netsh winsock reset >nul
echo NETSH INT IP RESET...
netsh int ip reset >nul
echo IPCONFIG IPV4...
ipconfig /release >nul
ipconfig /renew >nul

:: extended reset
echo RENEW EL...
ipconfig /renew EL >nul
echo IPCONFIG IPV6...
ipconfig /release6 >nul
ipconfig /renew6 >nul

:: dns reset
echo IPCONFIG FLUSHDNS...
ipconfig /flushdns >nul
echo IPCONFIG REGDNS...
ipconfig /registerdns >nul
exit /b


:: end of a function
:endfunc
echo.&echo [36m[!time!] Выполнение завершено^^!
if !exaf!==1 (endlocal&exit/b)
echo Нажмите любую кнопку, чтобы вернуться в главное меню...[0m
pause>nul&endlocal&cls
goto :ask


