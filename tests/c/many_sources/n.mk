#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# make list of generated sources

# included by: gen.mk, lib.mk

# will generate 1000 sources
n := 1
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n

# temporary counter
c:=

# make list of generated sources: $(gen_dir)/tests/c/many_sources/f0.c $(gen_dir)/tests/c/many_sources/f1.c ...
generated := $(patsubst %,$(gen_dir)/tests/c/many_sources/%.c,$(foreach i,$n,f$(words $c)$(eval c+=1)))
