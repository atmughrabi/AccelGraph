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

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "accelerator_verification.h"
#include "myMalloc.h"
#include "libcxl.h"
#include "capienv.h"

#include "graphCSR.h"

// ********************************************************************************************
// ***************                  AFU General                                  **************
// ********************************************************************************************

static struct AcceleratorVerificationConfig accelerator_runtime_config;
static int accelerator_runtime_config_loaded;

static int acceleratorLoadRuntimeConfig(
    struct AcceleratorVerificationConfig *config)
{
    if(!accelerator_runtime_config_loaded)
    {
        if(acceleratorVerificationLoadConfig(&accelerator_runtime_config))
            return 1;

        accelerator_runtime_config_loaded = 1;
    }

    (*config) = accelerator_runtime_config;
    return 0;
}

static void acceleratorCallStart(const char *operation)
{
    if(acceleratorVerificationWatchdogArm(operation))
    {
        fprintf(stderr, "Failed to arm accelerator call watchdog: %s\n", operation);
        _exit(EXIT_FAILURE);
    }
}

static void acceleratorCallStop(void)
{
    if(acceleratorVerificationWatchdogDisarm())
    {
        fprintf(stderr, "Failed to disarm accelerator call watchdog\n");
        _exit(EXIT_FAILURE);
    }
}

static void acceleratorWatchdogInitialize(void)
{
    struct AcceleratorVerificationConfig config;

    if(acceleratorLoadRuntimeConfig(&config) ||
       acceleratorVerificationWatchdogInitialize(config.call_timeout_ms))
        exit(EXIT_FAILURE);
}

static void setupAFUFailure(struct cxl_afu_h **afu, const char *operation, int status)
{
    int error_number = status > 0 ? status : errno;

    fprintf(
        stderr,
        "AFU setup failed: operation=%s status=%d error=%s\n",
        operation,
        status,
        error_number ? strerror(error_number) : "not available");

    if(afu && (*afu))
    {
        acceleratorCallStart("free AFU after setup failure");
        cxl_afu_free((*afu));
        acceleratorCallStop();
        (*afu) = NULL;
    }

    exit(EXIT_FAILURE);
}

static void acceleratorVerificationFailure(
    struct cxl_afu_h **afu,
    struct AFUStatus *afu_status,
    struct AcceleratorVerification *verification,
    enum AcceleratorVerificationState state,
    uint64_t now_ms,
    uint64_t target)
{
    uint64_t elapsed_ms = now_ms - verification->started_ms;
    uint64_t idle_ms = now_ms - verification->last_progress_ms;

    fprintf(
        stderr,
        "Accelerator verification failed: phase=%s reason=%s elapsed_ms=%" PRIu64
        " idle_ms=%" PRIu64 " progress=%" PRIu64 ":%" PRIu64
        " target=%" PRIu64 " afu_status=0x%016" PRIx64
        " cu_status=0x%016" PRIx64 " error=0x%016" PRIx64 "\n",
        verification->phase,
        acceleratorVerificationStateName(state),
        elapsed_ms,
        idle_ms,
        verification->progress_primary,
        verification->progress_secondary,
        target,
        afu_status->afu_status,
        afu_status->cu_status,
        afu_status->error);

    releaseAFU(afu);
    exit(EXIT_FAILURE);
}

static void acceleratorValidateAFU(
    struct cxl_afu_h **afu,
    struct AFUStatus *afu_status,
    const char *phase)
{
    if(afu && (*afu) && afu_status)
        return;

    fprintf(stderr, "Invalid AFU state before %s\n", phase);
    releaseAFU(afu);
    exit(EXIT_FAILURE);
}

static void acceleratorMMIOFailure(
    struct cxl_afu_h **afu,
    const char *operation,
    uint64_t offset,
    int status)
{
    int error_number = status > 0 ? status : errno;

    fprintf(
        stderr,
        "Accelerator MMIO failed: operation=%s offset=0x%08" PRIx64
        " status=%d error=%s\n",
        operation,
        offset,
        status,
        error_number ? strerror(error_number) : "not available");

    releaseAFU(afu);
    exit(EXIT_FAILURE);
}

