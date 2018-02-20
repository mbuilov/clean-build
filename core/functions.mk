#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# different helper functions - this file is included by $(cb_dir)/core/_defs.mk

ifeq (,$(filter-out undefined environment,$(origin trace_calls)))
include $(dir $(lastword $(MAKEFILE_LIST)))../trace/trace.mk
endif

# hide macro expansions
hide = $(subst $$,$$$$,$1)

# note: assume no newlines and comments in $1
unhide_raw = $(eval unhide_:=$1)$(unhide_)

# note: assume no newlines in $1
unhide_comments = $(call unhide_raw,$(subst \#,\\\#,$1))

# unhide macro expansions
unhide = $(call unhide_comments,$(subst $(newline),$$(newline),$1))

# hide spaces in string
hide_spaces = $(subst $(space),$$(space),$(hide))

# hide tabs in string
hide_tabs = $(subst $(tab),$$(tab),$(hide))

# hide tabs and spaces in string
hide_tab_spaces = $(subst $(tab),$$(tab),$(hide_spaces))

# map [A-Z] -> [a-z]
tolower = $(subst \
  A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst \
  J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst \
  S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

# map [a-z] -> [A-Z]
toupper = $(subst \
  a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst \
  j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst \
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

# return string of spaces to add to given argument to align total argument length to fixed width (8 chars)
# note: cache computed padding values
padto = $(if $(findstring undefined,$(origin $1.^pad)),$(eval $1.^pad:=$$(padto1)))$($1.^pad)

# 1) check number of digits: if $4 > $3 -> $2 > $1
# 2) else if number of digits are equal, check number values
is_less1 = $(if $(filter-out $3,$(lastword $(sort $3 $4))),1,$(if $(filter $3,$4),$(filter-out $1,$(lastword $(sort $1 $2)))))

# compare numbers: check if $1 < $2
# note: assume there are no leading zeros in $1 or $2
is_less = $(call is_less1,$1,$2,$(repl09),$(call repl09,$2))

# replace [0-9] characters with ' 0'
repl090 = $(subst 9, 0,$(subst 8, 0,$(subst 7, 0,$(subst 6, 0,$(subst 5, 0,$(subst \
  4, 0,$(subst 3, 0,$(subst 2, 0,$(subst 1, 0,$(subst 0, 0,$1))))))))))

# compare floating point numbers: check if $1 < $2, e.g. 1.21 < 2.4
# 1) compare integer parts (that must be present)
# 2) if they are equal, compare fractional parts (may be optional)
# note: assume there are no leading zeros in integer parts of $1 or $2
is_less_float6 = $(filter-out $1,$(lastword $(sort $1 $2)))
is_less_float5 = $(subst $(space),,$(wordlist $(words .$1),999999,$2))
is_less_float4 = $(call is_less_float6,$1$(call is_less_float5,$3,$4),$2$(call is_less_float5,$4,$3))
is_less_float3 = $(call is_less_float4,$1,$2,$(repl090),$(call repl090,$2))
is_less_float2 = $(if $(is_less),1,$(if $(filter $1,$2),$(call is_less_float3,$(word 2,$3 0),$(word 2,$4 0))))
is_less_float1 = $(call is_less_float2,$(firstword $1),$(firstword $2),$1,$2)
is_less_float  = $(call is_less_float1,$(subst ., ,$1),$(subst ., ,$2))

# strip leading zeros, e.g. 012 004 -> 12 4
strip_leading0 = $(if $(findstring $(space)0, $1),$(call strip_leading0,$(patsubst 0%,%,$1)),$1)

# sort numbers, e.g. 20 101 2 -> 2 20 101
# 1) find longest number
# 2) add leading zeros to numbers so all numbers will be of the same length
# 3) sort numbers
# 4) strip leading zeros
# note: assume there are no leading zeros in numbers
sort_numbers2 = $(sort $(foreach n,$1,$(subst $(space),,$(wordlist $(words .$(call repl090,$n)),999999,$2))$n))
sort_numbers1 = $(call sort_numbers2,$1,$(subst ., 0,$(lastword $(sort $(repl09)))))
sort_numbers  = $(call strip_leading0,$(sort_numbers1))

# reverse the list, e.g. 2 20 101 -> 101 20 2
# note: may return leading spaces
reverse = $(if $(word 5,$1),$(call reverse,$(wordlist 5,999999,$1))) $(word 4,$1) $(word 3,$1) $(word 2,$1) $(word 1,$1)

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
# note: last 6-th argument of function $1 is empty on first call and $8 on next calls
xargs = $(call xargs1,$1,$2,$3,$(words x $(wordlist 1,$3,$2)),$4,$5,$6,$7,,$8)

# assuming that function $1($(sublist $2 by $3),$4,$5,$6,$7) will return shell command
# generate many shell commands separated by $(newline) - each command will be executed in new subshell
# note: last 6-th argument of function $1 is empty on first call and $(newline) on next calls
xcmd = $(call xargs,$1,$2,$3,$4,$5,$6,$7,$(newline))

# return list $1 without last element
trim = $(wordlist 2,$(words $1),x $1)

# remove duplicates in list $1 preserving order of elements: 1 2 3 2 1 -> 1 2 3
uniq = $(strip $(uniq1))
uniq1 = $(if $1,$(firstword $1) $(call uniq1,$(filter-out $(firstword $1),$1)))

# check if arguments are not equal
neq = $(or $(subst x$1,,x$2),$(subst x$2,,x$1))

# apply multiple pattern substitutions to a text
# $1 - list of patterns
# $2 - replacement
# $3 - text
# example:
#  $(call patsubst_multiple,a% b%,%,a1 b2) -> 1 2
#  $(call patsubst_multiple,%1 %2,%,a1 b2) -> a b
patsubst_multiple = $(if $1,$(call patsubst_multiple,$(wordlist 2,999999,$1),$2,$(patsubst $(firstword $1),$2,$3)),$3)

# delete tails/heads
# $1 - list of tails/heads
# $2 - text
# example:
#  $(call cut_heads,a b,a1 b2) -> 1 2
#  $(call cut_tails,1 2,a1 b2) -> a b
cut_heads = $(call patsubst_multiple,$(addsuffix %,$1),%,$2)
cut_tails = $(call patsubst_multiple,$(addprefix %,$1),%,$2)

# remove last path element
# 1 2 3 -> 1 2, .. .. -> .. .. ..
normp2 = $(if $(filter-out ..,$1),$(trim),$1 ..)

# check last path element: if it is .. then trim it and element before it
# 1 2 .. 3 4 .. -> 1 3
normp1 = $(if $(word 2,$1),$(if $(filter ..,$(lastword $1)),$(call normp2,$(call \
  normp1,$(trim))),$(call normp1,$(trim)) $(lastword $1)), $1)

# normalize path: 1/3//5/.././6/../7 -> 1/3/7
normp = $(if $(filter /%,$1),/)$(subst $(space),/,$(strip $(call normp1,$(filter-out .,$(subst /, ,$1)))))

# find common part of two paths
# note: if returns non-empty result, it will be prefixed by leading /
cmn_path1 = $(if $1,$(if $(subst /$(firstword $1)/,,/$(firstword $2)/),,/$(firstword $1)$(call \
  cmn_path1,$(wordlist 2,999999,$1),$(wordlist 2,999999,$2))))

# find common part of two paths
# $1:     aa/bb/cc/
# $2:     aa/dd/qq/
# result: aa/
# note: add / before $1 and $2 paths - to not strip off leading /
cmn_path = $(patsubst //%,%/,$(call cmn_path1,/$(subst /, ,$1),/$(subst /, ,$2)))

# convert "a/b/c/" -> "../../../"
back_prefix = $(addsuffix /,$(subst $(space),/,$(foreach x,$(subst /, ,$1),..)))

# compute relative path from directory $1 to destination file or directory $2
# $1:     /aa/bb/cc/    - path to current directory
# $2:     /aa/dd/qq/    - path to destination file or directory
# result: ../../dd/qq/  - relative path to destination file or directory from current directory
# note: ensure that $1 and $2 are ended with /
# note: result is empty if $1 and $2 are match exactly
relpath2 = $(call back_prefix,$(1:$3%=%))$(2:$3%=%)
relpath1 = $(call relpath2,$1,$2,$(call cmn_path,$1,$2))
relpath  = $(call relpath1,$(1:/=)/,$(2:/=)/)

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
# 1/2:| 1
# 1/2/3:| 1/2
#
# $1 - list of directories - result of $(split_dirs)
# $2 - prefix to add to all directories
mk_dir_deps = $(subst :|,:| $2,$(addprefix $(newline)$2,$(filter-out %:|,$(join $1,$(call get_dir,$1,:|)))))

# $1 - recursive macro, on first call becomes simple
# $2 - macro value
# for example, if 'my_value' is not defined yet, but it will be defined at time of 'my_macro' call, then:
#  my_macro = $(call lazy_simple,my_macro,$(my_value))
lazy_simple = $(eval $(findstring override,$(origin $1)) $1:=$$2)$($1)

# append/prepend text $2 to a value of variable $1
# note: do not adds a space between joined $1 and $2, unlike operator += does
define_append = $(eval define $1$(newline)$(value $1)$2$(newline)endef)
define_prepend = $(eval define $1$(newline)$2$(value $1)$(newline)endef)

# append/prepend simple (already expanded) text $2 to a value of variable $1
# note: do not adds a space between joined $1 and $2, unlike operator += does
append_simple = $(if $(findstring simple,$(flavor $1)),$(eval $1:=$$($1)$$2),$(define_append))
prepend_simple = $(if $(findstring simple,$(flavor $1)),$(eval $1:=$$2$$($1)),$(define_prepend))

# substitute references to variables with their values in given text
# $1 - text
# $2 - names of variables
# note: assume references to variables $2 are not escaped in $1, e.g.: ---$$(var)--
# note: also may not work correctly for computed variable names, e.g.: ---$(v$(ar))--
subst_var_refs = $(if $2,$(call subst_var_refs,$(subst $$($(firstword $2)),$(value $(firstword $2)),$1),$(wordlist 2,999999,$2)),$1)

# redefine macro $1 partially expanding it - replace references to variables in list $2 with their values
# note: assume references to variables $2 are not escaped in $(value $1), e.g.: ---$$(var)--
# note: also may not work correctly for computed variable names, for example:   ---$(v$(ar))--
expand_partially = $(eval define $1$(newline)$(call subst_var_refs,$(value $1),$2)$(newline)endef)

# remove references to variables from given text
# $1 - text
# $2 - names of variables
# note: assume references to variables $2 are not escaped in $1, e.g.: ---$$(var)--
# note: also may not work correctly for computed variable names, e.g.: ---$(v$(ar))--
remove_var_refs = $(if $2,$(call remove_var_refs,$(subst $$($(firstword $2)),,$1),$(wordlist 2,999999,$2)),$1)

# try to redefine macro as a simple (i.e. non-recursive) variable
# $1 - macro name
# $2 - list of variables to try to substitute with their values in $(value $1)
# 1) check that variables in $2 are all simple
# 2) check that there is no references to other variables in the value of macro $1
# 3) re-define macro $1 as a simple (non-recursive) variable
# note: assume references to variables $2 are not escaped in $(value $1), e.g.: ---$$(var)--
# note: also may not work correctly for computed variable names, for example:   ---$(v$(ar))--
try_make_simple = $(if $(filter $(words $2),$(words $(filter simple,$(foreach =,$2,$(flavor $=))))),$(if \
  $(findstring $$,$(call remove_var_refs,$(value $1),$2)),,$(eval $1:=$$($1))))

# redefine macro $1 so that when expanding, it will give a new value only if current key value matches
#  the predefined one (constant tag), else returns an old value the macro had before it was redefined
#
# $1 - name of redefined macro      (constant string)
# $2 - name of key variable         (global or target-specific, may be a recursive macro)
# $3 - predefined key value         (constant tag, must not contain %)
# $4 - new value of redefined macro (returned only if key value matches tag $3)
#
# note: defines 2 variables:
#  $3^o.$1 - old value of macro $1
#  $3^n.$1 - new value of macro $1
#
# note: 'keyed_redefine' is useful in target-specific context, to suppress
#  inheritance of target-specific variables to dependent goals, e.g.:
#
#  A := 1
#  my_target: K := x
#  my_target: $(call keyed_redefine,A,K,x,2)
#  my_target: my_depend
#  my_depend: K := a
#  my_target:; $(info $@:A=$A) # 2
#  my_depend:; $(info $@:A=$A) # 1
keyed_redefine = $(eval $(if $(findstring simple,$(flavor $1)),$3^o.$1 := $$($1),define $3^o.$1$(newline)$(value \
  $1)$(newline)endef)$(newline)$(if $(findstring $$,$4),define $3^n.$1$(newline)$4$(newline)endef,$3^n.$1 := $$4)$(newline)$(findstring \
  override,$(flavor $1)) $1 = $$(if $$(filter $3,$$($2)),$$($3^n.$1),$$($3^o.$1)))

# protect variables of $(cb_dir)/trace/trace.mk from modification in target makefiles
# note: do not trace calls to these macros
# note: 'cb_protected_vars' variable is used here temporary and will be redefined later
cb_protected_vars = $(call set_global,MAKE_TRACE_IN_COLOR make_trace_in_color \
  empty space tab comment backslash percent comma newline open_brace close_brace keyword_override keyword_define keyword_endef \
  format_traced_value infofn dump_vars dump_max dump_args tracefn encode_traced_var_name trace_calls_template check_if_traced trace_calls)

# protect variables from modification in target makefiles
# note: trace namespace: functions
# note: 'cb_protected_vars' variable is used here temporary and will be redefined later
cb_protected_vars += $(call set_global,hide unhide_raw unhide_comments unhide hide_spaces hide_tabs hide_tab_spaces \
  tolower toupper repl09 repl09AZ padto1 padto is_less1 is_less repl090 \
  is_less_float6 is_less_float5 is_less_float4 is_less_float3 is_less_float2 is_less_float1 is_less_float \
  strip_leading0 sort_numbers2 sort_numbers1 sort_numbers reverse \
  xargs1 xargs xcmd trim uniq uniq1 neq patsubst_multiple cut_heads cut_tails \
  normp2 normp1 normp cmn_path1 cmn_path back_prefix relpath2 relpath1 relpath \
  ver_major ver_minor ver_patch ver_compatible1 ver_compatible \
  get_dir split_dirs1 split_dirs mk_dir_deps lazy_simple \
  define_append=$$1=$$1 define_prepend=$$1=$$1 append_simple=$$1=$$1 prepend_simple=$$1=$$1 \
  subst_var_refs expand_partially=$$1=$$1 remove_var_refs try_make_simple=$$1;$$2=$$1 keyed_redefine,functions)
