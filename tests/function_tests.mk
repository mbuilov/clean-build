$(info ================ functions ================)

# test functions

c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

include $(c_dir)../core/functions.mk

#######################################
# test 'hide/unhide_raw'

e = 1 $2 3
h := $(call hide,$(value e))

# note: 'unhide_raw' expects no newlines and comments in $1
u := $(call unhide_raw,$h)

ifneq ("$(value e)","$u")
$(error test failed!)
endif

#######################################
# test 'unhide_comments'

e = 1 $2 \# 3 \\#
h := $(call hide,$(value e))

# note: 'unhide_comments' expects no newlines in $1
u := $(call unhide_comments,$h)

ifneq ("$(value e)","$u")
$(error test failed!)
endif

#######################################
# test 'unhide'

define e
1 $2 \#
3 \\#
endef

h := $(call hide,$(value e))
u := $(call unhide,$h)

ifneq ("$(subst $(newline),...,$(value e))","$(subst $(newline),...,$u)")
$(error test failed!)
endif

#######################################
# test 'hide_spaces'

e = 1 $2 \# 3 \\#

h := $(call hide_spaces,$(value e))

ifneq (1,$(words $h))
$(error test failed!)
endif

u := $(call unhide,$h)

ifneq ("$(value e)","$u")
$(error test failed!)
endif

#######################################
# test 'hide_tabs'

e = 1	$2 \# 3 \\#

h := $(call hide_tabs,$(value e))

ifneq (4,$(words $h))
$(error test failed!)
endif

u := $(call unhide,$h)

ifneq ("$(value e)","$u")
$(error test failed!)
endif

#######################################
# test 'hide_tab_spaces'

e = 1	$2 \# 3 \\#

h := $(call hide_tab_spaces,$(value e))

ifneq (1,$(words $h))
$(error test failed!)
endif

u := $(call unhide,$h)

ifneq ("$(value e)","$u")
$(error test failed!)
endif

#######################################
# test 'tolower'

e = 1A B C D E F G H I J K L M N O P Q R S T U V W X Y Z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z2

h := $(call tolower,$(value e))

ifneq ("$h","1a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z2")
$(error test failed!)
endif

#######################################
# test 'toupper'

e = 1a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z2

h := $(call toupper,$(value e))

ifneq ("$h","1A B C D E F G H I J K L M N O P Q R S T U V W X Y Z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z2")
$(error test failed!)
endif

#######################################
# test 'repl09'

e = 0a 1 2m3 z4 5r y678i9

h := $(call repl09,$(value e))

ifneq ("$h",".a . .m. z. .r y...i.")
$(error test failed!)
endif

#######################################
# test 'repl09AZ'

e = A B CDEFGH0aI JKLMN O1PQ R2STmU3 Vz4 W5r XYy678iZ9

h := $(call repl09AZ,$(value e))

ifneq ("$h",". . .......a. ..... .... ....m.. .z. ..r ..y...i..")
$(error test failed!)
endif

#######################################
# test 'padto'

h1 := $(call padto,A)
h2 := $(call padto,AB)
h3 := $(call padto,AB3)
h4 := $(call padto,AB3C)
h5 := $(call padto,AB3CD)
h6 := $(call padto,AB3CD6)
h7 := $(call padto,AB3DE6F)

ifneq ("$(h1)","       ")
$(error test failed!)
endif
ifneq ("$(h2)","      ")
$(error test failed!)
endif
ifneq ("$(h3)","     ")
$(error test failed!)
endif
ifneq ("$(h4)","    ")
$(error test failed!)
endif
ifneq ("$(h5)","   ")
$(error test failed!)
endif
ifneq ("$(h6)","  ")
$(error test failed!)
endif
ifneq ("$(h7)"," ")
$(error test failed!)
endif

#######################################
# test 'isless'

ifneq ("","$(call is_less,0,0)")
$(error test failed!)
endif
ifneq ("","$(call is_less,1,0)")
$(error test failed!)
endif
ifeq ("","$(call is_less,0,1)")
$(error test failed!)
endif
ifneq ("","$(call is_less,1,1)")
$(error test failed!)
endif
ifneq ("","$(call is_less,2,1)")
$(error test failed!)
endif
ifeq ("","$(call is_less,1,2)")
$(error test failed!)
endif
ifneq ("","$(call is_less,100,100)")
$(error test failed!)
endif
ifneq ("","$(call is_less,100,1)")
$(error test failed!)
endif
ifeq ("","$(call is_less,1,100)")
$(error test failed!)
endif
ifneq ("","$(call is_less,200,100)")
$(error test failed!)
endif
ifeq ("","$(call is_less,100,200)")
$(error test failed!)
endif

