# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
#****************************************************************************
#
# host_os.mk
# Defines variables and macros used to abstract out the host operating system

#-------------------------------------------------------------------------------
# Windows not supported
#-------------------------------------------------------------------------------
ifdef COMPSPEC
  ifndef CYGPATH
    $(error Native Windows build not supported - must use Cygwin instead)
  endif
endif

#-------------------------------------------------------------------------------
# Linux & Cygwin common
#-------------------------------------------------------------------------------
AND     := ;
RM      := rm -f
RMDIR   := rm -rf
MV      := mv -f
CP      := cp -f
MKDIR   := mkdir -p
DEVNULL := /dev/null
DATE    := date
DATE_IN_SECS := date "+%s"
TIMESTAMP    := date "+%Y%m%d%H%M%S"

#-------------------------------------------------------------------------------
# Cygwin-specific and Linux-specific
#-------------------------------------------------------------------------------
ifdef CYGPATH
  DBL_QTE := \\\"
else
  DBL_QTE := \"
endif

#-------------------------------------------------------------------------------
# Macro definitions
#-------------------------------------------------------------------------------
make-dir = $(if $(wildcard $(1)),,$(MKDIR) $(1);echo "    [mkdir] Created dir: $(1)")

define elapsed-time
	@echo "Total time: $(shell expr $(shell $(DATE_IN_SECS)) - $(START_TIME)) seconds"
endef

#function for removing duplicates in a list
remduplicates = $(strip $(if $1,$(firstword $1) $(call remduplicates,$(filter-out $(firstword $1),$1))))

tolower = $(shell echo $(1) | tr "[:upper:]" "[:lower:]")
toupper = $(shell echo $(1) | tr "[:lower:]" "[:upper:]")

