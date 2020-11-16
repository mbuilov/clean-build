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

GCC4_PEDANTIC_CFLAGS := $(GCC4_PEDANTIC_CXXFLAGS) -Wbad-function-cast -Wc++-compat -Wdeclaration-after-statement \
 -Wimplicit -Wimplicit-function-declaration -Wimplicit-int -Wjump-misses-init -Wmissing-parameter-type -Wmissing-prototypes \
 -Wold-style-declaration -Wold-style-definition -Wpointer-sign -Wstrict-prototypes -Wunsuffixed-float-constants -Wvariadic-macros \

GCC4_PEDANTIC_CXXFLAGS += -Wno-old-style-cast -Wno-long-long -Wno-variadic-macros# -fvisibility-inlines-hidden

# gcc 5

GCC5_PEDANTIC_CFLAGS := -Warray-bounds=2 -Wbool-compare -Wdate-time -Wfatal-errors -Wfloat-conversion -Wformat-signedness \
 -Wlogical-not-parentheses -Wmemset-transposed-args -Wnormalized -Wodr -Wopenmp-simd -Wshift-count-negative -Wshift-count-overflow \
 -Wsizeof-array-argument -Wsuggest-final-methods -Wsuggest-final-types -Wswitch-bool -Wno-aggregate-return -Wno-padded \
 -Wno-switch-default -Wno-float-conversion -Wno-date-time

GCC5_PEDANTIC_CXXFLAGS := $(GCC4_PEDANTIC_CXXFLAGS) $(GCC5_PEDANTIC_CFLAGS) -pedantic-errors -Wabi-tag -Wc++11-compat -Wc++14-compat \
 -Wconditionally-supported -Wconversion-null -Wctor-dtor-privacy -Wdelete-incomplete -Wdelete-non-virtual-dtor -Wliteral-suffix \
 -Wnoexcept -Wnon-virtual-dtor -Woverloaded-virtual -Wreorder -Wsign-promo -Wstrict-null-sentinel -Wsuggest-override -Wvariadic-macros \
 -Wno-useless-cast -Wno-system-headers -Wno-zero-as-null-pointer-constant -Wno-effc++

GCC5_PEDANTIC_CFLAGS := $(GCC4_PEDANTIC_CFLAGS) $(GCC5_PEDANTIC_CFLAGS) -Wincompatible-pointer-types -Wnested-externs

# gcc 6

GCC6_PEDANTIC_CXXFLAGS := -Wduplicated-cond -Wmisleading-indentation -Wnull-dereference -Wshift-negative-value -Wshift-overflow=2 \
 -Wtautological-compare

GCC6_PEDANTIC_CFLAGS := $(filter-out -Winline,$(GCC5_PEDANTIC_CFLAGS)) $(GCC6_PEDANTIC_CXXFLAGS) -Woverride-init-side-effects

GCC6_PEDANTIC_CXXFLAGS := $(filter-out -Winline,$(GCC5_PEDANTIC_CXXFLAGS)) $(GCC6_PEDANTIC_CXXFLAGS)

# gcc 9

