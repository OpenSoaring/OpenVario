SUMMARY = "NetCDF C++ (netCDF-4 API) library"
DESCRIPTION = "Unidata netcdf-cxx4: C++ bindings for NetCDF, provides the \
<netcdf> header and libnetcdf_c++4 that OpenSoar links against \
(-lnetcdf_c++4 -lnetcdf) for SkySight forecast decoding."
HOMEPAGE = "https://www.unidata.ucar.edu/software/netcdf/"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=7a265567ba44537b8d1ed8b406d4b25c"

SRC_URI = " \
	https://github.com/Unidata/netcdf-cxx4/archive/refs/tags/v${PV}.tar.gz;downloadfilename=netcdf-cxx4-${PV}.tar.gz \
	file://fix_new_delete.patch \
"
SRC_URI[sha256sum] = "e3fe3d2ec06c1c2772555bf1208d220aab5fee186d04bd265219b0bc7a978edc"

S = "${WORKDIR}/netcdf-cxx4-${PV}"

DEPENDS = "netcdf-c"

# autotools (not cmake) on purpose: it yields libnetcdf_c++4.so, which is the
# name OpenSoar's build/netcdf.mk links for non-thirdparty targets
# (the cmake build would produce libnetcdf-cxx4.so instead).
inherit autotools pkgconfig

EXTRA_OECONF = " \
	--with-nc-config=no \
	--disable-filter-testing \
	--disable-static \
	--disable-doxygen \
"

FILES:${PN}-dev += " \
	${bindir}/ncxx4-config \
	${libdir}/libnetcdf-cxx.settings \
"
