#!/usr/bin/python3

import os, shutil, subprocess, sys

print('python run-docker.py without docker!  ')
print('==========================================')

#==============================================================
#==============================================================
#==============================================================
my_env = os.environ.copy()
if sys.platform.startswith('win'):    # is win
    cwd = os.getcwd().replace('\\', '/')
else:                                 # is linux:
    cwd = os.getcwd()


print('cwd:  ', cwd)

build_cmd  = './ov-scripts/build-image.py'
# build_cmd  = 'build-image.py'
if sys.platform.startswith('win'):
    sys_platform = 'windows'
else:
    sys_platform = 'linux'

myprocess = subprocess.Popen([build_cmd, sys_platform,
       '' if (len(sys.argv) < 2) else sys.argv[1],
       '' if (len(sys.argv) < 3) else sys.argv[2],
       '' if (len(sys.argv) < 4) else sys.argv[3],
       ], env = my_env, cwd = cwd, shell = False)
myprocess.wait()

