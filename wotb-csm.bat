@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

set "arg=%1"
if "%arg%" == "admin" (
title wotb-csm (admin^)
) else (
    echo [93m[powershell] Requesting admin rights . . .
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/k \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

:ask
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
echo [96mp / ping - Провести диагностику сети и измерить задержку до кластеров[0m
echo [96mwf / firewall - Открыть монитор Windows Defender[0m
echo [96mh / help - Перейти на страницу GitHub[0m
echo.
echo [96mr / restart - [93mПерезапустить этот пакет[0m
echo [96mx / close -[0m [31mЗавершить работу[0m


::Вопрос от функции
echo.
set /p select="[92mВвод:[0m "

if "%select%"=="b"  set act=block& goto cluster-manager
if "%select%"=="ub" set act=unblock& goto cluster-manager

if "%select%"=="ba"  cls & call :block-all & goto :endfunc
if "%select%"=="uba" cls & call :unblock-all & goto :endfunc

if "%select%"=="1" goto rules-create
if "%select%"=="2" goto rules-delete
if "%select%"=="3" goto update-ipset

if "%select%"=="p"    goto check-ping
if "%select%"=="ping" goto check-ping

::controls
if "%select%"=="x"     goto end
if "%select%"=="end"   goto end
if "%select%"=="close" goto end

if "%select%"=="r"       goto restart
if "%select%"=="restart" goto restart

:: open github
if "%select%"=="h"    goto github
if "%select%"=="help" goto github

::   open Windows Firewall
if "%select%"=="wf"       goto :wf
if "%select%"=="firewall" goto :wf

endlocal
goto ask


:update-ipset
cls
echo [93mОбновление списка диапазонов, пожалуйста подождите...

call :unblock-all

cd /d "%~dp0"
echo [36m
:: Запуск обновления данных (можно вынести в отдельный пункт меню "Обновить IP")
powershell -ExecutionPolicy Bypass -File "pwsh\update_ipset.ps1"

echo.
echo [0mГотово^^!

echo.
echo [0mСписок найденных активных доменов и их диапазонов:[0m
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [36m%%a [%%b][0m
)
echo.
echo Найденные домены сохранены (в [96m"%ranges_file%"[0m) и теперь вы можете просто создать/обновить правила в брандмауэре, в главном меню^^![0m

goto endfunc



:rules-create
cls
echo.
choice /C "10" /m "[93mПодтвердите [36mСОЗДАНИЕ [93mправил в брандмауэре"
if "%errorlevel%"=="1" (goto rules-create-y)
if "%errorlevel%"=="2" (goto rules-create-n)
goto endfunc

:rules-create-y
echo.

set rule_description="Правило для блокирования кластеров СНГ сервера игры Tanks Blitz (created in wotb-csm)"

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mНастройка блокировки: %%a [%%b][0m
    
    :: Удаляем старое правило для этого конкретного домена, если оно было
    netsh advfirewall firewall delete rule name="%%a_block" >nul 2>&1
    
    :: Добавляем новое правило
    netsh advfirewall firewall add rule name="%%a_block" description=%rule_description% dir=out action=block remoteip=%%b >nul
    netsh advfirewall firewall add rule name="%%a_block" description=%rule_description% dir=in action=block remoteip=%%b >nul
)

echo.
echo Правила брандмауэра созданы^^!
goto endfunc

:rules-create-n
endlocal
goto ask


:rules-delete
cls
echo.

choice /C "10" /m "[93mПодтвердите [91mУДАЛЕНИЕ [93mправил из брандмауэра"
if "%errorlevel%"=="1" (call :rules-delete-y)
if "%errorlevel%"=="2" (call :rules-delete-n)
goto endfunc


:rules-delete-y
echo.

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mУдаление правила: %%a [%%b][0m
    :: Удаляем старое правило для этого конкретного домена, если оно было
    netsh advfirewall firewall delete rule dir=out name="%%a_block" >nul 2>&1
    netsh advfirewall firewall delete rule dir=in name="%%a_block" >nul 2>&1
)

echo.
echo Правила в брандмауэре удалены^^!
exit /b

:rules-delete-n
endlocal
goto ask



:block-all
:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [0mБлокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=yes >nul
    netsh advfirewall firewall set rule name="%%a_block" dir=in new enable=yes >nul
)
echo Все кластера заблокированы^^!
exit /b


:unblock-all
:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [0mРазблокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=no >nul
    netsh advfirewall firewall set rule name="%%a_block" dir=in new enable=no >nul
)
echo Все кластера разблокированы^^!
exit /b



:cluster-manager
cls
echo.
if "%act%"=="block" (
    echo [96m[ [91m--- БЛОКИРОВКА КЛАСТЕРА ---[96m ][0m
    echo.
    set rule_state=yes
) else (
    echo [96m[ [92m--- РАЗБЛОКИРОВКА КЛАСТЕРА ---[96m ][0m
    echo.
    set rule_state=no
)

:: Проверка наличия файла данных
set "ranges_file=%~dp0pwsh\ip_map_ru.txt"
if not exist "%ranges_file%" (
    echo [91mОшибка: Сначала обновите базу IP диапазонов^^![0m
    goto endfunc
)

:: Включаем локальные переменные, чтобы не засорять память
setlocal enabledelayedexpansion
set count=0

:: Сбор и вывод доменов
for /f "usebackq tokens=1 delims=:" %%a in ("%ranges_file%") do (
    if not defined seen_%%a (
        set /a count+=1
        set "cluster[!count!]=%%a"
        set "seen_%%a=1"
        echo [0m[!count!] %%a[0m
    )
)

if %count%==0 (
    echo [91mСписок доменов пуст[0m
    endlocal
    goto endfunc
)

echo.
set /p c_choice="Выберите номер (0 для отмены): "

if "%c_choice%"=="0" endlocal & goto ask
if not defined cluster[%c_choice%] (
    echo [91mНеверный выбор^^![0m
    endlocal
    >nul timeout /t 1
    goto cluster-manager
)

:: Извлекаем выбранный домен
set "sel_domain=!cluster[%c_choice%]!"
:: Изменяем правило
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=out new enable=%rule_state% >nul 2>&1
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=in new enable=%rule_state% >nul 2>&1

echo.
if "%act%"=="block" (
    echo [0mКластер !sel_domain! заблокирован^^![0m
) else (
    echo [0mКластер !sel_domain! разблокирован^^![0m
)

endlocal
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
endlocal
goto ask



:end
endlocal
exit



:check-ping
cls
echo.
echo [93m[ --- ПРОВЕРКА ЗАДЕРЖКИ КЛАСТЕРОВ (PING) --- ] [0m

set "domains_file=%~dp0pwsh\domains_ru.txt"
if not exist "%domains_file%" (
    echo  [91mОшибка: Файл доменов не найден! [0m
    goto endfunc
)

echo.
call :unblock-all
call :network-diagnostics

echo.
echo [96mПожалуйста, подождите. Идет опрос серверов... [0m
echo.

:: Однострочник PowerShell: читает файл, пингует каждый домен и выводит результат
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-Content '%domains_file%' | ForEach-Object { " ^
        "$res = Test-Connection -ComputerName $_ -Count 2 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average;" ^
        "if ($res.Average) {" ^
            "$ms = [Math]::Round($res.Average);" ^
            "if ($ms -lt 60) { $color = '[92m' } elseif ($ms -lt 120) { $color = '[93m' } else { $color = '[91m' };" ^
            "Write-Host (' {0} {1}ms' -f $_.PadRight(30), $ms) -ForegroundColor ([ConsoleColor]::Cyan);" ^
        "} else {" ^
            "Write-Host (' {0} ОШИБКА ДОСТУПА' -f $_.PadRight(30)) -ForegroundColor Red;" ^
        "}" ^
    "}"

echo.
echo [0mПроверка завершена^^!
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
echo.
echo [93mЗапуск сетевой диагностики...[0m
:: VPN
echo.
sc query | findstr /I "VPN">nul
if !errorlevel!==0 (
    echo [91m[^^!] Обнаружены службы VPN[0m
    echo [93m[совет] Они могут повлиять на этот тест. Убедитесь что они отключены[0m
) else (
    echo [ok] VPN
)

:: WARP
echo.
sc query | findstr /I "WARP">nul
if !errorlevel!==0 (
    echo.
    echo [91m[^^!] Обнаружен WARP[0m
    echo [93m[совет] Он может повлиять на тест. Убедитесь что он выключен[0m
) else (
    echo [ok] WARP
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

::Ethernet
echo.
powershell -Command "if ((Get-NetAdapter | Where-Object {$Status -eq 'Up'}).MediaConnectionState -contains 'Wireless') { exit 1 } else { exit 0 }"
if !errorlevel!==1 (
    echo [93m[совет] Вы используете Wi-Fi. Для минимальной задержки рекомендуется Ethernet[0m
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

:: Проверка фоновых закачек (BITS)
echo.
powershell -NoProfile -Command ^
 "if (Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue|Where-Object {$_.State -eq 'Transferring'}) {" ^
    "Write-Host '[91m[^^!] Идет фоновая загрузка обновлений/файлов^^![0m'" ^
    "} else {" ^
        "Write-Host '[0m[ok] Канал не занят системными загрузками[0m'"^
    "}"

:: Проверка загрузки CPU (если проц загружен на 100%, пинг тоже будет скакать)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$c = Get-Counter '\Processor(_Total)\%% Processor Time' -SampleInterval 1 -MaxSamples 1;" ^
 "$v = [Math]::Round($c.CounterSamples[0].CookedValue);" ^
 "if ($v -gt 80) { Write-Host ('[91m[!] CPU Load: {0}%% - High[0m' -f $v) }" ^
 "else { Write-Host ('[0m[ok] CPU Load: {0}%%[0m' -f $v) }"

echo.
echo Диагностика завершена
exit /b



:: end of a function
:endfunc
echo.&echo [36m[!time!] Выполнение завершено^^!
if !exaf!==1 (endlocal&exit/b)
echo Нажмите любую кнопку чтобы вернуться в главное меню...[0m
pause>nul&endlocal&cls
goto :ask


