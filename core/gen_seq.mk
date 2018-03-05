#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'cb_gen_seq' - sequence generator: 0 1 2 ... 9999999

cb_p6:=
cb_p5:=
cb_p4:=
cb_p3:=
cb_p2:=
cb_p1:=

cb_gen_overflow = $(error overflow in 'cb_gen')

cb_g6 := cb_61g
cb_60g = 0$(eval cb_g6:=cb_61g)
cb_61g = 1$(eval cb_g6:=cb_62g)
cb_62g = 2$(eval cb_g6:=cb_63g)
cb_63g = 3$(eval cb_g6:=cb_64g)
cb_64g = 4$(eval cb_g6:=cb_65g)
cb_65g = 5$(eval cb_g6:=cb_66g)
cb_66g = 6$(eval cb_g6:=cb_67g)
cb_67g = 7$(eval cb_g6:=cb_68g)
cb_68g = 8$(eval cb_g6:=cb_69g)
cb_69g = 9$(eval cb_g6:=cb_gen_overflow)

cb_g5 := cb_51g
cb_50g = $(eval cb_p6:=$($(cb_g6)))$(cb_p6)0$(eval cb_g5:=cb_51g)
cb_51g = $(cb_p6)1$(eval cb_g5:=cb_52g)
cb_52g = $(cb_p6)2$(eval cb_g5:=cb_53g)
cb_53g = $(cb_p6)3$(eval cb_g5:=cb_54g)
cb_54g = $(cb_p6)4$(eval cb_g5:=cb_55g)
cb_55g = $(cb_p6)5$(eval cb_g5:=cb_56g)
cb_56g = $(cb_p6)6$(eval cb_g5:=cb_57g)
cb_57g = $(cb_p6)7$(eval cb_g5:=cb_58g)
cb_58g = $(cb_p6)8$(eval cb_g5:=cb_59g)
cb_59g = $(cb_p6)9$(eval cb_g5:=cb_50g)

cb_g4 := cb_41g
cb_40g = $(eval cb_p5:=$($(cb_g5)))$(cb_p5)0$(eval cb_g4:=cb_41g)
cb_41g = $(cb_p5)1$(eval cb_g4:=cb_42g)
cb_42g = $(cb_p5)2$(eval cb_g4:=cb_43g)
cb_43g = $(cb_p5)3$(eval cb_g4:=cb_44g)
cb_44g = $(cb_p5)4$(eval cb_g4:=cb_45g)
cb_45g = $(cb_p5)5$(eval cb_g4:=cb_46g)
cb_46g = $(cb_p5)6$(eval cb_g4:=cb_47g)
cb_47g = $(cb_p5)7$(eval cb_g4:=cb_48g)
cb_48g = $(cb_p5)8$(eval cb_g4:=cb_49g)
cb_49g = $(cb_p5)9$(eval cb_g4:=cb_40g)

cb_g3 := cb_31g
cb_30g = $(eval cb_p4:=$($(cb_g4)))$(cb_p4)0$(eval cb_g3:=cb_31g)
cb_31g = $(cb_p4)1$(eval cb_g3:=cb_32g)
cb_32g = $(cb_p4)2$(eval cb_g3:=cb_33g)
cb_33g = $(cb_p4)3$(eval cb_g3:=cb_34g)
cb_34g = $(cb_p4)4$(eval cb_g3:=cb_35g)
cb_35g = $(cb_p4)5$(eval cb_g3:=cb_36g)
cb_36g = $(cb_p4)6$(eval cb_g3:=cb_37g)
cb_37g = $(cb_p4)7$(eval cb_g3:=cb_38g)
cb_38g = $(cb_p4)8$(eval cb_g3:=cb_39g)
cb_39g = $(cb_p4)9$(eval cb_g3:=cb_30g)

cb_g2 := cb_21g
cb_20g = $(eval cb_p3:=$($(cb_g3)))$(cb_p3)0$(eval cb_g2:=cb_21g)
cb_21g = $(cb_p3)1$(eval cb_g2:=cb_22g)
cb_22g = $(cb_p3)2$(eval cb_g2:=cb_23g)
cb_23g = $(cb_p3)3$(eval cb_g2:=cb_24g)
cb_24g = $(cb_p3)4$(eval cb_g2:=cb_25g)
cb_25g = $(cb_p3)5$(eval cb_g2:=cb_26g)
cb_26g = $(cb_p3)6$(eval cb_g2:=cb_27g)
cb_27g = $(cb_p3)7$(eval cb_g2:=cb_28g)
cb_28g = $(cb_p3)8$(eval cb_g2:=cb_29g)
cb_29g = $(cb_p3)9$(eval cb_g2:=cb_20g)

cb_g1 := cb_11g
cb_10g = $(eval cb_p2:=$($(cb_g2)))$(cb_p2)0$(eval cb_g1:=cb_11g)
cb_11g = $(cb_p2)1$(eval cb_g1:=cb_12g)
cb_12g = $(cb_p2)2$(eval cb_g1:=cb_13g)
cb_13g = $(cb_p2)3$(eval cb_g1:=cb_14g)
cb_14g = $(cb_p2)4$(eval cb_g1:=cb_15g)
cb_15g = $(cb_p2)5$(eval cb_g1:=cb_16g)
cb_16g = $(cb_p2)6$(eval cb_g1:=cb_17g)
cb_17g = $(cb_p2)7$(eval cb_g1:=cb_18g)
cb_18g = $(cb_p2)8$(eval cb_g1:=cb_19g)
cb_19g = $(cb_p2)9$(eval cb_g1:=cb_10g)

