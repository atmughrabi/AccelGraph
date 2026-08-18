#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

#include "capienv.h"

static struct cxl_afu_h fake_afu;
static uint64_t fake_afu_status;
static uint64_t fake_cu_status;
static uint64_t fake_target = 4;
static uint64_t fake_result = 2;
static uint32_t fake_progress_reads;
static uint32_t fake_reset_reads;
static uint32_t fake_completion_count;
static uint32_t fake_afu_config_writes;
static uint32_t fake_cu_config_writes;
static int fake_completion_ack;
static int fake_device_error;
static int fake_fail_open;
static int fake_fail_mmio;
static int fake_freeze_completion;
static int fake_stuck_reset;
static int fake_unmap_count;
static int fake_free_count;

int cxl_mmio_install_sigbus_handler(void)
{
    return 0;
}

struct cxl_afu_h *cxl_afu_open_dev(char *path)
{
    (void)path;

    if(fake_fail_open)
    {
        errno = ENODEV;
        return NULL;
    }

    fake_afu.active = 1;
    return &fake_afu;
}

int cxl_afu_attach(struct cxl_afu_h *afu, uint64_t wed)
{
    return (!afu || !wed) ? -1 : 0;
}

void cxl_afu_free(struct cxl_afu_h *afu)
{
    if(afu)
    {
        afu->active = 0;
        fake_free_count++;
    }
}

int cxl_mmio_map(struct cxl_afu_h *afu, uint32_t flags)
{
    return (!afu || flags != CXL_MMIO_BIG_ENDIAN) ? -1 : 0;
}

int cxl_mmio_unmap(struct cxl_afu_h *afu)
{
    if(!afu)
        return -1;

    fake_unmap_count++;
    return 0;
}

int cxl_mmio_write64(struct cxl_afu_h *afu, uint64_t offset, uint64_t data)
{
    if(!afu)
        return -1;

    switch(offset)
    {
    case AFU_CONFIGURE:
        fake_afu_config_writes++;
        if(fake_afu_config_writes > 1)
            fake_afu_status = data;
        break;
    case CU_CONFIGURE:
        fake_cu_config_writes++;
        if(fake_cu_config_writes == 1)
            break;

        if(fake_completion_ack)
        {
            fake_completion_ack = 0;
            fake_progress_reads = 0;
        }
        fake_cu_status = data ? 1 : 0;
        break;
    case CU_RETURN_DONE_ACK:
        fake_completion_ack = data != 0;
        fake_completion_count += fake_completion_ack;
        break;
    default:
        break;
    }

    return 0;
}

int cxl_mmio_read64(struct cxl_afu_h *afu, uint64_t offset, uint64_t *data)
{
    if(!afu || !data)
        return -1;

    if(fake_fail_mmio)
    {
        errno = EIO;
        return -1;
    }

    switch(offset)
    {
    case AFU_STATUS:
        *data = fake_afu_status;
        break;
    case CU_STATUS:
        *data = (fake_completion_ack && !fake_stuck_reset) ?
            0 : fake_cu_status;
        if(fake_completion_ack)
            fake_reset_reads++;
        break;
    case ERROR_REG:
        *data = (fake_device_error && fake_progress_reads) ? 1 : 0;
        break;
    case CU_RETURN:
        *data = ++fake_progress_reads;
        break;
    case CU_RETURN_2:
        *data = fake_progress_reads;
        break;
    case CU_RETURN_DONE:
        *data = (!fake_freeze_completion &&
                 !fake_completion_ack &&
                 fake_progress_reads >= 2) ?
            fake_target : 0;
        break;
    case CU_RETURN_DONE_2:
        *data = (!fake_freeze_completion &&
                 !fake_completion_ack &&
                 fake_progress_reads >= 2) ?
            fake_result : 0;
        break;
    default:
        *data = 0;
        break;
    }

    return 0;
}

