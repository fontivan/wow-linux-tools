#!/usr/bin/env bash

########################################################################################################################
# MIT License
#
# Copyright (c) 2021 fontivan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
########################################################################################################################

########################################################################################################################
### Configuration
########################################################################################################################
set -eou pipefail

########################################################################################################################
# Constants
########################################################################################################################

if [[ -z "${1}" ]]; then
  echo "ERROR: Provide path to Lutris Battle.net installation folder as $arg1"
  exit 1
fi

BNET_HOME="${1}"
C_DRIVE="/drive_c/Program Files (x86)"
PROGRAM_FILES_PATH="${BNET_HOME}/${C_DRIVE}"
WOW_HOME="${PROGRAM_FILES_PATH}/World of Warcraft"
CLASSIC_WOW="${WOW_HOME}/_classic_"
RETAIL_WOW="${WOW_HOME}/_retail_"
CURSEBREAKER_EXECUTABLE="CurseBreaker"

MANDATORY_FOLDERS=(
  "${BNET_HOME}"
  "${WOW_HOME}"
)

WOW_FOLDERS=(
  "${CLASSIC_WOW}"
  "${RETAIL_WOW}"
)

########################################################################################################################
### Functions
########################################################################################################################

########################################################################################################################
# TODO: Add header
########################################################################################################################
function ValidateFolders() {

  # All the folders in this list must be present to continue.
  for FOLDER in "${MANDATORY_FOLDERS[@]}"; do

    # Tell the user what we're about to test
    echo "INFO: Checking if directory '${FOLDER}' exists..."

    # Check if the folder is present
    if [[ ! -d "${FOLDER}" ]]; then

      # If its not present then spit out the error and return 1
      echo "ERROR: Directory '${FOLDER}' not found."
      return 1
    fi
  done

  # If we got here then we know all the mandatory folders were present.
  echo "INFO: All mandatory folders present!"

  # This local variable will be used to store the state that at least one World of Warcraft folder is detected.
  local atLeastOneWowVersionInstalled
  atLeastOneWowVersionInstalled="false"

  # At least one of the folders in this list must be present.
  for FOLDER in "${WOW_FOLDERS[@]}"; do

    # Tell the user what we're about to test
    echo "INFO: Checking if directory '${FOLDER}' exists..."

    # Check if the folder is present
    if [[ ! -d "${FOLDER}" ]]; then

      # Print a warning if its not present.
      echo "WARN: Directory '${FOLDER}' not found."
    else
      # Save the fact that the folder exists
      atLeastOneWowVersionInstalled="true"
    fi
  done

  # If no World of Warcraft folder is detected then we will print and error and return 1.
  if ! "${atLeastOneWowVersionInstalled}"; then
    echo "ERROR: No World of Warcraft folders detected."
    return 1
  fi

  # If we got here then we have passed all validation so let the user know we're ready.
  echo "INFO: All validation checks passed!"
  return 0
}

########################################################################################################################
# TODO: Add header
########################################################################################################################
function UpdateAddons() {
  for FOLDER in "${WOW_FOLDERS[@]}"; do

    # We know at least one of the World of Warcraft folders is present, but we aren't 100% sure this folder is present.
    # We will log a warning and continue to the next folder.
    if [[ ! -d "${FOLDER}" ]]; then
      echo "WARN: Folder '${FOLDER}' not present."
      continue
    fi

    CURSEBREAKER_PATH="${FOLDER}/${CURSEBREAKER_EXECUTABLE}"
    CURSEBREAKER_ARGS="update"

    # The CurseBreaker executable must be both present and executable.
    if [[ ! -x "${CURSEBREAKER_PATH}" ]]; then
      echo "ERROR: File '${CURSEBREAKER_PATH}' is either not present or is not executable."
      return 1
    fi

    # Tell the user that we're about to update the addons.
    echo "INFO: Updating addons with '${CURSEBREAKER_PATH}'..."

    # If we fail to update the addons then we will return 1
    if ! "${CURSEBREAKER_PATH}" "${CURSEBREAKER_ARGS}"; then
      echo "ERROR: Failed to update addons using path '${CURSEBREAKER_PATH}'."
      return 1
    fi

  done

  # Let the user know that we updated the addons in all the detected World of Warcraft folders.
  echo "INFO: Updated all addons!"
  return 0
}

########################################################################################################################
# TODO: Add header
########################################################################################################################
function Main() {
  ValidateFolders || exit 1
  UpdateAddons || exit 1
}

########################################################################################################################
### Main
########################################################################################################################

Main
exit 0
