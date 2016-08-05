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
# compile.mk
# Defines the variables used to configure the toolchain for building artifacts.
#
# Variable requirements:
# 	SDK_BASE_DIR - path to base of SDK directory

#----------------------------------------------------------------------------
# Set up build tool definitions
#----------------------------------------------------------------------------
TEMPLATE_DIR := $(SDK_BASE_DIR)/components/toolchain/gcc
# this include sets GNU_INSTALL_ROOT, GNU_PREFIX
ifdef COMSPEC
  include $(TEMPLATE_DIR)/Makefile.windows
else
  include $(TEMPLATE_DIR)/Makefile.posix
endif

CC              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gcc'
CPP             := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gcc' -E
AS              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-as'
AR              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ar' -r
LD              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ld'
NM              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-nm'
OBJDUMP         := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objdump'
OBJCOPY         := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objcopy'
SIZE            := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-size'

#----------------------------------------------------------------------------
# Create lower case versions of device, variant, softdevice
#----------------------------------------------------------------------------
LC_DEVICE_SERIES  = $(call tolower,$(DEVICE_SERIES))
LC_DEVICE_VARIANT = $(call tolower,$(DEVICE_VARIANT))

#----------------------------------------------------------------------------
# Add system, startup, and linker files used by all builds
#----------------------------------------------------------------------------
SOURCE = $(SDK_BASE_DIR)/components/toolchain/system_$(LC_DEVICE_SERIES).c \
				 $(SDK_BASE_DIR)/components/toolchain/gcc/gcc_startup_$(LC_DEVICE_SERIES).s

LINKER_SCRIPT ?= $(SDK_BASE_DIR)/components/toolchain/gcc/$(LC_DEVICE_SERIES)_xx$(LC_DEVICE_VARIANT).ld

#----------------------------------------------------------------------------
# Set pre-processor flags
#----------------------------------------------------------------------------
ifeq ($(CFG_IS_DEBUG),true)
  CPPFLAGS += -DDEBUG
else
  CPPFLAGS += -DNDEBUG
endif

CPPFLAGS += -D$(call toupper,$(DEVICE_SERIES))
ifeq ($(call toupper,$(DEVICE_SERIES)),NRF52)		# add errata
  CPPFLAGS += -DNRF52_PAN_12
  CPPFLAGS += -DNRF52_PAN_15
  CPPFLAGS += -DNRF52_PAN_58
  CPPFLAGS += -DNRF52_PAN_20
  CPPFLAGS += -DNRF52_PAN_54
  CPPFLAGS += -DNRF52_PAN_31
  CPPFLAGS += -DNRF52_PAN_30
  CPPFLAGS += -DNRF52_PAN_51
  CPPFLAGS += -DNRF52_PAN_36
  CPPFLAGS += -DNRF52_PAN_53
  CPPFLAGS += -DNRF52_PAN_64
  CPPFLAGS += -DNRF52_PAN_55
  CPPFLAGS += -DNRF52_PAN_62
  CPPFLAGS += -DNRF52_PAN_63
endif

#----------------------------------------------------------------------------
# Set compile flags
#----------------------------------------------------------------------------
CFLAGS = $(OPTIM)
ifeq ($(CFG_IS_DEBUG),true)
  CFLAGS += -Og
endif
CFLAGS += -std=gnu99 -mthumb -mabi=aapcs -fno-builtin --short-enums
CFLAGS += -ffunction-sections -fdata-sections -fno-strict-aliasing
CFLAGS += -Werror -Wall -Wno-unused-parameter -Wno-extra -Wpacked
CFLAGS += -mcpu=$(CFG_TARGET_CPU) -mtune=$(CFG_TARGET_CPU)
ifeq ($(CFG_TARGET_CPU),cortex-m4)
  CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
else
  CFLAGS += -mfloat-abi=soft -mfpu=vfp
endif

DEPFLAGS = -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"

COMPILER = $(CC) $(CFLAGS) $(CPPFLAGS) $(INCLUDES) $(DEPFLAGS)

#----------------------------------------------------------------------------
# Set assembler flags
#----------------------------------------------------------------------------
# set up the common options
ASMFLAGS = -x assembler-with-cpp
ifeq ($(CFG_IS_DEBUG),true)
  ASMFLAGS += -g
endif
ASMFLAGS += -mcpu=$(CFG_TARGET_CPU) -mthumb
ASMFLAGS += -D$(call toupper,$(DEVICE_SERIES))

ASSEMBLER = $(CC) $(ASMFLAGS) $(CPPFLAGS) $(INCLUDES) $(DEPFLAGS)

#----------------------------------------------------------------------------
# Set linker flags
#----------------------------------------------------------------------------
LDFLAGS  = -Xlinker -Map=$(BUILD_DIR)/$(PROJECT_NAME).map
LDFLAGS += -mthumb -mabi=aapcs -mcpu=$(CFG_TARGET_CPU)
ifneq ($(CFG_IS_DEBUG),true)
  LDFLAGS += -s
endif
LDFLAGS += -L $(TEMPLATE_DIR) -T $(LINKER_SCRIPT)
ifeq ($(CFG_TARGET_CPU),cortex-m4)
  LDFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
else
  LDFLAGS += -mfloat-abi=soft -mfpu=vfp
endif
LDFLAGS += -Wl,--gc-sections -Wl,--fatal-warnings
LDFLAGS += --specs=nano.specs -lc -lnosys

# if any below not previously set, clearing them ensures they exists (avoids a warning)
LIBS     ?=
# typically set to -L lib_dir_path
LIBDIRS  ?=

LINKER = $(CC) $(LDFLAGS) $(LIBDIRS)

#----------------------------------------------------------------------------
# Set librarian flags
#----------------------------------------------------------------------------
ARFLAGS  = rucvs

#----------------------------------------------------------------------------
# Various macros and variables to make rules and targets simpler
#----------------------------------------------------------------------------
# Macro to take a list of source files and create a list of output files with
# the supplied directory path prepended and the supplied suffix replacing the
# original suffix.
# supplied suffix (e.g., file.c -> Debug/file.o)
#   $(call output-files,source_list,output_dir,suffix)
output-files = $(addprefix $2/,$(addsuffix $3,$(notdir $(basename $(strip $1)))))

# Macro to take a list composed of directories (with trailing "/") and append
# the % wildcard used to pattern match (i.e., in a filter or filter-out command)
#   $(call add-dir-wildcard,dir_list)
add-dir-wildcard = $(patsubst %/,%/%,$(strip $1))

# if SOURCE not previously set, clearing it ensures it exists (avoids a warning)
# Note: SOURCE variable drives much of the build system makefiles, so it is
# important that is is set appropriately in the project's makefile.
SOURCE   ?=
C_FILES   = $(filter %.c,$(strip $(SOURCE)))
ASM_FILES = $(filter %.s,$(strip $(SOURCE)))
COMPILE_FILES = $(C_FILES) $(ASM_FILES)

OBJ_FILES = $(call output-files,$(COMPILE_FILES),$(BUILD_DIR),.o)
DEP_FILES = $(call output-files,$(COMPILE_FILES),$(BUILD_DIR),.d)
PREPROC_FILES  = $(call output-files,$(COMPILE_FILES),$(BUILD_DIR),.i)

# if INCLUDE_DIRS not previously set, clearing it ensures it exists (avoids a warning)
INCLUDE_DIRS ?=
INCLUDES      = $(foreach incdir,$(strip $(INCLUDE_DIRS)),-I $(incdir))

PROJECT_BINFILE = $(BUILD_DIR)/$(PROJECT_NAME).bin

