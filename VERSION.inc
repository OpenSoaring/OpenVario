# The versions of this image, kept in this one file so that a new test
# build needs only one place to be raised.  bitbake reads it through
# BBPATH (the repository root): the image name takes OV_VERSION, the
# opensoar recipe takes its package version from OPENSOAR_VERSION and
# the xcsoar 7.45 recipe from XCSOAR_VERSION.  The ov-scripts read the
# same file to name and sort what they publish, which is why it uses
# plain shell assignments without spaces.
OV_VERSION="3.25.t12"
OPENSOAR_VERSION="7.45.25.t04"
XCSOAR_VERSION="7.45.3"