static void acceleratorMMIORead(
    struct cxl_afu_h **afu,
    uint64_t offset,
    uint64_t *value,
    const char *operation)
{
    int status;

    acceleratorCallStart(operation);
    status = cxl_mmio_read64((*afu), offset, value);
    acceleratorCallStop();
    if(status)
        acceleratorMMIOFailure(afu, operation, offset, status);
}

static void acceleratorMMIOWrite(
    struct cxl_afu_h **afu,
    uint64_t offset,
    uint64_t value,
    const char *operation)
{
    int status;

    acceleratorCallStart(operation);
    status = cxl_mmio_write64((*afu), offset, value);
    acceleratorCallStop();
    if(status)
        acceleratorMMIOFailure(afu, operation, offset, status);
}

static void acceleratorVerificationGetConfig(
    struct cxl_afu_h **afu,
    struct AcceleratorVerificationConfig *config)
{
    if(acceleratorLoadRuntimeConfig(config))
    {
        releaseAFU(afu);
        exit(EXIT_FAILURE);
    }
}

static uint64_t acceleratorVerificationGetNow(struct cxl_afu_h **afu)
{
    uint64_t now_ms;

    if(acceleratorVerificationNowMs(&now_ms))
    {
        releaseAFU(afu);
        exit(EXIT_FAILURE);
    }

    return now_ms;
}

static void acceleratorVerificationWait(
    struct cxl_afu_h **afu,
    uint64_t poll_interval_us,
    uint64_t *poll_count)
{
    if((*poll_count)++ < ACCELERATOR_SPIN_POLLS_DEFAULT)
        return;

    if(acceleratorVerificationPause(poll_interval_us))
    {
        releaseAFU(afu);
        exit(EXIT_FAILURE);
    }
}

static void acceleratorPrintFailureStats(struct CmdResponseStats *stats)
{
    fprintf(
        stderr,
        "Accelerator response stats: done=%" PRIu64 " read=%" PRIu64
        " write=%" PRIu64 " restart=%" PRIu64 " paged=%" PRIu64
        " flushed=%" PRIu64 " aerror=%" PRIu64 " derror=%" PRIu64
        " failed=%" PRIu64 " fault=%" PRIu64 " nres=%" PRIu64
        " nlock=%" PRIu64 " cycles=%" PRIu64 "\n",
        stats->DONE_count,
        stats->DONE_READ_count,
        stats->DONE_WRITE_count,
        stats->DONE_RESTART_count,
        stats->PAGED_count,
        stats->FLUSHED_count,
        stats->AERROR_count,
        stats->DERROR_count,
        stats->FAILED_count,
        stats->FAULT_count,
        stats->NRES_count,
        stats->NLOCK_count,
        stats->CYCLE_count);
}

static void waitAFUCompletionReset(
    struct cxl_afu_h **afu,
    struct AFUStatus *afu_status,
    struct AcceleratorVerificationConfig *config)
{
    struct AcceleratorVerification verification;
    enum AcceleratorVerificationState state;
    uint64_t reset_done = afu_status->cu_return_done;
    uint64_t reset_done_2 = afu_status->cu_return_done_2;
    uint64_t reset_status = afu_status->cu_status;
    uint64_t poll_count = 0;
    uint64_t now_ms = acceleratorVerificationGetNow(afu);

    acceleratorVerificationStart(
        &verification,
        "CU completion reset",
        now_ms,
        config->start_timeout_ms,
        config->start_timeout_ms,
        reset_done,
        reset_done_2);

    do
    {
        acceleratorMMIORead(
            afu,
            CU_RETURN_DONE,
            &reset_done,
            "read CU completion reset");
        acceleratorMMIORead(
            afu,
            CU_RETURN_DONE_2,
            &reset_done_2,
            "read CU completion reset data");
        acceleratorMMIORead(
            afu,
            CU_STATUS,
            &reset_status,
            "read CU reset status");

        afu_status->cu_status = reset_status;
        now_ms = acceleratorVerificationGetNow(afu);
        state = acceleratorVerificationObserve(
            &verification,
            now_ms,
            reset_done,
            reset_done_2,
            !reset_done && !reset_done_2 && !reset_status,
            0);

        if(state == ACCELERATOR_VERIFICATION_COMPLETE)
            break;

        if(state != ACCELERATOR_VERIFICATION_PENDING)
            acceleratorVerificationFailure(afu, afu_status, &verification, state, now_ms, 0);

        acceleratorVerificationWait(afu, config->poll_interval_us, &poll_count);
    }
    while(1);
}