# common C/C++ warnings
GCC9_PEDANTIC_CFLAGS := -fstrict-overflow
GCC9_PEDANTIC_CFLAGS += -Wall
GCC9_PEDANTIC_CFLAGS += -Wextra
GCC9_PEDANTIC_CFLAGS += -Waddress
GCC9_PEDANTIC_CFLAGS += -Waddress-of-packed-member
#GCC9_PEDANTIC_CFLAGS += -Waggregate-return
GCC9_PEDANTIC_CFLAGS += -Waggressive-loop-optimizations
GCC9_PEDANTIC_CFLAGS += -Walloc-zero
GCC9_PEDANTIC_CFLAGS += -Walloca
GCC9_PEDANTIC_CFLAGS += -Warray-bounds=2
GCC9_PEDANTIC_CFLAGS += -Wattribute-alias=2
GCC9_PEDANTIC_CFLAGS += -Wattribute-warning
GCC9_PEDANTIC_CFLAGS += -Wattributes
GCC9_PEDANTIC_CFLAGS += -Wbool-compare
GCC9_PEDANTIC_CFLAGS += -Wbool-operation
GCC9_PEDANTIC_CFLAGS += -Wbuiltin-declaration-mismatch
GCC9_PEDANTIC_CFLAGS += -Wbuiltin-macro-redefined
GCC9_PEDANTIC_CFLAGS += -Wcannot-profile
GCC9_PEDANTIC_CFLAGS += -Wcast-align=strict
GCC9_PEDANTIC_CFLAGS += -Wcast-function-type
GCC9_PEDANTIC_CFLAGS += -Wcast-qual
GCC9_PEDANTIC_CFLAGS += -Wchar-subscripts
GCC9_PEDANTIC_CFLAGS += -Wclobbered
GCC9_PEDANTIC_CFLAGS += -Wcomment
GCC9_PEDANTIC_CFLAGS += -Wconversion
GCC9_PEDANTIC_CFLAGS += -Wcoverage-mismatch
GCC9_PEDANTIC_CFLAGS += -Wcpp
GCC9_PEDANTIC_CFLAGS += -Wdangling-else
GCC9_PEDANTIC_CFLAGS += -Wdate-time
GCC9_PEDANTIC_CFLAGS += -Wdeprecated
GCC9_PEDANTIC_CFLAGS += -Wdeprecated-declarations
GCC9_PEDANTIC_CFLAGS += -Wdisabled-optimization
GCC9_PEDANTIC_CFLAGS += -Wdiv-by-zero
GCC9_PEDANTIC_CFLAGS += -Wdouble-promotion
GCC9_PEDANTIC_CFLAGS += -Wduplicated-branches
GCC9_PEDANTIC_CFLAGS += -Wduplicated-cond
GCC9_PEDANTIC_CFLAGS += -Wempty-body
GCC9_PEDANTIC_CFLAGS += -Wendif-labels
GCC9_PEDANTIC_CFLAGS += -Wenum-compare
GCC9_PEDANTIC_CFLAGS += -Wexpansion-to-defined
GCC9_PEDANTIC_CFLAGS += -Wfloat-conversion
#GCC9_PEDANTIC_CFLAGS += -Wfloat-equal
GCC9_PEDANTIC_CFLAGS += -Wformat=2
GCC9_PEDANTIC_CFLAGS += -Wformat-contains-nul
GCC9_PEDANTIC_CFLAGS += -Wformat-extra-args
GCC9_PEDANTIC_CFLAGS += -Wformat-nonliteral
GCC9_PEDANTIC_CFLAGS += -Wformat-security
GCC9_PEDANTIC_CFLAGS += -Wformat-y2k
GCC9_PEDANTIC_CFLAGS += -Wformat-zero-length
GCC9_PEDANTIC_CFLAGS += -Wformat-overflow=2
GCC9_PEDANTIC_CFLAGS += -Wformat-signedness
GCC9_PEDANTIC_CFLAGS += -Wformat-truncation=2
GCC9_PEDANTIC_CFLAGS += -Wframe-address
GCC9_PEDANTIC_CFLAGS += -Wfree-nonheap-object
GCC9_PEDANTIC_CFLAGS += -Whsa
GCC9_PEDANTIC_CFLAGS += -Wif-not-aligned
GCC9_PEDANTIC_CFLAGS += -Wignored-attributes
GCC9_PEDANTIC_CFLAGS += -Wignored-qualifiers
GCC9_PEDANTIC_CFLAGS += -Wimplicit-fallthrough=3
GCC9_PEDANTIC_CFLAGS += -Winit-self
#GCC9_PEDANTIC_CFLAGS += -Winline
GCC9_PEDANTIC_CFLAGS += -Wint-in-bool-context
GCC9_PEDANTIC_CFLAGS += -Wint-to-pointer-cast
GCC9_PEDANTIC_CFLAGS += -Winvalid-memory-model
GCC9_PEDANTIC_CFLAGS += -Winvalid-pch
GCC9_PEDANTIC_CFLAGS += -Wlogical-not-parentheses
GCC9_PEDANTIC_CFLAGS += -Wlogical-op
GCC9_PEDANTIC_CFLAGS += -Wlto-type-mismatch
GCC9_PEDANTIC_CFLAGS += -Wmain
GCC9_PEDANTIC_CFLAGS += -Wmaybe-uninitialized
GCC9_PEDANTIC_CFLAGS += -Wmemset-elt-size
GCC9_PEDANTIC_CFLAGS += -Wmemset-transposed-args
GCC9_PEDANTIC_CFLAGS += -Wmisleading-indentation
GCC9_PEDANTIC_CFLAGS += -Wmissing-attributes
GCC9_PEDANTIC_CFLAGS += -Wmissing-braces
GCC9_PEDANTIC_CFLAGS += -Wmissing-declarations
GCC9_PEDANTIC_CFLAGS += -Wmissing-field-initializers
GCC9_PEDANTIC_CFLAGS += -Wmissing-format-attribute
GCC9_PEDANTIC_CFLAGS += -Wmissing-include-dirs
GCC9_PEDANTIC_CFLAGS += -Wmissing-noreturn
GCC9_PEDANTIC_CFLAGS += -Wmissing-profile
GCC9_PEDANTIC_CFLAGS += -Wmultichar
GCC9_PEDANTIC_CFLAGS += -Wmultistatement-macros
GCC9_PEDANTIC_CFLAGS += -Wnarrowing
GCC9_PEDANTIC_CFLAGS += -Wnonnull
GCC9_PEDANTIC_CFLAGS += -Wnonnull-compare
GCC9_PEDANTIC_CFLAGS += -Wnormalized=nfc
GCC9_PEDANTIC_CFLAGS += -Wnull-dereference
GCC9_PEDANTIC_CFLAGS += -Wodr
GCC9_PEDANTIC_CFLAGS += -Wopenmp-simd
GCC9_PEDANTIC_CFLAGS += -Woverflow
GCC9_PEDANTIC_CFLAGS += -Woverlength-strings
GCC9_PEDANTIC_CFLAGS += -Wpacked
GCC9_PEDANTIC_CFLAGS += -Wpacked-bitfield-compat
GCC9_PEDANTIC_CFLAGS += -Wpacked-not-aligned
#GCC9_PEDANTIC_CFLAGS += -Wpadded
GCC9_PEDANTIC_CFLAGS += -Wparentheses
GCC9_PEDANTIC_CFLAGS += -Wpedantic
GCC9_PEDANTIC_CFLAGS += -Wpointer-arith
GCC9_PEDANTIC_CFLAGS += -Wpointer-compare
GCC9_PEDANTIC_CFLAGS += -Wpragmas
GCC9_PEDANTIC_CFLAGS += -Wpsabi
#GCC9_PEDANTIC_CFLAGS += -Wredundant-decls
GCC9_PEDANTIC_CFLAGS += -Wrestrict
GCC9_PEDANTIC_CFLAGS += -Wreturn-local-addr
GCC9_PEDANTIC_CFLAGS += -Wreturn-type
GCC9_PEDANTIC_CFLAGS += -Wscalar-storage-order
GCC9_PEDANTIC_CFLAGS += -Wsequence-point
GCC9_PEDANTIC_CFLAGS += -Wshadow
GCC9_PEDANTIC_CFLAGS += -Wshadow=local
GCC9_PEDANTIC_CFLAGS += -Wshadow=compatible-local
GCC9_PEDANTIC_CFLAGS += -Wshadow=global
GCC9_PEDANTIC_CFLAGS += -Wshift-count-negative
GCC9_PEDANTIC_CFLAGS += -Wshift-count-overflow
GCC9_PEDANTIC_CFLAGS += -Wshift-negative-value
GCC9_PEDANTIC_CFLAGS += -Wshift-overflow=2
GCC9_PEDANTIC_CFLAGS += -Wsign-compare
GCC9_PEDANTIC_CFLAGS += -Wsign-conversion
GCC9_PEDANTIC_CFLAGS += -Wsizeof-array-argument
GCC9_PEDANTIC_CFLAGS += -Wsizeof-pointer-div
GCC9_PEDANTIC_CFLAGS += -Wsizeof-pointer-memaccess
GCC9_PEDANTIC_CFLAGS += -Wstack-protector
GCC9_PEDANTIC_CFLAGS += -Wstrict-aliasing=1
GCC9_PEDANTIC_CFLAGS += -Wstrict-overflow=2
#GCC9_PEDANTIC_CFLAGS += -Wstrict-overflow=5
GCC9_PEDANTIC_CFLAGS += -Wstringop-overflow=4
GCC9_PEDANTIC_CFLAGS += -Wstringop-truncation
GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=cold
#GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=const
GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=format
GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=malloc
GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=noreturn
#GCC9_PEDANTIC_CFLAGS += -Wsuggest-attribute=pure
GCC9_PEDANTIC_CFLAGS += -Wsuggest-final-methods
GCC9_PEDANTIC_CFLAGS += -Wsuggest-final-types
GCC9_PEDANTIC_CFLAGS += -Wswitch
GCC9_PEDANTIC_CFLAGS += -Wswitch-bool
#GCC9_PEDANTIC_CFLAGS += -Wswitch-default
#GCC9_PEDANTIC_CFLAGS += -Wswitch-enum
GCC9_PEDANTIC_CFLAGS += -Wswitch-unreachable
GCC9_PEDANTIC_CFLAGS += -Wsync-nand
GCC9_PEDANTIC_CFLAGS += -Wtautological-compare
GCC9_PEDANTIC_CFLAGS += -Wtrampolines
GCC9_PEDANTIC_CFLAGS += -Wtrigraphs
GCC9_PEDANTIC_CFLAGS += -Wtype-limits
GCC9_PEDANTIC_CFLAGS += -Wundef
GCC9_PEDANTIC_CFLAGS += -Wuninitialized
GCC9_PEDANTIC_CFLAGS += -Wunknown-pragmas
GCC9_PEDANTIC_CFLAGS += -Wunreachable-code
GCC9_PEDANTIC_CFLAGS += -Wunsafe-loop-optimizations
GCC9_PEDANTIC_CFLAGS += -Wunused
GCC9_PEDANTIC_CFLAGS += -Wunused-but-set-parameter
GCC9_PEDANTIC_CFLAGS += -Wunused-but-set-variable
GCC9_PEDANTIC_CFLAGS += -Wunused-const-variable=2
GCC9_PEDANTIC_CFLAGS += -Wunused-function
GCC9_PEDANTIC_CFLAGS += -Wunused-label
GCC9_PEDANTIC_CFLAGS += -Wunused-local-typedefs
#GCC9_PEDANTIC_CFLAGS += -Wunused-macros
GCC9_PEDANTIC_CFLAGS += -Wunused-parameter
GCC9_PEDANTIC_CFLAGS += -Wunused-result
GCC9_PEDANTIC_CFLAGS += -Wunused-value
GCC9_PEDANTIC_CFLAGS += -Wunused-variable
GCC9_PEDANTIC_CFLAGS += -Wvarargs
GCC9_PEDANTIC_CFLAGS += -Wvariadic-macros
GCC9_PEDANTIC_CFLAGS += -Wvector-operation-performance
GCC9_PEDANTIC_CFLAGS += -Wvla
GCC9_PEDANTIC_CFLAGS += -Wvolatile-register-var
GCC9_PEDANTIC_CFLAGS += -Wwrite-strings

