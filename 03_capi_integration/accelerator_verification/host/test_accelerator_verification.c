#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

#include "accelerator_verification.h"

static int failures;

static void check(int condition, const char *name)
{
    if(!condition)
    {
        fprintf(stderr, "FAIL %s\n", name);
        failures++;
    }
}

int main(void)
{
    struct AcceleratorVerificationConfig config;
    struct AcceleratorVerification verification;
    uint64_t before_ms;
    uint64_t after_ms;

    unsetenv("ACCELERATOR_START_TIMEOUT_MS");
    unsetenv("ACCELERATOR_STALL_TIMEOUT_MS");
    unsetenv("ACCELERATOR_RUN_TIMEOUT_MS");
    unsetenv("ACCELERATOR_POLL_INTERVAL_US");

    check(!acceleratorVerificationLoadConfig(&config), "default configuration");
    check(config.start_timeout_ms == ACCELERATOR_START_TIMEOUT_MS_DEFAULT, "default start timeout");
    check(config.stall_timeout_ms == ACCELERATOR_STALL_TIMEOUT_MS_DEFAULT, "default stall timeout");
    check(config.run_timeout_ms == ACCELERATOR_RUN_TIMEOUT_MS_DEFAULT, "default run timeout");
    check(config.call_timeout_ms == ACCELERATOR_CALL_TIMEOUT_MS_DEFAULT, "default call timeout");
    check(config.poll_interval_us == ACCELERATOR_POLL_INTERVAL_US_DEFAULT, "default poll interval");

    setenv("ACCELERATOR_START_TIMEOUT_MS", "250", 1);
    check(!acceleratorVerificationLoadConfig(&config), "configuration override");
    check(config.start_timeout_ms == 250, "start timeout override");

    setenv("ACCELERATOR_START_TIMEOUT_MS", "0", 1);
    check(acceleratorVerificationLoadConfig(&config), "zero timeout rejected");
    unsetenv("ACCELERATOR_START_TIMEOUT_MS");

    setenv("ACCELERATOR_POLL_INTERVAL_US", "1000001", 1);
    check(acceleratorVerificationLoadConfig(&config), "excessive poll interval rejected");
    unsetenv("ACCELERATOR_POLL_INTERVAL_US");

    setenv("ACCELERATOR_CALL_TIMEOUT_MS", "0", 1);
    check(acceleratorVerificationLoadConfig(&config), "zero call timeout rejected");
    unsetenv("ACCELERATOR_CALL_TIMEOUT_MS");

    setenv("ACCELERATOR_START_TIMEOUT_MS", "1", 1);
    setenv("ACCELERATOR_POLL_INTERVAL_US", "2000", 1);
    check(acceleratorVerificationLoadConfig(&config), "poll interval beyond timeout rejected");
    unsetenv("ACCELERATOR_START_TIMEOUT_MS");
    unsetenv("ACCELERATOR_POLL_INTERVAL_US");

    acceleratorVerificationStart(&verification, "test", 100, 1000, 100, 0, 0);
    check(
        acceleratorVerificationObserve(&verification, 150, 0, 0, 0, 0) ==
            ACCELERATOR_VERIFICATION_PENDING,
        "pending state");
    check(
        acceleratorVerificationObserve(&verification, 175, 1, 0, 0, 0) ==
            ACCELERATOR_VERIFICATION_PENDING,
        "progress state");
    check(
        acceleratorVerificationObserve(&verification, 274, 1, 0, 0, 0) ==
            ACCELERATOR_VERIFICATION_PENDING,
        "stall deadline extended");
    check(
        acceleratorVerificationObserve(&verification, 275, 1, 0, 0, 0) ==
            ACCELERATOR_VERIFICATION_STALLED,
        "stall detected");

    acceleratorVerificationStart(&verification, "test", 100, 100, 1000, 0, 0);
    check(
        acceleratorVerificationObserve(&verification, 200, 1, 0, 0, 0) ==
            ACCELERATOR_VERIFICATION_TIMED_OUT,
        "absolute timeout detected");

    acceleratorVerificationStart(&verification, "test", 100, 1000, 1000, 0, 0);
    check(
        acceleratorVerificationObserve(&verification, 101, 0, 0, 1, 0) ==
            ACCELERATOR_VERIFICATION_COMPLETE,
        "completion detected");
    check(
        acceleratorVerificationObserve(&verification, 101, 0, 0, 0, 1) ==
            ACCELERATOR_VERIFICATION_DEVICE_ERROR,
        "device error detected");
    check(
        !acceleratorVerificationNowMs(&before_ms) &&
            !acceleratorVerificationPause(1000) &&
            !acceleratorVerificationNowMs(&after_ms) &&
            after_ms >= before_ms,
        "monotonic clock and polling");

    {
        pid_t child = fork();
        int child_status = 0;

        if(child == 0)
        {
            close(STDERR_FILENO);

            if(acceleratorVerificationWatchdogInitialize(10) ||
               acceleratorVerificationWatchdogArm("verification test"))
                _exit(2);

            acceleratorVerificationPause(100000);
            _exit(3);
        }

        check(child > 0, "watchdog child created");
        if(child > 0)
        {
            check(waitpid(child, &child_status, 0) == child, "watchdog child collected");
            check(
                WIFEXITED(child_status) &&
                    WEXITSTATUS(child_status) == EXIT_FAILURE,
                "blocked call watchdog");
        }
    }

    {
        pid_t child = fork();
        int child_status = 0;

        if(child == 0)
        {
            if(acceleratorVerificationWatchdogInitialize(10) ||
               acceleratorVerificationWatchdogArm("disarm test") ||
               acceleratorVerificationWatchdogDisarm())
                _exit(2);

            acceleratorVerificationPause(100000);
            _exit(EXIT_SUCCESS);
        }

        check(child > 0, "watchdog disarm child created");
        if(child > 0)
        {
            check(waitpid(child, &child_status, 0) == child, "watchdog disarm child collected");
            check(
                WIFEXITED(child_status) &&
                    WEXITSTATUS(child_status) == EXIT_SUCCESS,
                "call watchdog disarm");
        }
    }

    if(failures)
        return EXIT_FAILURE;

    printf("PASS accelerator_verification\n");
    return EXIT_SUCCESS;
}
