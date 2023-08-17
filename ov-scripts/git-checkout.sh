#!/bin/bash

CURR_DIR=$(pwd)
if [ "$LOCAL" == "" ]; then LOCAL=august-d ; fi

if [ "$GITHUB" == "" ]; then GITHUB=origin ; fi
GITHUB=august
REMOTE=$LOCAL
# REMOTE=$GITHUB

# if "$BRANCH" is empty take the predefined branch
if [ "$BRANCH" == "" ]; then BRANCH=dev-branch ; fi
echo "BRANCH   = $BRANCH"
BUILD_PATH=$CURR_DIR/OpenVario

CLEAN_UP="n"

echo "CURR_DIR = $CURR_DIR"

if [ -d $BUILD_PATH ]; then
  cd $BUILD_PATH
  echo "BUILD_PATH = $BUILD_PATH"

  git fetch $REMOTE
  git checkout -B $BRANCH
  
  if [ "$CLEAN_UP" == "y" ]; then
    # das folgende löscht auch ALLE temporären (bitbake) Dateien ;-(
    # damit wird der 'saubere' Ursprungszustand nach dem Clone hergestellt!
    echo "Clean up complete system!"
    git clean -xfd
    # git clean -xf
    # git clean -xfn # dry run with -n
  fi

  git submodule sync
  git submodule init
  git submodule foreach --recursive git clean -xfd
  git reset --hard
  git submodule foreach --recursive git reset --hard
  git submodule update --init --recursive
  git reset --hard $REMOTE/$BRANCH
  git submodule update --init --recursive
else
  git clone --recursive https://github.com/August2111/OpenVario -b $BRANCH 
  # the next is only for August2111:
  git remote rename origin $GITHUB
  git remote add $LOCAL /mnt/d/Projects/OpenVario/OpenVario
fi

git remote -v

SCRIPT_PATH=$(dirname "$(readlink -e "$0")")
echo "SCRIPT_PATH = $SCRIPT_PATH"

chmod -R 757 $SCRIPT_PATH

cd $CURR_DIR

