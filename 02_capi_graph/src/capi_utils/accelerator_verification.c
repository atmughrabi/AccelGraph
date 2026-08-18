// -----------------------------------------------------------------------------
//
//      "AccelGraph"
//
// -----------------------------------------------------------------------------

#include <errno.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "accelerator_verification.h"

static timer_t accelerator_watchdog_timer;
static int accelerator_watchdog_initialized;
static uint64_t accelerator_watchdog_timeout_ms;
static volatile sig_atomic_t accelerator_watchdog_armed;
static volatile sig_atomic_t accelerator_watchdog_message_size;
static char accelerator_watchdog_message[256];

static void acceleratorVerificationWatchdogHandler(int signal_number)
{
    ssize_t written;

    (void)signal_number;

    if(!accelerator_watchdog_armed)
        return;

    atomic_signal_fence(memory_order_seq_cst);

    if(accelerator_watchdog_message_size > 0)
    {
        written = write(
            STDERR_FILENO,
            accelerator_watchdog_message,
            (size_t)accelerator_watchdog_message_size);
        (void)written;
    }

    _exit(EXIT_FAILURE);
}

static int acceleratorVerificationReadValue(
    const char *name,
    uint64_t default_value,
    uint64_t max_value,
    uint64_t *value)
{
    const char *text = getenv(name);
    char *end = NULL;
    unsigned long long parsed;

    if(!text)
    {
        *value = default_value;
        return 0;
    }

    errno = 0;
    parsed = strtoull(text, &end, 10);

    if(errno || end == text || *end != '\0' ||
       parsed == 0 || parsed > max_value)
    {
        fprintf(stderr, "Invalid %s value: %s\n", name, text);
        return 1;
    }

    *value = (uint64_t)parsed;
    return 0;
}

static uint64_t acceleratorVerificationElapsed(uint64_t now_ms, uint64_t then_ms)
{
    if(now_ms < then_ms)
        return 0;

    return now_ms - then_ms;
}

int acceleratorVerificationLoadConfig(struct AcceleratorVerificationConfig *config)
{
    if(!config)
        return 1;

    if(acceleratorVerificationReadValue(
           "ACCELERATOR_START_TIMEOUT_MS",
           ACCELERATOR_START_TIMEOUT_MS_DEFAULT,
           ACCELERATOR_TIMEOUT_MS_MAX,
           &(config->start_timeout_ms)))
        return 1;

    if(acceleratorVerificationReadValue(
           "ACCELERATOR_STALL_TIMEOUT_MS",
           ACCELERATOR_STALL_TIMEOUT_MS_DEFAULT,
           ACCELERATOR_TIMEOUT_MS_MAX,
           &(config->stall_timeout_ms)))
        return 1;

    if(acceleratorVerificationReadValue(
           "ACCELERATOR_RUN_TIMEOUT_MS",
           ACCELERATOR_RUN_TIMEOUT_MS_DEFAULT,
           ACCELERATOR_TIMEOUT_MS_MAX,
           &(config->run_timeout_ms)))
        return 1;

    if(acceleratorVerificationReadValue(
           "ACCELERATOR_CALL_TIMEOUT_MS",
           ACCELERATOR_CALL_TIMEOUT_MS_DEFAULT,
           ACCELERATOR_TIMEOUT_MS_MAX,
           &(config->call_timeout_ms)))
        return 1;

    if(acceleratorVerificationReadValue(
           "ACCELERATOR_POLL_INTERVAL_US",
           ACCELERATOR_POLL_INTERVAL_US_DEFAULT,
           ACCELERATOR_POLL_INTERVAL_US_MAX,
           &(config->poll_interval_us)))
        return 1;

    if(config->poll_interval_us > (config->start_timeout_ms * 1000ULL) ||
       config->poll_interval_us > (config->stall_timeout_ms * 1000ULL) ||
       config->poll_interval_us > (config->run_timeout_ms * 1000ULL))
    {
        fprintf(stderr, "ACCELERATOR_POLL_INTERVAL_US must not exceed a configured timeout\n");
        return 1;
    }

    return 0;
}

int acceleratorVerificationNowMs(uint64_t *now_ms)
{
    struct timespec now;

    if(!now_ms)
        return 1;

    if(clock_gettime(CLOCK_MONOTONIC, &now))
    {
        fprintf(stderr, "clock_gettime failed: %s\n", strerror(errno));
        return 1;
    }

    *now_ms = ((uint64_t)now.tv_sec * 1000ULL) +
              ((uint64_t)now.tv_nsec / 1000000ULL);
    return 0;
}

int acceleratorVerificationPause(uint64_t poll_interval_us)
{
    struct timespec interval;

    if(!poll_interval_us)
        return 1;

    interval.tv_sec = (time_t)(poll_interval_us / 1000000ULL);
    interval.tv_nsec = (long)((poll_interval_us % 1000000ULL) * 1000ULL);

    while(nanosleep(&interval, &interval))
    {
        if(errno != EINTR)
        {
            fprintf(stderr, "nanosleep failed: %s\n", strerror(errno));
            return 1;
        }
    }

    return 0;
}

