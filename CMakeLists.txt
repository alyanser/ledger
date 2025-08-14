cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

project(ledger)

file(GLOB_RECURSE SOURCE_FILES src/*.cc)
file(GLOB_RECURSE HEADER_FILES include/*.h)

find_package(Qt6 COMPONENTS Network Widgets Core Qml Quick REQUIRED)

if(UNIX)
	find_package(PkgConfig REQUIRED)

	pkg_check_modules(GLIB REQUIRED glib-2.0)

	if(NOT GLIB_FOUND)
		message(FATAL_ERROR "glib-2.0 not found")
	endif()

	pkg_check_modules(LIBSECRET REQUIRED libsecret-1)

	if(NOT LIBSECRET_FOUND)
		message(FATAL_ERROR "libsecret-1 not found")
	endif()
endif()

set(FIREBASE_SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/firebase_cpp_sdk")

if(NOT EXISTS "${FIREBASE_SDK_PATH}/include/firebase/app.h")
	message(FATAL_ERROR "Firebase SDK (13.0.0) not found in ${FIREBASE_SDK_PATH}")
endif()

if(UNIX)
	set(FIREBASE_LIB_PATH "${FIREBASE_SDK_PATH}/libs/linux/x86_64/cxx11")
else()
	set(FIREBASE_LIB_PATH "${FIREBASE_SDK_PATH}/libs/windows/VS2019/MD/x64/Release")
endif()

find_library(FIREBASE_APP_LIBRARY NAMES firebase_app libfirebase_app.a PATHS ${FIREBASE_LIB_PATH} NO_DEFAULT_PATH)
find_library(FIREBASE_FIRESTORE_LIBRARY  NAMES firebase_firestore libfirebase_firestore.a PATHS ${FIREBASE_LIB_PATH} NO_DEFAULT_PATH)
find_library(FIREBASE_AUTH_LIBRARY NAMES firebase_auth libfirebase_auth.a PATHS ${FIREBASE_LIB_PATH} NO_DEFAULT_PATH)

if(NOT FIREBASE_APP_LIBRARY)
	message(FATAL_ERROR "Firebase App library not found in ${FIREBASE_LIB_PATH}")
endif()

if(NOT FIREBASE_FIRESTORE_LIBRARY)
	message(FATAL_ERROR "Firebase Firestore library not found in ${FIREBASE_LIB_PATH}")
endif()

if(NOT FIREBASE_AUTH_LIBRARY)
	message(FATAL_ERROR "Firebase Auth library not found in ${FIREBASE_LIB_PATH}")
endif()

qt_add_resources(RESOURCE_ADDED resources.qrc)

qt_add_executable(
	${PROJECT_NAME}
	${SOURCE_FILES}
	${HEADER_FILES}
	${RESOURCE_ADDED}
)

target_link_libraries(
	${PROJECT_NAME}
	PRIVATE
	Qt6::Widgets
	Qt6::Core
	Qt6::Qml
	Qt6::Quick
	${FIREBASE_APP_LIBRARY}
	${FIREBASE_AUTH_LIBRARY}
	${FIREBASE_FIRESTORE_LIBRARY}
)

if(UNIX)
	target_link_libraries(
		${PROJECT_NAME}
		PRIVATE
		${GLIB_LIBRARIES}
		${LIBSECRET_LIBRARIES}
		pthread
		dl
	)
else()
	target_link_libraries(
		${PROJECT_NAME}
		PRIVATE
		bcrypt
		dbghelp
		crypt32
		secur32
		ws2_32
		ole32
		oleaut32
		shlwapi
		version
		winmm
		advapi32
	)
endif()

target_include_directories(
	${PROJECT_NAME}
	PRIVATE
	include
)

target_include_directories(
	${PROJECT_NAME}
	SYSTEM PRIVATE
	${Qt6Core_INCLUDE_DIRS}
	${Qt6Widgets_INCLUDE_DIRS}
	${Qt6Qml_INCLUDE_DIRS}
	${Qt6Quick_INCLUDE_DIRS}
	${FIREBASE_SDK_PATH}/include
)

if(UNIX)
	target_include_directories(
		${PROJECT_NAME}
		SYSTEM PRIVATE
		${GLIB_INCLUDE_DIRS}
		${LIBSECRET_INCLUDE_DIRS}
	)
endif()
