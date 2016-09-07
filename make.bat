@echo off

rem helper for auto-setting %TOP% environment variable:
rem look for .top file in top-level directories

for %%x in (
.
..
..\..
..\..\..
..\..\..\..
..\..\..\..\..
..\..\..\..\..\..
..\..\..\..\..\..\..
..\..\..\..\..\..\..\..
..\..\..\..\..\..\..\..\..
..\..\..\..\..\..\..\..\..\..
..\..\..\..\..\..\..\..\..\..\..
..\..\..\..\..\..\..\..\..\..\..\..
) do if exist %%x\.top (
	set XX=%%x
	goto :run
)
echo could not find .top in current directory or in parent directories"
exit /B 1

:run
rem get absolute path to directory with .top file
pushd %XX%
set XX=%CD%
popd

rem replace \ with / in path to .top
endlocal & set TOP=%XX:\=/%

rem if defined GMAKE variable - path to gnu make executable, use it
if defined GMAKE ("%GMAKE%" %*) else (gnumake.exe %*)
