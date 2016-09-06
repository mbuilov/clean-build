# this file included by $(MTOP)/defs.mk after including $(MTOP)/protection.mk

empty:=
space := $(empty) #
tab   := $(empty)	#
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

# print result $2 of the function $1
infofn = $(info $1: result: =>$(newline)$2)$2

# dump variables from list $1, prefixing output with optional prefix $2, $3 - optional pre-prefix, example:
# $(call dump,VAR1,pr) -> print 'dump: pr:VAR1=xxx => yyy'
dump = $(foreach v,$1,$(info $3dump: $(addsuffix : ,$2)$v$(if $(filter recursive,$(flavor $v)),,:)=$(value $v)))

# trace function call parameters - print function name and parameter values
# add $(trace_params) as the first statement of traced function body, for example: fun = $(trace_params)fn_body
trace_params = $(info params: $$($0) {)$(if $1,$(info $$1=$1))$(if $2,$(info $$2=$2))$(if $3,$(info $$3=$3))$(if \
  $4,$(info $$4=$4))$(if $5,$(info $$5=$5))$(if $6,$(info $$6=$6))$(if $7,$(info $$7=$7))$(if \
  $8,$(info $$8=$8))$(if $9,$(info $$9=$9))$(if $(10),$(info $$10=$(10)))$(if $(11),$(info $$11=$(11)))$(if \
  $(12),$(info $$12=$(12)))$(if $(13),$(info $$13=$(13)))$(if $(14),$(info $$14=$(14)))$(if \
  $(15),$(info $$15=$(15)))$(if $(16),$(info $$16=$(16)))$(if $(17),$(info $$17=$(17)))$(if \
  $(18),$(info $$18=$(18)))$(if $(19),$(info $$19=$(19)))$(if $(20),$(info $$20=$(20)))$(info params: } $$($0))

# helper template for $(trace_calls)
# $1 - macro name
# $2 - names of variables to dump before traced call
# $3 - names of variables to dump after traced call
# note: $1 may be defined as multi-line macro via 'define' directive - replace $(newline)'s with $$(newline)
define trace_calls_template
$(empty)
define $1_traced_
$(value $1)
endef
$1 = $$(info begin: $$$$($1) {)$$(if $$1,$$(info $$$$1=$$1))$$(if $$2,$$(info $$$$2=$$2))$$(if $$3,$$(info $$$$3=$$3))$$(if \
  $$4,$$(info $$$$4=$$4))$$(if $$5,$$(info $$$$5=$$5))$$(if $$6,$$(info $$$$6=$$6))$$(if $$7,$$(info $$$$7=$$7))$$(if \
  $$8,$$(info $$$$8=$$8))$$(if $$9,$$(info $$$$9=$$9))$$(if $$(10),$$(info $$$$10=$$(10)))$$(if $$(11),$$(info $$$$11=$$(11)))$$(if \
  $$(12),$$(info $$$$12=$$(12)))$$(if $$(13),$$(info $$$$13=$$(13)))$$(if $$(14),$$(info $$$$14=$$(14)))$$(if \
  $$(15),$$(info $$$$15=$$(15)))$$(if $$(16),$$(info $$$$16=$$(16)))$$(if $$(17),$$(info $$$$17=$$(17)))$$(if \
  $$(18),$$(info $$$$18=$$(18)))$$(if $$(19),$$(info $$$$19=$$(19)))$$(if $$(20),$$(info $$$$20=$$(20)))$$(call \
  dump,$2,,$1: )$$(info $1: value: =>$$(newline)$$(value $1_traced_))$$(call \
  infofn,$1,$$($1_traced_))$$(call dump,$3,,$1: )$$(info end: } $$$$($1))
$(call CLEAN_BUILD_PROTECT_VARS1,$1)
endef

# replace macros with their trace equivalents
# $1 - macro names
# $2 - names of variables to dump before traced call
# $3 - names of variables to dump after traced call
# note: may also be used for simple variables, for example: $(call trace_calls,Macro,VarPre,VarPost)
trace_calls = $(eval $(foreach f,$1,$(call trace_calls_template,$f,$2,$3)))

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
repl1 = $(subst 0,.,$(subst 1,.,$(subst 2,.,$(subst 3,.,$(subst 4,.,$(subst 5,.,$(subst 6,.,$(subst 7,.,$(subst 8,.,$(subst 9,.,$(subst \
  A,.,$(subst B,.,$(subst C,.,$(subst D,.,$(subst E,.,$(subst F,.,$(subst G,.,$(subst H,.,$(subst \
  I,.,$(subst J,.,$(subst K,.,$(subst L,.,$(subst M,.,$(subst N,.,$(subst O,.,$(subst P,.,$(subst Q,.,$(subst R,.,$(subst \
  S,.,$(subst T,.,$(subst U,.,$(subst V,.,$(subst W,.,$(subst X,.,$(subst Y,.,$(subst Z,.,$1))))))))))))))))))))))))))))))))))))

# to align to 8 chars
padto1 = $(subst .,       ,$(subst ..,      ,$(subst ...,     ,$(subst \
  ....,    ,$(subst .....,   ,$(subst ......,  ,$(subst ......., ,$1)))))))

# return string of spaces to add to given argument to align total argument length to fixed width (8 chars)
padto = $(call padto1,$(repl1))

# call function $1 many times with arguments from list $2 groupped by $3 elements
# and with auxiliary argument $4, separating function calls with $5
xargs = $(call $1,$(wordlist 1,$3,$2),$4)$(if \
  $(word $(words x $(wordlist 1,$3,$2)),$2),$5$(call \
  xargs,$1,$(wordlist $(words x $(wordlist 1,$3,$2)),$(words $2),$2),$3,$4,$5))

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
join_with = $(subst $(space),$2,$(strip $1))

# protect variables from modification in target makefiles
CLEAN_BUILD_PROTECTED += empty space tab comma newline comment \
  infofn dump trace_params trace_calls_template trace_calls \
  unspaces ifaddq qpath tolower toupper repl1 padto1 padto xargs xcmd trim normp2 normp1 normp \
  cmn_path1 cmn_path back_prefix relpath2 relpath1 relpath join_with
