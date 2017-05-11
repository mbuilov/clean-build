# to build and test example, just run from this directory

# for linux:

make OS:=LINUX CPU:=x86 check

# for windows:

C:\tools\gnumake-4.2.1-x64.exe OS:=WINXX CPU:=x86 WINVARIANT:=WIN7 VS:="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017" WDK:="C:\Program Files (x86)\Windows Kits\10" WDK_TARGET:="10.0.15063.0" check
