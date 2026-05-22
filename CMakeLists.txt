cmake_minimum_required(VERSION 3.14)

# Tell CMake to generate compile_commands.json for clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 1. Fallback: Check if Clang is installed, otherwise use GCC
# NOTE: This must be set BEFORE the project() command!
find_program(CLANG_PATH clang)
if(CLANG_PATH)
    set(CMAKE_C_COMPILER "clang")
    message(STATUS "Selected compiler: clang")
else()
    set(CMAKE_C_COMPILER "gcc")
    message(STATUS "Clang not found, falling back to gcc")
endif()

project(kryptografia-aks C)

# Define the main executable
add_executable(${PROJECT_NAME} src/main.c src/poly.c src/poly.h)

# ---------------------------------------------------------
# Link the standard math library (-lm)
# ---------------------------------------------------------
target_link_libraries(${PROJECT_NAME} PRIVATE m)


# Attempt to find a system-wide GMP installation
find_path(GMP_INCLUDE_DIR NAMES gmp.h)
find_library(GMP_LIBRARY NAMES gmp libgmp)

if(GMP_INCLUDE_DIR AND GMP_LIBRARY)
    message(STATUS "Found system GMP: ${GMP_LIBRARY}")

    # Link the system GMP to the project
    target_include_directories(${PROJECT_NAME} PRIVATE ${GMP_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GMP_LIBRARY})

else()
    message(STATUS "System GMP not found. Checking for vendored GMP...")

    set(GMP_VENDOR_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/GMP")

    # 2. Error out if the vendor directory doesn't contain the configure script
    if(NOT EXISTS "${GMP_VENDOR_DIR}/configure")
        message(FATAL_ERROR "System GMP was not found, and vendor/GMP/configure is missing. "
                            "Please install GMP system-wide or pull the GMP source into vendor/GMP.")
    endif()

    message(STATUS "Building GMP from vendor directory using ${CMAKE_C_COMPILER}...")

    include(ExternalProject)

    set(GMP_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/gmp_build")
    set(GMP_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/gmp_install")

    # 3. Build GMP using the selected compiler via ExternalProject
    ExternalProject_Add(gmp_vendor
        SOURCE_DIR "${GMP_VENDOR_DIR}"
        PREFIX "${GMP_BUILD_DIR}"
        # We prepend 'env CC=${CMAKE_C_COMPILER}' to force GMP's configure script to use the chosen compiler
        CONFIGURE_COMMAND env CC=${CMAKE_C_COMPILER} "${GMP_VENDOR_DIR}/configure"
                          "--prefix=${GMP_INSTALL_DIR}"
                          "--disable-shared"
                          "--enable-static"
                          "--with-pic"
        BUILD_COMMAND make
        INSTALL_COMMAND make install
        BUILD_IN_SOURCE 0
    )

    # Point CMake to the newly built vendor library and headers
    set(GMP_VENDOR_INCLUDE_DIR "${GMP_INSTALL_DIR}/include")
    set(GMP_VENDOR_LIBRARY "${GMP_INSTALL_DIR}/lib/libgmp.a")

    # Create the include directory at configure time to prevent CMake errors
    file(MAKE_DIRECTORY ${GMP_VENDOR_INCLUDE_DIR})

    # Link the locally built GMP to the project
    target_include_directories(${PROJECT_NAME} PRIVATE ${GMP_VENDOR_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GMP_VENDOR_LIBRARY})

    # Ensure kryptografia-aks waits for GMP to finish compiling
    add_dependencies(${PROJECT_NAME} gmp_vendor)
endif()
