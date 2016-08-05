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
# targets.mk
# Defines the common make targets.

#----------------------------------------------------------------------------
# Figure out if the target cares about dependency files or config file
#----------------------------------------------------------------------------
# list of targets that do not rely on .d files...
NON_DEPENDENT_TARGETS := configure \
                         clean distclean \
                         gccversion help noop targets diagnose
ifneq ($(filter-out $(NON_DEPENDENT_TARGETS),$(MAKECMDGOALS)),)
  NEED_DEP_FILES := 1
else
  NEED_DEP_FILES := 0
endif

# list of targets that rely on "make configure" step...
CONFIG_TARGETS        := all clean distclean build

ifeq ($(filter-out $(CONFIG_TARGETS),$(MAKECMDGOALS)),)
  NEED_CONFIG_FILE = 1
else
  NEED_CONFIG_FILE = 0
endif

#----------------------------------------------------------------------------
# Echo the target being built; a no-functioning target - just used to log
# info to the build output
#----------------------------------------------------------------------------
.PHONY : begin
BEGIN =
begin :
	@if [ "x" != "x$(BEGIN)" ] ; then echo "$(BEGIN):" ; fi

#----------------------------------------------------------------------------
# Create build artifacts directory if doesn't exist
#----------------------------------------------------------------------------
.PHONY : init end

init : BEGIN=init
init : begin
	@echo "     [date] start date - $(START_DATE)"
	$(Q)$(call make-dir,$(BUILD_DIR))

end :
	@echo "     [date] end date - $(shell $(DATE))"

#----------------------------------------------------------------------------
# Target for creating a build configuration. After involing "make configure"
# a persistent build setup is created until "make distclean" is invoked.
#----------------------------------------------------------------------------
.PHONY : configure
configure : BEGIN=configure
configure : begin
	$(Q)$(UCTOOLS_DIR)/config.sh -o $(CONFIG_FILE) -p
	@echo "[configure] ============================ configured properties ============================"
	$(Q)cat $(CONFIG_FILE)
	@echo

#-------------------------------------------------------------------------------
# Remove build artifacts directory and configuration file
#-------------------------------------------------------------------------------
.PHONY : clean distclean

clean : BEGIN=clean
clean : begin
	@echo "   [delete] deleting directory $(BUILD_DIR)"
	$(Q)$(RMDIR) $(BUILD_DIR)

distclean : BEGIN=distclean
distclean : begin clean
	@echo "   [delete] deleting $(CONFIG_FILE)"
	$(Q)$(RM) $(CONFIG_FILE)

#----------------------------------------------------------------------------
# Show compiler version, for build log
#----------------------------------------------------------------------------
.PHONY : gccversion
gccversion :
	@$(CC) --version

#----------------------------------------------------------------------------
# Show all possible targets; diagnose a makefile/dependency problem
#----------------------------------------------------------------------------
.PHONY : help noop targets diagnose

help :
	@echo "Generic targets:"
	@echo "  help            - Show this help message"
	@echo "  targets         - List all possible make targets"
	@echo "  configure       - Prompts for various info needed to configure the build"
	@echo "  all             - Build \"all\" targets (default)"
	@echo "  clean           - Remove most generated files but keep the config and tags files"
	@echo "  distclean       - Remove all generated files"
	@echo "  diagnose [targets]        - Print debugging information (diagnosing Makefile problems)"
	@echo "  make VERBOSE=1 [targets]  - Verbose build; prints detailed commands"
	@echo ""

noop : ;

targets :
	$(Q)$(MAKE) --print-data-base --question noop | \
      grep -v "[A-Z]:/" | \
      awk '/^Makefile:/             { next } \
           /^begin:/                { next } \
           /^end:/                  { next } \
           /^gccversion:/           { next } \
           /^init[-a-z]*:/          { next } \
           /^[Mm]akefile:/          { next } \
           /^noop:/                 { next } \
           /^targets:/              { next } \
           /^[^.%!][-A-Za-z0-9_]*:/ { print substr($$1, 1, length($$1)-1) }' | \
      sort | pr -t -w 80 -4

diagnose :
	$(Q)$(MAKE) --debug=v --just-print --warn-undefined-variables $(filter-out diagnose,$(MAKECMDGOALS))

