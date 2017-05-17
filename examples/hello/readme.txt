# to build and test example, just run from this directory

# for Linux:

make OS:=LINUX CPU:=x86 check

# for Windows:

C:\tools\gnumake-4.2.1-x64.exe OS:=WINXX CPU:=x86 WINVARIANT:=WIN7 VS:="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017" WDK:="C:\Program Files (x86)\Windows Kits\10" WDK_TARGET:="10.0.15063.0" check


Tips:
make clean     - delete built files only for given TARGET/OS/CPU combination, except directories
make distclean - delete all built artifacts: files and directories, for all TARGET/OS/CPU combinations
make conf      - save build parameters to generated conf.mk, to not specify them again on next make invocation
