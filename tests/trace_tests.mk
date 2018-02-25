c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

include $(c_dir)../trace/trace.mk

# sample function
A = $(subst x,y,$1)

#######################################
# test 'infofn'

X := $(call infofn,$(call A,1 x 2 y 3 z))

# 'infofn' must not affect returned value
ifneq ("1 y 2 y 3 z","$X")
$(error test failed!)
endif

X := $(call infofn,$(call A,1 x 2 y 3 z),test: )

# 'infofn' must not affect returned value
ifneq ("1 y 2 y 3 z","$X")
$(error test failed!)
endif

#######################################
# test 'dump_vars'

Y := 1$(call dump_vars)2

# 'dump_vars' must not produce any value
ifneq ("$Y","12")
$(error test failed!)
endif

Y := 1$(call dump_vars,,test: )2

# 'dump_vars' must not produce any value
ifneq ("$Y","12")
$(error test failed!)
endif

Y := 1$(call dump_vars,X)2

# 'dump_vars' must not produce any value
ifneq ("$Y","12")
$(error test failed!)
endif

Y := 1$(call dump_vars,X Y,test: )2

# 'dump_vars' must not produce any value
ifneq ("$Y","12")
$(error test failed!)
endif

#######################################
# test 'tracefn'

Z = $(tracefn)$(call A,2x3y)

Y := $Z

# 'tracefn' must not affect returned value
ifneq ("$Y","2y3y")
$(error test failed!)
endif

Y := $(call Z)

# 'tracefn' must not affect returned value
ifneq ("$Y","2y3y")
$(error test failed!)
endif

Y := $(call Z,1)

# 'tracefn' must not affect returned value
ifneq ("$Y","2y3y")
$(error test failed!)
endif

Y := $(call Z,1,2)

# 'tracefn' must not affect returned value
ifneq ("$Y","2y3y")
$(error test failed!)
endif

#######################################
# test 'trace_calls'

$(call trace_calls,A)

X := $(call A,1 x 2 y 3 z,$Y)

# 'trace_calls' must not affect returned value
ifneq ("$X","1 y 2 y 3 z")
$(error test failed!)
endif

define T
$(filter X,$1)
$2-$2
endef

X := $(call T,Y X z,$Y)

$(call trace_calls,T)

Y := $(call T,Y X z,$Y)

# 'trace_calls' must not affect returned value
ifneq ("$X","$Y")
$(error test failed!)
endif

#######################################
all:
	@echo success
