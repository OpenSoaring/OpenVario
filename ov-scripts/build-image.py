#!/usr/bin/python3

import os, shutil, subprocess, sys

print('### Thats OpenVario ###')
print('#   Do it in Docker   #')
print('#######################')
print('build with github.com/OpenVario')
print('')
#--------------------------------------
my_env = os.environ.copy()
cwd = os.getcwd()

if len(sys.argv) > 1:
    ov_type = sys.argv[2]
    if ov_type == '--all' or ov_type == '-a':
          machines = [
          'ov-ch70',
          'ov-pq70',
          'ov-ch57',
          'ov-am43',
          'ov-am70s',
          'ov-ch70s',
          # n.d. 'ov-ch57s',
        ]
    elif ov_type == 'am70s':
                machines = ['ov-am70s']
    elif ov_type == 'pq70':
                machines = ['ov-pq70']
    elif ov_type == 'tx70':
                machines = ['ov-ch70']
    elif ov_type == 'ch70':
                machines = ['ov-ch70']
    elif ov_type == 'ch70s':
                machines = ['ov-ch70s']
    elif ov_type == 'ch57':
                machines = ['ov-ch57']
    elif ov_type == 'am43':
                machines = ['ov-am43']
    else:
                machines = [ov_type]
else:
    # only one!
    machines = ['ov-ch70']

# my_env['TEMPLATECONF'] = 'meta-openvario/conf'
# my_env['TEMPLATECONF'] = '../meta-ov/conf'
my_env['TEMPLATECONF'] = 'meta-ov/conf'
# my_env['TOPDIR'] = cwd

#myprocess = subprocess.Popen([
#    'TEMPLATECONF=meta-openvario/conf source',
#     'source',
#    './oe-init-build-env' # /home/pokyuser
#], env = my_env, cwd=cwd+'/poky', shell = False)
#myprocess.wait()


for machine in machines:
    print('=== Build OV with machine: ', machine, ' === ', sys.argv[1], ' === ', sys.argv[3])
    print('===============================================')
    print('===============================================')
    my_env['MACHINE'] =  machine

    target = 'xcsoar-maps-alps'
    target = 'linux-mainline'
    target = 'openvario-image'
    target = 'openvario-larus'
    # target = 'openvario-image-testing'
    # target = 'ov-august'
    
    target = 'ov-opensoar'
    print('=== Start ', target,' with machine: ', machine)
    myprocess = subprocess.Popen([cwd+'/ov-scripts/build-ov.sh', target ], env = my_env, cwd=cwd, shell = False)   
    myprocess.wait()
    
    print('=== OV with machine: ', machine, ' is ready ===')
    print('===============================================')
    print('===============================================')


    target = 'openvario-recovery-initramfs'
    print('=== Start ', target,' with machine: ', machine)
    myprocess = subprocess.Popen([cwd+'/ov-scripts/build-ov.sh', target ], env = my_env, cwd=cwd, shell = False)   
    myprocess.wait()

    print('=== OV with machine: ', machine, ' is ready ===')
    print('===============================================')
    print('===============================================')

    target = 'openvario-recovery-image'
    print('=== Start ', target,' with machine: ', machine)
    myprocess = subprocess.Popen([cwd+'/ov-scripts/build-ov.sh', target ], env = my_env, cwd=cwd, shell = False)   
    myprocess.wait()

    print('=== OV with machine: ', machine, ' is ready ===')
    print('===============================================')
    print('===============================================')

# ========================================================================================================================
# ========================================================================================================================
#
print('Finish all machines!!!!')
