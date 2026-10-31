@echo off
chcp 65001 >nul
REM ==================================================
REM Практическая работа: Диагностика клиентского компьютера
REM Выполнил: Папилов Д.
REM Дата: 31.10.2026
REM ==================================================

REM Путь к отчёту — папка, где лежит сам bat-файл
set "REPORT=%~dp0pc_report.txt"

REM ---------- Заголовок ----------
echo ==============================================
echo         ДИАГНОСТИКА КОМПЬЮТЕРА
echo ==============================================
echo ============================================== > "%REPORT%"
echo         ДИАГНОСТИКА КОМПЬЮТЕРА >> "%REPORT%"
echo ============================================== >> "%REPORT%"
echo.

REM ---------- Операционная система ----------
echo --- ОПЕРАЦИОННАЯ СИСТЕМА ---
echo. >> "%REPORT%"
echo --- ОПЕРАЦИОННАЯ СИСТЕМА --- >> "%REPORT%"
wmic os get Caption,Version /format:list | findstr "="
wmic os get Caption,Version /format:list | findstr "=" >> "%REPORT%"
echo.

REM ---------- Процессор ----------
echo --- ПРОЦЕССОР ---
echo --- ПРОЦЕССОР --- >> "%REPORT%"
wmic cpu get Name /format:list | findstr "="
wmic cpu get Name /format:list | findstr "=" >> "%REPORT%"
echo.

REM ---------- Оперативная память ----------
echo --- ОПЕРАТИВНАЯ ПАМЯТЬ ---
echo --- ОПЕРАТИВНАЯ ПАМЯТЬ --- >> "%REPORT%"
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:list ^| find "="') do set "TOTAL_KB=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get FreePhysicalMemory /format:list ^| find "="') do set "FREE_KB=%%a"
set "TOTAL_KB=%TOTAL_KB:~0,-1%"
set "FREE_KB=%FREE_KB:~0,-1%"
set /a TOTAL_GB=TOTAL_KB/1048576
set /a FREE_GB=FREE_KB/1048576
echo Всего памяти: %TOTAL_GB% ГБ
echo Свободно памяти: %FREE_GB% ГБ
echo Всего памяти: %TOTAL_GB% ГБ >> "%REPORT%"
echo Свободно памяти: %FREE_GB% ГБ >> "%REPORT%"
echo.

REM ---------- Диск C ----------
echo --- ДИСК C ---
echo --- ДИСК C --- >> "%REPORT%"
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get Size /format:list ^| find "="') do set "SIZE_BYTES=%%a"
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:list ^| find "="') do set "FREE_BYTES=%%a"
set "SIZE_BYTES=%SIZE_BYTES:~0,-1%"
set "FREE_BYTES=%FREE_BYTES:~0,-1%"
set /a DISK_SIZE_GB=SIZE_BYTES/1073741824
set /a DISK_FREE_GB=FREE_BYTES/1073741824
echo Всего на диске: %DISK_SIZE_GB% ГБ
echo Свободно на диске: %DISK_FREE_GB% ГБ
echo Всего на диске: %DISK_SIZE_GB% ГБ >> "%REPORT%"
echo Свободно на диске: %DISK_FREE_GB% ГБ >> "%REPORT%"
echo.

REM ---------- Установленные программы ----------
echo --- УСТАНОВЛЕННЫЕ ПРОГРАММЫ ---
echo --- УСТАНОВЛЕННЫЕ ПРОГРАММЫ --- >> "%REPORT%"
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2>nul | findstr "DisplayName"
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2>nul | findstr "DisplayName" >> "%REPORT%"
reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2>nul | findstr "DisplayName" >> "%REPORT%"
echo.

REM ---------- Завершение ----------
echo Отчёт сохранён: %REPORT%
echo Отчёт сохранён >> "%REPORT%"
pause
