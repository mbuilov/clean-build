#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

$(info ================ sequence generator =======)

# test sequence generator

cb_checking:=
cb_first_phase_vars:=
set_global:=

c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

z := test_
include $(c_dir)../core/seq.mk

ifneq (0,$(test_seq))
$(error test failed!)
endif

ifneq (1,$(test_seq))
$(error test failed!)
endif

ifneq (2,$(test_seq))
$(error test failed!)
endif

ifneq (3,$(test_seq))
$(error test failed!)
endif

ifneq (4,$(test_seq))
$(error test failed!)
endif

ifneq (5,$(test_seq))
$(error test failed!)
endif

ifneq (6,$(test_seq))
$(error test failed!)
endif

ifneq (7,$(test_seq))
$(error test failed!)
endif

ifneq (8,$(test_seq))
$(error test failed!)
endif

ifneq (9,$(test_seq))
$(error test failed!)
endif

ifneq (10,$(test_seq))
$(error test failed!)
endif

ifneq (11,$(test_seq))
$(error test failed!)
endif

$(foreach x,12 13 14 15 16 17 18 19 20 21 22 23 24 25,$(if $(filter $x,$(test_seq)),,$(error test failed for $x!)))

z := test2_
include $(c_dir)../core/seq.mk

X := 1
X := $X $X $X $X $X $X $X $X $X $X # 10
X := $X $X $X $X $X $X $X $X $X $X # 100
X := $X $X $X $X $X $X $X $X $X $X # 1000

$(foreach x,$X,$(eval lastw:=$$(test2_seq)))

ifneq (999,$(lastw))
$(error test failed: lastw=$(lastw)!)
endif

#######################################
all:
	@:
