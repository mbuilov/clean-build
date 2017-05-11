ifndef TOP

# project configuration file

# project root directory
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# clean-build path
override MTOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../../)

# major.minor.patch
override PRODUCT_VER := 1.0.0

# next variables are needed for generating resurce file under Windows
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

endif
