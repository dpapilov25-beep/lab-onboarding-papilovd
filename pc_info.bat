@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem =============================
rem Шаг 7: Временная метка и инициализация
rem =============================
set "timestamp=%date% %time%"
set "report_file=pc_report.txt"

rem Очистка старых данных перед началом
if exist "%report_file%" del "%report_file%"

rem =============================
rem Шаг 2: Подпрограмма вывода (логирования)
rem =============================
:log
rem %~1 берет текст без кавычек, защищая от спецсимволов
echo %~1
echo %~1>>"%report_file%"
exit /b

rem =============================
rem Основной блок
rem =============================
call :log "========================================"
call :log "Аудит рабочего места. Отчет сформирован: %timestamp%"
call :log "========================================"
call :log ""

rem =============================
rem Шаг 3: Сбор данных о системе с защитой
rem =============================
call :log "[СБОР ДАННЫХ О СИСТЕМЕ]"

rem Очистка переменных
set "os_name="
set "total_ram="
set "disk_c="

rem Сбор ОС
for /f "skip=2 tokens=2*" %%A in ('wmic os get Caption /value 2^>nul') do (
    if defined os_name goto :skip_os
    set "os_name=%%B"
)
:skip_os
if not defined os_name (
    call :log "Операционная система: Данные не получены (возможно, нет прав или wmic недоступен)"
) else (
    call :log "Операционная система: %os_name%"
)

rem Сбор ОЗУ (защита от пустоты и деление через PowerShell для надежности)
for /f "skip=2 tokens=2*" %%A in ('wmic ComputerSystem get TotalPhysicalMemory /value 2^>nul') do (
    if defined total_ram goto :skip_ram
    set "total_ram=%%B"
)
:skip_ram
if not defined total_ram (
    call :log "Оперативная память: Данные не получены"
) else (
    for /f "delims=" %%R in ('powershell -NoProfile -Command "[math]::Round(%total_ram%/1GB, 2)"') do set "total_ram_gb=%%R"
    call :log "Оперативная память: %total_ram_gb% ГБ"
)

rem Сбор диска C
for /f "skip=3 tokens=3" %%A in ('wmic logicaldisk where "DeviceID='C:'" get Size /value 2^>nul') do (
    if defined disk_c goto :skip_disk
    set "disk_c=%%A"
)
:skip_disk
if not defined disk_c (
    call :log "Диск C: Данные не получены"
) else (
    for /f "delims=" %%D in ('powershell -NoProfile -Command "[math]::Round(%disk_c%/1GB/1024, 2)"') do set "disk_c_gb=%%D"
    call :log "Диск C (объем): %disk_c_gb% ГБ"
)
call :log ""

rem =============================
rem Шаг 4: Сбор списка установленных программ
rem =============================
call :log "[АНАЛИЗ УСТАНОВЛЕННОГО ПО]"
set "temp_file=%temp%\apps_list.txt"
if exist "%temp_file%" del "%temp_file%"

rem Опрос 64-битных программ
for /f "tokens=2,*" %%A in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s /v DisplayName ^| find "REG_SZ"') do (
    echo %%B>>"%temp_file%"
)
rem Опрос 32-битных программ
for /f "tokens=2,*" %%A in ('reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /s /v DisplayName ^| find "REG_SZ"') do (
    echo %%B>>"%temp_file%"
)

rem Удаление дубликатов и сортировка (требует сортировки, если есть)
sort "%temp_file%" /O "%temp_file%"
call :log "Список программ для анализа собран."
call :log ""

rem =============================
rem Шаг 5: Рекомендации по недостающему ПО
rem =============================
call :log "[РЕКОМЕНДАЦИИ: НЕДОСТАЮЩЕЕ БАЗОВОЕ ПО]"

rem Массивы для поиска (через переменные, так как в .bat нет массивов)
set "office_found=0"
set "browser_found=0"
set "pdf_found=0"
set "archiver_found=0"
set "antivirus_found=0"