char *capiDevicePath(void)
{
    char *device = getenv("CAPI_DEVICE");

    return (device && device[0]) ? device : DEVICE_1;
}

int setupAFUGraphCSR(struct cxl_afu_h **afu, struct WEDGraphCSR *wedGraphCSR)
{
    int status;

    if(!afu)
        setupAFUFailure(NULL, "validate AFU handle", EINVAL);

    (*afu) = NULL;

    if(!wedGraphCSR)
        setupAFUFailure(afu, "validate graph WED", EINVAL);

    acceleratorWatchdogInitialize();
    acceleratorCallStart("install MMIO fault handler");
    status = cxl_mmio_install_sigbus_handler();
    acceleratorCallStop();
    if(status)
        setupAFUFailure(afu, "install MMIO fault handler", status);

    acceleratorCallStart("open AFU device");
    (*afu) = cxl_afu_open_dev(capiDevicePath());
    acceleratorCallStop();
    if(!(*afu))
        setupAFUFailure(afu, "open device", errno);

    acceleratorCallStart("attach graph WED");
    status = cxl_afu_attach((*afu), (uint64_t)wedGraphCSR);
    acceleratorCallStop();
    if(status)
        setupAFUFailure(afu, "attach graph WED", status);

    acceleratorCallStart("map AFU MMIO");
    status = cxl_mmio_map((*afu), CXL_MMIO_BIG_ENDIAN);
    acceleratorCallStop();
    if(status < 0)
        setupAFUFailure(afu, "map MMIO", status);

#ifdef  VERBOSE
    printWEDGraphCSRPointers(wedGraphCSR);
#endif

    return 0;

}


void startAFU(struct cxl_afu_h **afu, struct AFUStatus *afu_status)
{
    struct AcceleratorVerificationConfig config;
    struct AcceleratorVerification verification;
    enum AcceleratorVerificationState state;
    uint64_t now_ms;
    uint64_t poll_count = 0;

    acceleratorValidateAFU(afu, afu_status, "AFU configuration");
    acceleratorVerificationGetConfig(afu, &config);

    if(!(afu_status->afu_config))
    {
        fprintf(stderr, "AFU configuration must be non-zero\n");
        releaseAFU(afu);
        exit(EXIT_FAILURE);
    }

    afu_status->afu_status = 0;
    afu_status->error = 0;

#ifdef  VERBOSE
    // printf("AFU configuration start status(0x%08lx) \n", (afu_status->afu_status) );
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "AFU configuration START", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->afu_status));
#endif
    now_ms = acceleratorVerificationGetNow(afu);
    acceleratorVerificationStart(
        &verification,
        "AFU configuration",
        now_ms,
        config.start_timeout_ms,
        config.start_timeout_ms,
        0,
        0);

    do
    {
        acceleratorMMIOWrite(afu, AFU_CONFIGURE, afu_status->afu_config, "write AFU configuration");
        acceleratorMMIOWrite(afu, AFU_CONFIGURE_2, afu_status->afu_config_2, "write AFU configuration data");
        acceleratorMMIORead(afu, AFU_STATUS, &(afu_status->afu_status), "read AFU status");
        acceleratorMMIORead(afu, ERROR_REG, &(afu_status->error), "read AFU configuration error");
        now_ms = acceleratorVerificationGetNow(afu);
        state = acceleratorVerificationObserve(
            &verification,
            now_ms,
            afu_status->afu_status,
            0,
            afu_status->afu_status == afu_status->afu_config,
            afu_status->error != 0);

        if(state == ACCELERATOR_VERIFICATION_COMPLETE)
            break;

        if(state != ACCELERATOR_VERIFICATION_PENDING)
            acceleratorVerificationFailure(
                afu,
                afu_status,
                &verification,
                state,
                now_ms,
                afu_status->afu_config);

        acceleratorVerificationWait(afu, config.poll_interval_us, &poll_count);
    }
    while(1);
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
    struct AcceleratorVerificationConfig config;
    struct AcceleratorVerification verification;
    enum AcceleratorVerificationState state;
    uint64_t now_ms;
    uint64_t poll_count = 0;

    acceleratorValidateAFU(afu, afu_status, "CU configuration");
    acceleratorVerificationGetConfig(afu, &config);

    if(!(afu_status->cu_config))
    {
        fprintf(stderr, "CU configuration must be non-zero\n");
        releaseAFU(afu);
        exit(EXIT_FAILURE);
    }

    afu_status->cu_status = 0;
    afu_status->error = 0;

