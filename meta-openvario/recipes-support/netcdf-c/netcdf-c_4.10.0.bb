SUMMARY = "NetCDF C library (classic/netCDF-3 formats, without HDF5/DAP)"
DESCRIPTION = "Unidata NetCDF-C, built with the same feature set OpenSoar uses \
for its bundled third-party libraries: no HDF5 (=> no netCDF-4 files), \
no DAP/remote access, no NCZarr, no utilities."
HOMEPAGE = "https://www.unidata.ucar.edu/software/netcdf/"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=cbb22cd5ded182bbd11d88ea19479b58"

SRC_URI = "https://github.com/Unidata/netcdf-c/archive/refs/tags/v${PV}.tar.gz;downloadfilename=netcdf-c-${PV}.tar.gz"
SRC_URI[sha256sum] = "ce160f9c1483b32d1ba8b7633d7984510259e4e439c48a218b95a023dc02fd4c"

S = "${WORKDIR}/netcdf-c-${PV}"

# zlib: netcdf-c does find_package(ZLIB) unconditionally; without a target zlib
# in the sysroot cmake picks the x86 one from recipe-sysroot-native and the
# link of libnetcdf.so fails ("libz.so: file format not recognized")
DEPENDS = "m4-native zlib"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
	-DCMAKE_BUILD_TYPE=Release \
	-DZLIB_INCLUDE_DIR=${STAGING_INCDIR} \
	-DZLIB_LIBRARY=${STAGING_LIBDIR}/libz.so \
	-DBUILD_SHARED_LIBS=ON \
	-DNETCDF_ENABLE_HDF5=OFF \
	-DNETCDF_ENABLE_DAP=OFF \
	-DNETCDF_ENABLE_NCZARR=OFF \
	-DNETCDF_ENABLE_REMOTE_FUNCTIONALITY=OFF \
	-DNETCDF_ENABLE_BYTERANGE=OFF \
	-DNETCDF_BUILD_UTILITIES=OFF \
	-DNETCDF_ENABLE_TESTS=OFF \
	-DNETCDF_ENABLE_EXAMPLES=OFF \
	-DNETCDF_ENABLE_LIBXML2=OFF \
	-DNETCDF_ENABLE_PLUGINS=OFF \
	-DNETCDF_ENABLE_FILTER_SZIP=OFF \
	-DNETCDF_ENABLE_FILTER_BZ2=OFF \
	-DNETCDF_ENABLE_FILTER_BLOSC=OFF \
	-DNETCDF_ENABLE_FILTER_ZSTD=OFF \
	-DNETCDF_ENABLE_FILTER_TESTING=OFF \
"

# The compression filters are only used for netCDF-4/HDF5 data (disabled
# here) and, like zlib, cmake would otherwise pick up x86 libzstd/libbz2 from
# recipe-sysroot-native. Without an external bz2 netcdf-c uses its bundled copy.

# nc-config and the build-settings file are development helpers
FILES:${PN}-dev += " \
	${bindir}/nc-config \
	${libdir}/libnetcdf.settings \
"