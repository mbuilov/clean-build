# this file included by make_defs.mk

empty :=
space := $(empty) $(empty)
tab   := $(empty)	$(empty)
comma := ,
define newline
$(empty)
$(empty)
endef

# replace spaces with ?
unspaces = $(subst $(space),?,$1)

# add quotes if argument has embedded space
# if called like $(call ifaddq,a b) gives "a b"
# if called like $(call ifaddq,ab) gives ab
ifaddq = $(if $(word 2,$1),"$1",$1)

# convert back ? to spaces in paths adding some prefix
# if called like $(call prefq,-I,a?b cd) gives -I"a b" -Icd
pqpath = $(foreach x,$2,$1$(call ifaddq,$(subst ?, ,$x)))

# convert back ? to spaces in paths
# if called with $(call qpath,a?b cd) gives "a b" cd
qpath = $(foreach x,$1,$(call ifaddq,$(subst ?, ,$x)))

tolower = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst \
  I,i,$(subst J,i,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst \
  S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

toupper = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst \
  i,I,$(subst i,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst \
  s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

# call function $1 many times with arguments from list $2 groupped by $3 elements
# and with auxiliary argument $4, separating function calls with $5
xargs = $(call $1,$(wordlist 1,$3,$2),$4)$(if \
         $(word $(words 1 $(wordlist 1,$3,$2)),$2),$5$(call \
          xargs,$1,$(wordlist $(words 1 $(wordlist 1,$3,$2)),$(words $2),$2),$3,$4,$5))

# assuming that function $1($(sublist $2),$4) will return shell command
# generate many shell commands separated by $(newline) - each command will be executed in new subshell
xcmd = $(call xargs,$1,$2,$3,$4,$(newline))

# $1 - list, $2 - how much to trim + 1
trim = $(wordlist 1,$(words $(wordlist $2,999999,$1)),$1)

normp2 = $(if $(filter-out ..,$1),$(call trim,$1,2),$1 ..)

normp1 = $(if $(word 2,$1),$(if $(filter ..,$(lastword $1)),$(call normp2,$(call normp1,$(call trim,$1,2))),$(call normp1,$(call trim,$1,2)) $(lastword $1)), $1)

# normalize path: 1/3//5/.././6/../7 -> 1/3/7
normp = $(if $(filter /%,$1),/)$(subst $(space),/,$(strip $(call normp1,$(filter-out .,$(subst /, ,$1)))))

# find common parts of two lists
cmn_parts = $1$(if $(filter $(firstword $2),$(firstword $3)),$(call cmn_parts, $(firstword $2),$(wordlist 2,999999,$2),$(wordlist 2,999999,$3)))

# find common part of two paths
cmn_path = $(if $(filter /%,$1),/)$(subst $(space),/,$(strip $(call cmn_parts,,$(subst /, ,$1),$(subst /, ,$2))))

# convert "a/b/c" to "../../../"
back_prefix1 = ../$(if $(word 2,$1),$(call back_prefix1,$(wordlist 2,999999,$1)))
back_prefix = $(if $1,$(call back_prefix1,$(subst /, ,$1)))

# relative cd:
# $1:     /aa/bb/cc     - path to current directory
# $2:     /aa/dd/qq     - path to destination directory
# result: ../../dd/qq   - relative path to destination directory from current directory
reldir1 = $(call back_prefix,$(patsubst $3%,%,$1))$(patsubst /%,%,$(patsubst $3%,%,$2))
reldir = $(call reldir1,$1,$2,$(call cmn_path,$1,$2))