static int expectChildFailure(int fail_open, int fail_mmio)
{
    pid_t child = fork();
    int status = 0;

    if(child == 0)
    {
        struct cxl_afu_h *afu;
        struct WEDGraphCSR wed = {0};
        struct AFUStatus afu_status = {0};

        close(STDERR_FILENO);
        fake_fail_open = fail_open;
        fake_fail_mmio = fail_mmio;
        wed.num_vertices = (uint32_t)fake_target;
        setupAFUGraphCSR(&afu, &wed);

        afu_status.afu_config = 1;
        startAFU(&afu, &afu_status);
        _exit(2);
    }

    if(child < 0 || waitpid(child, &status, 0) != child)
        return 1;

    return !(WIFEXITED(status) && WEXITSTATUS(status) == EXIT_FAILURE);
}

static int expectRuntimeFailure(
    int freeze_completion,
    int stuck_reset,
    int device_error)
{
    pid_t child = fork();
    int status = 0;

    if(child == 0)
    {
        struct cxl_afu_h *afu;
        struct WEDGraphCSR wed = {0};
        struct AFUStatus afu_status = {0};

        close(STDERR_FILENO);
        setenv("ACCELERATOR_START_TIMEOUT_MS", "10", 1);
        setenv("ACCELERATOR_STALL_TIMEOUT_MS", "10", 1);
        setenv("ACCELERATOR_RUN_TIMEOUT_MS", "20", 1);
        setenv("ACCELERATOR_CALL_TIMEOUT_MS", "100", 1);
        setenv("ACCELERATOR_POLL_INTERVAL_US", "1000", 1);

        fake_freeze_completion = freeze_completion;
        fake_stuck_reset = stuck_reset;
        fake_device_error = device_error;
        wed.num_vertices = (uint32_t)fake_target;
        setupAFUGraphCSR(&afu, &wed);

        afu_status.afu_config = 1;
        afu_status.cu_config = 1;
        afu_status.cu_config_2 = 1;
        afu_status.cu_config_3 = 1;
        afu_status.cu_config_4 = 1;
        afu_status.cu_stop = fake_target;

        startAFU(&afu, &afu_status);
        startCU(&afu, &afu_status);
        waitAFU(&afu, &afu_status);
        _exit(2);
    }

    if(child < 0 || waitpid(child, &status, 0) != child)
        return 1;

    return !(WIFEXITED(status) && WEXITSTATUS(status) == EXIT_FAILURE);
}

int main(void)
{
    struct cxl_afu_h *afu;
    struct WEDGraphCSR wed = {0};
    struct AFUStatus afu_status = {0};

    if(expectChildFailure(1, 0) ||
       expectChildFailure(0, 1) ||
       expectRuntimeFailure(1, 0, 0) ||
       expectRuntimeFailure(0, 1, 0) ||
       expectRuntimeFailure(0, 0, 1))
        return EXIT_FAILURE;

    wed.num_vertices = (uint32_t)fake_target;
    setupAFUGraphCSR(&afu, &wed);

    afu_status.afu_config = 0x1111000000000001ULL;
    afu_status.cu_config = 1;
    afu_status.cu_config_2 = 1;
    afu_status.cu_config_3 = 1;
    afu_status.cu_config_4 = 1;
    afu_status.cu_stop = fake_target;

    startAFU(&afu, &afu_status);
    startCU(&afu, &afu_status);
    waitAFU(&afu, &afu_status);

    if(afu_status.cu_return_done != fake_target ||
       afu_status.cu_return_done_2 != fake_result ||
       !fake_completion_ack ||
       !fake_reset_reads ||
       fake_afu_config_writes < 2 ||
       fake_cu_config_writes < 2)
        return EXIT_FAILURE;

    startCU(&afu, &afu_status);
    waitAFU(&afu, &afu_status);

    if(afu_status.cu_return_done != fake_target ||
       afu_status.cu_return_done_2 != fake_result ||
       fake_completion_count != 2)
        return EXIT_FAILURE;

    releaseAFU(&afu);

    if(afu || fake_unmap_count != 1 || fake_free_count != 1)
        return EXIT_FAILURE;

    printf("PASS capienv_verification\n");
    return EXIT_SUCCESS;
}
