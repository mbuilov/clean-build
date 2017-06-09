#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/defs.mk after including $(CLEAN_BUILD_DIR)/protection.mk

empty:=
space := $(empty) $(empty)
tab   := $(empty)	$(empty)
comma := ,
define newline
$(empty)
$(empty)
endef
newline := $(newline)
define comment
#
endef
comment := $(comment)
open_brace  := (
close_brace := )
keyword_endef := endef

# print result $1 and return $1
infofn = $(info $1)$1

# dump variables
# $1 - list of variables to dump
# $2 - optional prefix
# $3 - optional pre-prefix
# $(call dump,VAR1,prefix,Q) -> print 'Qdump: prefix: VAR1=xxx'
dump = $(foreach v,$1,$(info $3dump: $(2:=: )$v$(if $(filter recursive,$(flavor $v)),,:)=$(value $v)))

# maximum number of arguments of any macro
dump_max := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30

# set default values for unspecified functions parameters
$(eval override $(subst $(space),:=$(newline)override ,$(dump_max)):=)

# dump function arguments
dump_args := $(foreach i,$(dump_max),:$$(if $$($i),$$(info $$$$$i=$$($i))))
$(eval dump_args = $(subst $(space):,, $(dump_args)))

# trace function call parameters - print function name and parameter values
# - add $(trace_params) as the first statement of traced function body
# example: fun = $(trace_params)fn_body
trace_params = $(warning params: $$($0) {)$(dump_args)$(info params: } $$($0))

# helper template for $(trace_calls)
# $1 - macro name, must accept no more than $(dump_max) arguments
# $2 - names of variables to dump before traced call
# $3 - names of variables to dump after traced call
define trace_calls_template
$(empty)
define $1_t_
$(value $1)
endef
override $1 = $$(warning $$$$($1) {)$$(dump_args)$$(call dump,$2,,$1: )$$(info ------$1 value---->)$$(info \
  $$(value $1_t_))$$(info ------$1 result--->)$$(call infofn,$$(call $1_t_,_dump_params_))$$(call dump,$3,,$1: )$$(info end: } $$$$($1))
$(call CLEAN_BUILD_PROTECT_VARS1,$1 $1_t_)
endef

# replace _dump_params_
$(eval define trace_calls_template$(newline)$(subst _dump_params_,$$$$$(open_brace)$(subst \
  $(space),$(close_brace)$(comma)$$$$$(open_brace),$(dump_max))$(close_brace),$(value trace_calls_template))$(newline)endef)

# replace macros with their trace equivalents
# $1 - traced macro names
# $2 - names of variables to dump before traced call
# $3 - names of variables to dump after traced call
# note: may also be used for simple variables, for example: $(call trace_calls,Macro,VarPre,VarPost)
trace_calls = $(eval $(foreach f,$1,$(call trace_calls_template,$f,$2,$3)))

# replace spaces with ?
unspaces = $(subst $(space),?,$1)

# add quotes if argument has embedded space
# if called like $(call ifaddq,a b) gives "a b"
# if called like $(call ifaddq,ab) gives ab
ifaddq = $(if $(findstring $(space),$1),"$1",$1)

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

# replace [0-9] characters with .
repl09 = $(subst 0,.,$(subst 1,.,$(subst 2,.,$(subst 3,.,$(subst 4,.,$(subst \
  5,.,$(subst 6,.,$(subst 7,.,$(subst 8,.,$(subst 9,.,$1))))))))))

# replace [0-9A-Z] characters with .
repl09AZ = $(call repl09,$(subst \
  A,.,$(subst B,.,$(subst C,.,$(subst D,.,$(subst E,.,$(subst F,.,$(subst G,.,$(subst H,.,$(subst \
  I,.,$(subst J,.,$(subst K,.,$(subst L,.,$(subst M,.,$(subst N,.,$(subst O,.,$(subst P,.,$(subst Q,.,$(subst R,.,$(subst \
  S,.,$(subst T,.,$(subst U,.,$(subst V,.,$(subst W,.,$(subst X,.,$(subst Y,.,$(subst Z,.,$1)))))))))))))))))))))))))))

# return string of spaces to add to given argument to align total argument length to fixed width (8 chars)
padto1 = $(subst .,       ,$(subst ..,      ,$(subst ...,     ,$(subst \
  ....,    ,$(subst .....,   ,$(subst ......,  ,$(subst ......., ,$(repl09AZ))))))))

# cache computed padding values
define padto2
ifeq (undefined,$(origin $1_pad_))
$1_pad_:=$(padto1)
endif
endef

# return string of spaces to add to given argument to align total argument length to fixed width (8 chars)
padto = $(eval $(value padto2))$($1_pad_)

# 1) check number of digits: if $4 > $3 -> $2 > $1
# 2) else if number of digits are equal, check number values
is_less1 = $(if $(filter-out $3,$(lastword $(sort $3 $4))),1,$(if $(filter $3,$4),$(filter-out $1,$(lastword $(sort $1 $2)))))

