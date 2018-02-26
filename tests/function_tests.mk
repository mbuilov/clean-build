c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

include $(c_dir)../core/functions.mk

#######################################
# test 'hide/unhide_raw'

E = 1 $2 3
H := $(call hide,$(value E))

# note: 'unhide_raw' expects no newlines and comments in $1
U := $(call unhide_raw,$H)

ifneq ("$(value E)","$U")
$(error test failed!)
endif

#######################################
# test 'unhide_comments'

E = 1 $2 \# 3 \\#
H := $(call hide,$(value E))

# note: 'unhide_comments' expects no newlines in $1
U := $(call unhide_comments,$H)

ifneq ("$(value E)","$U")
$(error test failed!)
endif

#######################################
# test 'unhide'

define E
1 $2 \#
3 \\#
endef

H := $(call hide,$(value E))
U := $(call unhide,$H)

ifneq ("$(subst $(newline),...,$(value E))","$(subst $(newline),...,$U)")
$(error test failed!)
endif

#######################################
# test 'hide_spaces'

E = 1 $2 \# 3 \\#

H := $(call hide_spaces,$(value E))

ifneq (1,$(words $H))
$(error test failed!)
endif

U := $(call unhide,$H)

ifneq ("$(value E)","$U")
$(error test failed!)
endif

#######################################
# test 'hide_tabs'

E = 1	$2 \# 3 \\#

H := $(call hide_tabs,$(value E))

ifneq (4,$(words $H))
$(error test failed!)
endif

U := $(call unhide,$H)

ifneq ("$(value E)","$U")
$(error test failed!)
endif

#######################################
# test 'hide_tab_spaces'

E = 1	$2 \# 3 \\#

H := $(call hide_tab_spaces,$(value E))

ifneq (1,$(words $H))
$(error test failed!)
endif

U := $(call unhide,$H)

ifneq ("$(value E)","$U")
$(error test failed!)
endif

#######################################
# test 'tolower'

E = 1A B C D E F G H I J K L M N O P Q R S T U V W X Y Z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z2

H := $(call tolower,$(value E))

ifneq ("$H","1a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z2")
$(error test failed!)
endif

#######################################
# test 'toupper'

E = 1a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z2

H := $(call toupper,$(value E))

ifneq ("$H","1A B C D E F G H I J K L M N O P Q R S T U V W X Y Z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z2")
$(error test failed!)
endif

#######################################
# test 'repl09'

E = 0a 1 2m3 z4 5r y678i9

H := $(call repl09,$(value E))

ifneq ("$H",".a . .m. z. .r y...i.")
$(error test failed!)
endif

#######################################
# test 'repl09AZ'

E = A B CDEFGH0aI JKLMN O1PQ R2STmU3 Vz4 W5r XYy678iZ9

H := $(call repl09AZ,$(value E))

ifneq ("$H",". . .......a. ..... .... ....m.. .z. ..r ..y...i..")
$(error test failed!)
endif

#######################################
# test 'padto'

H1 := $(call padto,A)
H2 := $(call padto,AB)
H3 := $(call padto,AB3)
H4 := $(call padto,AB3C)
H5 := $(call padto,AB3CD)
H6 := $(call padto,AB3CD6)
H7 := $(call padto,AB3DE6F)

ifneq ("$(H1)","       ")
$(error test failed!)
endif
ifneq ("$(H2)","      ")
$(error test failed!)
endif
ifneq ("$(H3)","     ")
$(error test failed!)
endif
ifneq ("$(H4)","    ")
$(error test failed!)
endif
ifneq ("$(H5)","   ")
$(error test failed!)
endif
ifneq ("$(H6)","  ")
$(error test failed!)
endif
ifneq ("$(H7)"," ")
$(error test failed!)
endif

#######################################
# test 'isless'

ifneq (,$(call is_less,0,0))
$(error test failed!)
endif
ifneq (,$(call is_less,1,0))
$(error test failed!)
endif
ifeq (,$(call is_less,0,1))
$(error test failed!)
endif
ifneq (,$(call is_less,1,1))
$(error test failed!)
endif
ifneq (,$(call is_less,2,1))
$(error test failed!)
endif
ifeq (,$(call is_less,1,2))
$(error test failed!)
endif
ifneq (,$(call is_less,100,100))
$(error test failed!)
endif
ifneq (,$(call is_less,100,1))
$(error test failed!)
endif
ifeq (,$(call is_less,1,100))
$(error test failed!)
endif
ifneq (,$(call is_less,200,100))
$(error test failed!)
endif
ifeq (,$(call is_less,100,200))
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
ifneq (,$(call is_less_float,0,0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1,0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0,1))
$(error test failed!)
endif

