if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "DO NOT BUILD in-tree.")
endif()


cmake_minimum_required(VERSION "3.1...3.13")

if(${CMAKE_VERSION} VERSION_LESS 3.13)
    cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()


project(Graph_OpenMP	VERSION 1.0
						# DESCRIPTION "Graph processing benchmarking tool with OpenMP"
						LANGUAGES C)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../bin) # Put binaries into root of build tree

# add_compile_options(-O3 -Wall -m64 -fopenmp -g)

set(CMAKE_C_FLAGS "-O3 -Wall -m64 -g")

find_package(OpenMP REQUIRED)
# find_package(snap REQUIRED)
# find_package(cxl REQUIRED)

if (OPENMP_FOUND)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
endif()

include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include/utils)
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include/structures)
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include/preprocessing)
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include/graphalgorithms)


add_subdirectory(src)


# set(MY_CACHE_VARIABLE "VALUE" CACHE STRING "" FORCE)
# mark_as_advanced(MY_CACHE_VARIABLE)

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


#making an executable
# add_executable(binary_file_name .c .h files) (also this is the target name)

#making a library
#add_library( header library only use INTERFACE)

 #target_include_directories (target_name PUBLIC include_directory)

 #chaining targets
 #add_library(another static .g .h)
 #target_link_libraries(another PUBLIC one)