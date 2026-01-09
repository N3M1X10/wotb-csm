@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

:request-admin-rights
set adm_arg=%1
if "%adm_arg%" neq "admin" (
    echo [93m[powershell] Requesting admin rights...[0m
    powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Start-Process 'cmd.exe' -ArgumentList '/k \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

:: this is method that faster but its pretty old (soon vbs must be disabled by default in windows by microsoft)
rem :request-admin-rights
rem set "adm_arg=%~1"
rem if "%adm_arg%" neq "admin" (
rem     echo [93m[mshta vbscript] Requesting admin rights...[0m
rem     mshta vbscript:CreateObject("Shell.Application"^).ShellExecute("cmd.exe","/c ""%~f0"" admin","","runas",1^)(window.close^)
rem     exit /b
rem )



:ask
::menu session setup
chcp 65001>nul
title %~nx0
endlocal
setlocal EnableDelayedExpansion

::variable configuration
:: применяет к игре высокий приоритет процесса при любом запуске скриптом
:: ='' - default
:: ='1' - enable
set raise_priority=
:: var autofix
if not defined raise_priority (set raise_priority=0)

:: Отрисовка меню
cls
echo [101;93mМеню настройки игровых кластеров WOTB[0m
echo.
echo [93mМеню управления статусом правил:[0m
echo [96m1 - Блокировка кластеров[0m
echo [96m2 - Разблокировка кластеров[0m
echo [93mРаботаем с пачкой правил:[0m
echo [96mba - Заблокировать все кластеры[0m
echo [96muba - Разблокировать все кластеры[0m
echo [93mСервисные операции с правилами:[0m
echo [96m3 - [92mСоздать [96m/ [92mОбновить [96mправила для блокировки[0m
echo [96m4 - [91mУдалить [96mвсе правила блокировок в брандмауэре и hosts[0m
echo [96m5 - [93mОбновить [96mдиапазоны ip-адресов для блокировки[0m
echo.
echo [93mПрочие опции:[0m
echo [96mp / play - [92mзапустить WOTB[0m
echo [96mk / kill - [91mЗакрыть всё связанное с WOTB[0m
echo [96mc / clean - [93mПочистить кэш игры (активная игра будет перезапущена)[0m
echo [96mreset - [91mсбросить данные WOTB[0m
echo [96ml / ping - Измерить задержку до кластеров[0m
echo [96md / diag - Провести диагностику сети[0m
echo [96ms / stat - Узнать состояние правил[0m
echo [96mf / wf - Открыть монитор Windows Firewall[0m
echo [96mh / help / git - Перейти на страницу GitHub[0m
echo [96mr - [93mПерезапустить этот пакет[0m
echo [96mx - [91mЗавершить работу[0m

:: Вопрос от функции
echo.
set select=
set /p select="[92mВвод:[0m "

:: Сопоставление ввода с командами и их настройками
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

if "%select%"=="c"     call :wotb-cleaner-setup & goto endfunc
if "%select%"=="clean" call :wotb-cleaner-setup & goto endfunc

if "%select%"=="reset" call :wotb-cleaner-setup "entire" & goto endfunc

if "%select%"=="l" goto check-ping
if "%select%"=="ping" goto check-ping

if "%select%"=="d"    cls & call :network-diagnostics & goto endfunc
if "%select%"=="diag" cls & call :network-diagnostics & goto endfunc

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

:: mismatch
set draw_mismatch=
if "!draw_mismatch!"=="1" (
    if "%select%"=="" (
        start /b "" mshta vbscript:Execute("CreateObject(""WScript.Shell"").Popup ""Ошибка: Пустой ввод"", 1, ""%~nx0"", 16:close"^)
    ) else (
        start /b "" mshta vbscript:Execute("CreateObject(""WScript.Shell"").Popup ""Ошибка: Команда не распознана."" & vbCrLf & ""Проверьте выбранную раскладку или правильность ввода."", 2, ""%~nx0"", 16:close"^)
    )
)
goto ask



:: Поиск необходимых файлов
:check-ranges-file
if "%~1" neq "silent" (echo [90mищу файл с диапазонами...[0m)
set "ranges_file=%~dp0lists\ip_map.txt"
if "%~1"=="silent" (exit/b)
if not exist "!ranges_file!" (
    echo.
    if "%~1" neq "update" (
        echo [91mОшибка: Файл IP диапазонов не найден^^![0m
        echo [96m [i] Запустите обновление диапазонов в главном меню[0m
    )
    echo [93mФайл IP диапазонов не найден^^![0m
) else (
    echo [90mесть[0m
)
exit /b

:check-domains-file
if "%~1" neq "silent" (echo [90mищу файл с доменами...[0m)
set "domains_file=%~dp0lists\domains.txt"
if "%~1"=="silent" (exit/b)
if not exist "!domains_file!" (
    echo.
    echo [91mОшибка: Файл доменов не найден^^![0m
    echo [93mОткройте страницу на github и скачайте новый репозиторий оттуда. Либо создайте новый файл, рядом с этим сценарием (по пути: [96m!domains_file![93m^), и поместите в него свой список доменов кластеров[0m
    goto endfunc
) else (
    echo [90mесть[0m
)
exit /b



:update-ipset
cls
echo [96m[ [93m- - - Обновление списка диапазонов - - - [96m][0m
call :check-rules
if "!errorlevel!" lss "1" (
    rem dn
) else (
    choice /C "10" /m "[93m[?] Подтвердите [91mвременную разблокировку [93mправил в брандмауэре[0m"
    if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
    if "!errorlevel!"=="2" (goto ask)
)

:: Запуск обновления данных
call :check-ranges-file "update"
call :check-domains-file

echo [36m
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$domainsFile = '%domains_file%';" ^
    "$outputFile = '%ranges_file%';" ^
    "if (-not (Test-Path $domainsFile)) { exit 1 };" ^
    "Write-Host 'Сканирую и сохраняю статус правил...';" ^
    "$rules = Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter \"DisplayName like '%%tanksblitz%%'\" -ErrorAction SilentlyContinue;" ^
    "$backup = @();" ^
    "if ($rules) {" ^
        "foreach($r in $rules) { if($r.Enabled -eq 1) { $backup += $r.InstanceID } };" ^
        "Disable-NetFirewallRule -DisplayName '*tanksblitz*' -ErrorAction SilentlyContinue;" ^
    "}" ^
    "Write-Host 'Опрашиваю сервера...';" ^
    "try {" ^
        "$domains = Get-Content $domainsFile | Where-Object { $_ -match '\.' } | Select-Object -Unique;" ^
        "$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 15);" ^
        "$RunspacePool.Open();" ^
        "$Jobs = foreach ($d in $domains) {" ^
            "$ps = [PowerShell]::Create().AddScript({" ^
                "param($d);" ^
                "try {" ^
                    "[System.Net.Dns]::GetHostAddresses($d) | Where-Object { [int]$_.AddressFamily -eq 2 } | ForEach-Object {" ^
                        "$ip = $_.IPAddressToString;" ^
                        "try {" ^
                            "$r = Invoke-RestMethod -Uri ('rdap.db.ripe.net' + $ip) -TimeoutSec 2 -UseBasicParsing;" ^
                            "if ($r.cidr0_cidrs) { $d + ':' + $r.cidr0_cidrs.v4prefix + '/' + $r.cidr0_cidrs.length } " ^
                            "else { $d + ':' + $ip.Substring(0, $ip.LastIndexOf('.')) + '.0/24' }" ^
                        "} catch { $d + ':' + $ip.Substring(0, $ip.LastIndexOf('.')) + '.0/24' }" ^
                    "}" ^
                "} catch {}" ^
            "}).AddArgument($d);" ^
            "$ps.RunspacePool = $RunspacePool;" ^
            "@{ P = $ps; S = $ps.BeginInvoke() }" ^
        "};" ^
        "while ($Jobs.S.IsCompleted -contains $false) { Start-Sleep -Milliseconds 50 };" ^
        "$res = foreach ($j in $Jobs) { $j.P.EndInvoke($j.S); $j.P.Dispose() };" ^
        "$RunspacePool.Close();" ^
        "if ($res) {" ^
            "$res | Group-Object { $_.Split(':')[0] } | ForEach-Object {" ^
                "$_.Name + ':' + (($_.Group | ForEach-Object { $_.Split(':')[1] } | Select-Object -Unique) -join ',')" ^
            "} | Out-File $outputFile -Encoding ascii;" ^
        "}" ^
    "} finally {" ^
        "if ($backup) {" ^
            "Write-Host 'Восстанавливаю правила...';" ^
            "Enable-NetFirewallRule -Name $backup -ErrorAction SilentlyContinue;" ^
        "}" ^
    "}"
echo [36mГотово^^![0m

echo.
echo [93mСписок найденных активных доменов и их диапазонов:[0m
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [36m%%a [%%b][0m
)
echo.
echo Найденные диапазоны сохранены (в [96m"%ranges_file%"[0m) и теперь вы можете просто создать новые правила, в брандмауэре, в главном меню^^![0m
goto endfunc



:create-rules
cls
choice /C "10" /m "[93m[?] Подтвердите [36mСОЗДАНИЕ [93mправил блокировки[0m"
if "%errorlevel%"=="1" (goto create-rules-y)
if "%errorlevel%"=="2" (goto ask)

:create-rules
cls
choice /C "10" /m "[93m[?] Подтвердите [36mСОЗДАНИЕ [93mправил блокировки[0m"
if "%errorlevel%"=="1" (goto create-rules-y)
if "%errorlevel%"=="2" (goto ask)

:create-rules-y
set rule_description="Правило для блокирования кластеров СНГ сервера игры Tanks Blitz (created in wotb-csm)"

:: Удаляем все старые правила
call :remove-rules

echo.
echo [90mПытаюсь создать правила...[0m

call :check-ranges-file "silent"
if not exist "%ranges_file%" (
    echo [90mНет файла с диапазонами[0m
    goto endfunc
)


echo [90mПодготовка правил...[0m
(
    for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
        echo advfirewall firewall add rule name="%%a_block_out" description=%rule_description% dir=out action=block remoteip=%%b
        echo advfirewall firewall add rule name="%%a_block_in" description=%rule_description% dir=in action=block remoteip=%%b
    )
) | netsh >nul 2>&1

echo [90mПроверка создания правил...[0m
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    set "found="
    :: Проверяем наличие через встроенный фильтр findstr по выводу команды
    for /f "tokens=*" %%i in ('netsh advfirewall firewall show rule name^="%%a_block_out" 2^>nul ^| findstr /C:"%%a_block_out"') do (
        set "found=1"
    )
    if not defined found (
        echo [91mОшибка создания правила "%%a"[0m
    ) else (
        echo [92m[+] [93mСоздано правило домена: "%%a" [%%b][0m
    )
)
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    :: Редактируем hosts
    call :edit-hosts "%%a" "block"
)
:: Чистим кэш dns
ipconfig /flushdns>nul

echo [90mГотово[0m

echo.
echo [101;93m[i] ПРОЧТИ МЕНЯ ^^!^^!^^![0m
echo [93m[*] [36mКогда правила создадутся - они сразу заблокируют подключения по своим доменам[0m
echo [93m[*] [36mВыбери, которые тебе нужны и разблокируй в - главном меню[0m
echo.
echo [93m[*] [36mОбращаю внимание, что блокировка производится не только в брандмауэре (IP/CIDR), но и - в файле hosts (domains)[0m
goto endfunc



:rules-remove-confirm
cls
choice /C "10" /m "[93m[?] Подтвердите [91mУДАЛЕНИЕ [93mправил блокировки[0m"
if "%errorlevel%"=="1" (call :remove-rules & goto endfunc)
if "%errorlevel%"=="2" (goto ask)

:remove-rules
echo.
echo [90mПытаюсь удалить правила блокировки кластеров WOTB в брандмауэре...[0m
powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
$r = Get-NetFirewallRule ^| Where-Object { $_.DisplayName -like 'login*.tanksblitz.*_block_*' -or $_.DisplayName -like 'login*.wotblitz.*_block_*' }; ^
if ($r) { ^
    $r ^| Remove-NetFirewallRule; ^
    foreach ($rule in $r) { ^
        Write-Host ('[91m[-] [93mУдалено правило: {0} [0m' -f $rule.DisplayName) ^
    } ^
} else { ^
    Write-Host '[91mПравила не найдены :([0m' ^
}
echo.
echo [90mПытаюсь удалить записи блокировки кластеров WOTB в hosts...[0m
call :check-domains-file "silent"
for /f "usebackq tokens=1,2 delims=:" %%a in ("!domains_file!") do (
    call :edit-hosts "%%a" "unblock"
)

echo [90mГотово[0m
exit /b



:block-all
call :change-all "block"
exit/b
:unblock-all
call :change-all "unblock"
exit/b

:change-all
if "%~1"=="block" (
    set "msg=Блокировка"
    set "state=yes"
    set act=%~1
) else if "%~1"=="unblock" (
    set "msg=Разблокировка"
    set "state=no"
    set act=%~1
) else (
    echo Ошибка изменения всех правил
    exit/b
)

call :check-rules
if "!errorlevel!"=="0" (exit/b)
call :check-ranges-file
if "!errorlevel!"=="0" (exit/b)

if exist "!ranges_file!" (
    echo [90mЗапускаю перебор всех правил...[0m

    (
        cmd /d /v:on /c "for /f "usebackq tokens=1,2 delims=:" %%a in ("!ranges_file!") do @echo advfirewall firewall set rule name="%%a_block_out" dir=out new enable=!state!"
    ) 2>nul | netsh >nul 2>&1

    (
        cmd /d /v:on /c "for /f "usebackq tokens=1,2 delims=:" %%a in ("!ranges_file!") do @echo advfirewall firewall set rule name="%%a_block_in" dir=in new enable=!state!"
    ) 2>nul | netsh >nul 2>&1

    for /f "usebackq tokens=1,2 delims=:" %%a in ("!ranges_file!") do (
        call :edit-hosts "%%a" "!act!" "silent"
        echo [90m!msg!: %%a [%%b][0m
    )
    
    echo [90mГотово[0m
) else (
    echo [90m[Ошибка] Нет файла с диапазонами[0m
)
exit /b



:edit-hosts
set "domain=%~1"
set "act=%~2"
set "mode=%~3"
set "entry=0.0.0.0 %domain%"
set "TH=%TEMP%\h.tmp"
set "hosts_path=%SystemRoot%\System32\drivers\etc\hosts"

if exist "%hosts_path%" (
    attrib -r "%hosts_path%"
) else (
    echo [91mОшибка: Не удалось получить доступ к файлу hosts[0m
    exit /b
)

:: Проверяем наличие домена
findstr /L /C:"%domain%" "%hosts_path%" >nul
set "exists=%errorlevel%"

:: Логика выхода, если действие не требуется
if "%act%"=="block" if %exists% equ 0 (
    if /i "%mode%" neq "silent" echo [90mуже есть в файле hosts: "%domain%"[0m
    exit /b
)
if "%act%"=="unblock" if %exists% neq 0 exit /b

:: Выполнение операций
if "%act%"=="block" (
    echo.>>"%hosts_path%"
    echo %entry%>>"%hosts_path%"
)
if "%act%"=="unblock" (
    findstr /V /L /C:"%domain%" "%hosts_path%" > "%TH%"
    move /Y "%TH%" "%hosts_path%" >nul
)

:: Чистка пустых строк
findstr /V /R /C:"^[ ]*$" "%hosts_path%" > "%TH%"
move /Y "%TH%" "%hosts_path%" >nul

:: Вывод результата
if "%act%"=="unblock" (
    findstr /L /C:"%domain%" "%hosts_path%" >nul && (
        echo [91m[^^!^^!^^!] [90mошибка: "%domain%" остался[0m
    ) || (
        if /i "%mode%" neq "silent" echo [90mудален из hosts: "%domain%"[0m
    )
)

if "%act%"=="block" (
    if /i "%mode%" neq "silent" echo [90mзаблокирован в hosts: "%domain%"[0m
)

if exist "%TH%" del /f /q "%TH%"
exit /b



:cluster-manager
if "%act%"=="block" (
    set "func_title=[91m[ [93m- - - БЛОКИРОВКА КЛАСТЕРА - - -[91m ][0m"
    set rule_state=yes
) else (
    set "func_title=[92m[ [93m- - - РАЗБЛОКИРОВКА КЛАСТЕРА - - -[92m ][0m"
    set rule_state=no
)
echo !func_title!
echo.
call :check-ranges-file "silent"
call :draw-clusters-list
echo.
:cluster-manager-choice
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

set "c_idx="
choice /C:%keys% /N /M "[93m[?] Выберите номер или букву [96m(0 для выхода)[93m: "
set /a c_idx=%ERRORLEVEL%

:: Если нажали 1-й символ (это '0') - выходим
if "%c_idx%"=="1" goto ask

:: Корректируем индекс для массива (ERRORLEVEL в choice начинается с 1)
set /a c_choice=%c_idx%-1

:: Извлекаем данные по индексу
set "sel_domain=!cluster[%c_choice%]!"

:: ПРОВЕРКА: Если правило не существует
if "!status!"=="NotExist" (
    echo.
    echo [91m[^^!^^!^^!] Ошибка: Правило для [96m!sel_domain! [91mне найдено в Брандмауэре.[0m
    echo [93m[i] Сначала создайте правила через соответствующий пункт меню.[0m
)

:: Изменяем правило

:: Формируем команды в одну строку, разделяя их амперсандом, netsh получит их как единый пакет для исполнения
netsh advfirewall firewall set rule name="!sel_domain!_block_out" dir=out new enable=%rule_state% >nul 2>&1 & ^
netsh advfirewall firewall set rule name="!sel_domain!_block_in" dir=in new enable=%rule_state% >nul 2>&1

:: Проверка ошибок
if %errorlevel% neq 0 (
    echo [90m[i] Ошибка при применении правила netsh для: "!sel_domain!"[0m

) else (
    cls
    echo !func_title!
    echo.
    call :draw-clusters-list
    
    echo.
    call :edit-hosts "!sel_domain!" "%act%" "silent"
    if "%act%"=="block" (
        echo [91m [▢] [93mКластер [96m!sel_domain! [93mзаблокирован^^![0m
    ) else (
        echo [92m [[97m~[92m] [93mКластер [96m!sel_domain! [93mразблокирован^^![0m
    )
    echo.

)
goto cluster-manager-choice



:draw-clusters-list
set count=0
set "map=ABCDEFGHIJKLMNOPQRSTUVWXYZ"

:: 1. Очистка кеша
for /f "tokens=1 delims==" %%v in ('set cluster[ 2^>nul') do set "%%v="
for /f "tokens=1 delims==" %%v in ('set status[ 2^>nul') do set "%%v="
for /f "tokens=1 delims==" %%v in ('set "fw_db_" 2^>nul') do set "%%v="

:: 2. Сбор данных из реестра
for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f "_block_out" 2^>nul ^| findstr "_block_out"') do (
    set "raw=%%B"
    
    :: Извлекаем Name и отрезаем лишний знак =
    set "t_name=!raw:*Name=!"
    for /f "tokens=1 delims=|" %%N in ("!t_name!") do (
        set "v_name=%%N"
        if "!v_name:~0,1!"=="=" set "v_name=!v_name:~1!"
    )
    
    :: Извлекаем Active и отрезаем лишний знак =
    set "t_act=!raw:*Active=!"
    for /f "tokens=1 delims=|" %%S in ("!t_act!") do (
        set "v_act=%%S"
        if "!v_act:~0,1!"=="=" set "v_act=!v_act:~1!"
    )
    
    if defined v_name set "fw_db_!v_name!=!v_act!"
)

:: 3. Отрисовка
for /f "usebackq tokens=1 delims=:" %%a in ("%ranges_file%") do (
    set /a count+=1
    set "cluster[!count!]=%%a"
    set "target=%%a_block_out"
    
    set "status=NotExist"
    
    :: Проверка существования ключа в памяти
    if defined fw_db_!target! (
        for /f "delims=" %%V in ("!target!") do (
            if /i "!fw_db_%%V!"=="TRUE" (
                set "status=Enabled"
            ) else (
                set "status=Disabled"
            )
        )
    )

    :: Индексация
    if !count! LSS 10 (set "display_idx=!count!") else (
        set /a idx=!count!-10
        for /f "delims=" %%i in ("!idx!") do set "display_idx=!map:~%%i,1!"
    )

    :: Вывод строки
    if "!status!"=="Enabled" (
        echo [93m[!display_idx!] %%a [[91mБЛОКИРОВАН[93m][0m
    ) else if "!status!"=="Disabled" (
        echo [93m[!display_idx!] %%a [[92mДОСТУПЕН[93m][0m
    ) else (
        echo [93m[!display_idx!] %%a [[90mПРАВИЛО НЕ НАЙДЕНО[93m][0m
    )
)
exit /b



:rules-status
cls
echo [96m[ [93m- - - СТАТУС ПРАВИЛ БЛОКИРОВКИ - - - [96m][0m
echo.
call :check-ranges-file "silent"
call :draw-clusters-list
goto endfunc



:check-rules
if "%~1" neq "silent" (echo [90mпроверка правил...[0m)
call :check-ranges-file "silent"

set out_rules_count=0
set in_rules_count=0

if exist "!ranges_file!" (
    set "tmp_raw=%temp%\fw_raw.tmp"
    set "tmp_filtered=%temp%\fw_filtered.tmp"

    netsh advfirewall firewall show rule name=all > "!tmp_raw!" 2>&1
    findstr /i "_block_" "!tmp_raw!" > "!tmp_filtered!" 2>nul

    for /f "usebackq tokens=2* delims=: " %%i in ("!tmp_filtered!") do (
        set "r_name=%%j"
        for /f "usebackq tokens=1 delims=:" %%a in ("!ranges_file!") do (
            if "!r_name!"=="%%a_block_out" set /a out_rules_count+=1
            if "!r_name!"=="%%a_block_in" set /a in_rules_count+=1
        )
    )
    :: Удаляем временные файлы
    del /f /q "!tmp_raw!" "!tmp_filtered!" >nul 2>&1
)
:: Выводим данные в соответствии с режимом вывода
if "%~1" neq "silent" (
    if "!out_rules_count!" geq "1" (
        echo [90mправила найдены[0m
        exit /b 1
    ) else (
        if "!in_rules_count!" geq "1" (
            echo.
            echo [91m[^^!^^!^^!] [93mНайдено несоответствие среди правил.[0m
            echo [96mНайдены правила блокировки входящего подключения, но нет для исходящего[0m
            echo [93m[i] [36mПересоздайте правила в главном меню[0m
            echo.
            exit /b 0
        )
        echo [90mправила не найдены[0m
        exit /b 0
    )
) else (
    if "!out_rules_count!" geq "1" (exit /b 1) else (exit /b 0)
    if "!in_rules_count!" geq "1" (exit /b 1) else (exit /b 0)
)




:check-ping
cls
echo [96m[ [93m- - - ПРОВЕРКА ЗАДЕРЖКИ КЛАСТЕРОВ (PING) - - - [96m][0m

call :check-rules
if "!errorlevel!" lss "1" (
    rem dn
) else (
    choice /C "10" /m "[93m[?] Подтвердите [91mвременную разблокировку [93mправил в брандмауэре[0m"
    if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
    if "!errorlevel!"=="2" (goto ask)
)
call :check-domains-file

call :check-routing-services
call :check-vpn-adapters

echo.
echo [94m[ [36m- - - Запускаю проверку - - - [94m][36m
echo.

powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "Write-Host 'Сканирование и сохранение состояния правил...';" ^
    "$filter = \"DisplayName like '%%tanksblitz%%' or DisplayName like '%%wotblitz%%'\";" ^
    "$rules = Get-CimInstance -Namespace root/standardcimv2 -ClassName MSFT_NetFirewallRule -Filter $filter -ErrorAction SilentlyContinue;" ^
    "$backup = @();" ^
    "$tcpUsed = $false;" ^
    "if ($rules) {" ^
        "foreach($r in $rules) { if($r.Enabled -eq 1) { $backup += $r.InstanceID } };" ^
        "Write-Host 'Временное отключение правил...';" ^
        "$rules | Disable-NetFirewallRule -ErrorAction SilentlyContinue;" ^
    "};" ^
    "Write-Host 'Запуск опроса...';" ^
    "try {" ^
        "$domains = Get-Content '%domains_file%' | Where-Object { $_ -match '\.' };" ^
        "$instances = foreach ($d in $domains) {" ^
            "$ps = [PowerShell]::Create().AddScript({" ^
                "param($d);" ^
                "$results = @();" ^
                "$note = '';" ^
                "$usedTcpInLoop = $false;" ^
                "for($i=0; $i -lt 2; $i++) {" ^
                    "$sw = New-Object System.Diagnostics.Stopwatch;" ^
                    "$client = New-Object System.Net.Sockets.TcpClient;" ^
                    "try {" ^
                        "$reply = $pinger.Send($d, 1000);" ^
                        "if ($reply.Status -eq 'Success' -and $reply.RoundtripTime -gt 0) {" ^
                            "$results += $reply.RoundtripTime;" ^
                            "continue;" ^
                        "}" ^
                    "} catch {}" ^
                    "$pinger = New-Object System.Net.NetworkInformation.Ping;" ^
                    "try {" ^
                        "$sw.Start();" ^
                        "$connectTask = $client.ConnectAsync($d, 443);" ^
                        "$connectTask.Wait(2000) | Out-Null;" ^
                        "$sw.Stop();" ^
                        "if ($client.Connected) {" ^
                            "$results += $sw.Elapsed.TotalMilliseconds;" ^
                            "$client.Close();" ^
                            "$note = '  [90m(по TCP)[0m';" ^
                            "$usedTcpInLoop = $true;" ^
                            "continue;" ^
                        "}" ^
                    "} catch {}" ^
                "}" ^
                "if ($results.Count -gt 0) {" ^
                    "$avg = ($results | Measure-Object -Average).Average;" ^
                    "$displayMs = if ($avg -lt 1) { '<1' } else { [Math]::Round($avg).ToString() };" ^
                    "$c = if ($avg -lt 25) { '[92m' } elseif ($avg -lt 100) { '[93m' } else { '[91m' };" ^
                    "return @{ Output = ('[90m[ [93m{0} [90m] {1}{2}ms {3}[0m' -f $d.PadRight(25), $c, $displayMs, $note); TcpUsed = $usedTcpInLoop };" ^
                "} else {" ^
                    "return @{ Output = ('[90m[ [93m{0} [90m] [90mНЕДОСТУПЕН[0m' -f $d.PadRight(25)); TcpUsed = $false };" ^
                "}" ^
            "}).AddArgument($d);" ^
            "@{ PS = $ps; Async = $ps.BeginInvoke() }" ^
        "};" ^
        "while ($instances.Async.IsCompleted -contains $false) { Start-Sleep -Milliseconds 50 };" ^
        "foreach ($i in $instances) {" ^
            "$result = $i.PS.EndInvoke($i.Async);" ^
            "Write-Host ($result.Output);" ^
            "if ($result.TcpUsed) { $tcpUsed = $true };" ^
            "$i.PS.Dispose();" ^
        "};" ^
        "if ($tcpUsed) {" ^
            "Write-Host '';" ^
            "Write-Host '[91m[^!] [93mБыл применён замер [96mпо TCP[93m, вероятно мы стреляли в VPN, или ICMP-запросы блокируются по другой причине[0m';" ^
            "Write-Host '[93m[^!] [91mВ таком случае результат замеров наверняка искажён^![0m';" ^
            "Write-Host '[96m[^>] [93mПросьба убедиться что службы подобные VPN, либо другое подобное управление сетевым трафиком - [96mотключено[0m';" ^
            "Write-Host '[36m[^>] Затем, перезапустите эту проверку, для более точного результата[0m';" ^
        "}" ^
    "} finally {" ^
        "if ($backup) {" ^
            "Write-Host '';" ^
            "Write-Host 'Возврат блокировок...';" ^
            "Enable-NetFirewallRule -Name $backup -ErrorAction SilentlyContinue;" ^
        "}" ^
    "}"

echo.
echo [92mПроверка завершена
echo [0m[i] Теперь вы можете использовать эти данные для выбора ваших оптимальных кластеров[0m
goto endfunc



:wotb-cleaner-setup
cls
if "%~1"=="entire" (
    echo [93m[ [91mСброс WOTB [93m][0m
    echo.
    choice /C "10" /m "[93m[?] Подтвердите [91mУДАЛЕНИЕ ВСЕХ[93m кэшированных данных обеих игр. Это приведёт к потере настроек[0m"
    if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
    if "!errorlevel!"=="2" (goto ask)

) else (
    echo [94m[ [96m- - - Деликатная стирка кэша WOTB - - - [94m][0m
)


echo [90m&echo Завершаю игру, если она была открыта...
set "exeToStart="
for /f "usebackq delims=" %%p in (`powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
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

echo [90mЗаклинаю разработчиков игры, чтобы начали оптимизировать её...[0m
echo [90mИщу папки с кэшем игр...[0m
:: Извлекаем путь к Документам из реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal') do set "ActualDocs=%%b"
:: Разворачиваем переменные среды (если путь содержит %USERPROFILE%)
for /f "delims=" %%i in ('echo %ActualDocs%') do set "docs=%%i"

set "cis_wotb_path=!docs!\TanksBlitz\"
set "eu_wotb_path=%LOCALAPPDATA%\wotblitz\DAVAProject\"
rem echo.
rem echo [90mcis: "!cis_wotb_path!"[0m
rem echo [90meu: "!eu_wotb_path!"[0m

:: проверка наличия папок с кэшем
:: Формат: "путь;заголовок;имя_для_ошибки"
for %%a in ("!cis_wotb_path!;Tanks Blitz;tanksblitz", "!eu_wotb_path!;WoT Blitz;wotblitz") do (
    for /f "tokens=1,2,3 delims=;" %%b in (%%a) do (
        if not exist "%%b" (
            echo.
            echo [91m[^^!] [93mОшибка доступа. [90mПапка кэша игры (%%d^) не найдена[0m
        ) else (
            set "title=%%c"
            call :wotb-cleaner "%~1" "%%b"
        )
    )
)

:: кэш dns
ipconfig /flushdns>nul

:: если игра была запущена то возвращаем её назад
if defined exeToStart (
    echo.
    echo [93m[ Перезапуск игры... ([96m%exeToStart%[93m^) ][0m
    if "%raise_priority%"=="1" (
        start "" /high "!exeToStart!"
    ) else (
        start "" "!exeToStart!"
    )
    set "exeToStart="
)
exit /b



:wotb-cleaner
echo.&echo [104;93m[ !title! ][0m
set "wotb_path=%~2"
if "%~1"=="entire" (
    rd /q /s "!wotb_path!"
    echo.
    echo [90mПолный сброс завершён
) else (
    echo.
    echo [94m[ [36mудаляем кэш, в корне папки [94m][0m
    cd /d "!wotb_path!" & call :cycle-delete "*.txt;*.log;startupOptions.*;dynamic_content_version.*" "files"
    call :cycle-delete "region_cache" "folders"
    rem echo.
    rem echo [94m[ [36mчистим кэш внутри папок [94m][0m
    rem cd /d "cache" & call :cycle-delete "" "files"
)

:: [заметки]
:: server_config_*_*.dat - хранит настройки чувствительности мыши
:: game_options_local_options.dat - хранит настройки графики
exit /b



:cycle-delete
echo.
::setup
set count=0
set "array=%~1"
set "type=%~2"
set !array!="!array:;=" "!"
::array check
if not defined array (
    echo [91m[^^!^^!^^!] Ошибка. Файлы в вызове не были определены (а что удаляем то?^)[0m
    exit/b
)
::type check
if "!type!"=="files" (
    echo [100;30m[ удаляем файлики ][0m
) else if "!type!"=="folders" (
    echo [100;30m[ удаляем папки ][0m
) else (
    echo [91m[^^!^^!^^!] Ошибка. Не удалось определить тип данных в вызове ("!type!" - не знаю: папки это или файлы^)[0m
    exit /b
)
::cleaner
for %%t in (!array!) do (
    set item=%%~t
    if exist "!item!" (
        set /a count+=1
        if "!type!"=="files" (
            del /f /q "!item!"
            echo [90m * файл : "!item!" - удалён[0m
        ) else if "!type!"=="folders" (
            rd /q /s "!item!"
            echo [90m * папка : "!item!" - удалена[0m
        )
    )
)
if "!count!" lss "1" (echo [90m[ ничего не найдено ][0m)
exit/b



:start-wotb
cls
echo [92m[ [93m- - - Запуск WOTB - - - [92m][0m
echo.
echo [90mПробую запустить либо найти игры WOTB...[0m
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
    "$raise_priority = %raise_priority%;" ^
    "$eof_delay = {Start-Sleep -s 1};" ^
    "$apps = @(" ^
    "    @{ name='TanksBlitz'; exe='TanksBlitz.exe'; lName='Lesta Game Center'; lExe='lgc.exe'; lProc='lgc' }," ^
    "    @{ name='WoTBlitz'; exe='wotblitz.exe'; lName='Wargaming.net Game Center'; lExe='wgc.exe'; lProc='wgc' }" ^
    ");" ^
    "function Set-GamePriority($procName) {" ^
    "    if ($raise_priority -ne 1) { return }" ^
    "    Write-Host ' [*] Ожидание процесса для повышения приоритета...';" ^
    "    $timer = 0; while($timer -lt 60) {" ^
    "        $proc = Get-Process $procName -ErrorAction SilentlyContinue;" ^
    "        if ($proc) {" ^
    "            $proc.PriorityClass = 'High';" ^
    "            Write-Host ' [i] Приоритет установлен: Высокий';" ^
    "            return" ^
    "        }" ^
    "        Start-Sleep -m 500; $timer += 0.5" ^
    "    }" ^
    "}" ^
    "function Get-RealCasePath($path) {" ^
    "    try {" ^
    "        $file = New-Object System.IO.FileInfo($path);" ^
    "        if ($file.Exists) {" ^
    "            $handle = [Microsoft.Win32.SafeHandles.SafeFileHandle]$file.OpenRead().SafeFileHandle;" ^
    "            $sb = New-Object System.Text.StringBuilder(1024);" ^
    "            $sig = '[DllImport(\"kernel32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern uint GetFinalPathNameByHandle(IntPtr hFile, [Out] System.Text.StringBuilder lpszFilePath, uint cchFilePath, uint dwFlags);';" ^
    "            $type = Add-Type -MemberDefinition $sig -Name 'Win32Path' -Namespace 'Win32' -PassThru;" ^
    "            $res = $type::GetFinalPathNameByHandle($handle.DangerousGetHandle(), $sb, 1024, 0);" ^
    "            $handle.Close();" ^
    "            return $sb.ToString().Replace('\\?\', '')" ^
    "        }" ^
    "    } catch {}" ^
    "    return $path" ^
    "}" ^
    "function Get-PathFast($targetExe) {" ^
    "    $regPaths = @('HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched', 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*');" ^
    "    $pattern = '[A-Z]:\\.*' + [regex]::Escape($targetExe);" ^
    "    foreach ($root in $regPaths) {" ^
    "        $p = Get-ItemProperty $root -ErrorAction SilentlyContinue; if (-not $p) { continue }" ^
    "        foreach ($prop in $p.PSObject.Properties) {" ^
    "            $val = if ($prop.Value -is [string]) { $prop.Value } else { '' };" ^
    "            if ($prop.Name -match $pattern -or $val -match $pattern) {" ^
    "                $f = $matches[0]; if (Test-Path $f) { return Get-RealCasePath $f }" ^
    "            }" ^
    "        }" ^
    "    }" ^
    "    return $null" ^
    "}" ^
    "function Get-GamePath($exe) {" ^
    "    $fast = Get-PathFast $exe; if ($fast) { return $fast }" ^
    "    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' } | Select-Object -ExpandProperty RootDirectory;" ^
    "    foreach ($d in $drives) {" ^
    "        $rootFile = Get-ChildItem -Path $d -Filter $exe -ErrorAction SilentlyContinue; if ($rootFile) { return $rootFile.FullName }" ^
    "        $subDirs = Get-ChildItem -Path $d -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -notlike '*ReparsePoint*' };" ^
    "        foreach ($sd in $subDirs) {" ^
    "            $f = Get-ChildItem -Path $sd.FullName -Filter $exe -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1;" ^
    "            if ($f) { return $f }" ^
    "        }" ^
    "    }" ^
    "    return $null" ^
    "}" ^
    "function Wait-Launcher($proc) {" ^
    "    $sig = '[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);';" ^
    "    $type = Add-Type -MemberDefinition $sig -Name 'Win32PostMessage' -Namespace 'Win32' -PassThru;" ^
    "    $timer = [System.Diagnostics.Stopwatch]::StartNew();" ^
    "    while ($timer.Elapsed.TotalSeconds -lt 40) {" ^
    "        $p = Get-Process $proc -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 };" ^
    "        if ($p) { Start-Sleep -m 1000; $type::PostMessage($p.MainWindowHandle, 0x0112, 0xF060, [IntPtr]::Zero); return $true }" ^
    "        Start-Sleep -m 500" ^
    "    }; return $false" ^
    "}" ^
    "function Show-ConsoleMenu($Title, $Items) {" ^
    "    Write-Host ''; Write-Host $Title -ForegroundColor Yellow; Write-Host '';" ^
    "    $startPos = $Host.UI.RawUI.CursorPosition; $idx = 0;" ^
    "    while ($true) {" ^
    "        $Host.UI.RawUI.CursorPosition = $startPos;" ^
    "        for ($i = 0; $i -lt $Items.Count; $i++) {" ^
    "            $curr = $Items[$i]; $text = if($curr.Path){ $curr.Game + ' (' + $curr.Path + ')' } else { $curr.Game };" ^
    "            if ($i -eq $idx) { Write-Host '»' -NoNewline -ForegroundColor Yellow; Write-Host '[96m'$text } " ^
    "            else { Write-Host ' ' -NoNewline; Write-Host '[36m'$text }" ^
    "        }" ^
    "        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');" ^
    "        if ($key.VirtualKeyCode -eq 38 -and $idx -gt 0) { $idx-- }" ^
    "        elseif ($key.VirtualKeyCode -eq 40 -and $idx -lt $Items.Count - 1) { $idx++ }" ^
    "        elseif ($key.VirtualKeyCode -eq 13) { Write-Host ''; return $Items[$idx] }" ^
    "    }" ^
    "}" ^
    "$foundPaths = @();" ^
    "foreach ($a in $apps) {" ^
    "    $gp = Get-GamePath $a.exe;" ^
    "    if ($gp) { $foundPaths += [PSCustomObject]@{ Game=$a.name; Path=$gp; LName=$a.lName; LExe=$a.lExe; LProc=$a.lProc; ExeShort=$a.exe.Replace('.exe','') } }" ^
    "}" ^
    "if ($foundPaths.Count -eq 0) { Write-Host ' [i] Игры не найдены.' -ForegroundColor Red; exit }" ^
    "$foundPaths += [PSCustomObject]@{ Game='[91m[ ОТМЕНА ]'; Path=$null };" ^
    "$sel = Show-ConsoleMenu -Title '[?] Выберите вариант стрелочками:' -Items $foundPaths;" ^
    "if ($sel -and $sel.Path) {" ^
    "    if (Get-Process $sel.ExeShort -ErrorAction SilentlyContinue) {" ^
    "        Write-Host ' [i] Игра уже запущена' -ForegroundColor Yellow;" ^
    "        Set-GamePriority $sel.ExeShort;" ^
    "        &$eof_delay; exit" ^
    "    }" ^
    "    $lp = Get-PathFast $sel.LExe;" ^
    "    if (-not (Get-Process $sel.LProc -ErrorAction SilentlyContinue)) {" ^
    "        if ($lp) {" ^
    "            Write-Host ('[>] Запуск лаунчера ' + $sel.LName + '...') -ForegroundColor Cyan; Start-Process $lp;" ^
    "            if (Wait-Launcher $sel.LProc) { Write-Host '[>] Запуск игры...' -ForegroundColor Green; Start-Process $sel.Path }" ^
    "        } else { Write-Host ' [i] Лаунчер не найден.' -ForegroundColor Red }" ^
    "    } else { Write-Host '[>] Лаунчер активен. Запуск...' -ForegroundColor Green; Start-Process $sel.Path }" ^
    "    Set-GamePriority $sel.ExeShort;" ^
    "    &$eof_delay" ^
    "}"
rem goto endfunc
goto ask



:kill-wotb
cls
echo [96m[ [93m- - - Чистим процессы (wotb/wgc/lgc) - - - [96m][0m

echo.
choice /C "10" /m "[93m[?] Подтвердите [91mЗАВЕРШЕНИЕ [93mвсех процессов игры и лаунчеров. Это может вызвать сбои^![0m"
if "!errorlevel!"=="1" (echo [90mподтверждено[0m)
if "!errorlevel!"=="2" (goto ask)

:: Список процессов для завершения
set "array=TanksBlitz.exe;wotblitz.exe;lgc.exe;wgc.exe"
set !array!="!array:;=" "!"

echo.
echo [90mЗавершаем процессы...[0m
set count=0
for %%p in (!array!) do (
    set item=%%~p
    tasklist /fi "ImageName eq !item!" 2>NUL | find /i "!item!" >NUL
    if not errorlevel 1 (
        taskkill /f /t /im !item! >nul 2>&1
        echo [90m * процесс : "!item!" - убит[0m
        set /a count+=1
    )
)
if "%count%" lss "1" (echo [90m[i] Процессы не были найдены[0m) else (echo [90mГотово[0m)
goto endfunc



:network-diagnostics
echo [96m[ [93m- - - Сетевая диагностика - - - [96m][0m

echo.
echo [93m[i] [36mЭтот процесс может занять некоторое время[0m

call :check-routing-services
call :check-vpn-adapters
call :network-diag-via-pwsh

:end-of-net-diag
echo.
echo [92mДиагностика завершена[0m
echo [0m[i] Каждый пункт без "ok" означает - предупреждение. Это означает, что вы можете воспользоваться поиском в интернете, для детального решения каждой сетевой проблемы со стороны вашей системы[0m
exit /b


:check-routing-services
echo.
set "count=0"
set "array=VPN;tun;tap;WARP;cFosSpeed;WinDivert;zapret;winws"
set !array!="!array:;=" "!"
for %%a in (!array!) do (
    for /f "tokens=*" %%i in ('sc query ^| findstr /I "%%a"') do (
        set /a "count+=1"
    )
)
if "%count%" geq "1" (
    echo [91m[^^!] [93mОбнаружены потенциальные службы, которые могут влиять на пинг (и на все тесты^), если они в активном состоянии:
    for %%a in (!array!) do (
        sc query | findstr /I "%%a">nul && (
            echo [90mFound item with: "%%a"[96m
            sc query | findstr /I "%%a"
        )
    )
) else (
    echo [92m[ok][90m Routing Services
)
set count=

:: System Proxy
echo.
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable | findstr "0x1" >nul
if "!errorlevel!"=="0" (
    echo [91m[^^!] [93mВключен системный прокси-сервер. Это может исказить пинг[0m
) else (
    echo [92m[ok][90m system proxy
)
exit/b


:check-vpn-adapters
echo.
set "count=0"
set "array=vpn;warp;wireguard;wg;awg;tunnel;tun;tap;wintun;tailscale;zerotier;openvpn;sing-box"
for %%i in (!array!) do (
    netsh interface show interface | findstr /I "%%i" | findstr /i "Enabled">nul && (
        set /a count+=1
    )
)
if "%count%" geq "1" (
    echo [91m[^^!] [93mОбнаружены активные VPN-адаптеры. Они могут влиять на пинг и на тесты:
    for %%i in (!array!) do (
        netsh interface show interface | findstr /I "%%i" | findstr /i "Enabled">nul && (
            echo [90mFound item matching: "%%i"
            echo  {Admin State} / {State} / {Type} / {Interface Name} [96m
            netsh interface show interface | findstr /I "%%i" | findstr /i "Enabled"
        )
    )
) else (
    echo [92m[ok] [90mNo VPN Adapters found
)
exit/b


:network-diag-via-pwsh
echo.&echo [94m[ [36m- - - Перехожу к powershell проверкам - - - [94m]&echo [0m[90m
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference = 'SilentlyContinue';" ^
 "function W-Ok($m) { Write-Host ('[92m[ok][90m ' + $m) };" ^
 "function W-Wn($m) { Write-Host ('[93m[^!] ' + $m) };" ^
 "function W-Er($m) { Write-Host ('[91m[^!^!^!][93m ' + $m) };" ^
 "" ^
 "Write-Host '[*] Waiting for adapter and driver to stabilize' -NoNewline;" ^
 "$ready = $false; for ($i=0; $i -lt 30; $i++) {" ^
 "  $if = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' -and (Get-NetRoute -InterfaceIndex $_.InterfaceIndex -DestinationPrefix '0.0.0.0/0') } | Select-Object -First 1;" ^
 "  if ($if) { $ready = $true; break };" ^
 "  Write-Host '.' -NoNewline; Start-Sleep -Seconds 1;" ^
 "}" ^
 "Write-Host '';" ^
 "if (-not $ready) { W-Er 'Active adapter with Internet access not found.'; exit };" ^
 "$ad = Get-NetAdapter -InterfaceIndex $if.InterfaceIndex;" ^
 "Write-Host '';" ^
 "" ^
 "if ($ad.PhysicalMediaType -match '802.11|Wireless') { W-Wn 'You are using Wi-Fi. Ethernet is recommended for gaming.' } else { W-Ok 'Ethernet connection detected.' };" ^
 "Write-Host '';" ^
 "if ($if.NlMtu -lt 1500) { W-Wn ('Low MTU: ' + $if.NlMtu + ' (norm 1500). Possible fragmentation.') } else { W-Ok ('MTU: ' + $if.NlMtu) };" ^
 "Write-Host '';" ^
 "" ^
 "Write-Host 'Checking DNS latency...';" ^
 "$srvs = Get-DnsClientServerAddress -InterfaceIndex $if.InterfaceIndex -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses -Unique;" ^
 "foreach ($dns in $srvs) {" ^
 "  Write-Host ('[*] ' + $dns.PadRight(25)) -NoNewline;" ^
 "  $sw = [Diagnostics.Stopwatch]::StartNew(); $success = $false;" ^
 "  for($j=0; $j -lt 2; $j++) { if (Resolve-DnsName google.com -Server $dns -QuickTimeout -ErrorAction SilentlyContinue) { $success = $true; break } }" ^
 "  $ms = [int]$sw.Elapsed.TotalMilliseconds;" ^
 "  if ($success) {" ^
 "    if ($ms -gt 100) { Write-Host ('[91mSLOW (' + $ms + ' ms)') } else { Write-Host ('[92mOK (' + $ms + ' ms)') }" ^
 "  } else { Write-Host '[91mDNS FAIL' }" ^
 "}" ^
 "Write-Host '';" ^
 "" ^
 "Write-Host 'Checking RSS (Receive Side Scaling)...';" ^
 "$sysRss = (Get-NetOffloadGlobalSetting).ReceiveSideScaling;" ^
 "$nicRss = Get-NetAdapterRss -Name $ad.Name -ErrorAction SilentlyContinue | Where-Object { $_.Enabled };" ^
 "if ($sysRss -eq 'Enabled' -and $nicRss) { W-Ok 'RSS: Fully Enabled (Global + NIC)' } else { W-Wn 'RSS: Limited or mismatched configuration' };" ^
 "Write-Host '';" ^
 "" ^
 "Write-Host 'Checking RSC (Receive Segment Coalescing)...';" ^
 "$sysRsc = (Get-NetOffloadGlobalSetting).ReceiveSegmentCoalescing;" ^
 "$nicRsc = Get-NetAdapterRsc -Name $ad.Name -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Enabled };" ^
 "if ($sysRsc -eq 'Disabled' -and -not $nicRsc) { W-Ok 'RSC: Fully Disabled (Optimal for Games)' } " ^
 "else { " ^
 "  $nStat = if ($nicRsc) { 'Enabled' } else { 'Disabled' }; " ^
 "  W-Wn ('RSC: Active (Global:' + $sysRsc + ' / NIC:' + $nStat + ')') " ^
 "};" ^
 "Write-Host '';" ^
 "" ^
 "Write-Host 'Checking Driver Optimizations...';" ^
 "$adv = Get-NetAdapterAdvancedProperty -Name $ad.Name -ErrorAction SilentlyContinue;" ^
 "$flow = $adv | Where-Object { $_.DisplayName -match 'Flow|потоком' -or $_.RegistryKeyword -eq 'FlowControl' };" ^
 "if ($flow) { if ($flow.DisplayValue -match 'Disabled|Off|Выкл|none') { W-Ok 'Flow Control: Disabled' } else { W-Wn 'Flow Control: Enabled' } } else { W-Ok 'Flow Control: Not supported' };" ^
 "" ^
 "$intM = $adv | Where-Object { $_.RegistryKeyword -eq 'InterruptModeration' -or $_.DisplayName -match 'Interrupt|Модерация' };" ^
 "if ($intM) { if ($intM.DisplayValue -match 'Disabled|Off|Выкл') { W-Ok 'Interrupt Moderation: Disabled' } else { W-Wn 'Interrupt Moderation: Enabled' } } else { W-Ok 'Interrupt Moderation: Not supported' };" ^
 "Write-Host '';" ^
 "" ^
 "$tcpK = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\' + $ad.InterfaceGuid;" ^
 "if (Test-Path $tcpK) {" ^
 "  $taf = (Get-ItemProperty $tcpK -Name TcpAckFrequency -ErrorAction SilentlyContinue).TcpAckFrequency;" ^
 "  if ($taf -eq 1) { W-Ok 'TCP Ack Frequency: Optimized (1)' } else { W-Wn 'TCP Ack Frequency: Default' };" ^
 "} else { W-Wn 'TCP Ack Frequency: Registry path not found' };" ^
 "Write-Host '';" ^
 "" ^
 "$cpu = (Get-CimInstance Win32_Processor).LoadPercentage;" ^
 "if ($cpu -gt 80) { W-Er ('CPU Load: ' + $cpu + '%%') } else { W-Ok ('CPU Load: ' + $cpu + '%%') };"
exit/b


:: end of a function
:endfunc
echo.&echo [36m[!time!] Выполнение завершено^^!
if !exaf!==1 (endlocal&exit/b)
echo Нажмите любую кнопку, чтобы вернуться в главное меню...[0m
pause>nul&endlocal&cls
goto :ask


:restart
cls
endlocal
start "" /b cmd /c "%~f0"
exit


:wf
:: Запуск Windows Firewall...
start WF.msc
goto ask


:github
:: opening github...
explorer "https://github.com/N3M1X10/wotb-csm"
goto ask


:close
endlocal
exit
