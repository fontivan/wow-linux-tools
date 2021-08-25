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

# Get the path of this script's own directory
MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The path to the common libraries
LIB_DIR="${MY_DIR}/../../common/lib"

# The classic World of Warcraft subfolder.
CLASSIC_SUBFOLDER="_classic_"

# The arguments we will be passing to the CurseBreaker executable
CURSEBREAKER_ARGS="headless"

# The name of the CurseBreaker executable.
CURSEBREAKER_EXECUTABLE_NAME="CurseBreaker"

# The relative path of the drive_c wine folder within the Lutris installation.
PROGRAM_FILES_FOLDER="drive_c/Program Files (x86)"

# The retail World of Warcraft subfolder.
RETAIL_SUBFOLDER="_retail_"

# The World of Warcraft folder.
WOW_FOLDER="World of Warcraft"

# The path of the Lutris install for Battle.net
# This will be set later
BATTLE_NET_PATH=""

# The path of the Program Files wine directory.
# This will be set later.
PROGRAM_FILES_PATH=""

# The path of the World of Warcraft installation.
# This will be set later.
WOW_PATH=""

# The path to the Classic World of Warcraft subfolder.
# This will be set later
CLASSIC_PATH=""

# The path to the Retail World of Warcraft subfolder.
# This will be set later
RETAIL_PATH=""

########################################################################################################################
### Functions
########################################################################################################################

########################################################################################################################
# function LoadCommonResources()
#
# Description:
#   Load the resource files from the common library directory
# Inputs:
#   $LIB_DIR - The folder containing the common libraries
# Returns:
#   0 - If the file exists and was loaded successfully.
#   1 - If the file does not exist or could not be loaded.
########################################################################################################################
function LoadCommonResources() {

  # Check if the file exists
  if [[ ! -d "${LIB_DIR}" ]]; then
    # If the file doesn't exist then this is a serious problem
    PrintError "The library directory '${LIB_DIR}' could not be found."
    return 1
  fi

  # Source the resource file containing the configuration
  # shellcheck disable=SC1090
  local fileList
  fileList="$(ls "${LIB_DIR}")"

  # This will be returned later
  local returnCode
  returnCode="0"

  local currentFile
  local currentPath
  # Loop over all the files in the directory
  for currentFile in ${fileList}; do
    # Construct the absolute path to the file
    currentPath="${LIB_DIR}/${currentFile}"

    # Check if the file even exists
    if [[ -f ${currentPath} ]]; then

      # If the file exists try to load it
      # shellcheck disable=SC1090
      if ! source "${currentPath}"; then
        # The file could not be loaded
        PrintError "The library file '${currentPath}' could not be loaded."
        returnCode="1"
      fi
    else
      # The file could not be found
      PrintError "The library file '${currentPath}' could not be found."
      returnCode="1"
    fi
  done

  return "${returnCode}"

}

########################################################################################################################
### Functions
########################################################################################################################

########################################################################################################################
# TODO: Add header
########################################################################################################################
function ValidateInputs() {

  # If no arguments were provided then `set -e` will cause `${1}` to throw an error
  if [[ $# -eq 0 ]]; then
    PrintError "No arguments specified. Must specify the Lutris Battle.net install folder."
    return 1
  fi

  # If ${1} was provided then we expect it to be a directory
  if [[ ! -d "${1}" ]]; then
    PrintError "Provided path '${1}' was not a directory, or is not accessible."
    return 1
  fi

  BATTLE_NET_PATH="${1}"
  PROGRAM_FILES_PATH="${BATTLE_NET_PATH}/${PROGRAM_FILES_FOLDER}"
  WOW_PATH="${PROGRAM_FILES_PATH}/${WOW_FOLDER}"
  CLASSIC_PATH="${WOW_PATH}/${CLASSIC_SUBFOLDER}"
  RETAIL_PATH="${WOW_PATH}/${RETAIL_SUBFOLDER}"
  return 0

}

########################################################################################################################
# TODO: Add header
########################################################################################################################
function ValidateDependenciesAndUpdateAddons() {

  # A local variable will be used to loop over the mandatory folders.
  local mandatoryFolders
  mandatoryFolders=(
    "${BATTLE_NET_PATH}"
    "${PROGRAM_FILES_PATH}"
    "${WOW_PATH}"
  )

  # A local variable will be used to store the for loop variable.
  local currentFolder

  # All the folders in this list must be present to continue.
  for currentFolder in "${mandatoryFolders[@]}"; do

    # Tell the user what we're about to test
    PrintInfo "Checking if directory '${currentFolder}' exists..."

    # Check if the folder is present
    if [[ ! -d "${currentFolder}" ]]; then

      # If its not present then spit out the error and return 1
      PrintError "Directory '${currentFolder}' not found."
      return 1
    fi
  done

  # If we got here then we know all the mandatory folders were present.
  PrintInfo "All mandatory folders present!"

  # A local variable will be used to loop over the World of Warcraft subfolders.
  local wowSubfolders
  wowSubfolders=(
    "${CLASSIC_PATH}"
    "${RETAIL_PATH}"
  )

  # A local variable used to save the current CurseBreaker path
  local curseBreakerPath

  # At least one of the folders in this list must be present.
  for currentFolder in "${wowSubfolders[@]}"; do

    curseBreakerPath="${currentFolder}/${CURSEBREAKER_EXECUTABLE_NAME}"

    # Tell the user what we're about to test
    PrintInfo "Checking if directory '${currentFolder}' exists..."

    # Check if the folder is present
    if [[ ! -d "${currentFolder}" ]]; then

      # Print a warning if its not present.
      PrintWarning "Directory '${currentFolder}' not found."

    # If the folder exists then we also want to check if CurseBreaker exists within the folder.
    elif [[ -x "${curseBreakerPath}" ]]; then

      # Tell the user that we're about to update the addons.
      PrintInfo "Updating addons in folder '${currentFolder}'."

      # If we fail to update the addons then we will return 1
      if ! "${curseBreakerPath}" "${CURSEBREAKER_ARGS}"; then
        PrintError "Failed to update addons using path '${CURSEBREAKER_PATH}'."
        return 1
      fi

      PrintInfo "Successfully updated addons in folder '${currentFolder}'."

    fi
  done

  return 0
}

########################################################################################################################
# TODO: Add header
########################################################################################################################
function Main() {
  LoadCommonResources || ReportErrorAndExit
  ValidateInputs "${@}" || ReportErrorAndExit
  ValidateDependenciesAndUpdateAddons || ReportErrorAndExit
  exit 0
}

########################################################################################################################
### Main
########################################################################################################################

# Call the main function
Main "${@}"