#ifdef  VERBOSE
    printf("*-----------------------------------------------------*\n");
    printf("| %-13s %-23s %-13s | \n", " ", "CU configuration START", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lx| \n", "status", (afu_status->cu_status));
#endif
    now_ms = acceleratorVerificationGetNow(afu);
    acceleratorVerificationStart(
        &verification,
        "CU configuration",
        now_ms,
        config.start_timeout_ms,
        config.start_timeout_ms,
        0,
        0);

    do
    {
        acceleratorMMIOWrite(afu, CU_CONFIGURE, afu_status->cu_config, "write CU configuration");
        acceleratorMMIOWrite(afu, CU_CONFIGURE_2, afu_status->cu_config_2, "write CU configuration data 2");
        acceleratorMMIOWrite(afu, CU_CONFIGURE_3, afu_status->cu_config_3, "write CU configuration data 3");
        acceleratorMMIOWrite(afu, CU_CONFIGURE_4, afu_status->cu_config_4, "write CU configuration data 4");
        acceleratorMMIORead(afu, CU_STATUS, &(afu_status->cu_status), "read CU status");
        acceleratorMMIORead(afu, ERROR_REG, &(afu_status->error), "read CU configuration error");
        now_ms = acceleratorVerificationGetNow(afu);
        state = acceleratorVerificationObserve(
            &verification,
            now_ms,
            afu_status->cu_status,
            0,
            afu_status->cu_status != 0,
            afu_status->error != 0);

        if(state == ACCELERATOR_VERIFICATION_COMPLETE)
            break;

        if(state != ACCELERATOR_VERIFICATION_PENDING)
            acceleratorVerificationFailure(afu, afu_status, &verification, state, now_ms, 1);

        acceleratorVerificationWait(afu, config.poll_interval_us, &poll_count);
    }
    while(1);
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

    struct AcceleratorVerificationConfig config;
    struct AcceleratorVerification verification;
    enum AcceleratorVerificationState state;
    struct CmdResponseStats cmdResponseStats = {0};
    uint64_t now_ms;
    uint64_t poll_count = 0;

    acceleratorValidateAFU(afu, afu_status, "CU execution");
    acceleratorVerificationGetConfig(afu, &config);
    afu_status->cu_return = 0;
    afu_status->cu_return_2 = 0;
    afu_status->cu_return_done = 0;
    afu_status->cu_return_done_2 = 0;
    afu_status->error = 0;

    now_ms = acceleratorVerificationGetNow(afu);
    acceleratorVerificationStart(
        &verification,
        "CU execution",
        now_ms,
        config.run_timeout_ms,
        config.stall_timeout_ms,
        0,
        0);

#ifdef  VERBOSE_2
    printf("*-----------------------------------------------------*\n");
    printf("| (#) Data: %-14lu | %-24s |\n", afu_status->cu_stop, "(#) Data Processed");
    printf(" -----------------------------------------------------\n");
#endif
    do
    {
        // Poll for errors always
        acceleratorMMIORead(afu, ERROR_REG, &(afu_status->error), "read CU execution error");

        // read final return result
        acceleratorMMIORead(afu, CU_RETURN_DONE, &(afu_status->cu_return_done), "read CU completion");
        acceleratorMMIORead(afu, CU_RETURN_DONE_2, &(afu_status->cu_return_done_2), "read CU completion data");
        acceleratorMMIORead(afu, CU_RETURN, &(afu_status->cu_return), "read CU progress");
        acceleratorMMIORead(afu, CU_RETURN_2, &(afu_status->cu_return_2), "read CU progress data");

#ifdef  VERBOSE_2
        if(afu_status->cu_return && afu_status->cu_return_2)
            printf("\r| R: %-21lu | W: %-22lu|", afu_status->cu_return, afu_status->cu_return_2);
        fflush(stdout);
#endif

        now_ms = acceleratorVerificationGetNow(afu);
        state = acceleratorVerificationObserve(
            &verification,
            now_ms,
            afu_status->cu_return,
            afu_status->cu_return_2,
            afu_status->cu_return_done >= afu_status->cu_stop,
            afu_status->error != 0);

        if(state == ACCELERATOR_VERIFICATION_COMPLETE)
        {
            readCmdResponseStats(afu, &cmdResponseStats);
            acceleratorMMIOWrite(
                afu,
                CU_RETURN_DONE_ACK,
                afu_status->cu_return_done ?
                    afu_status->cu_return_done :
                    (afu_status->cu_return_done_2 ?
                        afu_status->cu_return_done_2 : 1),
                "acknowledge CU completion");
            waitAFUCompletionReset(afu, afu_status, &config);
            break;
        }

        if(state == ACCELERATOR_VERIFICATION_DEVICE_ERROR)
        {
            printMMIO_error(afu_status->error);
            readCmdResponseStats(afu, &cmdResponseStats);
            acceleratorPrintFailureStats(&cmdResponseStats);
            acceleratorMMIOWrite(
                afu,
                ERROR_REG_ACK,
                afu_status->error,
                "acknowledge CU execution error");
            acceleratorVerificationFailure(afu, afu_status, &verification, state, now_ms, afu_status->cu_stop);
        }

        if(state != ACCELERATOR_VERIFICATION_PENDING)
        {
            readCmdResponseStats(afu, &cmdResponseStats);
            acceleratorPrintFailureStats(&cmdResponseStats);
            acceleratorVerificationFailure(afu, afu_status, &verification, state, now_ms, afu_status->cu_stop);
        }

        acceleratorVerificationWait(afu, config.poll_interval_us, &poll_count);
    }
    while(1);

#ifdef  VERBOSE_2
    printf("\n*-----------------------------------------------------*\n");
#endif
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


    acceleratorMMIORead(afu, DONE_COUNT_REG, &(cmdResponseStats->DONE_count), "read DONE count");
    acceleratorMMIORead(afu, DONE_RESTART_COUNT_REG, &(cmdResponseStats->DONE_RESTART_count), "read restart count");

    acceleratorMMIORead(afu, DONE_PREFETCH_READ_COUNT_REG, &(cmdResponseStats->DONE_PREFETCH_READ_count), "read prefetch read count");
    acceleratorMMIORead(afu, DONE_PREFETCH_WRITE_COUNT_REG, &(cmdResponseStats->DONE_PREFETCH_WRITE_count), "read prefetch write count");

    acceleratorMMIORead(afu, PAGED_COUNT_REG, &(cmdResponseStats->PAGED_count), "read paged count");
    acceleratorMMIORead(afu, FLUSHED_COUNT_REG, &(cmdResponseStats->FLUSHED_count), "read flushed count");
    acceleratorMMIORead(afu, AERROR_COUNT_REG, &(cmdResponseStats->AERROR_count), "read address error count");
    acceleratorMMIORead(afu, DERROR_COUNT_REG, &(cmdResponseStats->DERROR_count), "read data error count");
    acceleratorMMIORead(afu, FAILED_COUNT_REG, &(cmdResponseStats->FAILED_count), "read failed count");
    acceleratorMMIORead(afu, FAULT_COUNT_REG, &(cmdResponseStats->FAULT_count), "read fault count");
    acceleratorMMIORead(afu, NRES_COUNT_REG, &(cmdResponseStats->NRES_count), "read no-resource count");
    acceleratorMMIORead(afu, NLOCK_COUNT_REG, &(cmdResponseStats->NLOCK_count), "read lock count");
    acceleratorMMIORead(afu, CYCLE_COUNT_REG, &(cmdResponseStats->CYCLE_count), "read cycle count");
    acceleratorMMIORead(afu, DONE_READ_COUNT_REG, &(cmdResponseStats->DONE_READ_count), "read completed read count");
    acceleratorMMIORead(afu, DONE_WRITE_COUNT_REG, &(cmdResponseStats->DONE_WRITE_count), "read completed write count");

    acceleratorMMIORead(afu, READ_BYTE_COUNT_REG, &(cmdResponseStats->READ_BYTE_count), "read byte count");
    acceleratorMMIORead(afu, WRITE_BYTE_COUNT_REG, &(cmdResponseStats->WRITE_BYTE_count), "read written byte count");
    acceleratorMMIORead(afu, PREFETCH_READ_BYTE_COUNT_REG, &(cmdResponseStats->PREFETCH_READ_BYTE_count), "read prefetched byte count");
    acceleratorMMIORead(afu, PREFETCH_WRITE_BYTE_COUNT_REG, &(cmdResponseStats->PREFETCH_WRITE_BYTE_count), "read prefetched write byte count");

}

