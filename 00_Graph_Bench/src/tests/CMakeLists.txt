

AUX_SOURCE_DIRECTORY(${CMAKE_CURRENT_SOURCE_DIR} MyCSources)

add_executable(test_quantization test_quantization.c)

target_link_libraries(test_quantization LINK_PUBLIC  GRAPH_UTILS GRAPH_ALGORITHMS GRAPH_PREPROCESSING GRAPH_STRUCTURES)