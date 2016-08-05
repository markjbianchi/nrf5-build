#!/usr/bin/env bash
#
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
# Shell script for creating a build configuration file
#   User is optionally prompted with options for each of the key build parameters.
#   Resulting answers are written to commandline-supplied filename as make include file.
#
#----------------------------------------------------------------------------
# usage function
#----------------------------------------------------------------------------
function usage {
  local errmsg="$1"

  if [ "_$errmsg" != "_" ] ; then
    echo
    echo "$errmsg"
    echo
  fi
  echo "Usage: `basename $0` -o outfile [-p] [-i infile] [-M \"MAKEVAR = abc\"] [-D CfgVar=xyz]"
  echo "  -o outfile          name of file to write results to"
  echo "  -p                  prompt user to select options"
  echo "  -i infile           name of input file to append to config file. This file is intended to"
  echo "                      contain make variables or macros. If -p also set, then the user is not"
  echo "                      prompted for additional content - the assumption is that the additional"
  echo "                      content is contained in infile."
  echo "  -M \"MAKEVAR = xyz\"  make variable assignment(s)"
  echo "  -D Cfgvar=xyz       configuration variable assignment(s). Recognized variables and options:"
  echo "                          Cpu=[${CPU_OPTIONS// /|}]"
  echo "                          Debug=[${DEBUG_OPTIONS// /|}]"
  echo "                          Optim=[${OPTIMIZE_OPTIONS// /|}]"
}

#----------------------------------------------------------------------------
# function that does all the work of prompting for a selection
#----------------------------------------------------------------------------
function choose_one {
  local prompt="$1"
  local choices="$2"
  PS3="$3"
  local input=""

  echo ; echo $prompt
  select input in $choices ; do
    if [ ${#input} -eq 0 ] ; then
      echo "Invalid choice - select the number next to the desired choice"
    else
      the_choice=$input
      break
    fi
  done
}

#----------------------------------------------------------------------------
# function that prompts user to choose values for various configuration parameters
#----------------------------------------------------------------------------
function prompt_for_answers {
  local the_choice=""

  choose_one "Select the target CPU..." "$CPU_OPTIONS" "CPU? "
  Cpu=$the_choice

  choose_one "Is this a debug build..." "$DEBUG_OPTIONS" "Debug? "
  Debug=$the_choice

  choose_one "Select the compiler optimization level..." "$OPTIMIZE_OPTIONS" "Level? "
  Optim=$the_choice
}

#----------------------------------------------------------------------------
# function that outputs the result of the selections
#----------------------------------------------------------------------------
function save_results {
  local file="$1"
  local dir=$(dirname $file)
  local gitbuild=$(git rev-list --count HEAD | xargs printf "%04d")

  {
    echo "# target CPU: $CPU_OPTIONS"
    echo "CFG_TARGET_CPU := $Cpu"
    echo
    echo "# debug: $DEBUG_OPTIONS"
    echo "CFG_IS_DEBUG   := $Debug"
    echo
    echo "# optimization: $OPTIMIZE_OPTIONS"
    echo "CFG_OPTIMIZE   := $Optim"
    echo
    echo "GIT_BUILDNUM   := $gitbuild"

    case $Optim in
      min)    echo "OPTIM          := -O1" ;;
      normal) echo "OPTIM          := -O2" ;;
      max)    echo "OPTIM          := -O3" ;;
      size)   echo "OPTIM          := -Os" ;;
      *)      echo "OPTIM          := -O0" ;;
    esac
  } > $file
}

#----------------------------------------------------------------------------
# function that prompts user to enter any additonal info for config file
#----------------------------------------------------------------------------
function prompt_for_extra {
  local file="$1"

  echo
  echo "Enter additional content to be added to configuration file, e.g.:"
  echo "  UCTOOLS_DIR := $(PROJECT_BASE_DIR)/tools"
  echo "  CPPFLAGS  += -D TURN_IT_ON"
  echo "(Hit <Enter> on an empty line to exit)"
  while read ; do
    if [ "_$REPLY" != "_"  ] ; then
      echo $REPLY >> $file
    else
      break
    fi
  done
}

