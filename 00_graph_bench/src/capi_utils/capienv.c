// -----------------------------------------------------------------------------
//
//		"00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : capienv.c
// Create : 2019-10-09 19:20:39
// Revise : 2019-10-09 19:32:45
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------

#include <linux/types.h>
#include <stdio.h>
#include <stdlib.h>

#include "myMalloc.h"
#include "graphCSR.h"
#include "libcxl.h"
#include "capienv.h"

// ********************************************************************************************
// ***************                  AFU General 	                             **************
// ********************************************************************************************



// ********************************************************************************************
// ***************                  MMIO General 	                             **************
// ********************************************************************************************
	
	void printMMIO_error( uint64_t error )
{

    if(error >> 12)
    {
        switch(error >> 12)
        {
        case 1:
            printf("(BIT-12) Job Address Error\n");
            break;
        case 2:
            printf("(BIT-13) Job Command Error\n");
            break;
        }
    }
    else if(error >> 10)
    {
        switch(error >> 10)
        {
        case 1:
            printf("(BIT-10) MMIO Address Parity-Error\n");
            break;
        case 2:
            printf("(BIT-11) MMIO Data Parity-Error\n");
            break;
        }

    }
    else if(error >> 9)
    {
        printf("(BIT-9) Write Tag Parity-Error\n");
    }
    else if(error >> 7)
    {
        switch(error >> 7)
        {
        case 1:
            printf("(BIT-7) Read Data Parity-Error\n");
            break;
        case 2:
            printf("(BIT-8) Read Tag Parity-Error\n");
            break;
        }

    }
    else if(error >> 0)
    {
        switch(error >> 0)
        {
        case 1:
            printf("(BIT-0) Response AERROR\n");
            break;
        case 2:
            printf("(BIT-1) Response DERROR\n");
            break;
        case 4:
            printf("(BIT-2) Response FAILD\n");
            break;
        case 8:
            printf("(BIT-3) Response FAULT\n");
            break;
        case 64:
            printf("(BIT-6) Response tag Parity-Error\n");
            break;
        }
    }

}

// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct  WEDGraphCSR *mapGraphCSRToWED(struct GraphCSR *graph)
{

    struct WEDGraphCSR *wed = my_malloc(sizeof(struct WEDGraphCSR));

    wed->num_edges    = graph->num_edges;
    wed->num_vertices = graph->num_vertices;
#if WEIGHTED
    wed->max_weight   = graph->max_weight;
#else
    wed->max_weight   = 0;
#endif

    wed->vertex_out_degree  = graph->vertices->out_degree;
    wed->vertex_in_degree   = graph->vertices->in_degree;
    wed->vertex_edges_idx   = graph->vertices->edges_idx;

    wed->edges_array_src    = graph->sorted_edges_array->edges_array_src;
    wed->edges_array_dest   = graph->sorted_edges_array->edges_array_dest;
#if WEIGHTED
    wed->edges_array_weight = graph->sorted_edges_array->edges_array_weight;
#endif

#if DIRECTED
    wed->inverse_vertex_out_degree  = graph->inverse_vertices->out_degree;
    wed->inverse_vertex_in_degree   = graph->inverse_vertices->in_degree;
    wed->inverse_vertex_edges_idx   = graph->inverse_vertices->edges_idx;

    wed->inverse_edges_array_src    = graph->inverse_sorted_edges_array->edges_array_src;
    wed->inverse_edges_array_dest   = graph->inverse_sorted_edges_array->edges_array_dest;
#if WEIGHTED
    wed->inverse_edges_array_weight = graph->inverse_sorted_edges_array->edges_array_weight;
#endif
#endif



    wed->done = 0;

    return wed;
}


void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed)
{

    printf("[WEDGraphCSR structure\n");
    printf("  wed: %p\n", wed);
    printf("  wed->num_edges: %u\n", wed->num_edges);
    printf("  wed->num_vertices: %u\n", wed->num_vertices);
#if WEIGHTED
    printf("  wed->max_weight: %u\n", wed->max_weight);
#endif
    printf("  wed->vertex_in_degree: %p\n", wed->vertex_in_degree);
    printf("  wed->vertex_out_degree: %p\n", wed->vertex_out_degree);
    printf("  wed->vertex_edges_idx: %p\n", wed->vertex_edges_idx);

    printf("  wed->edges_array_src: %p\n", wed->edges_array_src);
    printf("  wed->edges_array_dest: %p\n", wed->edges_array_dest);
#if WEIGHTED
    printf("  wed->edges_array_weight: %p\n", wed->edges_array_weight);
#endif

#if DIRECTED
    printf("  wed->inverse_vertex_in_degree: %p\n", wed->inverse_vertex_in_degree);
    printf("  wed->inverse_vertex_out_degree: %p\n", wed->inverse_vertex_out_degree);
    printf("  wed->inverse_vertex_edges_idx: %p\n", wed->inverse_vertex_edges_idx);

    printf("  wed->inverse_edges_array_src: %p\n", wed->inverse_edges_array_src);
    printf("  wed->inverse_edges_array_dest: %p\n", wed->inverse_edges_array_dest);
#if WEIGHTED
    printf("  wed->inverse_edges_array_weight: %p\n", wed->inverse_edges_array_weight);
#endif
#endif

    printf("  wed->auxiliary1: %p\n", wed->auxiliary1);
    printf("  wed->auxiliary2: %p\n", wed->auxiliary2);
    printf("  wed->done: %p\n", &(wed->done));

}
