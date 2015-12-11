# this file included by make_defs.mk

empty :=
space := $(empty) $(empty)
tab   := $(empty)	$(empty)
comma := ,
define newline
$(empty)
$(empty)
endef
newline := $(newline)

# run via $(MAKE) T=1 to trace functions
ifeq ("$(origin T)","command line")
TRACE := $T
endif

# 0 -> $(empty)
TRACE := $(TRACE:0=)

ifdef TRACE

# dump variables from list $1, prefixing output with optional prefix $2, example:
#
# $(call dump,VAR1 VAR2,pr) -> print 'pr:VAR1=xxx => yyy'
#                           -> print 'pr:VAR2=nnn => mmm'
#
dump = $(foreach v,$1,$(info dump: $(addsuffix :,$2)$v=$(value $v)$(if $(filter-out simple,$(flavor $v)), => $($v))))

# trace function call - print function name and parameter values, example:
# $(trace)$(fn)            -> print 'fn()'
# $(trace1)$(call fn1,a)   -> print 'fn1(a)'
# $(trace2)$(call fn2,a,b) -> print 'fn2(a,b)'
# ...
trace = $(info trace: $0())
trace1 = $(info trace: $0($1))
trace2 = $(info trace: $0($1,$2))
trace3 = $(info trace: $0($1,$2,$3))
trace4 = $(info trace: $0($1,$2,$3,$4))
trace5 = $(info trace: $0($1,$2,$3,$4,$5))

# helper template for will_trace...() functions
# $1 - function name
# $2 - number of args
define will_trace_template
$1_traced_ = $(value $1)
$1 = $$(call dump,$3)$$(trace$2)$$($1_traced_)
CLEAN_BUILD_PROTECTED += $1_traced_
endef

# replace function with its trace equivalent
# $1 - function name
# $2 - optional list of variables to dump before function call
will_trace = $(eval $(call will_trace_template,$1,$2))
will_trace1 = $(eval $(call will_trace_template,$1,1,$2))
will_trace2 = $(eval $(call will_trace_template,$1,2,$2))
will_trace3 = $(eval $(call will_trace_template,$1,3,$2))
will_trace4 = $(eval $(call will_trace_template,$1,4,$2))
will_trace5 = $(eval $(call will_trace_template,$1,5,$2))

else # !TRACE

dump:=
trace:=
trace1:=
trace2:=
trace3:=
trace4:=
trace5:=
will_trace:=
will_trace1:=
will_trace2:=
will_trace3:=
will_trace4:=
will_trace5:=

endif # !TRACE

# replace spaces with ?
unspaces = $(subst $(space),?,$1)

# add quotes if argument has embedded space
# if called like $(call ifaddq,a b) gives "a b"
# if called like $(call ifaddq,ab) gives ab
ifaddq = $(if $(word 2,$1),"$1",$1)

# convert back ? to spaces in paths adding some prefix
# if called like $(call qpath,a?b cd,-I) gives -I"a b" -Icd
qpath = $(foreach x,$1,$2$(call ifaddq,$(subst ?, ,$x)))

