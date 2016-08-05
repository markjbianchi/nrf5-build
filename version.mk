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
# version.mk
# Defines variables and targets for generating a version include file
#
# host_os.mk should be included before this file.
# Variable requirements:
# 	FW_VERSION_FILE - path and name of version file (defaults to
#                     $(PROJECT_DIR)/include/version.h)

#-----------------------------------------------------------------------------
# Revision stamp variables
#-----------------------------------------------------------------------------
DATETIME      := $(shell date +%c)
DATESTAMP     := $(shell date +%Y%m%d)
ifeq ($(OS),Windows_NT)
  ifndef CYGPATH
    BUILDNUM      := 0
    BUILDNUM_STR  := 0000
    COMMIT_STR    := windows
  else
    BUILDNUM      := $(shell git rev-list --count HEAD)
    BUILDNUM_STR  := $(shell echo ${BUILDNUM} | xargs printf %04d)
    COMMIT_STR    := $(shell git rev-list --abbrev-commit --max-count=1 HEAD)
  endif
else
  BUILDNUM      := $(shell git rev-list --count HEAD)
  BUILDNUM_STR  := $(shell echo ${BUILDNUM} | xargs printf %04d)
  COMMIT_STR    := $(shell git rev-list --abbrev-commit --max-count=1 HEAD)
endif
FW_VERSION_FILE ?= $(CUR_DIR)/include/version.h

#-----------------------------------------------------------------------------
# Build targets
#-----------------------------------------------------------------------------
#.PHONY : version

version: MAJOR := $(shell read -p 'Major ver: ' maj; echo $$maj)
version: MINOR := $(shell read -p 'Minor ver: ' min; echo $$min)

version:
	@echo '// This file was generated - Do Not Edit!'          > ${FW_VERSION_FILE}
	@echo '// Created: ${DATETIME}'                           >> ${FW_VERSION_FILE}
	@echo                                                     >> ${FW_VERSION_FILE}
	@echo '#define FW_VERSION_STR           "${MAJOR}.${MINOR}.${BUILDNUM_STR}"' >> ${FW_VERSION_FILE}
	@echo '#define FW_VERSION_DATESTAMP     ${DATESTAMP}L'     >> ${FW_VERSION_FILE}
	@echo '#define FW_VERSION_BUILDNUM_STR  "${BUILDNUM_STR}"' >> ${FW_VERSION_FILE}
	@echo '#define FW_VERSIION_COMMIT_STR   "${COMMIT_STR}"'   >> ${FW_VERSION_FILE}
	@echo                                                     >> ${FW_VERSION_FILE}
	@echo                                                     >> ${FW_VERSION_FILE}
#	@unix2dos ${FW_VERSION_FILE} >/dev/null 2>&1
