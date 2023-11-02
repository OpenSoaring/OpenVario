#!/bin/bash

fdisk /dev/mmcblk0 << EOF
p
n
p
3
1048576


p
w
EOF