# map [A-Z] -> [a-z]
tolower = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst \
  I,i,$(subst J,i,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst \
  S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

# map [a-z] -> [A-Z]
toupper = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst \
  i,I,$(subst i,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst \
  s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

# replace [A-Z] characters with .
repl1 = $(subst A,.,$(subst B,.,$(subst C,.,$(subst D,.,$(subst E,.,$(subst F,.,$(subst G,.,$(subst H,.,$(subst \
  I,.,$(subst J,.,$(subst K,.,$(subst L,.,$(subst M,.,$(subst N,.,$(subst O,.,$(subst P,.,$(subst Q,.,$(subst R,.,$(subst \
  S,.,$(subst T,.,$(subst U,.,$(subst V,.,$(subst W,.,$(subst X,.,$(subst Y,.,$(subst Z,.,$1))))))))))))))))))))))))))

# to align to 8 chars
padto1 = $(subst .,       ,$(subst ..,      ,$(subst ...,     ,$(subst \
  ....,    ,$(subst .....,   ,$(subst ......,  ,$(subst ......., ,$1)))))))

# return string of spaces to add to given argument to align total argument length to fixed width (8 chars)
padto = $(call padto1,$(repl1))

# call function $1 many times with arguments from list $2 groupped by $3 elements
# and with auxiliary argument $4, separating function calls with $5
xargs = $(call $1,$(wordlist 1,$3,$2),$4)$(if \
         $(word $(words 1 $(wordlist 1,$3,$2)),$2),$5$(call \
          xargs,$1,$(wordlist $(words 1 $(wordlist 1,$3,$2)),$(words $2),$2),$3,$4,$5))

# assuming that function $1($(sublist $2),$4) will return shell command
# generate many shell commands separated by $(newline) - each command will be executed in new subshell
xcmd = $(call xargs,$1,$2,$3,$4,$(newline))

# return list $1 without last element
trim = $(wordlist 2,$(words $1),x $1)

# 1 2 3 -> 1 2, .. .. -> .. .. ..
normp2 = $(if $(filter-out ..,$1),$(trim),$1 ..)

# 1 2 .. 3 4 .. -> 1 3
normp1 = $(if $(word 2,$1),$(if $(filter ..,$(lastword $1)),$(call normp2,$(call \
  normp1,$(trim))),$(call normp1,$(trim)) $(lastword $1)), $1)

# normalize path: 1/3//5/.././6/../7 -> 1/3/7
normp = $(if $(filter /%,$1),/)$(subst $(space),/,$(strip $(call normp1,$(filter-out .,$(subst /, ,$1)))))

# find common part of two paths
# note: if returns non-empty result, it will be prefixed by leading /
cmn_path1 = $(if $(filter $(firstword $1),$(firstword $2)),/$(firstword $1)$(call \
  cmn_path1,$(wordlist 2,999999,$1),$(wordlist 2,999999,$2)))

# find common part of two paths
# $1:     aa/bb/cc/
# $2:     aa/dd/qq/
# result: aa/
# note: add | before $1 and $2 paths - to not stip off leading /
cmn_path = $(patsubst /|%,%/,$(call cmn_path1,$(subst /, ,|$1),$(subst /, ,|$2)))

# convert "a/b/c/" -> "../../../"
back_prefix = $(addsuffix /,$(subst $(space),/,$(foreach x,$(subst /, ,$1),..)))

# compute relative path from directory $1 to destination file or directory $2
# $1:     /aa/bb/cc/    - path to current directory
# $2:     /aa/dd/qq/    - path to destination file or directory
# result: ../../dd/qq/  - relative path to destination file or directory from current directory
# note: ensure that $1 and $2 are ended with /
relpath2 = $(call back_prefix,$(1:$3%=%))$(2:$3%=%)
relpath1 = $(call relpath2,$1,$2,$(call cmn_path,$1,$2))
relpath = $(call relpath1,$(1:/=)/,$(2:/=)/)

# join elements of list $1 with $2
# example: $(call join_with,a b c,|) -> a|b|c
join_with = $(patsubst %$2,%,$(subst $(space),,$(foreach x,$1,$x$2)))

# trace calls to next functions if TRACE defined
$(call will_trace2,qpath)
$(call will_trace4,xcmd)
$(call will_trace1,normp)
$(call will_trace2,relpath)
$(call will_trace2,join_with)

# protect variables from modification in target makefiles
CLEAN_BUILD_PROTECTED += empty space tab comma newline \
  TRACE dump trace trace1 trace2 trace3 trace4 trace5 \
  will_trace_template will_trace will_trace1 will_trace2 will_trace3 will_trace4 will_trace5 \
  unspaces ifaddq qpath tolower toupper repl1 padto1 padto xargs xcmd trim normp2 normp1 normp \
  cmn_path1 cmn_path back_prefix relpath2 relpath1 relpath join_with
