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
          'openvario-7-CH070',
          'openvario-7-PQ070',
          # n.d. 'openvario-7-AM070',
          'openvario-57-lvds',
          'openvario-43-rgb',
          'openvario-7-AM070-DS2',
          'openvario-7-CH070-DS2',
          # n.d. 'openvario-57-ldvs-DS2',
        ]
    elif ov_type == 'AM70':
                machines = ['openvario-7-AM070-DS2']
    elif ov_type == 'PQ70':
                machines = ['openvario-7-PQ070']
    elif ov_type == 'TX70':
                machines = ['openvario-7-CH070']
    elif ov_type == 'CH70':
                machines = ['openvario-7-CH070']
    elif ov_type == 'CH70':
                machines = ['openvario-7-CH070']
    elif ov_type == 'CH57':
                machines = ['ov-ch57']
    elif ov_type == 'ch57':
                machines = ['ov-ch57']
    else:
                machines = [ov_type]
else:
    # only one!
    machines = ['openvario-7-CH070']

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
