# pedantic flags for clang

CLANG3_PEDANTIC_CFLAGS := -Weverything -Wno-padded -Wno-cast-align -Wno-reserved-id-macro -Wno-extended-offsetof \
 -Wno-covered-switch-default -Wno-documentation -Wno-assume -Wno-disabled-macro-expansion

CLANG3_PEDANTIC_CXXFLAGS := $(CLANG_3_PEDANTIC_CFLAGS) -Wno-old-style-cast -Wno-c++11-long-long -Wno-variadic-macros \
 -Wno-unused-member-function
