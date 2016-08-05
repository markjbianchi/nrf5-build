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
# rules.mk
# Defines the standard rules for creating various target files.

# Delete all standard suffixes just so we don't get inadvertent suffix rules
# coming into play. We only want pattern rules that we specify.
.SUFFIXES :

#----------------------------------------------------------------------------
# Rules for compiling a .s to generate a .o in the $BUILD_DIR
#----------------------------------------------------------------------------
define compile-asm-file
$(BUILD_DIR)/$(notdir $(basename $(1))).o : $(1)
	@echo "       [as] compiling $$<"
	$(Q)$$(ASSEMBLER) -c -o $$@ $$<
endef

#----------------------------------------------------------------------------
# Rules for compiling a .c to generate a .o in the $BUILD_DIR
#----------------------------------------------------------------------------
define compile-c-file
$(BUILD_DIR)/$(notdir $(basename $(1))).o : $(1)
	@echo "       [cc] compiling $$<"
	$(Q)$$(COMPILER) -c -o $$@ $$<
endef

#----------------------------------------------------------------------------
# Rule for preprocessing a .c to generate a .i in the $BUILD_DIR
#----------------------------------------------------------------------------
define preproc-c-file
$(BUILD_DIR)/$(notdir $(basename $(1))).i : $(1)
	@echo "       [cc] preprocessing $$<"
	$(Q)$$(CPP) $$(INCLUDES) $$(CPPFLAGS) -o $$@ $$<
endef

#----------------------------------------------------------------------------
# Rules for creating an ELF executable
#----------------------------------------------------------------------------
$(BUILD_DIR)/%.out : $(OBJ_FILES) $(LIBS)
	@echo "       [ld] starting link $(*).out"
	$(Q)$(LINKER) $(OBJ_FILES) $(LIBS) -o $@

#----------------------------------------------------------------------------
# Rules for creating binary file and intel hex file from ELF executable
#----------------------------------------------------------------------------
$(BUILD_DIR)/%.bin : %.out
	@echo "  [objcopy] translating/stripping $<"
	$(Q)$(OBJCOPY) -O binary $< $@
	$(Q)$(SIZE) $< ; #$(Q)$(OBJDUMP) -h -S $< > $*.lss

$(BUILD_DIR)/%.hex : %.out
	@echo "  [objcopy] translating/stripping $<"
	$(Q)$(OBJCOPY) -O ihex $< $@
	$(Q)$(SIZE) $< ; #$(Q)$(OBJDUMP) -h -S $< > $*.lss

#----------------------------------------------------------------------------
# Rules for programming device
#----------------------------------------------------------------------------
flash : $(BUILD_DIR)/%.hex
	@echo "  [nrfjprog] flashing $<"
	$(Q)nrfjprog --program $< -f $(call tolower,$(DEVICE_SERIES)) --chiperase
	$(Q)nrfjprog --reset -f $(call tolower,$(DEVICE_SERIES))

flash_softdevice :
	@echo Flashing s130_nrf51_2.0.0_softdevice.hex
	nrfjprog --program ../../components/softdevice/s130/hex/s130_nrf51_2.0.0_softdevice.hex -f nrf51 --chiperase
	nrfjprog --reset -f nrf51
