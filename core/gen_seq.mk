#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define '$zgen_seq' - sequence generator: 0 1 2 ... 9999999

# generator prefix - may be defined before including this file
ifeq (,$(filter-out undefined environment,$(origin z)))
z := cb_
endif

# generated number prefixes
$zp6:=
$zp5:=
$zp4:=
$zp3:=
$zp2:=
$zp1:=

$(eval $zgen_overflow = $$(error overflow in '$zgen'))

# this makefile may be included multiple times
ifeq (,$(filter-out undefined environment,$(origin cb_gen_step_template)))

# generate next number
# $z - name prefix
# $n - order
# $p - next (higher) order
# '$zg$n' - "pointer" to the function returning next number value
# '$zp$p' - generated number prefix
# '$zg$p' - "pointer" to the function returning next number prefix value
define cb_gen_step_template
$zg$n := $z$n1g
$z$n0g = $(eval $zp$p:=$($($zg$p)))$(call set_global,$zg$p $zp$p)$($zp$p)0$(eval $zg$n:=$z$n1g)
$z$n1g = $($zp$p)1$(eval $zg$n:=$z$n2g)
$z$n2g = $($zp$p)2$(eval $zg$n:=$z$n3g)
$z$n3g = $($zp$p)3$(eval $zg$n:=$z$n4g)
$z$n4g = $($zp$p)4$(eval $zg$n:=$z$n5g)
$z$n5g = $($zp$p)5$(eval $zg$n:=$z$n6g)
$z$n6g = $($zp$p)6$(eval $zg$n:=$z$n7g)
$z$n7g = $($zp$p)7$(eval $zg$n:=$z$n8g)
$z$n8g = $($zp$p)8$(eval $zg$n:=$z$n9g)
$z$n9g = $($zp$p)9$(eval $zg$n:=$z$n0g)
endef

# remove call to 'set_global' if not in "check-mode"
ifndef cb_checking
cb_gen_step_value = $(subst $$(call set_global,$$zg$$p $$zp$$p),,$(value cb_gen_step_template))
else
cb_gen_step_value = $(value cb_gen_step_template)
endif

endif # !defined cb_gen_step_template

# define $zg6:
# 1) $z$n0g is not used
# 2) $($zp$p) is not used
# 3) next value after $z$n9g must be $zgen_overflow
$(eval $(subst \
  $$z,$z,$(subst \
  $$n,6,$(subst \
  $$z$$n0g,$$zgen_overflow,$(subst \
  $$($$zp$$p),,$(subst \
  $$z$$n0g = $$(eval $$zp$$p:=$$($$($$zg$$p)))$$(call set_global,$$zg$$p $$zp$$p)$$($$zp$$p)0$$(eval $$zg$$n:=$$z$$n1g),,$(value \
  cb_gen_step_template)))))))

# define $zg5, $zg4, $zg3, $zg2, $zg1
$(eval $(subst $$z,$z,$(subst $$n,5,$(subst $$p,6,$(cb_gen_step_value)))))
$(eval $(subst $$z,$z,$(subst $$n,4,$(subst $$p,5,$(cb_gen_step_value)))))
$(eval $(subst $$z,$z,$(subst $$n,3,$(subst $$p,4,$(cb_gen_step_value)))))
$(eval $(subst $$z,$z,$(subst $$n,2,$(subst $$p,3,$(cb_gen_step_value)))))
$(eval $(subst $$z,$z,$(subst $$n,1,$(subst $$p,2,$(cb_gen_step_value)))))

# define $zgen:
# 1) initially set $zgen to point to $z_g - to return 0 as the first value of $zgen
$(eval $(subst \
  $$z,$z,$(subst \
  $$n,en,$(subst \
  $$p,1,$(subst \
  := $$z$$n1g,:= $z_g,$(cb_gen_step_value))))))

# define $z_g function (called by $zgen at first time - to return 0 as the first value)
$(eval $z_g = 0$$(eval $zgen:=$zen1g))

# define $zgen_seq - generate next sequence number
ifndef cb_checking
$(eval $zgen_seq = $$($$($zgen)))
else
$(eval $zgen_seq = $$($$($zgen))$$(call set_global,$zgen))
endif

# makefile parsing first phase variables
cb_first_phase_vars += $zp6 $zp5 $zp4 $zp3 $zp2 $zp1 $zgen_overflow \
  $zg6 $z60g $z61g $z62g $z63g $z64g $z65g $z66g $z67g $z68g $z69g \
  $zg5 $z50g $z51g $z52g $z53g $z54g $z55g $z56g $z57g $z58g $z59g \
  $zg4 $z40g $z41g $z42g $z43g $z44g $z45g $z46g $z47g $z48g $z49g \
  $zg3 $z30g $z31g $z32g $z33g $z34g $z35g $z36g $z37g $z38g $z39g \
  $zg2 $z20g $z21g $z22g $z23g $z24g $z25g $z26g $z27g $z28g $z29g \
  $zg1 $z10g $z11g $z12g $z13g $z14g $z15g $z16g $z17g $z18g $z19g \
  $zgen $zen0g $zen1g $zen2g $zen3g $zen4g $zen5g $zen6g $zen7g $zen8g $zen9g \
  $z_g $zgen_seq

# protect macros from modifications in target makefiles,
# do not trace calls to these macros
$(call set_global,$zp6 $zp5 $zp4 $zp3 $zp2 $zp1 $zgen_overflow \
  $zg6 $z60g $z61g $z62g $z63g $z64g $z65g $z66g $z67g $z68g $z69g \
  $zg5 $z50g $z51g $z52g $z53g $z54g $z55g $z56g $z57g $z58g $z59g \
  $zg4 $z40g $z41g $z42g $z43g $z44g $z45g $z46g $z47g $z48g $z49g \
  $zg3 $z30g $z31g $z32g $z33g $z34g $z35g $z36g $z37g $z38g $z39g \
  $zg2 $z20g $z21g $z22g $z23g $z24g $z25g $z26g $z27g $z28g $z29g \
  $zg1 $z10g $z11g $z12g $z13g $z14g $z15g $z16g $z17g $z18g $z19g \
  $zgen $zen0g $zen1g $zen2g $zen3g $zen4g $zen5g $zen6g $zen7g $zen8g $zen9g \
  $z_g)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: $zgen_seq
$(call set_global,$zgen_seq,$zgen_seq)