# compare numbers: check if $1 < $2
# NOTE: assume there are no leading zeros in $1 or $2
is_less = $(call is_less1,$1,$2,$(repl09),$(call repl09,$2))

# $1 - function
# $2 - full arguments list
# $3 - sublist size
# $4 - sublist size + 1 if $2 is big enough
# $5 - auxiliary function argument 1
# $6 - auxiliary function argument 2
# $7 - auxiliary function argument 3
# $8 - auxiliary function argument 4
# $9 - function calls first separator
# $(10) - function calls separator
xargs1 = $(if $2,$9$(call $1,$(wordlist 1,$3,$2),$5,$6,$7,$8,$9)$(call xargs1,$1,$(wordlist $4,999999,$2),$3,$4,$5,$6,$7,$8,$(10),$(10)))

# call function $1 many times with arguments from list $2 grouped by $3 elements
# and with auxiliary arguments $4,$5,$6,$7,$8 separating function calls with $8
# note: last 6-th argument of function $1 is <empty> on first call and $8 on next calls
xargs = $(call xargs1,$1,$2,$3,$(words x $(wordlist 1,$3,$2)),$4,$5,$6,$7,,$8)

# assuming that function $1($(sublist $2 by $3),$4,$5,$6,$7) will return shell command
# generate many shell commands separated by $(newline) - each command will be executed in new subshell
# note: last 6-th argument of function $1 is <empty> on first call and $(newline) on next calls
xcmd = $(call xargs,$1,$2,$3,$4,$5,$6,$7,$(newline))

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
# note: add | before $1 and $2 paths - to not strip off leading /
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
join_with = $(subst $(space),$2,$(strip $1))

# get major, minor or patch number from version string like 1.2.3
# if cannot get needed value, return 0
ver_major = $(firstword $(subst ., ,$1) 0)
ver_minor = $(firstword $(word 2,$(subst ., ,$1)) 0)
ver_patch = $(firstword $(word 3,$(subst ., ,$1)) 0)

# if $1 == $2 {
#   if $3 < 4
#     <empty>
#   else if $3 == $4 {
#     if $5 < $6
#       <empty>
#     else
#       1
#   }
#   else
#     1
# }
# else
#   <empty>
ver_compatible1 = $(if $(filter $1,$2),$(if $(call \
  is_less,$3,$4),,$(if $(filter $3,$4),$(if $(call \
  is_less,$5,$6),,1),1)))

# compare versions $1 and $2:
# - major versions must match
# - minor and patch versions of $1 must not be less than of $2
# returns non-empty string if versions are compatible
ver_compatible = $(call ver_compatible1,$(ver_major),$(call \
  ver_major,$2),$(ver_minor),$(call ver_minor,$2),$(ver_patch),$(call ver_patch,$2))

# get parent directory name of $1 without / at end
# add optional prefix $2 before parent directory
# returns empty directory name prefixed by $2 if no parent directory:
# 1/2/3 -> 1/2
# 1     -> $(empty)
get_dir = $(patsubst $2.,$2,$(patsubst %/,$2%,$(dir $1)))

# split paths to list of intermediate directories: 1/2/3 -> 1 1/2 1/2/3
split_dirs1 = $(if $1,$1 $(call split_dirs1,$(get_dir)))
split_dirs = $(sort $(split_dirs1))

# make child-parent order dependencies for directories
#
# - for list:
# 1 1/2 1/2/3
#
# - produce:
# 1/2: |1
# 1/2/3: |1/2
#
# $1 - list of directories - result of $(split_dirs)
# $2 - prefix to add to all directories
mk_dir_deps = $(subst :|,:| $2,$(addprefix $(newline)$2,$(filter-out %:|,$(join $1,$(call get_dir,$1,:|)))))

# $1 - recursive macro, on first call becomes simple
# $2 - macro value
# for example, if MY_VALUE is not defined yet, but it will be defined at time of MY_MACRO call, then:
# MY_MACRO = $(call lazy_simple,MY_MACRO,$(MY_VALUE))
lazy_simple = $(eval $(filter override,$(origin $1)) $1:=$$2)$($1)

# protect variables from modification in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,empty space tab comma newline comment open_brace close_brace \
  infofn dump dump_max dump_args trace_params trace_calls_template trace_calls \
  unspaces ifaddq qpath tolower toupper repl09 repl09AZ padto1 padto2 padto \
  is_less1 is_less xargs1 xargs xcmd trim normp2 normp1 normp \
  cmn_path1 cmn_path back_prefix relpath2 relpath1 relpath join_with \
  ver_major ver_minor ver_patch ver_compatible1 ver_compatible \
  get_dir split_dirs1 split_dirs mk_dir_deps lazy_simple)