void printBandwidth(uint64_t size, double time_elapsed, uint64_t rep_bytes)
{

    double size_GB = (double)(size) * (double)rep_bytes / (double)(1024 * 1024 * 1024);
    double size_MB = (double)(size) * (double)rep_bytes / (double)(1024 * 1024);
    double bandwidth_GB = size_GB / time_elapsed; //GB/s
    double bandwidth_MB = size_MB / time_elapsed; //MB/s

    printf("| %-22s | %-27.20lf| \n", "Data MB", size_MB);
    printf("| %-22s | %-27.20lf| \n", "Data GB", size_GB);
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27.20lf| \n", "BandWidth MB/s", bandwidth_MB);
    printf("| %-22s | %-27.20lf| \n", "BandWidth GB/s", bandwidth_GB);
}

void printCmdResponseStats(struct CmdResponseStats *cmdResponseStats)
{

    uint64_t size_read  = (cmdResponseStats->DONE_READ_count);
    uint64_t size_write = (cmdResponseStats->DONE_WRITE_count);
    uint64_t size       = size_read + (size_write);

    uint64_t size_read_byte  = (cmdResponseStats->READ_BYTE_count);
    uint64_t size_write_byte = (cmdResponseStats->WRITE_BYTE_count);
    uint64_t size_byte       = size_read_byte + (size_write_byte);

    double time_elapsed = (double)(cmdResponseStats->CYCLE_count * 4) / 1e9;

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "AFU Stats", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "CYCLE_count ", cmdResponseStats->CYCLE_count);
    printf("| %-22s | %-27.20lf| \n", "Time (Seconds)", time_elapsed);
    printf(" -----------------------------------------------------\n");

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Total BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size, time_elapsed, 128);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Total Read BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size_read, time_elapsed, 128);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Total Write BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size_write, time_elapsed, 128);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Effective total BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size_byte, time_elapsed, 1);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Effective Read BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size_read_byte, time_elapsed, 1);

    printf("*-----------------------------------------------------*\n");
    printf("| %-15s %-19s %-15s | \n", " ", "Effective Write BW", " ");
    printf(" -----------------------------------------------------\n");
    printBandwidth(size_write_byte, time_elapsed, 1);

    printf("*-----------------------------------------------------*\n");
    printf("| %-12s %-25s %-12s | \n", " ", "Byte Transfer Stats", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-22s | %-27lu| \n", "READ_BYTE_count", cmdResponseStats->READ_BYTE_count);
    printf("| %-22s | %-27lu| \n", "WRITE_BYTE_count", cmdResponseStats->WRITE_BYTE_count);
    printf(" -----------------------------------------------------\n");
    printf("| %-26s | %-23lu| \n", "PREFETCH_READ_BYTE_count", cmdResponseStats->PREFETCH_READ_BYTE_count);
    printf("| %-26s | %-23lu| \n", "PREFETCH_WRITE_BYTE_count", cmdResponseStats->PREFETCH_WRITE_BYTE_count);
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
    int status;

    if(!afu || !(*afu))
        return;

    acceleratorCallStart("unmap AFU MMIO");
    status = cxl_mmio_unmap((*afu));
    acceleratorCallStop();
    if(status)
        fprintf(stderr, "Failed to unmap AFU MMIO: status=%d error=%s\n", status, strerror(errno));

    acceleratorCallStart("free AFU");
    cxl_afu_free((*afu));
    acceleratorCallStop();
    (*afu) = NULL;
}

