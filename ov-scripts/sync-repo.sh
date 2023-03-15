#!/bin/bash

git fetch --all

git reset --hard origin/dev-branch

chmod 757 -R ./ov-scripts

./ov-scripts/run-build.py CH57

