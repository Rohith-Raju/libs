# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

option(USE_BUNDLED_ZLIB "Enable building of the bundled zlib" ${USE_BUNDLED_DEPS})

if(ZLIB_INCLUDE)
	# we already have zlib
elseif(NOT USE_BUNDLED_ZLIB)
	find_path(ZLIB_INCLUDE zlib.h PATH_SUFFIXES zlib)
	find_library(ZLIB_LIB NAMES z)
	if(ZLIB_INCLUDE AND ZLIB_LIB)
		message(STATUS "Found zlib: include: ${ZLIB_INCLUDE}, lib: ${ZLIB_LIB}")
	else()
		message(FATAL_ERROR "Couldn't find system zlib")
	endif()
else()
	set(ZLIB_SRC "${PROJECT_BINARY_DIR}/zlib-prefix/src/zlib")
	set(ZLIB_INCLUDE "${ZLIB_SRC}")
	set(ZLIB_HEADERS "")
	list(
		APPEND
		ZLIB_HEADERS
		"${ZLIB_INCLUDE}/crc32.h"
		"${ZLIB_INCLUDE}/deflate.h"
		"${ZLIB_INCLUDE}/gzguts.h"
		"${ZLIB_INCLUDE}/inffast.h"
		"${ZLIB_INCLUDE}/inffixed.h"
		"${ZLIB_INCLUDE}/inflate.h"
		"${ZLIB_INCLUDE}/inftrees.h"
		"${ZLIB_INCLUDE}/trees.h"
		"${ZLIB_INCLUDE}/zconf.h"
		"${ZLIB_INCLUDE}/zlib.h"
		"${ZLIB_INCLUDE}/zutil.h"
	)
	if(NOT TARGET zlib)
		# Match both release and relwithdebinfo builds
		if(CMAKE_BUILD_TYPE MATCHES "[R,r]el*")
			set(ZLIB_CFLAGS "-O3")
		else()
			set(ZLIB_CFLAGS "-g")
		endif()
		if(ENABLE_PIC)
			set(ZLIB_CFLAGS "${ZLIB_CFLAGS} -fPIC")
		endif()

		message(STATUS "Using bundled zlib in '${ZLIB_SRC}'")
		if(NOT WIN32)
			if(BUILD_SHARED_LIBS)
				set(ZLIB_LIB_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
				set(ZLIB_CONFIGURE_FLAGS)
			else()
				set(ZLIB_LIB_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX})
				set(ZLIB_CONFIGURE_FLAGS "--static")
			endif()
			set(ZLIB_LIB "${ZLIB_SRC}/libz${ZLIB_LIB_SUFFIX}")
			ExternalProject_Add(
				zlib
				PREFIX "${PROJECT_BINARY_DIR}/zlib-prefix"
				URL "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"
				URL_HASH "SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
				CONFIGURE_COMMAND CFLAGS=${ZLIB_CFLAGS} ./configure --prefix=${ZLIB_SRC}
								  ${ZLIB_CONFIGURE_FLAGS}
				BUILD_COMMAND make
				BUILD_IN_SOURCE 1
				BUILD_BYPRODUCTS ${ZLIB_LIB}
				INSTALL_COMMAND ""
			)
			install(
				FILES "${ZLIB_LIB}"
				DESTINATION "${CMAKE_INSTALL_LIBDIR}/${LIBS_PACKAGE_NAME}"
				COMPONENT "libs-deps"
			)
			install(
				FILES ${ZLIB_HEADERS}
				DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBS_PACKAGE_NAME}/zlib"
				COMPONENT "libs-deps"
			)
		else()
			if(BUILD_SHARED_LIBS)
				set(ZLIB_LIB_SUFFIX "${CMAKE_SHARED_LIBRARY_SUFFIX}")
				set(ZLIB_LIB "${ZLIB_SRC}/lib/zlib$<$<CONFIG:Debug>:d>${ZLIB_LIB_SUFFIX}")
			else()
				set(ZLIB_LIB_SUFFIX "${CMAKE_STATIC_LIBRARY_SUFFIX}")
				set(ZLIB_LIB "${ZLIB_SRC}/lib/zlibstatic$<$<CONFIG:Debug>:d>${ZLIB_LIB_SUFFIX}")
			endif()
			ExternalProject_Add(
				zlib
				PREFIX "${PROJECT_BINARY_DIR}/zlib-prefix"
				URL "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"
				URL_HASH "SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
				BUILD_IN_SOURCE 1
				BUILD_BYPRODUCTS ${ZLIB_LIB}
				CMAKE_ARGS -DCMAKE_POLICY_DEFAULT_CMP0091:STRING=NEW
						   -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY}
						   -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
						   -DCMAKE_POSITION_INDEPENDENT_CODE=${ENABLE_PIC}
						   -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
						   -DCMAKE_INSTALL_PREFIX=${ZLIB_SRC}
			)
			install(
				FILES "${ZLIB_LIB}"
				DESTINATION "${CMAKE_INSTALL_LIBDIR}/${LIBS_PACKAGE_NAME}"
				COMPONENT "libs-deps"
			)
			install(
				FILES ${ZLIB_HEADERS}
				DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBS_PACKAGE_NAME}/zlib"
				COMPONENT "libs-deps"
			)
		endif()
	endif()
endif()

if(NOT TARGET zlib)
	add_custom_target(zlib)
endif()

include_directories(${ZLIB_INCLUDE})
