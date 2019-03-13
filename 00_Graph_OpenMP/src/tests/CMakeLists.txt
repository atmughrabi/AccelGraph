
FILE(GLOB MyCSources *.c)

add_library(
	GRAPH_TESTS STATIC
	${CMAKE_CURRENT_SOURCE_DIR}/${MyCSources}
	)