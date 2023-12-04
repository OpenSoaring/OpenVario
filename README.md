[![Automated Release Notes by gren](https://img.shields.io/badge/%F0%9F%A4%96-release%20notes-00B2EE.svg)](https://github-tools.github.io/github-release-notes/)

# OpenVario

This is a fork of the OpenVario project 'GitHub.com/Openvario/meta-openvario' to support the embedded OpenVario hardware

## How to build an image

### Prerequisites

 - Linux installation 
 - Installed Docker (https://docs.docker.com/install/)
 
### Fetching sources

```
git clone --recurse-submodules https://github.com/Openvario/meta-openvario.git
cd meta-openvario
```

This will fetch the sources including all submodules.

### Starting the containerd build environment
```
docker run -it --rm -v $(pwd):/workdir ghcr.io/openvario/ovbuild-container:main --workdir=/workdir
```

### Configuring the build (only necessary once after fetching the repos)

```
source openembedded-core/oe-init-build-env .
```

### Setting the machine

```
export MACHINE=ov-ch70
```

Available machines for the OpenVario with the original adapter board are:
- ov-pq70
- ov-ch70
- ov-am43
- ov-ch57

Available machines for the OpenVario with the new adapter board DS2 are:
- ov-ch70s
- ov-am70s
- ov-ch57s

### Starting the build

```
bitbake openvario-image
```
