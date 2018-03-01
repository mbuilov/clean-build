# included by touch.mk and check.mk

# for the 1000 files
n := 1
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n
n := $n $n $n $n $n $n $n $n $n $n

# files list
files := $(eval c:=)$(foreach i,$n,$(g_dir)/t$(words $c).txt$(eval c+=1))