cb_gen := cb__g
cb__g = $(eval cb_p1:=)0$(eval cb_gen:=cb_1g)
cb_0g = $(eval cb_p1:=$($(cb_g1)))$(cb_p1)0$(eval cb_gen:=cb_1g)
cb_1g = $(cb_p1)1$(eval cb_gen:=cb_2g)
cb_2g = $(cb_p1)2$(eval cb_gen:=cb_3g)
cb_3g = $(cb_p1)3$(eval cb_gen:=cb_4g)
cb_4g = $(cb_p1)4$(eval cb_gen:=cb_5g)
cb_5g = $(cb_p1)5$(eval cb_gen:=cb_6g)
cb_6g = $(cb_p1)6$(eval cb_gen:=cb_7g)
cb_7g = $(cb_p1)7$(eval cb_gen:=cb_8g)
cb_8g = $(cb_p1)8$(eval cb_gen:=cb_9g)
cb_9g = $(cb_p1)9$(eval cb_gen:=cb_0g)

# generate next sequence number
ifndef cb_checking
cb_gen_seq = $($(cb_gen))
else
$(eval cb_50g = $(subst $$(cb_p6),$$(call set_global,cb_p6 cb_g6)$$(cb_p6),$(value cb_50g)))
$(eval cb_40g = $(subst $$(cb_p5),$$(call set_global,cb_p5 cb_g5)$$(cb_p5),$(value cb_40g)))
$(eval cb_30g = $(subst $$(cb_p4),$$(call set_global,cb_p4 cb_g4)$$(cb_p4),$(value cb_30g)))
$(eval cb_20g = $(subst $$(cb_p3),$$(call set_global,cb_p3 cb_g3)$$(cb_p3),$(value cb_20g)))
$(eval cb_10g = $(subst $$(cb_p2),$$(call set_global,cb_p2 cb_g2)$$(cb_p2),$(value cb_10g)))
$(eval cb_0g = $(subst $$(cb_p1),$$(call set_global,cb_p1 cb_g1)$$(cb_p1),$(value cb_0g)))
cb_gen_seq = $($(cb_gen))$(call set_global,cb_gen)
endif

# makefile parsing first phase variables
cb_first_phase_vars += \
  cb_p6 cb_p5 cb_p4 cb_p3 cb_p2 cb_p1 cb_gen_overflow \
  cb_g6 cb_60g cb_61g cb_62g cb_63g cb_64g cb_65g cb_66g cb_67g cb_68g cb_69g \
  cb_g5 cb_50g cb_51g cb_52g cb_53g cb_54g cb_55g cb_56g cb_57g cb_58g cb_59g \
  cb_g4 cb_40g cb_41g cb_42g cb_43g cb_44g cb_45g cb_46g cb_47g cb_48g cb_49g \
  cb_g3 cb_30g cb_31g cb_32g cb_33g cb_34g cb_35g cb_36g cb_37g cb_38g cb_39g \
  cb_g2 cb_20g cb_21g cb_22g cb_23g cb_24g cb_25g cb_26g cb_27g cb_28g cb_29g \
  cb_g1 cb_10g cb_11g cb_12g cb_13g cb_14g cb_15g cb_16g cb_17g cb_18g cb_19g \
  cb_gen cb__g cb_0g cb_1g cb_2g cb_3g cb_4g cb_5g cb_6g cb_7g cb_8g cb_9g \
  cb_gen_seq

# protect macros from modifications in target makefiles,
# do not trace calls to these macros
$(call set_global, \
  cb_p6 cb_p5 cb_p4 cb_p3 cb_p2 cb_p1 cb_gen_overflow \
  cb_g6 cb_60g cb_61g cb_62g cb_63g cb_64g cb_65g cb_66g cb_67g cb_68g cb_69g \
  cb_g5 cb_50g cb_51g cb_52g cb_53g cb_54g cb_55g cb_56g cb_57g cb_58g cb_59g \
  cb_g4 cb_40g cb_41g cb_42g cb_43g cb_44g cb_45g cb_46g cb_47g cb_48g cb_49g \
  cb_g3 cb_30g cb_31g cb_32g cb_33g cb_34g cb_35g cb_36g cb_37g cb_38g cb_39g \
  cb_g2 cb_20g cb_21g cb_22g cb_23g cb_24g cb_25g cb_26g cb_27g cb_28g cb_29g \
  cb_g1 cb_10g cb_11g cb_12g cb_13g cb_14g cb_15g cb_16g cb_17g cb_18g cb_19g \
  cb_gen cb__g cb_0g cb_1g cb_2g cb_3g cb_4g cb_5g cb_6g cb_7g cb_8g cb_9g)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: cb_gen_seq
$(call set_global,cb_gen_seq,cb_gen_seq)
