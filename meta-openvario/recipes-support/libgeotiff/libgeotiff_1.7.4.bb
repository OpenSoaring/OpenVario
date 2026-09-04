SUMMARY = "GeoTIFF library (georeferencing tags for TIFF images)"
DESCRIPTION = "libgeotiff provides the GeoTIFF API (geotiff.h, xtiffio.h, \
libgeotiff.so) that OpenSoar links with -ltiff -lgeotiff when built with \
HAVE_GEOTIFF (SkySight forecast overlays)."
HOMEPAGE = "https://github.com/OSGeo/libgeotiff"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=f80854a7049ee9433d1f93336fe22f10"

SRC_URI = "https://download.osgeo.org/geotiff/libgeotiff/libgeotiff-${PV}.tar.gz"
SRC_URI[sha256sum] = "c598d04fdf2ba25c4352844dafa81dde3f7fd968daa7ad131228cd91e9d3dc47"

# proj (7.0.1) comes from meta-oe; libgeotiff >= 1.6 requires PROJ >= 6
DEPENDS = "tiff proj"

inherit cmake pkgconfig

# tiff/proj are pinned to the target sysroot explicitly so cmake never falls
# back to whatever happens to be in recipe-sysroot-native (see netcdf-c)
EXTRA_OECMAKE = " \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=ON \
	-DWITH_UTILITIES=OFF \
	-DBUILD_MAN=OFF \
	-DBUILD_DOC=OFF \
	-DWITH_JPEG=OFF \
	-DWITH_ZLIB=OFF \
	-DWITH_TOWGS84=ON \
	-DTIFF_INCLUDE_DIR=${STAGING_INCDIR} \
	-DTIFF_LIBRARY=${STAGING_LIBDIR}/libtiff.so \
	-DPROJ_INCLUDE_DIR=${STAGING_INCDIR} \
	-DPROJ_LIBRARY=${STAGING_LIBDIR}/libproj.so \
"

# proj.db (package "proj") is needed at runtime for CRS lookups
RDEPENDS:${PN} += "proj"
