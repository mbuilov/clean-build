#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# make list of generated sources

# included by: gen.mk, lib.mk, exe.mk, dll.mk

# where test sources are generated
test_gen_dir := $(gen_dir)/tests/c/many_sources

# will generate 1000 sources
# sequence: 1 1 1 1 ...
n := 1
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n

# sequence: 0 1 2 3 ...
seq := $(eval c:=)$(foreach i,$n,$(words $c)$(eval c+=1))

# make list of generated sources: $(gen_dir)/tests/c/many_sources/f0.c $(gen_dir)/tests/c/many_sources/f1.c ...
generated := $(patsubst %,$(test_gen_dir)/f%.c,$(seq))
