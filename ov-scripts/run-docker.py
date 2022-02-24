#!/usr/bin/python3

import os, shutil, subprocess, sys

branch  = 'hardknott'
# branch  = 'honister'

print('python run-docker.py with Branch ', branch)
print('==========================================')

def DockerImageAvailable(image_name):
# test image detection
	out = open('docker-out.txt', 'w')
	myprocess = subprocess.Popen(['docker', 'image', 'ls', '-q', image_name], env = my_env, cwd = cwd, stdout = out, shell = False)
	myprocess.wait()
	out.close()

	out = open('docker-out.txt', 'r')
	image_id = out.read()
	out.close()

	print('image_name: ', image_name,', image-id = ', image_id, ' --- ', len(image_id))
	return image_id
#==============================================================
#==============================================================
#==============================================================
my_env = os.environ.copy()
if sys.platform.startswith('win'):    # is win
    cwd = os.getcwd().replace('\\', '/')
else:                                 # is linux:
    cwd = os.getcwd()

image_name = 'openvario/' + branch + ':latest'

print(' Path-Variable is: ', cwd, '!!!!!!!!!!!!!!')

dockerfile = 'scripts/Dockerfile'
# image_id = DockerImageAvailable(image_name)

if len(DockerImageAvailable(image_name)) > 0:  # with_docker_build:
    myprocess = subprocess.Popen(['docker', 'build', '--file', dockerfile, '-t', image_name, './'], env = my_env, cwd = cwd, shell = False)
    myprocess.wait()


target_dir = '/opt/openvario'
target_dir = '/openvario'
set_target_dir = ''
build_cmd  = target_dir + '/ov-scripts/build-image.py'
if sys.platform.startswith('win'):
    sys_platform = 'windows'
    # is win, but this is very preliminary
    target_dir = '/home/pokyuser'  # overwrite previous!
    ### delete:    # myprocess = subprocess.Popen(['docker', 'run', '-u "pokyuser"' , '--rm', '--mount', 'type=bind,source='+ cwd + ',target=' + target_dir, '-it', image_name
    ### delete:    # myprocess = subprocess.Popen(['docker', 'run', '--rm', '--mount', 'type=bind,source='+ cwd + ',target=' + target_dir, '-it', image_name
    ### delete:    myprocess = subprocess.Popen(['docker', 'run', '--rm', '--mount', 'type=bind,source='+ cwd + ',target=' + target_dir, '-it', image_name
    ### delete:    , './build-image.py'  ], env = my_env, cwd = cwd, shell = False)
    ### delete:    # , '/opt/openvario/build-image.py'  ], env = my_env, cwd = cwd, shell = False)
else:
    sys_platform = 'linux'
    # is linux:
    # target_dir = '/home/pokyuser'
    set_target_dir = '--workdir=' + target_dir
    ### delete:    myprocess = subprocess.Popen(['docker', 'run', '--rm', '--mount', 'type=bind,source='+ cwd + ',target=' + target_dir, '-it', image_name
    ### delete:    , './build-image.py'  ], env = my_env, cwd = cwd, shell = False)

### delete:myprocess.wait()

# sudo docker run --rm --mount type=bind,source=$(pwd),target=/opt/openvario -it openvario/hardknott:latest --workdir=/opt/openvario
myprocess = subprocess.Popen(['docker', 'run', '--rm', '--mount', 'type=bind,source='+ cwd + ',target=' + target_dir, '-it', image_name
       , set_target_dir, build_cmd, sys_platform,
       '' if (len(sys.argv) < 2) else sys.argv[1],
       '' if (len(sys.argv) < 3) else sys.argv[2],
       '' if (len(sys.argv) < 4) else sys.argv[3],
       ], env = my_env, cwd = cwd, shell = False)
myprocess.wait()

print('Finish: run-docker.py')

