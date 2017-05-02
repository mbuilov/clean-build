# to build and test example, just run from this directory

# for linux:

make MTOP=`realpath ../..` OS=LINUX CPU=x86 check

# for windows:

C:\tools\gnumake-4.2.1-x64.exe MTOP="$(abspath ../..)" OS=WINXX CPU=x86 OSVARIANT=WIN7 VS="c:\Program Files (x86)\Microsoft Visual Studio 14.0" WDK="c:\Program Files (x86)\Windows Kits\10" WDK_TARGET="10.0.14393.0" check
