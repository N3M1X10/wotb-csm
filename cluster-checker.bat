@echo off
chcp 65001>nul
setlocal

::Settings
set headcolor=[96m
set bodycolor=[33m
set pls-enter-comm=[31m[      Пожалуйста, введите команду      ][0m
set incorrect-command=[31m[   Некорректная команда   ][0m

::Head
title TanksBlitz Cluster Checker
echo [101;93mTanksBlitz Cluster Checker CIS[0m
echo.
echo [33mВыберите команду:[0m
echo [96m[ s / start - Начать проверку всех кластеров ][0m
echo [96m[ 0 - Начать проверку кластера C0 ][0m
echo [96m[ 1 - Начать проверку кластера C1 ][0m
echo [96m[ 2 - Начать проверку кластера C2 ][0m
echo [96m[ 3 - Начать проверку кластера C3 ][0m
echo [96m[ 4 - Начать проверку кластера C4 ][0m
echo [96m[ 5 - Начать проверку кластера C5 ][0m
echo.
echo [33mДругие опции:[0m
echo [96m[ r / restart - [33mПерезапустить программу внутри этого окна[0m [96m ][0m
echo [96m[ x / end     -[0m [31mЗавершить работу[0m[96m                           ][0m[0m
echo.

:func
set a=
set /p a= "[92mВвод: [0m"

::commands trackers
if "%a%"==""  goto begin
if "%a%"=="s"     goto begin
if "%a%"=="start" goto begin

if "%a%"=="0" goto command0
if "%a%"=="1" goto command1
if "%a%"=="2" goto command2
if "%a%"=="3" goto command3
if "%a%"=="4" goto command4
if "%a%"=="5" goto command5

if "%a%"=="readme" goto help
if "%a%"=="help"   goto help
if "%a%"=="h"      goto help

::controls trackers
:: close program
if "%a%"=="x"       exit
if "%a%"=="X"       exit
if "%a%"=="end"     exit

::restart program inside one window
if "%a%"=="r"          goto restart
if "%a%"=="restart"    goto restart

Echo %incorrect-command%

goto func

:command-missing
Echo %pls-enter-comm%
goto func

::cluster commands

::ALL CLUSTERS CHECK
:begin
echo %headcolor%[   Кластер 0 из 5   ]%bodycolor%
ping login0.tanksblitz.ru
echo.

echo %headcolor%[   Кластер 1 из 5   ]%bodycolor%
ping login1.tanksblitz.ru
echo.

echo %headcolor%[   Кластер 2 из 5   ]%bodycolor%
ping login2.tanksblitz.ru
echo.

echo %headcolor%[   Кластер 3 из 5   ]%bodycolor%
ping login3.tanksblitz.ru
echo.

echo %headcolor%[   Кластер 4 из 5   ]%bodycolor%
ping login4.tanksblitz.ru
echo.

echo %headcolor%[   Кластер 5 из 5   ]%bodycolor%
ping login5.tanksblitz.ru
echo.

echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

::SPLIT CHECK

:command0
echo %headcolor%[   Кластер 0   ]%bodycolor%
ping login0.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

:command1
echo %headcolor%[   Кластер 1   ]%bodycolor%
ping login1.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

:command2
echo %headcolor%[   Кластер 2   ]%bodycolor%
ping login2.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

:command3
echo %headcolor%[   Кластер 3   ]%bodycolor%
ping login3.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

:command4
echo %headcolor%[   Кластер 4   ]%bodycolor%
ping login4.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

:command5
echo %headcolor%[   Кластер 5   ]%bodycolor%
ping login5.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

::other commands
:help
Echo.
Echo [33m Запуск...[0m
rem cd /d readme
start "" "Readme-ECC.txt"
IF %ERRORLEVEL% NEQ 0 (
Echo [31mНе удаётся открыть файл[0m
echo.
goto func
)
Echo [92m Запущен![0m
Echo.
goto func

:restart
cls
cmd /c "%~f0" :
exit

pause
exit