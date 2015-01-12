# allow to join two or more makefiles in one makefile:
# include $(MTOP)/make_header.mk
# LIB = xxx1
# SRC = xxx.c
# include $(MTOP)/make_continue.mk
# LIB = xxx2
# SRC = xxx.c
# ...
# $(DEFINE_TARGETS)
ifndef MAKE_CONTINUE_HEADER
$(error Error: don't know how to continue, please include $(MTOP)/make_header.mk)
endif
SUB_LEVEL := $(SUB_LEVEL) 1
MAKE_CONT := $(MAKE_CONT) 2
$(MAKE_CONTINUE_FOOTER)
SUB_LEVEL := $(wordlist 2,999999,$(SUB_LEVEL))
$(MAKE_CONTINUE_HEADER)
MAKE_CONT += 1
