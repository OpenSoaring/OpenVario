#!/bin/bash

git fetch --all

git reset --hard august-d/dev-branch

chmod 757 -R ./ov-scripts

./ov-scripts/run-build.py CH57

