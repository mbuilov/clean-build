@echo off

rem find .top
setlocal
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
echo could not find .top
exit /B 1

:run
rem get absolute path to directory with .top file
pushd %XX%
set XX=%CD%
popd

rem replace \ with / in path to .top
endlocal & set TOP=%XX:\=/%

gnumake.exe %*
