#ifndef ACCELERATOR_VERIFICATION_H
#define ACCELERATOR_VERIFICATION_H

#include <stdint.h>

#define ACCELERATOR_START_TIMEOUT_MS_DEFAULT 10000ULL
#define ACCELERATOR_STALL_TIMEOUT_MS_DEFAULT 60000ULL
#define ACCELERATOR_RUN_TIMEOUT_MS_DEFAULT 1800000ULL
#define ACCELERATOR_CALL_TIMEOUT_MS_DEFAULT 30000ULL
#define ACCELERATOR_POLL_INTERVAL_US_DEFAULT 1000ULL
#define ACCELERATOR_SPIN_POLLS_DEFAULT 100ULL
#define ACCELERATOR_TIMEOUT_MS_MAX 86400000ULL
#define ACCELERATOR_POLL_INTERVAL_US_MAX 1000000ULL

enum AcceleratorVerificationState
{
    ACCELERATOR_VERIFICATION_DEVICE_ERROR = -3,
    ACCELERATOR_VERIFICATION_TIMED_OUT = -2,
    ACCELERATOR_VERIFICATION_STALLED = -1,
    ACCELERATOR_VERIFICATION_PENDING = 0,
    ACCELERATOR_VERIFICATION_COMPLETE = 1
};

struct AcceleratorVerificationConfig
{
    uint64_t start_timeout_ms;
    uint64_t stall_timeout_ms;
    uint64_t run_timeout_ms;
    uint64_t call_timeout_ms;
    uint64_t poll_interval_us;
};

struct AcceleratorVerification
{
    const char *phase;
    uint64_t started_ms;
    uint64_t last_progress_ms;
    uint64_t timeout_ms;
    uint64_t stall_timeout_ms;
    uint64_t progress_primary;
    uint64_t progress_secondary;
};

int acceleratorVerificationLoadConfig(struct AcceleratorVerificationConfig *config);
int acceleratorVerificationNowMs(uint64_t *now_ms);
int acceleratorVerificationPause(uint64_t poll_interval_us);
int acceleratorVerificationWatchdogInitialize(uint64_t timeout_ms);
int acceleratorVerificationWatchdogArm(const char *operation);
int acceleratorVerificationWatchdogDisarm(void);

void acceleratorVerificationStart(
    struct AcceleratorVerification *verification,
    const char *phase,
    uint64_t now_ms,
    uint64_t timeout_ms,
    uint64_t stall_timeout_ms,
    uint64_t progress_primary,
    uint64_t progress_secondary);

enum AcceleratorVerificationState acceleratorVerificationObserve(
    struct AcceleratorVerification *verification,
    uint64_t now_ms,
    uint64_t progress_primary,
    uint64_t progress_secondary,
    int complete,
    int device_error);

const char *acceleratorVerificationStateName(enum AcceleratorVerificationState state);

#endif