#######################################
# test 'repl090'

ifneq (" 0a 0 0b","$(call repl090,1a23b)")
$(error test failed!)
endif

#######################################
# test 'is_less_float'

# 1:  0    <->  0
ifneq ("","$(call is_less_float,0,0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1,0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0,1)")
$(error test failed!)
endif

# 2:  0.   <->  0.
ifneq ("","$(call is_less_float,0.,0.)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.,0.)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.,1.)")
$(error test failed!)
endif

# 3:  0.   <->  0
ifneq ("","$(call is_less_float,0.,0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.,0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.,1)")
$(error test failed!)
endif

# 4:  0    <->  0.
ifneq ("","$(call is_less_float,0,0.)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1,0.)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0,1.)")
$(error test failed!)
endif

# 5:  0.0  <->  0.0
ifneq ("","$(call is_less_float,0.0,0.0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.0,0.0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.0,1.0)")
$(error test failed!)
endif

# 6:  0    <->  0.0
ifneq ("","$(call is_less_float,0,0.0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1,0.0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0,1.0)")
$(error test failed!)
endif

# 7:  0.0  <->  0
ifneq ("","$(call is_less_float,0.0,0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.0,0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.0,1)")
$(error test failed!)
endif

# 8:  0.   <->  0.0
ifneq ("","$(call is_less_float,0.,0.0)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.,0.0)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.,1.0)")
$(error test failed!)
endif

# 9:  0.0  <->  0.
ifneq ("","$(call is_less_float,0.0,0.)")
$(error test failed!)
endif
ifneq ("","$(call is_less_float,1.0,0.)")
$(error test failed!)
endif
ifeq ("","$(call is_less_float,0.0,1.)")
$(error test failed!)
endif

ifeq ("","$(call is_less_float,0.33333,2)")
$(error test failed!)
endif

ifeq ("","$(call is_less_float,0.33333,0.4)")
$(error test failed!)
endif

ifneq ("","$(call is_less_float,0.33333,0.2222222)")
$(error test failed!)
endif

#######################################
# test 'strip_leading0'

ifneq ("a 1b 12c","$(call strip_leading0,0a 01b   012c)")
$(error test failed!)
endif

#######################################
# test 'sort_numbers'

ifneq ("2 20 101","$(call sort_numbers,20 101 2)")
$(error test failed!)
endif

#######################################
# test 'reverse'

ifneq ("p o n m l k j i h g f e d c b a","$(strip $(call reverse,a b c d e f g h i j k l m n o p))")
$(error test failed!)
endif

#######################################
# test 'xargs'

fn = <$6>($1)-$2-$3-$4-$5$(if $7,+)

t := $(call xargs,fn,a b c d e f g h i j k l m n o p,3,1,2,3,4,S)

ifneq ("<>(a b c)-1-2-3-4+S<S>(d e f)-1-2-3-4+S<S>(g h i)-1-2-3-4+S<S>(j k l)-1-2-3-4+S<S>(m n o)-1-2-3-4+S<S>(p)-1-2-3-4","$t")
$(error test failed!)
endif

#######################################
# test 'xcmd'

fn = $(if $6,!)($1)-$2-$3-$4-$5$(if $7,+)

t := $(call xcmd,fn,a b c d e f g h i j k l m n o p,3,1,2,3,4)

define e
(a b c)-1-2-3-4+
!(d e f)-1-2-3-4+
!(g h i)-1-2-3-4+
!(j k l)-1-2-3-4+
!(m n o)-1-2-3-4+
!(p)-1-2-3-4
endef

ifneq ("$(value e)","$t")
$(error test failed!)
endif

#######################################
# test 'uniq'

ifneq ("1 2 3","$(call uniq,1 2 3 2 1)")
$(error test failed!)
endif

#######################################
# test 'neq'

ifneq ("","$(call neq,1 2,1 2)")
$(error test failed!)
endif

ifeq ("","$(call neq,1 2,2 3)")
$(error test failed!)
endif

ifeq ("","$(call neq,1 2,1 2 )")
$(error test failed!)
endif

ifeq ("","$(call neq,1 2, 1 2)")
$(error test failed!)
endif

ifeq ("","$(call neq,1 2,1  2)")
$(error test failed!)
endif

#######################################
# test 'patsubst_multiple'

ifneq ("1 2 3 4 5","$(call patsubst_multiple,a% b%,%,a1 b2 a3 b4 a5)")
$(error test failed!)
endif