# disable some warnings
GCC9_PEDANTIC_CFLAGS += -Wno-long-long

# C++-specific warnings
GCC9_PEDANTIC_CXXFLAGS := $(GCC9_PEDANTIC_CFLAGS)
GCC9_PEDANTIC_CXXFLAGS += -Wabi-tag
GCC9_PEDANTIC_CXXFLAGS += -Waligned-new=all
GCC9_PEDANTIC_CXXFLAGS += -Wc++11-compat
GCC9_PEDANTIC_CXXFLAGS += -Wc++14-compat
GCC9_PEDANTIC_CXXFLAGS += -Wc++1z-compat
GCC9_PEDANTIC_CXXFLAGS += -Wcatch-value=3
GCC9_PEDANTIC_CXXFLAGS += -Wclass-conversion
GCC9_PEDANTIC_CXXFLAGS += -Wclass-memaccess
GCC9_PEDANTIC_CXXFLAGS += -Wconditionally-supported
GCC9_PEDANTIC_CXXFLAGS += -Wconversion-null
GCC9_PEDANTIC_CXXFLAGS += -Wctor-dtor-privacy
GCC9_PEDANTIC_CXXFLAGS += -Wdelete-incomplete
GCC9_PEDANTIC_CXXFLAGS += -Wdelete-non-virtual-dtor
GCC9_PEDANTIC_CXXFLAGS += -Wdeprecated-copy
GCC9_PEDANTIC_CXXFLAGS += -Wdeprecated-copy-dtor
#GCC9_PEDANTIC_CXXFLAGS += -Weffc++
GCC9_PEDANTIC_CXXFLAGS += -Wextra-semi
GCC9_PEDANTIC_CXXFLAGS += -Winherited-variadic-ctor
GCC9_PEDANTIC_CXXFLAGS += -Winit-list-lifetime
GCC9_PEDANTIC_CXXFLAGS += -Winvalid-offsetof
GCC9_PEDANTIC_CXXFLAGS += -Wliteral-suffix
GCC9_PEDANTIC_CXXFLAGS += -Wmultiple-inheritance
GCC9_PEDANTIC_CXXFLAGS += -Wnamespaces
GCC9_PEDANTIC_CXXFLAGS += -Wnoexcept
GCC9_PEDANTIC_CXXFLAGS += -Wnoexcept-type
GCC9_PEDANTIC_CXXFLAGS += -Wnon-template-friend
GCC9_PEDANTIC_CXXFLAGS += -Wnon-virtual-dtor
GCC9_PEDANTIC_CXXFLAGS += -Woverloaded-virtual
GCC9_PEDANTIC_CXXFLAGS += -Wpessimizing-move
GCC9_PEDANTIC_CXXFLAGS += -Wplacement-new=2
GCC9_PEDANTIC_CXXFLAGS += -Wpmf-conversions
GCC9_PEDANTIC_CXXFLAGS += -Wprio-ctor-dtor
GCC9_PEDANTIC_CXXFLAGS += -Wredundant-move
GCC9_PEDANTIC_CXXFLAGS += -Wregister
GCC9_PEDANTIC_CXXFLAGS += -Wreorder
GCC9_PEDANTIC_CXXFLAGS += -Wsign-promo
GCC9_PEDANTIC_CXXFLAGS += -Wsized-deallocation
GCC9_PEDANTIC_CXXFLAGS += -Wstrict-null-sentinel
GCC9_PEDANTIC_CXXFLAGS += -Wsubobject-linkage
GCC9_PEDANTIC_CXXFLAGS += -Wsuggest-override
GCC9_PEDANTIC_CXXFLAGS += -Wsynth
GCC9_PEDANTIC_CXXFLAGS += -Wtemplates
GCC9_PEDANTIC_CXXFLAGS += -Wterminate
#GCC9_PEDANTIC_CXXFLAGS += -Wuseless-cast
GCC9_PEDANTIC_CXXFLAGS += -Wvirtual-inheritance
GCC9_PEDANTIC_CXXFLAGS += -Wvirtual-move-assign
GCC9_PEDANTIC_CXXFLAGS += -Wzero-as-null-pointer-constant