// ********************************************************************************************
// ***************                  MMIO General                                 **************
// ********************************************************************************************

void printMMIO_error( uint64_t error )
{
    if(error & (1ULL << 14))
        fprintf(stderr, "(BIT-14) Credit Overflow AFU Error\n");
    if(error & (1ULL << 13))
        fprintf(stderr, "(BIT-13) Job Command Error\n");
    if(error & (1ULL << 12))
        fprintf(stderr, "(BIT-12) Job Address Error\n");
    if(error & (1ULL << 11))
        fprintf(stderr, "(BIT-11) MMIO Data Parity-Error\n");
    if(error & (1ULL << 10))
        fprintf(stderr, "(BIT-10) MMIO Address Parity-Error\n");
    if(error & (1ULL << 9))
        fprintf(stderr, "(BIT-9) Write Tag Parity-Error\n");
    if(error & (1ULL << 8))
        fprintf(stderr, "(BIT-8) Read Tag Parity-Error\n");
    if(error & (1ULL << 7))
        fprintf(stderr, "(BIT-7) Read Data Parity-Error\n");
    if(error & (1ULL << 6))
        fprintf(stderr, "(BIT-6) Response Tag Parity-Error\n");
    if(error & (1ULL << 5))
        fprintf(stderr, "(BIT-5) Response NLOCK\n");
    if(error & (1ULL << 4))
        fprintf(stderr, "(BIT-4) Response NRES\n");
    if(error & (1ULL << 3))
        fprintf(stderr, "(BIT-3) Response FAULT\n");
    if(error & (1ULL << 2))
        fprintf(stderr, "(BIT-2) Response FAILED\n");
    if(error & (1ULL << 1))
        fprintf(stderr, "(BIT-1) Response DERROR\n");
    if(error & (1ULL << 0))
        fprintf(stderr, "(BIT-0) Response AERROR\n");

}

