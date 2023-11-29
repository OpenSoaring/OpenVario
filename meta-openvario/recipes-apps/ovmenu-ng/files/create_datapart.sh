#!/bin/bash

PARTITION_START3=2359296

fdisk /dev/mmcblk0 << EOF
p
n
p
3
$PARTITION3_START


p
w
EOF
