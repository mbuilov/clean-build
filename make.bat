@rem helper for auto-setting %TOP% environment variable:
@rem look for .top file in top-level directories

@echo off

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
echo could not find .top in current directory or in parent directories"
exit /B 1

:run
rem get absolute path to directory with .top file
pushd %XX%
set XX=%CD%
popd

rem replace \ with / in path to .top
endlocal & set TOP=%XX:\=/%

gnumake.exe %*