ifneq ("a b c3 d4 f","$(call patsubst_multiple,%1 %2,%,a1 b2 c3 d4 f1)")
$(error test failed!)
endif

#######################################
# test 'cut_heads'

ifneq ("1 2","$(call cut_heads,a b,a1 b2)")
$(error test failed!)
endif

ifneq ("1a 1 2 c3 d4","$(call cut_heads,a b,1a a1 b2 c3 d4)")
$(error test failed!)
endif

#######################################
# test 'cut_tails'

ifneq ("a b","$(call cut_tails,1 2,a1 b2)")
$(error test failed!)
endif

ifneq ("1a a b c3 d4","$(call cut_tails,1 2,1a a1 b2 c3 d4)")
$(error test failed!)
endif

#######################################
# test 'trim'

ifneq ("a b c d e f g h i j k l m n o","$(call trim,a b c d e f g h i j k l m n o p)")
$(error test failed!)
endif

#######################################
# test 'normp'

ifneq ("1/3/7","$(call normp,1/3//5/.././6/../7)")
$(error test failed!)
endif

ifneq ("/1/3","$(call normp,/./1/2/../3//5/.././6/6/../../7/..)")
$(error test failed!)
endif

#######################################
# test 'cmn_path'

ifneq ("aa/","$(call cmn_path,aa/bb/cc/,aa/dd/qq/)")
$(error test failed!)
endif

ifneq ("a/a/a/a/","$(call cmn_path,a/a/a/a/bb/cc/,a/a/a/a/dd/qq/)")
$(error test failed!)
endif

ifneq ("/aa/bb/","$(call cmn_path,/aa/bb/cc/,/aa/bb/dd/qq/)")
$(error test failed!)
endif

ifneq ("/","$(call cmn_path,/aa/bb/cc/,/aa1/dd/qq/)")
$(error test failed!)
endif

ifneq ("","$(call cmn_path,aa/bb/cc/,aa1/dd/qq/)")
$(error test failed!)
endif

ifneq ("","$(call cmn_path,aa2/bb/cc/,aa1/dd/qq/)")
$(error test failed!)
endif

#######################################
# test 'back_prefix'

ifneq ("../../../","$(call back_prefix,a/b/c/)")
$(error test failed!)
endif

ifneq ("../../../","$(call back_prefix,a x/b y/c/)")
$(error test failed!)
endif

#######################################
# test 'relpath'

ifneq ("../../dd/qq/","$(call relpath,/aa/bb/cc/,/aa/dd/qq/)")
$(error test failed!)
endif

#######################################
# test 'ver_major'

ifneq ("0","$(call ver_major,)")
$(error test failed!)
endif
ifneq ("1","$(call ver_major,1)")
$(error test failed!)
endif
ifneq ("1","$(call ver_major,1.2)")
$(error test failed!)
endif
ifneq ("1","$(call ver_major,1.2.3)")
$(error test failed!)
endif

#######################################
# test 'ver_minor'

ifneq ("0","$(call ver_minor,)")
$(error test failed!)
endif
ifneq ("0","$(call ver_minor,1)")
$(error test failed!)
endif
ifneq ("2","$(call ver_minor,1.2)")
$(error test failed!)
endif
ifneq ("2","$(call ver_minor,1.2.3)")
$(error test failed!)
endif

#######################################
# test 'ver_patch'

ifneq ("0","$(call ver_patch,)")
$(error test failed!)
endif
ifneq ("0","$(call ver_patch,1)")
$(error test failed!)
endif
ifneq ("0","$(call ver_patch,1.2)")
$(error test failed!)
endif
ifneq ("3","$(call ver_patch,1.2.3)")
$(error test failed!)
endif

#######################################
# test 'ver_compatible'

ifeq ("","$(call ver_compatible,1.2.3,1)")
$(error test failed!)
endif

ifneq ("","$(call ver_compatible,1,1.2.3)")
$(error test failed!)
endif

ifeq ("","$(call ver_compatible,1.2.3,1.1)")
$(error test failed!)
endif

ifneq ("","$(call ver_compatible,1.1,1.2.3)")
$(error test failed!)
endif

ifeq ("","$(call ver_compatible,1.2.3,1.2)")
$(error test failed!)
endif

ifneq ("","$(call ver_compatible,1.2,1.2.3)")
$(error test failed!)
endif

ifeq ("","$(call ver_compatible,1.2.3,1.2.3)")
$(error test failed!)
endif

ifneq ("","$(call ver_compatible,2,1.2.3)")
$(error test failed!)
endif

#######################################
# test 'get_dir'

ifneq ("","$(call get_dir,1)")
$(error test failed!)
endif

