@echo off
chcp 65001 >nul
set name=RCMKV Tools&set version=v0.0
setlocal&cd /d "%~dp0"
title %name%   "%cd%"


:Start                            
set "SelectedThing=%~f1"
set "SelectedThingPath=%~dp1"
call :Config-Varset
call :Setup
if defined Context goto Input-Context

:Intro                            
echo. 
goto Options-Input

:Options                          
echo.&echo.&echo.&echo.
if defined timestart call :timer-end
set "timestart="
if defined Context (
	if %exitwait% GTR 99 (
		echo.&echo.
		echo %TAB%%g_%%processingtime% Press Any Key to Close this window.
		endlocal
		pause>nul&exit
	)
	echo %TAB%%g_%%processingtime% This window will close in %ExitWait% sec.
	endlocal
	ping localhost -n %ExitWait% >nul&exit
)

:Options-Input                    
echo %g_%--------------------------------------------------------------------------------------------------
title %name% %version%   "%cd%"

:Input-Command                    
for %%F in ("%cd%") do set "FolderName=%%~nxF"
if not defined OpenFrom set "FolderName=%cd%"
set "Command=(none)"
set /p "Command=%_%%w_%%FolderName%%_%%gn_%>"
set "Command=%Command:"=%"
echo %-% &echo %-% &echo %-%

if /i "%Command%"=="keyword"		goto FI-Keyword

if exist "%Command%" set "input=%command:"=%"&goto directInput
goto Input-Error


:Input-Context                    
title %name% %version% ^| "%SelectedThing%"
set Dir=cd /d "%SelectedThing%"
set SetIMG=set "img=%SelectedThing%"
cls
echo. &echo. &echo.
REM Other
if /i "%Context%"=="MKV.Cover-Delete"		goto MKV-Cover-Delete
if /i "%Context%"=="MKV.Subtitle-Merge"	goto MKV-Subtitle-Merge
if /i "%Context%"=="MKV.Extract"			goto MKV-Extract
if /i "%Context%"=="MP4.to.MKV"				goto MKV-Convert
if /i "%Context%"=="AVI.to.MKV"				goto MKV-Convert
if /i "%Context%"=="TS.to.MKV"				goto MKV-Convert
if /i "%Context%"=="SRT.Rename"				set "SubtitleExtension=srt"&goto SUB-Rename
if /i "%Context%"=="ASS.Rename"				set "SubtitleExtension=ass"&goto SUB-Rename
if /i "%Context%"=="XML.Rename"				set "SubtitleExtension=xml"&goto SUB-Rename
if /i "%Context%"=="FI.Deactivate" 			set "Setup=Deactivate" &goto Setup
goto Input-Error

:Input-Error                      
echo %TAB%%TAB%%r_% Invalid input.  %_%
echo.
if defined Context echo %ESC%%TAB%%TAB%%i_%%r_%%Context%%_%
if not defined Context echo %ESC%%TAB%%TAB%%i_%%r_%%Command%%_%
echo.
echo %TAB%%g_%The command, file path, or directory path is unavailable. 
rem echo %TAB%Use %gn_%Help%g_% to see available commands.
goto options



:MKV-Cover-Delete
call :Timer-start
echo %TAB%    %i_%  Deleting MKV Cover..  %_%
echo.
FOR %%K in (%xSelected%) do (
	echo %TAB%%c_%🎞%ESC%%c_%%%~nxK%ESC%
	PUSHD "%%~dpK" || echo %i_%%r_%  FAIL to PUSHD..  %_%
		"%MKVPROPEDIT%" "%%~nxK"	--delete-attachment name:cover.jpg  --delete-attachment name:cover.png ^
									--delete-attachment name:cover.jpeg --delete-attachment name:cover.gif ^
									--delete-attachment name:cover.tiff --delete-attachment name:cover.webp ^
									--delete-attachment name:cover.bmp --delete-attachment name:cover.svg ^
									--delete-attachment name:cover >nul
		MKVPROPEDIT.exe |exit /b
	POPD
)
echo.
echo %TAB%   %i_%%cc_%  Done!  %_%
goto options