# C-specific warnings
GCC9_PEDANTIC_CFLAGS += -Wabsolute-value
GCC9_PEDANTIC_CFLAGS += -Wbad-function-cast
GCC9_PEDANTIC_CFLAGS += -Wc++-compat
GCC9_PEDANTIC_CFLAGS += -Wc11-c2x-compat
GCC9_PEDANTIC_CFLAGS += -Wc99-c11-compat
GCC9_PEDANTIC_CFLAGS += -Wdeclaration-after-statement
GCC9_PEDANTIC_CFLAGS += -Wdesignated-init
GCC9_PEDANTIC_CFLAGS += -Wdiscarded-array-qualifiers
GCC9_PEDANTIC_CFLAGS += -Wdiscarded-qualifiers
GCC9_PEDANTIC_CFLAGS += -Wduplicate-decl-specifier
GCC9_PEDANTIC_CFLAGS += -Werror=implicit-function-declaration
GCC9_PEDANTIC_CFLAGS += -Wimplicit
GCC9_PEDANTIC_CFLAGS += -Wimplicit-function-declaration
GCC9_PEDANTIC_CFLAGS += -Wimplicit-int
GCC9_PEDANTIC_CFLAGS += -Wincompatible-pointer-types
GCC9_PEDANTIC_CFLAGS += -Wint-conversion
GCC9_PEDANTIC_CFLAGS += -Wjump-misses-init
GCC9_PEDANTIC_CFLAGS += -Wmissing-parameter-type
GCC9_PEDANTIC_CFLAGS += -Wmissing-prototypes
GCC9_PEDANTIC_CFLAGS += -Wnested-externs
GCC9_PEDANTIC_CFLAGS += -Wold-style-declaration
GCC9_PEDANTIC_CFLAGS += -Wold-style-definition
GCC9_PEDANTIC_CFLAGS += -Woverride-init
GCC9_PEDANTIC_CFLAGS += -Woverride-init-side-effects
GCC9_PEDANTIC_CFLAGS += -Wpointer-sign
GCC9_PEDANTIC_CFLAGS += -Wpointer-to-int-cast
GCC9_PEDANTIC_CFLAGS += -Wstrict-prototypes
#GCC9_PEDANTIC_CFLAGS += -Wunsuffixed-float-constants

# gcc 10

# common C/C++ warnings
GCC10_PEDANTIC_CFLAGS := -Wstring-compare
GCC10_PEDANTIC_CFLAGS += -Wzero-length-bounds

# C++-specific warnings
GCC10_PEDANTIC_CXXFLAGS := $(GCC9_PEDANTIC_CXXFLAGS) $(GCC10_PEDANTIC_CFLAGS)
GCC10_PEDANTIC_CXXFLAGS += -Wmismatched-tags
GCC10_PEDANTIC_CXXFLAGS += -Wredundant-tags

# C-specific warnings
GCC10_PEDANTIC_CFLAGS := $(GCC9_PEDANTIC_CFLAGS) $(GCC10_PEDANTIC_CFLAGS)