int acceleratorVerificationWatchdogInitialize(uint64_t timeout_ms)
{
    struct sigaction action;
    struct sigevent event;

    if(!timeout_ms || timeout_ms > ACCELERATOR_TIMEOUT_MS_MAX)
        return 1;

    accelerator_watchdog_timeout_ms = timeout_ms;

    if(accelerator_watchdog_initialized)
        return 0;

    memset(&action, 0, sizeof(action));
    action.sa_handler = acceleratorVerificationWatchdogHandler;
    sigemptyset(&(action.sa_mask));

    if(sigaction(SIGALRM, &action, NULL))
    {
        fprintf(stderr, "sigaction failed: %s\n", strerror(errno));
        return 1;
    }

    memset(&event, 0, sizeof(event));
    event.sigev_notify = SIGEV_SIGNAL;
    event.sigev_signo = SIGALRM;

    if(timer_create(CLOCK_MONOTONIC, &event, &accelerator_watchdog_timer))
    {
        fprintf(stderr, "timer_create failed: %s\n", strerror(errno));
        return 1;
    }

    accelerator_watchdog_initialized = 1;
    return 0;
}

int acceleratorVerificationWatchdogArm(const char *operation)
{
    struct itimerspec deadline = {0};
    int message_size;

    if(!accelerator_watchdog_initialized || !operation)
        return 1;

    message_size = snprintf(
        accelerator_watchdog_message,
        sizeof(accelerator_watchdog_message),
        "Accelerator call watchdog expired: operation=%s timeout_ms=%llu\n",
        operation,
        (unsigned long long)accelerator_watchdog_timeout_ms);

    if(message_size < 0)
        return 1;

    if((size_t)message_size >= sizeof(accelerator_watchdog_message))
        message_size = (int)(sizeof(accelerator_watchdog_message) - 1);

    accelerator_watchdog_message_size = (sig_atomic_t)message_size;
    deadline.it_value.tv_sec = (time_t)(accelerator_watchdog_timeout_ms / 1000ULL);
    deadline.it_value.tv_nsec =
        (long)((accelerator_watchdog_timeout_ms % 1000ULL) * 1000000ULL);
    atomic_signal_fence(memory_order_seq_cst);
    accelerator_watchdog_armed = 1;

    if(timer_settime(accelerator_watchdog_timer, 0, &deadline, NULL))
    {
        accelerator_watchdog_armed = 0;
        atomic_signal_fence(memory_order_seq_cst);
        fprintf(stderr, "timer_settime failed: %s\n", strerror(errno));
        return 1;
    }

    return 0;
}

int acceleratorVerificationWatchdogDisarm(void)
{
    struct itimerspec deadline = {0};

    if(!accelerator_watchdog_initialized)
        return 1;

    accelerator_watchdog_armed = 0;

    if(timer_settime(accelerator_watchdog_timer, 0, &deadline, NULL))
    {
        fprintf(stderr, "timer_settime failed: %s\n", strerror(errno));
        return 1;
    }

    return 0;
}

void acceleratorVerificationStart(
    struct AcceleratorVerification *verification,
    const char *phase,
    uint64_t now_ms,
    uint64_t timeout_ms,
    uint64_t stall_timeout_ms,
    uint64_t progress_primary,
    uint64_t progress_secondary)
{
    verification->phase = phase;
    verification->started_ms = now_ms;
    verification->last_progress_ms = now_ms;
    verification->timeout_ms = timeout_ms;
    verification->stall_timeout_ms = stall_timeout_ms;
    verification->progress_primary = progress_primary;
    verification->progress_secondary = progress_secondary;
}

enum AcceleratorVerificationState acceleratorVerificationObserve(
    struct AcceleratorVerification *verification,
    uint64_t now_ms,
    uint64_t progress_primary,
    uint64_t progress_secondary,
    int complete,
    int device_error)
{
    if(device_error)
        return ACCELERATOR_VERIFICATION_DEVICE_ERROR;

    if(complete)
        return ACCELERATOR_VERIFICATION_COMPLETE;

    if(progress_primary != verification->progress_primary ||
       progress_secondary != verification->progress_secondary)
    {
        verification->progress_primary = progress_primary;
        verification->progress_secondary = progress_secondary;
        verification->last_progress_ms = now_ms;
    }

    if(acceleratorVerificationElapsed(now_ms, verification->started_ms) >=
       verification->timeout_ms)
        return ACCELERATOR_VERIFICATION_TIMED_OUT;

    if(acceleratorVerificationElapsed(now_ms, verification->last_progress_ms) >=
       verification->stall_timeout_ms)
        return ACCELERATOR_VERIFICATION_STALLED;

    return ACCELERATOR_VERIFICATION_PENDING;
}

const char *acceleratorVerificationStateName(enum AcceleratorVerificationState state)
{
    switch(state)
    {
    case ACCELERATOR_VERIFICATION_COMPLETE:
        return "complete";
    case ACCELERATOR_VERIFICATION_DEVICE_ERROR:
        return "device-error";
    case ACCELERATOR_VERIFICATION_TIMED_OUT:
        return "timeout";
    case ACCELERATOR_VERIFICATION_STALLED:
        return "stalled";
    case ACCELERATOR_VERIFICATION_PENDING:
    default:
        return "pending";
    }
}