for /f "usebackq delims=" %%P in ("%temp_file%") do (
    set "prog=%%P"
    rem Офис
    if /i "!prog!"=="Microsoft Office" set "office_found=1"
    if /i "!prog:~0,8!"=="LibreOff" set "office_found=1"
    if /i "!prog:~0,7!"=="МойОфис" set "office_found=1"
    rem Браузеры
    if /i "!prog:~0,6!"=="Google" set "browser_found=1"
    if /i "!prog:~0,7!"=="Firefox" set "browser_found=1"
    if /i "!prog:~0,4!"=="Edge" set "browser_found=1"
    if /i "!prog:~0,6!"=="Яндекс" set "browser_found=1"
    rem PDF
    if /i "!prog:~0,7!"=="Acrobat" set "pdf_found=1"
    if /i "!prog:~0,4!"=="Foxit" set "pdf_found=1"
    if /i "!prog:~0,10!"=="SumatraPDF" set "pdf_found=1"
    rem Архиваторы
    if /i "!prog:~0,5!"=="7-Zip" set "archiver_found=1"
    if /i "!prog:~0,6!"=="WinRAR" set "archiver_found=1"
    rem Антивирусы
    if /i "!prog:~0,8!"=="Kaspersky" set "antivirus_found=1"
    if /i "!prog:~0,3!"=="ESET" set "antivirus_found=1"
    if /i "!prog:~0,7!"=="Dr.Web" set "antivirus_found=1"
    if /i "!prog:~0,8!"=="Windows Defender" set "antivirus_found=1"
)

if "!office_found!"=="0" call :log "Рекомендация: Не обнаружен офисный пакет. Рекомендуется установить LibreOffice или МойОфис."
if "!office_found!"=="1" call :log "Офисный пакет: Требование выполнено."

if "!browser_found!"=="0" call :log "Рекомендация: Не обнаружен браузер. Рекомендуется установить Яндекс.Браузер или Firefox."
if "!browser_found!"=="1" call :log "Браузер: Требование выполнено (системный Edge не учитывается как результат настройки)."

if "!pdf_found!"=="0" call :log "Рекомендация: Не обнаружено ПО для чтения PDF. Рекомендуется SumatraPDF."
if "!pdf_found!"=="1" call :log "Чтение PDF: Требование выполнено."

if "!archiver_found!"=="0" call :log "Рекомендация: Не обнаружен архиватор. Для работы с вложениями рекомендуется 7-Zip."
if "!archiver_found!"=="1" call :log "Архиватор: Требование выполнено."

if "!antivirus_found!"=="0" call :log "Рекомендация: Не обнаружен сторонний антивирус. Проверьте активность Windows Defender."
if "!antivirus_found!"=="1" call :log "Антивирус: Требование выполнено."
call :log ""

rem =============================
rem Шаг 6: Рекомендации по излишнему ПО
rem =============================
call :log "[РЕКОМЕНДАЦИИ: ИЗЛИШНЕЕ ПО (ПРОВЕРКА)]"

rem Группы признаков
set "found_games="
set "found_torrents="
set "found_personal_messengers="

for /f "usebackq delims=" %%P in ("%temp_file%") do (
    set "prog=%%P"
    rem Игры
    if /i "!prog:~0,5!"=="Steam" set "found_games=!prog!"
    if /i "!prog:~0,9!"=="Epic Games" set "found_games=!prog!"
    if /i "!prog:game!" NEQ "!prog!" set "found_games=!prog!"
    rem Торренты
    if /i "!prog:torrent!" NEQ "!prog!" set "found_torrents=!prog!"
    if /i "!prog:uTorrent!" NEQ "!prog!" set "found_torrents=!prog!"
    rem Личные мессенджеры
    if /i "!prog:~0,7!"=="Discord" set "found_personal_messengers=!prog!"
    if /i "!prog:~0,8!"=="Telegram" set "found_personal_messengers=!prog!"
    if /i "!prog:~0,6!"=="WhatsApp" set "found_personal_messengers=!prog!"
)

if defined found_games (
    call :log "Обнаружено игровое ПО: !found_games!"
    call :log "Рекомендация: Игровые платформы создают нагрузку на систему. Подлежит проверке."
) else (
    call :log "Игровое ПО: Не обнаружено."
)

if defined found_torrents (
    call :log "Обнаружен торрент-клиент: !found_torrents!"
    call :log "Рекомендация: Торрент-клиенты создают нагрузку на сеть. Подлежит проверке."
) else (
    call :log "Торрент-клиенты: Не обнаружены."
)

if defined found_personal_messengers (
    call :log "Обнаружен личный мессенджер: !found_personal_messengers!"
    call :log "Рекомендация: Проверьте, согласовано ли использование с политикой ИБ."
) else (
    call :log "Личные мессенджеры: Не обнаружены."
)
call :log ""

rem =============================
rem Шаг 7: Завершение
rem =============================
call :log "========================================"
call :log "Аудит завершен. Отчет сохранен в: %cd%\%report_file%"
call :log "========================================"
pause

rem Шаг 7: Очистка временных файлов
if exist "%temp_file%" del "%temp_file%"

endlocal
exit /b
