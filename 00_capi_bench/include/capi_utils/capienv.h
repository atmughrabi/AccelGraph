#ifndef CAPIENV_H
#define CAPIENV_H

#include <stdint.h>
#include "myMalloc.h"
#include "libcxl.h"

#include "graphCSR.h"

// ********************************************************************************************
// ***************                  MMIO General                                 **************
// ********************************************************************************************
// 0x3fffff8 >> 0x3FFFF10 used
#define AFU_STATUS              0x3FFFFF8
#define AFU_CONFIGURE           0x3FFFFF0
#define AFU_CONFIGURE_2         0x3FFFFE8

#define CU_STATUS               0x3FFFFE0
#define CU_CONFIGURE            0x3FFFFD8
#define CU_CONFIGURE_2          0x3FFFFD0
#define CU_CONFIGURE_3          0x3FFFFC8
#define CU_CONFIGURE_4          0x3FFFFC0

#define CU_RETURN               0x3FFFFB8         // running counters that you can read continuosly
#define CU_RETURN_2             0x3FFFFB0
#define CU_RETURN_ACK           0x3FFFFA8

#define  CU_RETURN_DONE         0x3FFFFA0
#define  CU_RETURN_DONE_ACK     0x3FFFF98

#define ERROR_REG               0x3FFFF90
#define ERROR_REG_ACK           0x3FFFF88

// ********************************************************************************************
// ***************                  AFU  Stats                                   **************
// ********************************************************************************************

#define  DONE_COUNT_REG                     0x3FFFF78
#define  DONE_RESTART_COUNT_REG             0x3FFFF70
#define  DONE_READ_COUNT_REG                0x3FFFF68
#define  DONE_WRITE_COUNT_REG               0x3FFFF60
#define  DONE_PREFETCH_READ_COUNT_REG       0x3FFFF58
#define  DONE_PREFETCH_WRITE_COUNT_REG      0x3FFFF50

#define  PAGED_COUNT_REG                    0x3FFFF48
#define  FLUSHED_COUNT_REG                  0x3FFFF40
#define  AERROR_COUNT_REG                   0x3FFFF38
#define  DERROR_COUNT_REG                   0x3FFFF30
#define  FAILED_COUNT_REG                   0x3FFFF28
#define  FAULT_COUNT_REG                    0x3FFFF20
#define  NRES_COUNT_REG                     0x3FFFF18
#define  NLOCK_COUNT_REG                    0x3FFFF10
#define  CYCLE_COUNT_REG                    0x3FFFF08

#define PREFETCH_READ_BYTE_COUNT_REG        0x3FFFF00
#define PREFETCH_WRITE_BYTE_COUNT_REG       0x3FFFEF8
#define READ_BYTE_COUNT_REG                 0x3FFFEF0
#define WRITE_BYTE_COUNT_REG                0x3FFFEE8


#ifdef  SIM
#define DEVICE_1              "/dev/cxl/afu0.0d"
#define DEVICE_2              "/dev/cxl/afu1.0d"
#else
#define DEVICE_1              "/dev/cxl/afu0.0d"
#define DEVICE_2              "/dev/cxl/afu1.0d"
#endif

struct AFUStatus
{
    uint64_t cu_stop;  // afu stopping condition
    uint64_t cu_config;
    uint64_t cu_config_2;
    uint64_t cu_config_3;
    uint64_t cu_config_4;
    uint64_t cu_status;
    uint64_t cu_mode;
    uint64_t afu_config;
    uint64_t afu_config_2;
    uint64_t afu_status;
    uint64_t error;
    uint64_t cu_return; // running return
    uint64_t cu_return_2; // running return
    uint64_t cu_return_done; // final return when cu send done
};


struct CmdResponseStats
{
    uint64_t DONE_count        ;
    uint64_t DONE_RESTART_count;
    uint64_t DONE_PREFETCH_READ_count;
    uint64_t DONE_PREFETCH_WRITE_count;
    uint64_t DONE_READ_count   ;
    uint64_t DONE_WRITE_count  ;
    uint64_t PAGED_count       ;
    uint64_t FLUSHED_count     ;
    uint64_t AERROR_count      ;
    uint64_t DERROR_count      ;
    uint64_t FAILED_count      ;
    uint64_t FAULT_count       ;
    uint64_t NRES_count        ;
    uint64_t NLOCK_count       ;
    uint64_t CYCLE_count       ;
    uint64_t PREFETCH_READ_BYTE_count;
    uint64_t PREFETCH_WRITE_BYTE_count;
    uint64_t READ_BYTE_count   ;
    uint64_t WRITE_BYTE_count  ;
};


// ********************************************************************************************
// ***************                      DataStructure CSR                        **************
// ********************************************************************************************

struct __attribute__((__packed__)) WEDGraphCSR
{
    uint32_t num_edges;                    // 4-Bytes
    uint32_t num_vertices;                 // 4-Bytes
    uint32_t max_weight;                   // 4-Bytes
    uint32_t auxiliary0;                   // 4-Bytes
    void *vertex_out_degree;            // 8-Bytes
    void *vertex_in_degree;             // 8-Bytes
    void *vertex_edges_idx;             // 8-Bytes
    void *edges_array_weight;           // 8-Bytes
    void *edges_array_src;              // 8-Bytes
    void *edges_array_dest;             // 8-Bytes
    //---------------------------------------------------//--// 64bytes
    void *inverse_vertex_out_degree;    // 8-Bytes
    void *inverse_vertex_in_degree;     // 8-Bytes
    void *inverse_vertex_edges_idx;     // 8-Bytes
    void *inverse_edges_array_weight;   // 8-Bytes
    void *inverse_edges_array_src;      // 8-Bytes
    void *inverse_edges_array_dest;     // 8-Bytes
    void *auxiliary1;                   // 8-Bytes
    void *auxiliary2;                   // 8-Bytes
}; // 108-bytes used from 128-Bytes WED;


// ********************************************************************************************
// ***************                        afu_config BIT-MAPPING                 **************
// ********************************************************************************************

struct WEDGraphCSR *mapGraphCSRToWED(struct GraphCSR *graph);
void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed);

// ********************************************************************************************
// ***************                  MMIO General                                 **************
// ********************************************************************************************

void printMMIO_error( uint64_t error );

// ********************************************************************************************
// ***************                  AFU General                                  **************
// ********************************************************************************************

int setupAFUGraphCSR(struct cxl_afu_h **afu, struct WEDGraphCSR *wedGraphCSR);
void startAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void startCU(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void waitAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status);
void readCmdResponseStats(struct cxl_afu_h **afu, struct CmdResponseStats *cmdResponseStats);
void printBandwidth(uint64_t size, double time_elapsed, uint64_t rep_bytes);
void printCmdResponseStats(struct CmdResponseStats *cmdResponseStats);
void releaseAFU(struct cxl_afu_h **afu);


#endif
