@echo off
chcp 65001>nul

:: Source: https://github.com/N3M1X10/wotb-csm

set "arg=%1"
if "%arg%" == "admin" (
title cluster-checker (admin^)
) else (
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/k \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

setlocal
echo [101;93mПроверка кластеров СНГ сервера Tanks Blitz[0m
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
echo [96m[ h / help    - Перейти на страницу GitHub[96m                ][0m
echo [96m[ r / restart - Перезапустить этот пакет[96m ][0m
echo [96m[ x / end     - [31mЗавершить работу[0m[96m                          ][0m[0m
echo.

::Settings
set headcolor=[96m
set bodycolor=[33m
set pls-enter-comm=[31m[      Пожалуйста, введите команду      ][0m
set incorrect-command=[31m[   Некорректная команда   ][0m

:func
set ask=
set /p ask= "[92mВвод: [0m"

::commands trackers
if "%ask%"==""  goto begin
if "%ask%"=="s"     goto begin
if "%ask%"=="start" goto begin

if "%ask%"=="0" goto one-cluster
if "%ask%"=="1" goto one-cluster
if "%ask%"=="2" goto one-cluster
if "%ask%"=="3" goto one-cluster
if "%ask%"=="4" goto one-cluster
if "%ask%"=="5" goto one-cluster

if "%ask%"=="h"      goto help
if "%ask%"=="help"   goto help

::controls trackers
:: close program
if "%ask%"=="x"       exit
if "%ask%"=="X"       exit
if "%ask%"=="end"     exit

::restart program inside one window
if "%ask%"=="r"          goto restart
if "%ask%"=="restart"    goto restart

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

:one-cluster
echo %headcolor%[   Кластер %ask%   ]%bodycolor%
ping login%ask%.tanksblitz.ru
echo.
echo [92m[   ПРОВЕРКА ЗАВЕРШЕНА   ][0m
echo.
goto func

::other commands
:help
echo.
echo ! github
explorer "https://github.com/N3M1X10/wotb-csm/blob/master/cluster-checker-guide.md"
echo.
goto func

:restart
endlocal
cls
cmd /c "%~f0" :
exit

pause
exit