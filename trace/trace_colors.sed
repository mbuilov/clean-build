# colorize traced macros, invoke as:
#  make -f test.mk 2>&1 | sed -f trace_colors.sed

# test.mk:1: tracefn: $(macrox) {
s/ tracefn: \($([^)]*)\) {$/ [35;1mtracefn:[m [32;1m\1[m [36m{[m/;t
# tracefn: } $(macrox)
s/^tracefn: } \($([^)]*)\)$/[35;1mtracefn:[m [36m}[m [31;1m\1[m/;t
# test.mk:1:  macroX-> macroY-> $(macroZ) 2{
s/ \($([^)]*)\) \([0-9][0-9]*\){$/ [32;1m\1[m [36m\2{[m/;t
# <------- }2 $(macroZ)
s/^<------- }\([0-9][0-9]*\) \($([^)]*)\)$/[33m<-------[m [36m}\1[m [31;1m\2[m/;t
# --- macrox value---->
s/^--- \([^ ]*\) value---->$/[32m---[m [32m\1[m [32mvalue---->[m/;t
# --- macrox result--->
s/^--- \([^ ]*\) result--->$/[33m---[m [32m\1[m [33mresult--->[m/;t
# 0<xxxx>
s/^[0-9][0-9]*</[36m&[m/
# macrox: dump: A:=<B>
s/^\([^=: ][^=: ]*\): dump: \([^=: ][^=: ]*\)\([:]\)=/[32m\1[m: [35;1mdump[m: [34;1m\2[m\3=/
s/^d</[31m&[m/
s/$(if /$([33;1mif[m /g
s/$(or /$([33;1mor[m /g
s/$(and /$([33;1mand[m /g
s/$(dir /$([33;1mdir[m /g
s/$(eval /$([33;1meval[m /g
s/$(call /$([33;1mcall[m /g
s/$(info /$([33;1minfo[m /g
s/$(join /$([33;1mjoin[m /g
s/$(sort /$([33;1msort[m /g
s/$(word /$([33;1mword[m /g
s/$(error /$([33;1merror[m /g
s/$(strip /$([33;1mstrip[m /g
s/$(shell /$([33;1mshell[m /g
s/$(subst /$([33;1msubst[m /g
s/$(value /$([33;1mvalue[m /g
s/$(words /$([33;1mwords[m /g
s/$(flavor /$([33;1mflavor[m /g
s/$(filter /$([33;1mfilter[m /g
s/$(notdir /$([33;1mnotdir[m /g
s/$(origin /$([33;1morigin[m /g
s/$(suffix /$([33;1msuffix[m /g
s/$(abspath /$([33;1mabspath[m /g
s/$(foreach /$([33;1mforeach[m /g
s/$(warning /$([33;1mwarning[m /g
s/$(basename /$([33;1mbasename[m /g
s/$(lastword /$([33;1mlastword[m /g
s/$(patsubst /$([33;1mpatsubst[m /g
s/$(realpath /$([33;1mrealpath[m /g
s/$(wildcard /$([33;1mwildcard[m /g
s/$(wordlist /$([33;1mwordlist[m /g
s/$(addprefix /$([33;1maddprefix[m /g
s/$(addsuffix /$([33;1maddsuffix[m /g
s/$(firstword /$([33;1mfirstword[m /g
s/$(findstring /$([33;1mfindstring[m /g
s/$(filter-out /$([33;1mfilter-out[m /g
s/define /[35mdefine[m /g
s/endef/[35m&[m/g
s/include /[35minclude[m /g
s/ifeq /[35mifeq[m /g
s/ifneq /[35mifneq[m /g
s/endif/[35m&[m/g
s/else/[35m&[m/g
s/\.PHONY/[35m&[m/g
s/[%(),$=|]/[36;1m&[m/g
s/+\[36;1m=\[m/[36;1m+=[m/g
s/:\[36;1m=\[m/[36;1m:=[m/g
s/\[36;1m$\[m\([_0-9a-zA-Z]\)/[35;1m$\1[m/g
# match $123=
s/^\[35;1m$\([0-9]\)\[m\([0-9]*\)\[36;1m=\[m/[34;1m$\1\2=[m/
