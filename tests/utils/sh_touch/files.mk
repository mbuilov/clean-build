#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by touch.mk and check.mk

# for the 1000 files
n := 1
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n

# list of 1000 files
files := $(eval c:=)$(foreach i,$n,t$(words $c).txt$(eval c+=1))