ifneq ("/1","$(call get_dir,/1/2)")
$(error test failed!)
endif

ifneq ("1/2","$(call get_dir,1/2/)")
$(error test failed!)
endif

ifneq ("/1/2","$(call get_dir,/1/2/)")
$(error test failed!)
endif

#######################################
# test 'split_dirs'

ifneq ("1 1/2 1/2/3","$(call split_dirs,1/2/3)")
$(error test failed!)
endif

ifneq ("/1 /1/2 /1/2/3","$(call split_dirs,/1/2/3)")
$(error test failed!)
endif

ifneq ("/1 /1/2","$(call split_dirs,/1/2)")
$(error test failed!)
endif

ifneq ("1 1/2","$(call split_dirs,1/2)")
$(error test failed!)
endif

ifneq ("1","$(call split_dirs,1)")
$(error test failed!)
endif

#######################################
# test 'mk_dir_deps'

define h
1/2:| 1
1/2/3:| 1/2
endef

ifneq ("$(value h)","$(call mk_dir_deps,1 1/2 1/2/3)")
$(error test failed!)
endif

define h
xx/1/2:| xx/1
xx/1/2/3:| xx/1/2
endef

ifneq ("$(value h)","$(call mk_dir_deps,1 1/2 1/2/3,xx/)")
$(error test failed!)
endif

define h
1/2:| 1
endef

ifneq ("$(value h)","$(call mk_dir_deps,1 1/2)")
$(error test failed!)
endif

define h
/xx/1/2:| /xx/1
endef

ifneq ("$(value h)","$(call mk_dir_deps,1 1/2,/xx/)")
$(error test failed!)
endif

ifneq ("","$(call mk_dir_deps,1,xx/)")
$(error test failed!)
endif

#######################################
# test 'lazy_simple'

a = $(call lazy_simple,a,$b+$c)

b := 1
c := 2

ifneq ("1+2","$a")
$(error test failed!)
endif

ifneq ("simple","$(flavor a)")
$(error test failed!)
endif

#######################################
# test 'define_append'

a = 1

ifneq ("","$(call define_append,a,$$b)")
$(error test failed!)
endif

ifneq ("1$$b","$(value a)")
$(error test failed!)
endif

ifneq ("recursive","$(flavor a)")
$(error test failed!)
endif

#######################################
# test 'define_prepend'

a = 1

ifneq ("","$(call define_prepend,a,$$b)")
$(error test failed!)
endif

ifneq ("$$b1","$(value a)")
$(error test failed!)
endif

ifneq ("recursive","$(flavor a)")
$(error test failed!)
endif

#######################################
# test 'append_simple'

a := 1

ifneq ("","$(call append_simple,a,2)")
$(error test failed!)
endif

ifneq ("12","$a")
$(error test failed!)
endif

ifneq ("simple","$(flavor a)")
$(error test failed!)
endif

#######################################
# test 'prepend_simple'

a := 1

ifneq ("","$(call prepend_simple,a,2)")
$(error test failed!)
endif

ifneq ("21","$a")
$(error test failed!)
endif

ifneq ("simple","$(flavor a)")
$(error test failed!)
endif

#######################################
# test 'subst_var_refs'

h = 1$(d)+$(bb)+4
d = 2
bb = a b

ifneq ("12+a b+4","$(call subst_var_refs,$(value h),d bb)")
$(error test failed!)
endif

#######################################
# test 'expand_partially'

h = 1$(d)+$(bb)+4
d = 2
bb = a b

ifneq ("","$(call expand_partially,h,d bb)")
$(error test failed!)
endif

ifneq ("12+a b+4","$(value h)")
$(error test failed!)
endif

ifneq ("recursive","$(flavor h)")
$(error test failed!)
endif

#######################################
# test 'remove_var_refs'

h = 1$(d)+$(bb)+4

ifneq ("1++4","$(call remove_var_refs,$(value h),d bb)")
$(error test failed!)
endif

#######################################
# test 'try_make_simple'

h = 1$(d)+$(bb)+4
d := 2
bb := a b

ifneq ("","$(call try_make_simple,h,d bb)")
$(error test failed!)
endif

ifneq ("12+a b+4","$(value h)")
$(error test failed!)
endif

ifneq ("simple","$(flavor h)")
$(error test failed!)
endif

#######################################
# test 'keyed_redefine'

a := 1

ifneq ("","$(call keyed_redefine,a,k,k1,2)")
$(error test failed!)
endif

k := kd

ifneq ("1","$a")
$(error test failed!)
endif

k := k1

ifneq ("2","$a")
$(error test failed!)
endif

#######################################
all:
	@:
