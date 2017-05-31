# pedantic flags for gcc

# gcc 4

GCC4_PEDANTIC_CXXFLAGS := -fstrict-overflow -Waddress -Waggressive-loop-optimizations -Wall -Wcast-align -Wcast-qual -Wchar-subscripts \
 -Wclobbered -Wcomment -Wconversion -Wcoverage-mismatch -Wdisabled-optimization -Wdouble-promotion -Wempty-body -Wenum-compare \
 -Wextra -Wfloat-equal -Wformat=2 -Wformat-nonliteral -Wformat-security -Wformat-y2k -Wignored-qualifiers -Winit-self -Winline \
 -Winvalid-pch -Wlogical-op -Wmain -Wmaybe-uninitialized -Wmissing-braces -Wmissing-declarations -Wmissing-field-initializers \
 -Wmissing-format-attribute -Wmissing-include-dirs -Wnarrowing -Wnonnull -Woverlength-strings -Wpacked -Wpacked-bitfield-compat \
 -Wparentheses -Wpedantic -Wpointer-arith -Wredundant-decls -Wreturn-type -Wsequence-point -Wshadow -Wsign-compare -Wsign-conversion \
 -Wsizeof-pointer-memaccess -Wstack-protector -Wstrict-aliasing=1 -Wstrict-overflow=5 -Wsuggest-attribute=const \
 -Wsuggest-attribute=format -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wswitch -Wswitch-enum -Wsync-nand -Wtrampolines \
 -Wtrigraphs -Wtype-limits -Wundef -Wuninitialized -Wunknown-pragmas -Wunsafe-loop-optimizations -Wunused -Wunused-but-set-parameter \
 -Wunused-but-set-variable -Wunused-function -Wunused-label -Wunused-local-typedefs -Wunused-parameter -Wunused-value -Wunused-variable \
 -Wvector-operation-performance -Wvla -Wvolatile-register-var -Wwrite-strings

GCC4_PEDANTIC_CFLAGS := -std=c99 $(GCC4_PEDANTIC_CXXFLAGS) -Wbad-function-cast -Wc++-compat -Wdeclaration-after-statement \
 -Wimplicit -Wimplicit-function-declaration -Wimplicit-int -Wjump-misses-init -Wmissing-parameter-type -Wmissing-prototypes \
 -Wold-style-declaration -Wold-style-definition -Wpointer-sign -Wstrict-prototypes -Wunsuffixed-float-constants -Wvariadic-macros \

GCC4_PEDANTIC_CXXFLAGS += -Wno-old-style-cast -Wno-long-long -Wno-variadic-macros# -fvisibility-inlines-hidden

# gcc 5

GCC5_PEDANTIC_CFLAGS := -Warray-bounds=2 -Wbool-compare -Wdate-time -Wfatal-errors -Wfloat-conversion -Wformat-signedness \
 -Wlogical-not-parentheses -Wmemset-transposed-args -Wnormalized -Wodr -Wopenmp-simd -Wshift-count-negative -Wshift-count-overflow \
 -Wsizeof-array-argument -Wsuggest-final-methods -Wsuggest-final-types -Wswitch-bool -Wno-aggregate-return -Wno-padded \
 -Wno-switch-default -Wno-float-conversion -Wno-date-time

GCC5_PEDANTIC_CXXFLAGS = $(GCC4_PEDANTIC_CXXFLAGS) $(GCC5_PEDANTIC_CFLAGS) -pedantic-errors -Wabi-tag -Wc++11-compat -Wc++14-compat \
 -Wconditionally-supported -Wconversion-null -Wctor-dtor-privacy -Wdelete-incomplete -Wdelete-non-virtual-dtor -Wliteral-suffix \
 -Wnoexcept -Wnon-virtual-dtor -Woverloaded-virtual -Wreorder -Wsign-promo -Wstrict-null-sentinel -Wsuggest-override -Wvariadic-macros \
 -Wno-useless-cast -Wno-system-headers -Wno-zero-as-null-pointer-constant -Wno-effc++

GCC5_PEDANTIC_CFLAGS := $(GCC4_PEDANTIC_CFLAGS) $(GCC5_PEDANTIC_CFLAGS) -Wincompatible-pointer-types -Wnested-externs

# gcc 6

GCC6_PEDANTIC_CXXFLAGS := -Wduplicated-cond -Wmisleading-indentation -Wnull-dereference -Wshift-negative-value -Wshift-overflow=2 \
 -Wtautological-compare

GCC6_PEDANTIC_CFLAGS := $(filter-out -Winline,$(GCC5_PEDANTIC_CFLAGS)) $(GCC6_PEDANTIC_CXXFLAGS) -Woverride-init-side-effects

GCC6_PEDANTIC_CXXFLAGS := $(filter-out -Winline,$(GCC5_PEDANTIC_CXXFLAGS)) $(GCC6_PEDANTIC_CXXFLAGS)