:MKV-Convert
call :Timer-start
echo %TAB%    %i_%  Converting to MKV..  %_%
echo.
for %%M in (%xSelected%) do (
	for %%X in (%VideoSupport%) do (
		if /i "%%~xM"=="%%X" (
			set "MP4name=%%~nxM"
			set "size_B=%%~zM"
			set "display=NOTMKV"
			call :FileSize
			call :MKV-Convert-display
			PUSHD "%%~dpM" || echo %i_%%r_%  FAIL to PUSHD..  %_%
				start /wait "%%~nxM" cmd.exe /c echo.^&echo.^&echo. ^
				^&echo %TAB%%cc_%Converting..%_% ^
				^&echo  "%c_%%%~nxM%_%"%gg_% ^
				^&"%MKVmerge%" -o "%%~nM.mkv" "%%~nxM"
			POPD
			if exist "%%~dpnM.mkv" (
				for %%K in ("%%~dpnM.mkv") do (
					set "MKVname=%%~nxK"
					set "size_B=%%~zK"
					set "display=MKV"
					call :FileSize
					call :MKV-Convert-display
				)
			) else (echo %TAB%%r_%%i_%Convert Fail!%_% "%%~nxM")
		)
	)
)
echo.
echo %TAB%   %i_%%cc_%  Done!  %_%
goto options

:MKV-Convert-display
if "%display%"=="MKV" (
	echo %TAB%%c_%🎞%ESC%%MKVname% %pp_%%size%%_% %g_%(%size_B% Bytes)%ESC%
) else (
	echo %TAB%%gg_%🎞%ESC%%MP4name% %pp_%%size%%_% %g_%(%size_B% Bytes)%ESC%
)
exit /b

:MKV-Subtitle-Merge
call :Timer-start
set MKVMergeSeparator=echo %_%-------------------------------------------------------------------------%_%
echo %TAB%    %i_%  Merging subtitle into MKV..  %_%
echo.
REM Detecting font..
for %%S in (%xSelected%) do (set "MKVpath=%%~dpS")
cd /d "%MKVpath%"
call :MKV-Subtitle-Font
echo.

REM Get MKV List
for %%S in (%xSelected%) do (
	if /i "%%~xS"==".mkv" (
		set "MKVname=%%~nS"
		set "MKVdir=%%~dpS__"
		set "size_B=%%~zS"
		call :FileSize
		call :MKV-Subtitle-merge_process
	)
)
echo       %_%%i_%   Done!   %_%
goto options

:MKV-Subtitle-merge_process
set "MKVDisplay=yes"
set MKVfileDisplay=%c_%🎞%ESC%%c_%%MKVname%.mkv%_% %pp_%%size% %g_%(%size_B% Bytes)%ESC%
set MKVfileDisplay_=%c_%🎞%ESC%%c_%%MKVname%.mkv%_% %pp_%%size% %g_%(%size_B% Bytes)%ESC%
PUSHD "%MKVdir:\__=%" || echo %i_%%r_% PUSH DIRECTORY FAIL! -^>%_%"%MKVdir%"

REM Search subtitle
set /a Found=0
for %%X in (%SubtitleSupport%) do (

	REM Search Sub with the same name.

	if exist "%MKVname%.%%X" (
		set /a Found+=1
		set "subLang=%subLanguage%"
		set "subFound=%MKVname%.%%X"
		call :MKV-Subtitle-display_sub
		set subtitleSet= ^
		--language			0:%subLanguage% ^
		--track-name		0:"%SubName%" ^
		--default-track	0:%SubSetAsDefault% ^
		--forced-display-flag 0:%SubForcedDisplay% ^
		"%MKVname%.%%X" 
	)

	REM Search Sub with the same name with language Tag.

	for %%S in ("%MKVname%__*.%%X") do (
		set /a Found+=1
		set "subFormat=.%%X"
		set "subFound=%%S"
		set "subLang=%%S"
		call :MKV-Subtitle-get_language
		call :MKV-Subtitle-display_sub
	)
)

if %Found% LSS 1 (
	%MKVMergeSeparator%
	echo %MKVfileDisplay_%
	echo %r_%📄 %g_%No subtitles matched the MKV file name.%_%
	%MKVMergeSeparator%
	echo.&echo.
	POPD&exit /b
)

echo %_%Subtitle found ^(%gn_%%Found%%_%^), %_%Adding subtitle into MKV ..%g_%
"%MKVMERGE%" -o "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" "%MKVname%.mkv" %subtitleSet%
if exist "%MKVname%.xml" (
	echo %_%Chapters found: "%MKVname%.xml"
	set AddChapters=--chapters "%MKVname%.xml"
	)
if exist "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" if defined AddFonts (
	echo %_%Fonts found ^(%gn_%%FontFound%%_%^), Adding fonts and chapters into MKV ..%g_%
	"%MKVPROPEDIT%" "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" %AddFonts% %AddChapters%
	if defined AddFonts1 "%MKVPROPEDIT%" "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" %AddFonts1% >nul
	if defined AddFonts2 "%MKVPROPEDIT%" "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" %AddFonts2% >nul
	if defined AddFonts3 "%MKVPROPEDIT%" "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" %AddFonts3% >nul
	if defined AddFonts4 "%MKVPROPEDIT%" "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" %AddFonts4% >nul
)

if exist "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" (
	for %%O in ("%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv") do (
		set "size_B=%%~zO" 
		call :FileSize
	)
)
if exist "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" echo %cc_%Success: %cc_%🎞%ESC%%yy_%%SubFileNamePrefix%%cc_%%MKVname%%yy_%%SubFileNameSuffix%%cc_%.mkv%_% %pp_%%size% %g_%(%size_B% Bytes)%ESC%
if not exist "%SubFileNamePrefix%%MKVname%%SubFileNameSuffix%.mkv" echo %r_%Fail!%_% %g_%Make sure it has a valid "name" and a valid "language id".%_%
echo.&echo.
POPD&exit /b

:MKV-Subtitle-display_sub
%MKVMergeSeparator%
for %%F in ("%subFound%") do (
	set "size_B=%%~zF"
	call :FileSize
)
if /i "%MKVDisplay%"=="yes" if found GEQ 1 echo %MKVfileDisplay%
if /i "%MKVDisplay%"=="yes" if found LSS 1 echo %MKVfileDisplay_%
set "MKVDisplay=no"
echo %yy_%📄%ESC%%yy_%%subFound%%_% %pp_%%size% %g_%(%size_B% Bytes)%_%%ESC%
echo %ESC%  %g_%Name:%w_%%SubName%	%g_%Language:%w_%%subLang%	%g_%Default:%w_%%SubSetAsDefault%	%g_%Force:%w_%%SubForcedDisplay%%ESC%
%MKVMergeSeparator%
exit /b

:MKV-Subtitle-get_language
call set "subLang=%%Sublang:%MKVname%__=%%"
call set "subLang=%%Sublang:%SubFormat%=%%"
set subtitleSet= %subtitleSet%^
	--language			0:"%subLang%" ^
	--track-name		0:"%SubName%" ^
	--default-track	0:"%SubSetAsDefault%" ^
	"%subFound%"
exit /b

:MKV-Subtitle-Font
set "FontFound=0"
if exist "fonts" (
	PUSHD "fonts"
		for %%F in (*.ttf,*.otf) do (
			set /a FontFound+=1
			set "Font=%%~fF"
			call :MKV-Subtitle-Font-Collect
		)
	POPD
)
if %FontFound% GEQ 1 (
	echo %_%Fonts detected%ESC%(%gg_%%FontFound%%_%).%ESC%
	echo Fonts will be added into MKV.
)
exit /b

:MKV-Subtitle-Font-Collect
if %fontfound% GEQ 200 (
	set AddFonts4=%AddFonts4% --add-attachment "%Font%"
	exit /b
	)
if %fontfound% GEQ 150 (
	set AddFonts3=%AddFonts3% --add-attachment "%Font%"
	exit /b
	)
if %fontfound% GEQ 100 (
	set AddFonts2=%AddFonts2% --add-attachment "%Font%"
	exit /b
	)
if %fontfound% GEQ 50 (
	set AddFonts1=%AddFonts1% --add-attachment "%Font%"
	exit /b
	)
set AddFonts=%AddFonts% --add-attachment "%Font%"
exit /b



:MKV-Extract
echo %TAB%    %i_%  Extracting MKV..  %_%
echo.
for %%S in (%xSelected%) do (set "MKVpath=%%~dpS")
cd /d "%MKVpath%"
echo.

REM Get MKV List
for %%S in (%xSelected%) do (
	if /i "%%~xS"==".mkv" (
		set "MKVname=%%~nS"
		set "MKVdir=%%~dpS__"
		set "MKVpath=%%~fS"
		set "size_B=%%~zS"
		call :FileSize
		call :MKV-Extract-Info
	)
)
echo       %_%%i_%   Done!   %_%
goto options

:MKV-Extract-Info
echo %TAB%%ESC%%c_% %MKVname%.mkv %g_%(%pp_%%size%%g_%)%ESC%
for /f "tokens=1,2,3,4 delims=:" %%C in ('call "%MKVinfo%" "%MKVpath%"') do (
	echo "[C]"%%C "[D]"%%D "[E]"%%E "[F]"%%F
)
echo.
exit /b


:SUB-Rename-Collect.VID
if exist "%filename:~0,-4%.%SubtitleExtension%" (
	echo %ESC%%g_%┌%g_%🎞 %g_%%filename%%ESC%
	echo %ESC%%g_%└%g_%📄 %g_%%filename:~0,-4%.%SubtitleExtension% %gn_%✓%g_%%ESC%
	echo.
	exit /b
)
set /a VIDcount+=1
set "VIDfile%VIDcount%=%filename%"
exit /b

:SUB-Rename-Collect.SUB
if exist "%filename:~0,-4%.mkv" exit /b
if exist "%filename:~0,-4%.mp4" exit /b
set /a SUBcount+=1
set "SUBfile%SUBcount%=%filename%"
exit /b


:SUB-Rename-Display
set /a DisplayCount+=1
call set "VIDfile=%%VIDfile%List%%%"
call set "SUBfile=%%SUBfile%List%%%"

if defined SUBfile%List% (
	echo %ESC%┌%c_%🎞 %c_%%VIDfile%%ESC%
	echo %ESC%└%w_%📄 %_%%SUBfile%%ESC%
) else (
	echo %ESC% %c_%🎞 %c_%%VIDfile%%ESC%
	echo %ESC% %c_%   %g_%No subtitle file.%ESC%
)
if not %DisplayCount% EQU %VIDcount% echo.
exit /b

:SUB-Rename-Action
set /a DisplayCount+=1
call set "VIDfile=%%VIDfile%List%%%"
call set "SUBfile=%%SUBfile%List%%%"

if defined SUBfile%List% (
	echo %ESC%┌%c_%🎞 %c_%%VIDfile%%ESC%
	echo %ESC%│%g_%📄 %SUBfile%%ESC%
	echo %ESC%└%w_%📄 %w_%%VIDfile:~0,-4%.%SubtitleExtension%%ESC%
	ren "%SUBfile%" "%VIDfile:~0,-4%.%SubtitleExtension%"
) else (
	echo %ESC% %c_%🎞 %c_%%VIDfile%%ESC%
	echo %ESC% %c_%   %g_%No subtitle file.%ESC%
)
if not %DisplayCount% EQU %VIDcount% echo.
exit /b

:SUB-Rename
for %%D in (%xSelected%) do set "SelectedThingPath=%%~dpD"
cd /d "%SelectedThingPath%"
set ActTitle=SUBTITLE
if /i ".%SubtitleExtension%"==".XML" set set ActTitle=CHAPTER
set separator=echo  %g_%---------------------------------------------------------------------------------%_%

	echo                     %i_%%w_% %ActTitle% AUTO RENAME %_%
	echo               %g_%Rename subtitle to video file name.%_%
	echo.
echo %i_%%cc_%1/2%_%%cc_% %u_%Matching files..                 %_%
echo.
%separator%
set VIDcount=0
for %%L in (*) do (
	set "filename=%%~nxL"
	if /i "%%~xL"==".MKV" call :SUB-Rename-Collect.VID
	if /i "%%~xL"==".MP4" call :SUB-Rename-Collect.VID
	if /i "%%~xL"==".%SubtitleExtension%" call :SUB-Rename-Collect.SUB
)
if %VIDcount% GTR 0 for /L %%F in (1,1,%VIDcount%) do (
	set List=%%F
	if defined VIDfile%%F call :SUB-Rename-Display
) else (
	echo.
	echo.
	echo    %g_%^(No %r_%*%c_%.MKV%g_%, %r_%*%c_%.MP4%g_% found. / No files to be proceed.^)%_%
)
%separator%
if %VIDcount% LSS 1 pause>nul&exit
echo  %i_%%gn_% %_% %g_%Press %cc_%^[A^]%g_% to Confirm. Press %r_%^[B^]%g_% to Cancel.%bk_%
CHOICE /N /C AB
if %errorlevel%==2 exit
echo.
echo.
echo.
echo %i_%%cc_%2/2%_%%cc_% %u_%Renaming files..                 %_%
echo.
%separator%
set DisplayCount=0
for /L %%F in (1,1,%VIDcount%) do (
	set List=%%F
	if defined VIDfile%%F call :SUB-Rename-Action
)
%separator%
echo.
echo    %i_%   Done.   %_%
pause>nul&exit

:FileSize                         
if "%size_B%"=="" set size=0 KB&echo %r_%Error: Fail to get file size!%_% &exit /b
set /a size_KB=%size_B%/1024
set /a size_MB=%size_KB%00/1024
set /a size_GB=%size_MB%/1024
set size_MB=%size_MB:~0,-2%.%size_MB:~-2%
set size_GB=%size_GB:~0,-2%.%size_GB:~-2%
if %size_B% NEQ 1024 set size=%size_B% Bytes
if %size_B% GEQ 1024 set size=%size_KB% KB
if %size_B% GEQ 1024000 set size=%size_MB% MB
if %size_B% GEQ 1024000000 set size=%size_GB% GB
exit /b

:Timer-start
set timestart=%time%
exit /b

:Timer-end
set timeend=%time%
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%timestart%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%timeend%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
 
set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%
 
:: Mission accomplished
set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%
if %mins% lss 1 set "show_mins="
if %mins% gtr 0 set "show_mins=%mins%m "
if %hours% lss 1 set "show_hours="
if %hours% gtr 0 set "show_hours=%hours%h " 
set ExecutionTime=%show_hours%%show_mins%%secs%.%ms%s
set "processingtime=The process took %ExecutionTime% ^|"
exit /b


:Config-Save                      
REM Save current config to config.ini
if exist "%Template%"        (for %%T in ("%Template%")        do set "Template=%%~nT")       else (set "Template=%rcfi%\template\(none).bat")
if exist "%TemplateForICO%"	(for %%T in ("%TemplateForICO%") do set "TemplateForICO=%%~nT") else (set "TemplateForICO=(none)")
if exist "%TemplateForPNG%"	(for %%T in ("%TemplateForPNG%") do set "TemplateForPNG=%%~nT") else (set "TemplateForPNG=insert a template name to use for .png files")
if exist "%TemplateForJPG%"	(for %%T in ("%TemplateForJPG%") do set "TemplateForJPG=%%~nT") else (set "TemplateForJPG=insert a template name to use for .jpg files")
if not defined TemplateIconSize set "TemplateIconSize=Auto"
(
	echo         [RCFI TOOLS CONFIGURATION]
	echo DrivePath="%cd%"
	echo Keyword="%Keyword%"
	echo Keyword-Extension="%Keyword-Extension%"
	echo Template="%Template%"
	echo TemplateForICO="%TemplateForICO%"
	echo TemplateForPNG="%TemplateForPNG%"
	echo TemplateForJPG="%TemplateForJPG%"
	echo TemplateAlwaysAsk="%TemplateAlwaysAsk%"
	echo TemplateTestMode="%TemplateTestMode%"
	echo TemplateTestMode-AutoExecute="%TemplateTestMode-AutoExecute%"
	echo TemplateIconSize="%TemplateIconSize%"
	echo ExitWait="%ExitWait%"
	
)>"%~dp0config.ini"
if /i "%TemplateIconSize%"=="Auto" set "TemplateIconSize="
set "Template=%rcfi%\template\%Template:"=%.bat"
set "TemplateForICO=%rcfi%\template\%TemplateForICO:"=%.bat"
set "TemplateForPNG=%rcfi%\template\%TemplateForPNG:"=%.bat"
set "TemplateForJPG=%rcfi%\template\%TemplateForJPG:"=%.bat"
EXIT /B

:Config-Load                      
REM Load Config from config.ini
if not exist "%~dp0config.ini" call :Config-GetDefault
if exist "%~dp0config.ini" (
	for /f "usebackq tokens=1,2 delims==" %%C in ("%~dp0config.ini") do (set "%%C=%%D")
) else (
	echo.&echo.&echo.&echo.
	echo       %w_%Couldn't load config.ini.   %r_%Access is denied.
	echo       %w_%Try Run As Admin.%_%
	%P5%&%p5%&exit
)
if exist %Preset% (for %%T in (%Template%) do set Template="%%~nT")       
set "DrivePath=%DrivePath:"=%"
set "Keyword=%Keyword:"=%"
set "Keyword-Extension=%Keyword-Extension:"=%"
set "Template=%rcfi%\template\%Template:"=%.bat"
set "TemplateForICO=%rcfi%\template\%TemplateForICO:"=%.bat"
set "TemplateForPNG=%rcfi%\template\%TemplateForPNG:"=%.bat"
set "TemplateForJPG=%rcfi%\template\%TemplateForJPG:"=%.bat"
set "TemplateAlwaysAsk=%TemplateAlwaysAsk:"=%"
set "TemplateTestMode=%TemplateTestMode:"=%"
set "TemplateTestMode-AutoExecute=%TemplateTestMode-AutoExecute:"=%"
set "TemplateIconSize=%TemplateIconSize:"=%"
if /i "%TemplateIconSize%"=="Auto" set "TemplateIconSize="
REM "AlwaysGenerateSample=%AlwaysGenerateSample:"=%"
rem set "RunAsAdmin=%RunAsAdmin:"=%"
set "ExitWait=%ExitWait:"=%"
EXIT /B

:Config-GetDefault                
cd /d "%~dp0"
(
	echo DrivePath="%cd%"
	echo Preset="(none)"
	echo PresetAlwaysAsk="No"
	echo ExitWait="100"
)>"%~dp0config.ini"
EXIT /B


