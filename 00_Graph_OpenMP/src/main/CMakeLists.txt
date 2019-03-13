

FILE(GLOB MyCSources *.c)

add_library(
	GRAPH_MAIN STATIC
	${CMAKE_CURRENT_SOURCE_DIR}/${MyCSources}
	)