# 2:  0.   <->  0.
ifneq (,$(call is_less_float,0.,0.))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.,0.))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.,1.))
$(error test failed!)
endif

# 3:  0.   <->  0
ifneq (,$(call is_less_float,0.,0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.,0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.,1))
$(error test failed!)
endif

# 4:  0    <->  0.
ifneq (,$(call is_less_float,0,0.))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1,0.))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0,1.))
$(error test failed!)
endif

# 5:  0.0  <->  0.0
ifneq (,$(call is_less_float,0.0,0.0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.0,0.0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.0,1.0))
$(error test failed!)
endif

# 6:  0    <->  0.0
ifneq (,$(call is_less_float,0,0.0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1,0.0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0,1.0))
$(error test failed!)
endif

# 7:  0.0  <->  0
ifneq (,$(call is_less_float,0.0,0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.0,0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.0,1))
$(error test failed!)
endif

# 8:  0.   <->  0.0
ifneq (,$(call is_less_float,0.,0.0))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.,0.0))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.,1.0))
$(error test failed!)
endif

# 9:  0.0  <->  0.
ifneq (,$(call is_less_float,0.0,0.))
$(error test failed!)
endif
ifneq (,$(call is_less_float,1.0,0.))
$(error test failed!)
endif
ifeq (,$(call is_less_float,0.0,1.))
$(error test failed!)
endif

ifeq (,$(call is_less_float,0.33333,2))
$(error test failed!)
endif

ifeq (,$(call is_less_float,0.33333,0.4))
$(error test failed!)
endif

ifneq (,$(call is_less_float,0.33333,0.2222222))
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

T := $(call xargs,fn,a b c d e f g h i j k l m n o p,3,1,2,3,4,S)

ifneq ("<>(a b c)-1-2-3-4+S<S>(d e f)-1-2-3-4+S<S>(g h i)-1-2-3-4+S<S>(j k l)-1-2-3-4+S<S>(m n o)-1-2-3-4+S<S>(p)-1-2-3-4","$T")
$(error test failed!)
endif

#######################################
# test 'xcmd'

fn = $(if $6,!)($1)-$2-$3-$4-$5$(if $7,+)

T := $(call xcmd,fn,a b c d e f g h i j k l m n o p,3,1,2,3,4)

define E
(a b c)-1-2-3-4+
!(d e f)-1-2-3-4+
!(g h i)-1-2-3-4+
!(j k l)-1-2-3-4+
!(m n o)-1-2-3-4+
!(p)-1-2-3-4
endef

ifneq ("$(value E)","$T")
$(error test failed!)
endif

#######################################
# test 'trim'

ifneq ("a b c d e f g h i j k l m n o","$(call trim,a b c d e f g h i j k l m n o p)")
$(error test failed!)
endif

#######################################
# test 'neq'

ifneq (,$(call neq,1 2,1 2))
$(error test failed!)
endif

ifeq (,$(call neq,1 2,2 3))
$(error test failed!)
endif

ifeq (,$(call neq,1 2,1 2 ))
$(error test failed!)
endif

ifeq (,$(call neq,1 2, 1 2))
$(error test failed!)
endif

ifeq (,$(call neq,1 2,1  2))
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
# test 'normp'

ifneq ("1/3/7","$(call normp,1/3//5/.././6/../7)")
$(error test failed!)
endif

ifneq ("/1/3","$(call normp,/./1/3//5/.././6/6/../../7/..)")
$(error test failed!)
endif

#######################################
# test 'cmn_path'

ifneq ("aa/","$(call cmn_path,aa/bb/cc/,aa/dd/qq/)")
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

#######################################
# test 'relpath'

#######################################
# test 'ver_major'

#######################################
# test 'ver_minor'

#######################################
# test 'ver_patch'

#######################################
# test 'ver_compatible'

#######################################
# test 'get_dir'

#######################################
# test 'split_dirs'

#######################################
# test 'mk_dir_deps'

#######################################
# test 'lazy_simple'

#######################################
# test 'define_append'

#######################################
# test 'define_prepend'

#######################################
# test 'append_simple'

#######################################
# test 'prepend_simple'

#######################################
# test 'subst_var_refs'

#######################################
# test 'expand_partially'

#######################################
# test 'remove_var_refs'

#######################################
# test 'try_make_simple'

#######################################
# test 'keyed_redefine'




#######################################
all:
	@echo success