:Config-Varset                    
rem Define color palette and some variables
set "g_=[90m"
set "gg_=[32m"
set "gn_=[92m"
set "u_=[4m"
set "w_=[97m"
set "r_=[31m"
set "rr_=[91m"
set "b_=[34m"
set "bb_=[94m"
set "bk_=[30m"
set "y_=[33m"
set "yy_=[93m"
set "c_=[36m"
set "cc_=[96m"
set "_=[0m"
set "-=[0m[30m-[0m"
set "i_=[7m"
set "p_=[35m"
set "pp_=[95m"
set "ntc_=%_%%i_%%w_% %_%%-%"
set "TAB=   "
set ESC=[30m"[0m
set "AST=%r_%*%_%"                         
set p1=ping localhost -n 1 ^>nul
set p2=ping localhost -n 2 ^>nul
set p3=ping localhost -n 3 ^>nul
set p4=ping localhost -n 4 ^>nul
set p5=ping localhost -n 5 ^>nul
set "RCMKV=%~dp0"
set "RCMKV=%RCMKV:~0,-1%"
set "RCMKVD=%RCMKV%\uninstall.cmd"
set "timestart="

rem Define some variables for MKV Tools
set "mkvpropedit=%RCMKV%\resources\mkvpropedit.exe"
set "mkvmerge=%RCMKV%\resources\mkvmerge.exe"
set "mkvextract=%RCMKV%\resources\mkvextract.exe"
set "mkvinfo=%RCMKV%\resources\mkvinfo.exe"
set "VideoSupport=.mp4,.avi,.ts"
set "SubtitleSupport=srt,sub,ass"
set "SubLanguage=ID"
set "SubName=Bahasa Indonesia"
set "SubSetAsDefault=Yes"
set "SubForcedDisplay=No"
set "SubFileNamePrefix="
set "SubFileNameSuffix=_"
set "ExitWait=100"

exit /b



:Setup                            
if /i "%setup%" EQU "Deactivate" set "setup_select=2" &goto Setup-Choice
if exist "%RCMKV%\resources\deactivating.RCMKV" set "Setup=Deactivate" &set "setup_select=2" &goto Setup-Choice
if exist "%RCMKVD%" (
	for /f "useback tokens=1,2 delims=:" %%S in ("%RCMKVD%") do set /a "InstalledRelease=%%T" 2>nul
	call :Setup-Update
	exit /b
) else echo.&echo.&echo.&set "setup_select=1" &goto Setup-Choice
echo.&echo.&echo.
Goto Setup-Options

:Setup-Update
set /a "CurrentRelease=%version:v0.=%"
if %CurrentRelease% GTR %InstalledRelease% echo Need to update!
exit /b

:Setup-Options                    
echo.&echo.
echo               %i_%     %name% %version%     %_%
echo.
echo            %g_%Activate or Deactivate Folder Icon Tools on Explorer Right Click menus
echo            %g_%Press %gn_%1%g_% to %w_%Activate%g_%, Press %gn_%2%g_% to %w_%Deactivate%g_%, Press %gn_%3%g_% to %w_%Exit%g_%.%bk_%
echo.&echo.
choice /C:123 /N
set "setup_select=%errorlevel%"

:Setup-Choice                     
if "%setup_select%"=="1" (
	echo %g_%Activating RCMKV Tools%_%
	set "Setup_action=install"
	set "HKEY=HKEY"
	goto Setup_process
)
if "%setup_select%"=="2" (
	echo %g_%Deactivating RCMKV Tools%_%
	set "Setup_action=uninstall"
	set "HKEY=-HKEY"
	goto Setup_process
)
if "%setup_select%"=="3" goto options
goto Setup-Options

:Setup_process                   
set "Setup_Write=%~dp0Setup_%Setup_action%.reg"
call :Setup_Writing
if not exist "%~dp0Setup_%Setup_action%.reg" goto Setup_error
echo %g_%Updating shell extension menu ..%_%
regedit.exe /s "%~dp0Setup_%Setup_action%.reg" ||goto Setup_error
del "%~dp0Setup_%Setup_action%.reg"

REM installing -> create "uninstall.bat"
if /i "%setup_select%"=="1" (
	echo cd /d "%%~dp0">"%RCMKVD%"
	echo set "Setup=Deactivate" ^&call "%name%" ^|^|pause^>nul :%version:v0.=%>>"%RCMKVD%"
	echo %w_%%name% %version%  %cc_%Activated%_%
	echo %g_%Folder Icon Tools has been added to the right-click menus. %_%
	if not defined input (goto intro)
)

REM uninstalling -> delete "uninstall.bat"
if /i "%setup_select%"=="2" (
	del "%RCMKV%\resources\deactivating.RCMKV" 2>nul
	if exist "%RCMKVD%" del "%RCMKVD%"
	echo %w_%%name% %version%  %r_%Deactivated%_%
	echo %g_%Folder Icon Tools have been removed from the right-click menus.%_%
if /i "%Setup%"=="Deactivate" set "Setup=Deactivated"
)
if /i "%Setup%"=="Deactivated" %p5%&%p3%&exit
goto options

:Setup_error                      
cls
echo.&echo.&echo.&echo.&echo.&echo.&echo.&echo.
echo            %r_%Setup fail.
echo            %w_%Permission denied.
set "setup="
set "context="
del "%RCMKV%\Setup_%Setup_action%.reg" 2>nul
del "%RCMKV%\resources\deactivating.RCMKV" 2>nul
pause>nul&exit


:Setup_Writing                    
echo %g_%Preparing registry entry ..%_%

rem Escaping the slash using slash
	set "curdir=%~dp0_."
	set "curdir=%curdir:\_.=%"
	set "curdir=%curdir:\=\\%"

rem Multi Select, Separate instance
	set cmd=cmd.exe /c
	set "RCMKVTools=%~f0"
	set RCMKVexe=^&call \"%RCMKVTools:\=\\%\"
	set SCMD=\"%curdir%\\resources\\SingleInstanceAccumulator.exe\" \"-c:cmd /c
	set SRCMKVexe=^^^&set xSelected=$files^^^&call \"\"%RCMKVTools:\=\\%\"\"\"


rem Define registry root
	set RegExBG=%HKEY%_CLASSES_ROOT\Directory\Background\shell
	set RegExDir=%HKEY%_CLASSES_ROOT\Directory\shell
	set RegExImage=%HKEY%_CLASSES_ROOT\SystemFileAssociations\image\shell
	set RegExShell=%HKEY%_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell
	set RegExICNS=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.icns\shell
	set RegExSVG=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.svg\shell
	set RegExMKV=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.mkv\shell
	set RegExMP4=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.mp4\shell
	set RegExAVI=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.avi\shell
	set RegExSRT=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.srt\shell
	set RegExASS=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.ass\shell
	set RegExXML=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.xml\shell
	set RegExTS=%HKEY%_CLASSES_ROOT\SystemFileAssociations\.ts\shell


rem Generating setup_*.reg
(
	echo Windows Registry Editor Version 5.00

	:REG-Context_Menu-MKV-Extract_Subtitle
	echo [%RegExMKV%\RCMKV.MKV.Extract]
	echo "MUIVerb"="Extract MKV"
	echo [%RegExMKV%\RCMKV.MKV.Extract\command]
	echo @="%SCMD% set \"Context=MKV.Extract\"%SRCMKVexe% \"%%1\""

	:REG-Context_Menu-MKV-Cover_Remove
	echo [%RegExMKV%\RCMKV.MKV.RemoveCover-Delete]
	echo "MUIVerb"="Remove MKV Cover"
	echo [%RegExMKV%\RCMKV.MKV.RemoveCover-Delete\command]
	echo @="%SCMD% set \"Context=MKV.Cover-Delete\"%SRCMKVexe% \"%%1\""
	
	:REG-Context_Menu-MKV-Merge_Subtitle
	echo [%RegExMKV%\RCMKV.MKV.Subtitle-Merge]
	echo "MUIVerb"="Merge files into MKV"
	echo [%RegExMKV%\RCMKV.MKV.Subtitle-Merge\command]
	echo @="%SCMD% set \"Context=MKV.Subtitle-Merge\"%SRCMKVexe% \"%%1\""

	:REG-Context_Menu-MP4
	echo [%RegExMP4%\RCMKV.MP4.Convert.to.MKV]
	echo "MUIVerb"="Convert MP4 to MKV"
	echo [%RegExMP4%\RCMKV.MP4.Convert.to.MKV\command]
	echo @="%SCMD% set \"Context=MP4.to.MKV\"%SRCMKVexe% \"%%1\""
	
	:REG-Context_Menu-AVI
	echo [%RegExAVI%\RCMKV.AVI.Convert.to.MKV]
	echo "MUIVerb"="Convert AVI to MKV"
	echo [%RegExAVI%\RCMKV.AVI.Convert.to.MKV\command]
	echo @="%SCMD% set \"Context=AVI.to.MKV\"%SRCMKVexe% \"%%1\""

	:REG-Context_Menu-TS
	echo [%RegExTS%\RCMKV.TS.Convert.to.MKV]
	echo "MUIVerb"="Convert TS to MKV"
	echo [%RegExTS%\RCMKV.TS.Convert.to.MKV\command]
	echo @="%SCMD% set \"Context=TS.to.MKV\"%SRCMKVexe% \"%%1\""

	:REG-Context_Menu-SRT_Rename
	echo [%RegExSRT%\RCMKV.SRT.Rename]
	echo "MUIVerb"="Rename subtitle to video"
	echo [%RegExSRT%\RCMKV.SRT.Rename\command]
	echo @="%SCMD% set \"Context=SRT.Rename\"%SRCMKVexe% \"%%1\""


	:REG-Context_Menu-ASS_Rename
	echo [%RegExASS%\RCMKV.ASS.Rename]
	echo "MUIVerb"="Rename subtitle to video"
	echo [%RegExASS%\RCMKV.ASS.Rename\command]
	echo @="%SCMD% set \"Context=ASS.Rename\"%SRCMKVexe% \"%%1\""

	:REG-Context_Menu-XML_Rename
	echo [%RegExXML%\RCMKV.XML.Rename]
	echo "MUIVerb"="Rename XML to video"
	echo [%RegExXML%\RCMKV.XML.Rename\command]
	echo @="%SCMD% set \"Context=XML.Rename\"%SRCMKVexe% \"%%1\""
	
)>>"%Setup_Write%"
exit /b