// ********************************************************************************************
// ***************                   DataStructure                               **************
// ********************************************************************************************


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
#else
    wed->edges_array_weight = 0;
#endif

#if DIRECTED
    wed->inverse_vertex_out_degree  = graph->inverse_vertices->out_degree;
    wed->inverse_vertex_in_degree   = graph->inverse_vertices->in_degree;
    wed->inverse_vertex_edges_idx   = graph->inverse_vertices->edges_idx;

    wed->inverse_edges_array_src    = graph->inverse_sorted_edges_array->edges_array_src;
    wed->inverse_edges_array_dest   = graph->inverse_sorted_edges_array->edges_array_dest;
#if WEIGHTED
    wed->inverse_edges_array_weight = graph->inverse_sorted_edges_array->edges_array_weight;
#else
    wed->inverse_edges_array_weight = 0;
#endif
#endif


    wed->auxiliary0 = 0;
    return wed;
}


void printWEDGraphCSRPointers(struct  WEDGraphCSR *wed)
{

    printf("*-----------------------------------------------------*\n");
    printf("| %-12s %-24s %-12s | \n", " ", "WED GraphCSR structure", " ");
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24p| \n", "wed",   wed);
    printf("| %-25s | %-24u| \n", "num_edges", wed->num_edges);
    printf("| %-25s | %-24u| \n", "num_vertices", wed->num_vertices);
    printf("| %-25s | %-24f| \n", "max_weight", wed->max_weight);
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24p| \n", "vertex_in_degree", wed->vertex_in_degree);
    printf("| %-25s | %-24p| \n", "vertex_out_degree", wed->vertex_out_degree);
    printf("| %-25s | %-24p| \n", "vertex_edges_idx", wed->vertex_edges_idx);
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24p| \n", "edges_array_src", wed->edges_array_src);
    printf("| %-25s | %-24p| \n", "edges_array_dest", wed->edges_array_dest);
    printf("| %-25s | %-24p| \n", "edges_array_weight", wed->edges_array_weight);
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24p| \n", "inverse_vertex_in_degree", wed->inverse_vertex_in_degree);
    printf("| %-25s | %-24p| \n", "inverse_vertex_out_degree", wed->inverse_vertex_out_degree);
    printf("| %-25s | %-24p| \n", "inverse_vertex_edges_idx", wed->inverse_vertex_edges_idx);
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24p| \n", "inverse_edges_array_src", wed->inverse_edges_array_src);
    printf("| %-25s | %-24p| \n", "inverse_edges_array_dest", wed->inverse_edges_array_dest);
    printf(" -----------------------------------------------------\n");
    printf("| %-25s | %-24u| \n", "auxiliary0", wed->auxiliary0);
    printf("| %-25s | %-24p| \n", "auxiliary1", wed->auxiliary1);
    printf("| %-25s | %-24p| \n", "auxiliary2", wed->auxiliary2);
    printf(" -----------------------------------------------------\n");
}
