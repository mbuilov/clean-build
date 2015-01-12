@echo off

rem find .top
setlocal
for %%x in (. .. ..\.. ..\..\.. ..\..\..\.. ..\..\..\..\.. ..\..\..\..\..\.. ..\..\..\..\..\..\.. ..\..\..\..\..\..\..\.. ..\..\..\..\..\..\..\..\..) do if exist %%x\.top (
	set XX=%%x
	goto :run
)
echo could not find .top
exit /B 1

:run
rem get absolute path to directory with .top file
pushd %XX%
set XX=%CD%
popd

rem replace \ with / in path to .top
:repeat
for /f "tokens=1* delims=\" %%i in ("%XX%") do (
	set XX=%%j
	if defined XX (
		set XX=%%i/%%j
		goto repeat
	) else (
		set XX=%%i
	)
)
endlocal & set TOP=%XX%

gnumake.exe %*
