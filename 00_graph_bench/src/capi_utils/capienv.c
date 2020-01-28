// -----------------------------------------------------------------------------
//
//      "CAPIPrecis"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : capienv.c
// Create : 2019-10-09 19:20:39
// Revise : 2019-12-01 00:12:59
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "myMalloc.h"
#include "libcxl.h"
#include "capienv.h"

#include "algorithm.h"

// ********************************************************************************************
// ***************                  AFU General                                  **************
// ********************************************************************************************

int setupAFU(struct cxl_afu_h **afu, struct WEDStruct *wed)
{

    (*afu) = cxl_afu_open_dev(DEVICE_1);
    if(!afu)
    {
        printf("Failed to open AFU: %m\n");
        return 1;
    }

    cxl_afu_attach((*afu), (uint64_t)wed);
    int base_address = cxl_mmio_map ((*afu), CXL_MMIO_BIG_ENDIAN);

    if (base_address < 0)
    {
        printf("fail cxl_mmio_map %d", base_address);
        return 1;
    }

    return 0;

}

void startAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status)
{
#ifdef  VERBOSE
    // printf("AFU configuration start status(0x%08lx) \n", (afu_status->afu_status) );
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "AFU configuration START", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->afu_status));
#endif
    do
    {
        cxl_mmio_write64((*afu), AFU_CONFIGURE, afu_status->afu_config);
        cxl_mmio_write64((*afu), AFU_CONFIGURE_2, afu_status->afu_config_2);
        cxl_mmio_read64((*afu), AFU_STATUS, (uint64_t *) & (afu_status->afu_status));
    }
    while(!(afu_status->afu_status));
#ifdef  VERBOSE
    // printf("AFU configuration done status(0x%08lx) \n", (afu_status->afu_status) );
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "AFU configuration DONE", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->afu_status));
    printf("*-----------------------------------------------------*\n");
#endif
}

void startCU(struct cxl_afu_h **afu, struct AFUStatus *afu_status)
{
#ifdef  VERBOSE
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "CU configuration START", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->cu_status));
#endif
    do
    {
        cxl_mmio_write64((*afu), CU_CONFIGURE, (uint64_t)afu_status->cu_config);
        cxl_mmio_write64((*afu), CU_CONFIGURE_2, (uint64_t)afu_status->cu_config_2);
        cxl_mmio_read64((*afu), CU_STATUS, (uint64_t *) & (afu_status->cu_status));
    }
    while(!((afu_status->cu_status)));
#ifdef  VERBOSE
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "CU configuration DONE", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->cu_status));
    printf("*-----------------------------------------------------*\n");
#endif
}

void waitAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status)
{

    struct CmdResponseStats cmdResponseStats = {0};

    do
    {
        // Poll for errors always
        cxl_mmio_read64((*afu), ERROR_REG, (uint64_t *) & (afu_status->error));
        cxl_mmio_write64((*afu), ERROR_REG_ACK, (uint64_t)afu_status->error);

        // read final return result
        cxl_mmio_read64((*afu), CU_RETURN_DONE, (uint64_t *) & (afu_status->cu_return_done));

        // if((((afu_status->cu_return_done) << 32) >> 32) >= (afu_status->cu_stop))
        //     break;

        if((afu_status->cu_return_done) >= (afu_status->cu_stop))
        {
            readCmdResponseStats(afu, &cmdResponseStats);
            cxl_mmio_write64((*afu), CU_RETURN_DONE_ACK, (uint64_t)afu_status->cu_return_done);
            break;
        }
    }
    while((!(afu_status->error)));

#ifdef  VERBOSE
    printCmdResponseStats(&cmdResponseStats);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-18s %-15s  | \n", " ", "CU return", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "Return", (afu_status->cu_return_done));
    printf("*-----------------------------------------------------*\n");

#endif

}

void readCmdResponseStats(struct cxl_afu_h **afu, struct CmdResponseStats *cmdResponseStats)
{


    cxl_mmio_read64((*afu), DONE_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_count));
    cxl_mmio_read64((*afu), DONE_RESTART_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_RESTART_count));

    cxl_mmio_read64((*afu), DONE_PREFETCH_READ_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_PREFETCH_READ_count));
    cxl_mmio_read64((*afu), DONE_PREFETCH_WRITE_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_PREFETCH_WRITE_count));

    cxl_mmio_read64((*afu), PAGED_COUNT_REG, (uint64_t *) & (cmdResponseStats->PAGED_count));
    cxl_mmio_read64((*afu), FLUSHED_COUNT_REG, (uint64_t *) & (cmdResponseStats->FLUSHED_count));
    cxl_mmio_read64((*afu), AERROR_COUNT_REG, (uint64_t *) & (cmdResponseStats->AERROR_count));
    cxl_mmio_read64((*afu), DERROR_COUNT_REG, (uint64_t *) & (cmdResponseStats->DERROR_count));
    cxl_mmio_read64((*afu), FAILED_COUNT_REG, (uint64_t *) & (cmdResponseStats->FAILED_count));
    cxl_mmio_read64((*afu), FAULT_COUNT_REG, (uint64_t *) & (cmdResponseStats->FAULT_count));
    cxl_mmio_read64((*afu), NRES_COUNT_REG, (uint64_t *) & (cmdResponseStats->NRES_count));
    cxl_mmio_read64((*afu), NLOCK_COUNT_REG, (uint64_t *) & (cmdResponseStats->NLOCK_count));
    cxl_mmio_read64((*afu), CYCLE_COUNT_REG, (uint64_t *) & (cmdResponseStats->CYCLE_count));
    cxl_mmio_read64((*afu), DONE_READ_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_READ_count));
    cxl_mmio_read64((*afu), DONE_WRITE_COUNT_REG, (uint64_t *) & (cmdResponseStats->DONE_WRITE_count));

}

