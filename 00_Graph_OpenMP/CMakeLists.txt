cmake_minimum_required(VERSION "3.3.2")
project("Graph_OpenMP")

# add_compile_options(-O3 -Wall -W -Werror -m64 -fopenmp -g)

set(CMAKE_C_FLAGS "-O3 -Wall -m64 -fopenmp -g")

add_subdirectory(include)
add_subdirectory(src)


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