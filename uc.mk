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
# uc.mk
# Defines functions and variables used to make the Makefiles cleaner, set
# up standard macros/vars, and provide operating system abstraction.

#----------------------------------------------------------------------------
# Make program configuration
#----------------------------------------------------------------------------
# Do not use make's built-in rules and variables; print "Entering directory..."
MAKEFLAGS += -rR --no-print-directory

#MAKEFILE_NAME := $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
MAKEFILE_NAME := $(MAKEFILE_LIST)
MAKEFILE_DIR  := $(dir $(MAKEFILE_NAME) )

#----------------------------------------------------------------------------
# Verify that key variable have been set in project Makefile
#----------------------------------------------------------------------------
PROJECT_NAME ?= none
ifndef DEVICE_SERIES
	$(error DEVICE_SERIES must be set to the nRF5x device used)
endif
ifndef DEVICE_VARIANT
	$(error DEVICE_VARIANT must be set to the nRF5x device variant used)
endif

ifndef PROJECT_BASE_DIR
	$(error PROJECT_BASE_DIR must be set to the path at the root of the project)
endif
ifndef UCTOOLS_DIR
	$(error UCTOOLS_DIR must be set to the path containing the make scripts)
endif
ifndef SDK_BASE_DIR
	$(error SDK_BASE_DIR must be set to the path containing the Nordic SDK)
endif

#----------------------------------------------------------------------------
# Verbosity of the make system
#----------------------------------------------------------------------------
# To put more focus on warnings, be less verbose by default.
# Use "make VERBOSE=1" on the command line to see full commands
ifdef VERBOSE
  ifeq ("$(origin VERBOSE)","command line")
    Q :=
  endif
else
  Q := @
endif

#----------------------------------------------------------------------------
# Host operating system abstraction macros file
#----------------------------------------------------------------------------
include $(UCTOOLS_DIR)/host_os.mk

#----------------------------------------------------------------------------
# Housekeeping variables
#----------------------------------------------------------------------------
# get the starting time to enable an elapsed time measurement
START_TIME := $(shell $(DATE_IN_SECS))
START_DATE := $(shell $(DATE))
BUILD_TIMESTAMP := $(shell $(TIMESTAMP))

#----------------------------------------------------------------------------
# Common make targets to be built
#----------------------------------------------------------------------------
# set default make goal "all", e.g., typing make with no target
# NOTE: the actual project-specific "all" target is defined in the project
# makefile which includes this file.
.DEFAULT_GOAL := all
MAKECMDGOALS  ?= all

# read in all the common make targets.
include $(UCTOOLS_DIR)/targets.mk

#----------------------------------------------------------------------------
# Configuration file include
#----------------------------------------------------------------------------
CONFIG_FILE = $(PROJECT_BASE_DIR)/config.mk

ifeq ($(NEED_CONFIG_FILE),1)
  ifneq ($(wildcard $(CONFIG_FILE)),$(CONFIG_FILE))
    $(error config file not present - run "make configure" first)
  endif
endif
-include $(CONFIG_FILE)

#----------------------------------------------------------------------------
# Standard build variables
#----------------------------------------------------------------------------
# specify the output location for all build artifacts
ifeq ($(CFG_IS_DEBUG),true)
  BUILD_DIR = $(PROJECT_BASE_DIR)/Debug
else
  BUILD_DIR = $(PROJECT_BASE_DIR)/Release
endif

#----------------------------------------------------------------------------
# Toolchain file include
#----------------------------------------------------------------------------
include $(UCTOOLS_DIR)/compile.mk

#----------------------------------------------------------------------------
# Common make rules include
#----------------------------------------------------------------------------
include $(UCTOOLS_DIR)/rules.mk

#----------------------------------------------------------------------------
# Version generation include
#----------------------------------------------------------------------------
#include $(UCTOOLS_DIR)/version.mk