void printCmdResponseStats(struct CmdResponseStats *cmdResponseStats)
{

    uint64_t size_read  = (cmdResponseStats->DONE_READ_count);
    uint64_t size_write = (cmdResponseStats->DONE_WRITE_count);
    uint64_t size       = size_read;
    if(size_write > size_read)
        size = size_write;
    double time_elapsed = (double)(cmdResponseStats->CYCLE_count * 4) / 1e9;
    double size_GB = (double)(size) / (double)(1024 * 1024 * 8);
    double size_MB = (double)(size) / (double)(1024 * 8);
    double bandwidth_GB = size_GB / time_elapsed; //GB/s
    double bandwidth_MB = size_MB / time_elapsed; //MB/s

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "AFU Stats", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "CYCLE_count ", cmdResponseStats->CYCLE_count);

    printf("| %-22s | %-27.20lf| \n", "Time (Seconds)", time_elapsed);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27.20lf| \n", "Data MB", size_MB);
    printf("| %-22s | %-27.20lf| \n", "Data GB", size_GB);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27.20lf| \n", "BandWidth MB/s", bandwidth_MB);
    printf("| %-22s | %-27.20lf| \n", "BandWidth GB/s", bandwidth_GB);


    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Responses Stats", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "DONE_count", cmdResponseStats->DONE_count);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "DONE_READ_count", cmdResponseStats->DONE_READ_count);
    printf("| %-22s | %-27lu| \n", "DONE_WRITE_count", cmdResponseStats->DONE_WRITE_count);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "DONE_RESTART_count", cmdResponseStats->DONE_RESTART_count);
    printf(" -----------------------------------------------------\n");
    printf("| %-26s | %-23lu| \n", "DONE_PREFETCH_READ_count", cmdResponseStats->DONE_PREFETCH_READ_count);
    printf("| %-26s | %-23lu| \n", "DONE_PREFETCH_WRITE_count", cmdResponseStats->DONE_PREFETCH_WRITE_count);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "PAGED_count", cmdResponseStats->PAGED_count);
    printf("| %-22s | %-27lu| \n", "FLUSHED_count", cmdResponseStats->FLUSHED_count);
    printf("| %-22s | %-27lu| \n", "AERROR_count", cmdResponseStats->AERROR_count);
    printf("| %-22s | %-27lu| \n", "DERROR_count", cmdResponseStats->DERROR_count);
    printf("| %-22s | %-27lu| \n", "FAILED_count", cmdResponseStats->FAILED_count);
    printf("| %-22s | %-27lu| \n", "NRES_count", cmdResponseStats->NRES_count);
    printf("| %-22s | %-27lu| \n", "NLOCK_count", cmdResponseStats->NLOCK_count);
    printf("*-----------------------------------------------------*\n");
}

void releaseAFU(struct cxl_afu_h **afu)
{
    cxl_mmio_unmap ((*afu));
    cxl_afu_free((*afu));
}

// ********************************************************************************************
// ***************                  MMIO General                                 **************
// ********************************************************************************************

void printMMIO_error( uint64_t error )
{
    if(error >> 14)
    {
        printf("(BIT-14) Credit Overflow AFU Error\n");
    }
    else if(error >> 12)
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
        case 16:
            printf("(BIT-4) Response NRES\n");
            break;
        case 32:
            printf("(BIT-5) Response NLOCK\n");
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

struct  WEDStruct *mapDataArraysToWED(struct DataArrays *dataArrays)
{

    struct WEDStruct *wed = my_malloc(sizeof(struct WEDStruct));

    wed->size_send    = dataArrays->size;
    wed->size_recive  = dataArrays->size;
    wed->array_send     = dataArrays->array_send;
    wed->array_receive  = dataArrays->array_receive;


#ifdef  VERBOSE
    printWEDPointers(wed);
#endif

    return wed;
}


void printWEDPointers(struct  WEDStruct *wed)
{

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-18s %-15s | \n", " ", "WEDStruct structure", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27p| \n", "wed",   wed);
    printf("| %-22s | %-27lu| \n", "wed->size_send", wed->size_send);
    printf("| %-22s | %-27lu| \n", "wed->size_recive", wed->size_recive);
    printf("| %-22s | %-27p| \n", "wed->array_send", wed->array_send);
    printf("| %-22s | %-27p| \n", "wed->array_receive", wed->array_receive);
    printf(" -----------------------------------------------------\n");

}
