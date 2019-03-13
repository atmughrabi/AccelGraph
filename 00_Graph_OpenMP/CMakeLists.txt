cmake_minimum_required(VERSION "3.3.2")
project("Graph_OpenMP")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}) # Put binaries into root of build tree

# add_compile_options(-O3 -Wall -m64 -fopenmp -g)

set(CMAKE_C_FLAGS "-O3 -Wall -m64 -g")

find_package(OpenMP REQUIRED)
# find_package(snap REQUIRED)
# find_package(cxl REQUIRED)

if (OPENMP_FOUND)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
endif()

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/include)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/src)


# add_library(
# 	Graph_OpenMP STATIC/DYNAMIC/MODULE
# 	.h
# 	.c)

# add_executable(
# 	"${PROJECT_NAME}" # name of executable
# 	obj1 # what we need to compile main
# 	obj2

# 	)

# install(TARGETS "${PROJECT_NAME}" DESTINATION bin) #${CMAKE_INSTALL_PREFIX}/bin
# install(FILES "main.c" DESTINATION src) #${CMAKE_INSTALL_PREFIX}/src