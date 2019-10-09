#ifndef CAPIENV_H
#define CAPIENV_H

#include <linux/types.h>
#include "myMalloc.h"
#include "graphCSR.h"
#include "libcxl.h"

// ********************************************************************************************
// ***************                  MMIO General 	                             **************
// ********************************************************************************************

#define ALGO_STATUS            0x3fffff8             // 0x3fffff8 >> 2 = 0xfffffe
#define ALGO_REQUEST           0x3fffff0             // 0x3fffff8 >> 2 = 0xfffffc
#define ERROR_REG              0x3FFFFE8

#ifdef  SIM
#define DEVICE              "/dev/cxl/afu0.0d"
#else
#define DEVICE              "/dev/cxl/afu1.0d"
#endif


// ********************************************************************************************
// ***************                  CSR DataStructure                            **************
// ********************************************************************************************

struct __attribute__((__packed__)) WEDGraphCSR
{
    __u32 num_edges;                    // 4-Bytes
    __u32 num_vertices;                 // 4-Bytes
    __u32 max_weight;                   // 4-Bytes
    void *vertex_out_degree;            // 8-Bytes
    void *vertex_in_degree;             // 8-Bytes
    void *vertex_edges_idx;             // 8-Bytes
    void *edges_array_weight;           // 8-Bytes
    void *edges_array_src;              // 8-Bytes
    void *edges_array_dest;             // 8-Bytes
    //---------------------------------------------------//
    void *inverse_vertex_out_degree;    // 8-Bytes  --// 64bytes
    //---------------------------------------------------//
    void *inverse_vertex_in_degree;     // 8-Bytes
    void *inverse_vertex_edges_idx;     // 8-Bytes
    void *inverse_edges_array_weight;   // 8-Bytes
    void *inverse_edges_array_src;      // 8-Bytes
    void *inverse_edges_array_dest;     // 8-Bytes
    void *auxiliary1;                  // 8-Bytes
    void *auxiliary2;                  // 8-Bytes
    __u32 done;                         // 4-Bytes
}; // 108-bytes used from 128-Bytes WEDt;

struct  WEDGraphCSR *mapGraphCSRToWED(struct GraphCSR *graph);
void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed);

// ********************************************************************************************
// ***************                  MMIO General 	                             **************
// ********************************************************************************************

void printMMIO_error( uint64_t error );


#endif
