#ifndef CAPIENV_H
#define CAPIENV_H

#include <linux/types.h>
#include "myMalloc.h"
#include "graphCSR.h"
#include "libcxl.h"


// ********************************************************************************************
// ***************                  MMIO General 	                             **************
// ********************************************************************************************

#define ALGO_STATUS            0x3FFFFF8             // 0x3fffff8 >> 2 = 0xfffffe
#define ALGO_REQUEST           0x3FFFFF0             // 0x3fffff8 >> 2 = 0xfffffc
#define ERROR_REG              0x3FFFFE8
#define AFU_STATUS             0x3FFFFE0
#define ALGO_RUNNING           0x3FFFFD8

#define ALGO_STATUS_ACK  0x3FFFFD0
#define ERROR_REG_ACK    0x3FFFFC8

#define  ALGO_STATUS_DONE     0x3FFFFC0
#define  ALGO_STATUS_DONE_ACK 0x3FFFFB8

#ifdef  SIM
#define DEVICE_1              "/dev/cxl/afu0.0d"
#else
#define DEVICE_1              "/dev/cxl/afu0.0d"
#define DEVICE_2              "/dev/cxl/afu1.0d"
#endif

struct AFUStatus
{
    uint64_t algo_stop; // afu stopping condition
    uint64_t algo_status;
    uint64_t num_cu;
    uint64_t error;
    uint64_t afu_status;
    uint64_t algo_running;
    uint64_t algo_status_done;
};

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
    void *auxiliary1;                   // 8-Bytes
    void *auxiliary2;                   // 8-Bytes
    __u32 afu_config;                   // 4-Bytes you can specify the read/write command to use the cache or not. 32-bit [0]-read [1]-write
}; // 108-bytes used from 128-Bytes WED;

// ********************************************************************************************
// ***************                        afu_config BIT-MAPPING                 **************
// ********************************************************************************************
 
 #define STRICT 0b000
 #define ABORT  0b001
 #define PAGE   0b010
 #define PREF   0b011
 #define SPEC   0b111

 #define READ_CL_S    0b1 // bit 31
 #define READ_CL_NA   0b0
 #define WRITE_MS     0b1
 #define WRITE_NA     0b0 // bit 30

 #define AFU_CONFIG 3 // 1100000 00000 00000 00000 00000 00000
 
/*

//command translation order
 // STRICT = 3'b000,
 // ABORT  = 3'b001,
 // PAGE   = 3'b010,
 // PREF   = 3'b011,
 // SPEC   = 3'b111


*/

struct  WEDGraphCSR *mapGraphCSRToWED(struct GraphCSR *graph);
void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed);

// ********************************************************************************************
// ***************                  MMIO General 	                             **************
// ********************************************************************************************

void printMMIO_error( uint64_t error );

// ********************************************************************************************
// ***************                  AFU General                                  **************
// ********************************************************************************************

int setupAFUGraphCSR(struct cxl_afu_h **afu, struct WEDGraphCSR *wedGraphCSR);
void startAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void waitJOBRunning(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void waitAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void releaseAFU(struct cxl_afu_h **afu);


#endif