#----------------------------------------------------------------------------
# function to verify value is contained in supplied list
#----------------------------------------------------------------------------
function is_value_in_list {
  local value="$1"
  local list="$2"
  local item=

  for item in $list ; do
    if [ $value = $item ] ; then
      return 0  # true
    fi
  done
  return 1      # false
}

#----------------------------------------------------------------------------
# function to process a commandline-supplied configuration variable
#----------------------------------------------------------------------------
function handle_cfg_var {
  local line="$1"
  local var=${line%%=*}
  local value=${line##*=}
  local opt=

  # Make sure the variable/assignment is well-formed (if var == line, then
  # there is no "=" present, if length value == 0, then nothing assigned).
  if [ "$var" = "$line" -o ${#value} -eq 0 ] ; then
    usage "No assignment made to configuration variable: $var"
    exit 1
  fi

  # See if variable is one of the possibles and that the assigned option is valid
  case "$var" in
    Cpu)   is_value_in_list "$value" "$CPU_OPTIONS"
            if [ $? -ne 0 ] ; then
              usage "Invalid assignment to $var: $value"
              exit 1
            fi ;;

    Debug)  is_value_in_list "$value" "$DEBUG_OPTIONS"
            if [ $? -ne 0 ] ; then
              usage "Invalid assignment to $var: $value"
              exit 1
            fi ;;

    Optim)  is_value_in_list "$value" "$OPTIMIZE_OPTIONS"
            if [ $? -ne 0 ] ; then
              usage "Invalid assignment to $var: $value"
              exit 1
            fi ;;

    *)      usage "Invalid configuration variable: $var"
            exit 1 ;;
  esac

  # Assign the valid value to the valid config var
  eval $var=$value
}

#----------------------------------------------------------------------------
# function to process a commandline-supplied make variable
#----------------------------------------------------------------------------
function handle_make_var {
  # ${#Makevars[@]} is the number of elements in the array, so this one-liner
  # is a tricky way of appending elements to the array - each call assigns
  # $1 to the next open array element (starting with elem 0)
  Makevars[${#Makevars[@]}]="$1"
}

#----------------------------------------------------------------------------
# Option lists, config var defaults
#----------------------------------------------------------------------------
CPU_OPTIONS="cortex-m0 cortex-m3 cortex-m4 unknown"
DEBUG_OPTIONS="true false"
OPTIMIZE_OPTIONS="none min normal max size"

Cpu=cortex-m0
Debug=true
Optim=normal

declare -a Makevars
#----------------------------------------------------------------------------
# Main script
#----------------------------------------------------------------------------
outfile=
prompt=n
infile=

# parse the command line options
while getopts ":o:pi:M:D:" flag ; do
  case "$flag" in
    o) outfile="$OPTARG"          ;;
    p) prompt=y                   ;;
    i) infile="$OPTARG"           ;;
    M) handle_make_var "$OPTARG"  ;;
    D) handle_cfg_var "$OPTARG"   ;;
    :) usage "Option \"$OPTARG\" requires and argument."
       exit 1
       ;;
    ?) usage "Invalid option: $OPTARG"
       exit 1
       ;;
  esac
done

# Make sure an output file was supplied. If input file was given, make sure
# it exists.
if [ -z $outfile ] ; then
  usage "Must provide an output file."
  exit 1
else
  > $outfile
fi
if [ ! -z $infile ] ; then
  if [ ! -f $infile ] ; then
    usage "Input file \"$infile\" doesn't exist!"
    exit 1
  fi
fi

# Prompt the user for answers if requested
if [ $prompt = "y" ] ; then
  prompt_for_answers
fi

# Write the results to the output file. If an input file was specified
# append that file to the output file; otherwise, if user is being
# prompted then continue by asking for any additional info and append
# it to output file
save_results $outfile
if [ ! -z $infile ] ; then
  cat $infile >> $outfile
elif [ $prompt = "y" ] ; then
  prompt_for_extra $outfile
fi

# Append any make variables set on the command line to the output file
for elem in "${Makevars[@]}" ; do
  echo $elem
done >> $outfile

exit 0

