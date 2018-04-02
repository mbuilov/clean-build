#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

$(info ================ tracing ==================)

# test tracing macros

c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

include $(c_dir)../trace/trace.mk

# sample function
a = $(subst x,y,$1)

#######################################
# test 'infofn'

x := $(call infofn,$(call a,1 x 2 y 3 z))

# 'infofn' must not affect returned value
ifneq ("1 y 2 y 3 z","$x")
$(error test failed!)
endif

x := $(call infofn,$(call a,1 x 2 y 3 z),test: )

# 'infofn' must not affect returned value
ifneq ("1 y 2 y 3 z","$x")
$(error test failed!)
endif

#######################################
# test 'dump_vars'

y := 1$(call dump_vars)2

# 'dump_vars' must not produce any value
ifneq ("$y","12")
$(error test failed!)
endif

y := 1$(call dump_vars,,test: )2

# 'dump_vars' must not produce any value
ifneq ("$y","12")
$(error test failed!)
endif

y := 1$(call dump_vars,x)2

# 'dump_vars' must not produce any value
ifneq ("$y","12")
$(error test failed!)
endif

y := 1$(call dump_vars,x y,test: )2

# 'dump_vars' must not produce any value
ifneq ("$y","12")
$(error test failed!)
endif

#######################################
# test 'tracefn'

z = $(tracefn)$(call a,2x3y)

y := $z

# 'tracefn' must not affect returned value
ifneq ("$y","2y3y")
$(error test failed!)
endif

y := $(call z)

# 'tracefn' must not affect returned value
ifneq ("$y","2y3y")
$(error test failed!)
endif

y := $(call z,1)

# 'tracefn' must not affect returned value
ifneq ("$y","2y3y")
$(error test failed!)
endif

y := $(call z,1,2)

# 'tracefn' must not affect returned value
ifneq ("$y","2y3y")
$(error test failed!)
endif

#######################################
# test 'trace_calls'

$(call trace_calls,a)

x := $(call a,1 x 2 y 3 z,$Y)

# 'trace_calls' must not affect returned value
ifneq ("$x","1 y 2 y 3 z")
$(error test failed!)
endif

define t
$(filter X,$1)
$2-$2
endef

x := $(call t,Y X z,$Y)

$(call trace_calls,t)

y := $(call t,Y X z,$Y)

# 'trace_calls' must not affect returned value
ifneq ("$x","$y")
$(error test failed!)
endif

#######################################
all:
	@:
