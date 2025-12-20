@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

set "arg=%1"
if "%arg%" == "admin" (
title wotb-csm (admin^)
) else (
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
echo [96mping - Проверить задержку до кластеров[0m
echo [96mwf / firewall - Открыть монитор Windows Defender[0m
echo [96mh / help - Перейти на страницу GitHub[0m
echo.
echo [96mr / restart - [93mПерезапустить этот пакет[0m
echo [96mx / close -[0m [31mЗавершить работу[0m


::Вопрос от функции
echo.
set /p a="[92mВвод:[0m "

if "%a%"=="b" set act=block& goto cluster-manager
if "%a%"=="ub" set act=unblock& goto cluster-manager

if "%a%"=="ba" goto block-all
if "%a%"=="uba" goto unblock-all

if "%a%"=="1" goto rules-create
if "%a%"=="2" goto rules-delete

if "%a%"=="ping" goto check-ping
if "%a%"=="3" goto update-ipset


::controls
if "%a%"=="x"     goto end
if "%a%"=="close" goto end
if "%a%"=="end"   goto end

if "%a%"=="r"       goto restart
if "%a%"=="restart" goto restart

:: open github
if "%a%"=="h"      goto github
if "%a%"=="help"   goto github

::   open Windows Firewall
if "%a%"=="wf"               goto :wf
if "%a%"=="firewall"         goto :wf

::ADD-PROGRAM-TO-EXCLUSIONS tool
if "%a%"=="add" goto addtoexclusions
if "%a%"=="rem" goto removefromexclusions

::	Если команда пустая
if "%a%"=="" goto command-missing

::	Если команда не распознана
Echo %incorrect-command%
goto endfunc

:command-missing
Echo %pls-enter-comm%
goto endfunc


:update-ipset
cls
:: Запуск обновления данных (можно вынести в отдельный пункт меню "Обновить IP")
echo [93mОбновление списка диапазонов, пожалуйста подождите...[96m
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "pwsh\update_ipset.ps1"

echo.
echo [92mГотово^^![0m

echo.&echo [0mСписок найденных активных доменов и их диапазонов:[0m
call :check-ranges-file
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [36m%%a [%%b][0m
)
echo.
echo [92mНайденные домены сохранены (в [96m"%ranges_file%"[92m) и теперь вы можете просто создать/обновить правила в брандмауэре, в главном меню^^![0m

goto endfunc


:::::::::::::::::::::::::::::::::
::Создание правил в брандмауэре::
:::::::::::::::::::::::::::::::::
:rules-create
cls
choice /C "10" /m "[93mПодтвердите СОЗДАНИЕ правил в брандмауэре"
if "%errorlevel%"=="1" (goto create-y)
if "%errorlevel%"=="2" (goto create-n)
goto endfunc

:create-y
echo.

set rule_description="Правило для блокирования кластеров СНГ сервера игры Tanks Blitz (created in wotb-csm)"

call :check-ranges-file

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mНастройка блокировки: %%a [%%b][0m
    
    :: Удаляем старое правило для этого конкретного домена, если оно было
    netsh advfirewall firewall delete rule name="%%a_block" >nul 2>&1
    
    :: Добавляем новое правило
    netsh advfirewall firewall add rule name="%%a_block" description=%rule_description% dir=out action=block remoteip=%%b >nul
    netsh advfirewall firewall add rule name="%%a_block" description=%rule_description% dir=in action=block remoteip=%%b >nul
)


echo [92mПравила брандмауэра созданы^^![0m
goto endfunc

:create-n
echo [31m[   создание правил отклонено   ][0m
goto endfunc



:::::::::::::::::::::::::::::::::
::Удаление правил в брандмауэре::
:::::::::::::::::::::::::::::::::
:rules-delete
cls
choice /C "10" /m "[93mПодтвердите УДАЛЕНИЕ правил в брандмауэре"
if "%errorlevel%"=="1" (goto rules-del-y)
if "%errorlevel%"=="2" (goto rules-del-n)
goto endfunc


:rules-del-y
call :check-ranges-file

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mУдаление правила: %%a [%%b][0m
    :: Удаляем старое правило для этого конкретного домена, если оно было
    netsh advfirewall firewall delete rule dir=out name="%%a_block" >nul 2>&1
    netsh advfirewall firewall delete rule dir=in name="%%a_block" >nul 2>&1
)

echo [92m[  Правила в брандмауэре удалены^^!  ][0m
goto endfunc

:rules-del-n
echo [31m[  удаление отклонено  ][0mx
goto endfunc



:block-all
cls
call :check-ranges-file

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mБлокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=yes >nul
    netsh advfirewall firewall set rule name="%%a_block" dir=in new enable=yes >nul
)
echo [92mВсе кластера заблокированы^^![0m
goto endfunc

:unblock-all
cls
call :check-ranges-file

:: Читаем файл и создаем правила
:: %%a - домен (имя правила), %%b - диапазон (IP/CIDR)
for /f "usebackq tokens=1,2 delims=:" %%a in ("%ranges_file%") do (
    echo [93mРазблокировка: %%a [%%b][0m
    netsh advfirewall firewall set rule name="%%a_block" dir=out new enable=no >nul
    netsh advfirewall firewall set rule name="%%a_block" dir=in new enable=no >nul
)
echo [92mВсе кластера разблокированы^^![0m
goto endfunc



::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::
:cluster-manager
cls
echo.
if "%act%"=="block" (
    echo [96m[ [91m--- БЛОКИРОВКА КЛАСТЕРА --- [96m][0m
    set rule_state=yes
) else (
    echo [96m[ [92m--- РАЗБЛОКИРОВКА КЛАСТЕРА --- [96m][0m
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

:: Сбор доменов
for /f "usebackq tokens=1 delims=:" %%a in ("%ranges_file%") do (
    if not defined seen_%%a (
        set /a count+=1
        set "cluster[!count!]=%%a"
        set "seen_%%a=1"
        echo [96m[!count!] %%a[0m
    )
)

if %count%==0 (
    echo [91mСписок доменов пуст[0m
    endlocal
    goto endfunc
)

echo.
set /p c_choice="Выберите номер (0 для отмены): "

if "%c_choice%"=="0" endlocal & goto endfunc
if not defined cluster[%c_choice%] (
    echo  [91mНеверный выбор^^![0m
    endlocal
    goto cluster-manager
)

:: Извлекаем выбранный домен
set "sel_domain=!cluster[%c_choice%]!"
:: Выполняем команду Firewall
:: Используем префикс WOTB_ для точности
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=out new enable=%rule_state% >nul 2>&1
netsh advfirewall firewall set rule name="!sel_domain!_block" dir=in new enable=%rule_state% >nul 2>&1

echo.
if "%act%"=="block" (
    echo [92mКластер !sel_domain! заблокирован^^![0m
) else (
    echo [92mКластер !sel_domain! разблокирован^^![0m
)

:: Очистка памяти и возврат
endlocal
goto endfunc

::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::



:restart
cls
endlocal
cmd /c "%~f0" :
exit


:wf
Echo [93m[      Запуск Windows Firewall ...      ][0m
start WF.msc
Echo [92m[       Windows Firewall Запущен!       ][0m
goto ask


:github
echo [96m ! github
explorer "https://github.com/N3M1X10/wotb-csm"
goto endfunc



:end
endlocal
exit



:check-ping
echo.
echo [93m[ --- ПРОВЕРКА ЗАДЕРЖКИ КЛАСТЕРОВ (PING) --- ] [0m
echo [91m ^^!^^!^^! НЕ ЗАБУДЬТЕ ОТКЛЮЧИТЬ БЛОКИРОВКУ КЛАСТЕРОВ ПЕРЕД ПРОВЕРКОЙ[0m
set "domains_file=%~dp0pwsh\domains_ru.txt"

if not exist "%domains_file%" (
    echo  [91mОшибка: Файл доменов не найден! [0m
    goto endfunc
)

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
echo [92mПроверка завершена. [0m
goto endfunc



:check-ranges-file
set "ranges_file=%~dp0pwsh\ip_map_ru.txt"
if not exist "%ranges_file%" (
    echo [91mОшибка: Не удалось получить данные об IP[0m
    goto endfunc
)
exit /b



:: end of a function
:endfunc
echo.&echo [!time!] Function has complete
if !exaf!==1 (endlocal&exit/b)
endlocal&pause&cls&goto :ask


