
#include "timer.h"

  void Start(struct Timer* timer) {
    gettimeofday(&(timer->start_time), NULL);
  }

  void Stop(struct Timer* timer) {
    gettimeofday(&(timer->elapsed_time), NULL);
    timer->elapsed_time.tv_sec  -= timer->start_time.tv_sec;
    timer->elapsed_time.tv_usec -= timer->start_time.tv_usec;
  }

  double Seconds(struct Timer* timer){
    return timer->elapsed_time.tv_sec + timer->elapsed_time.tv_usec/1e6;
  }

  double Millisecs(struct Timer* timer){
    return 1000*timer->elapsed_time.tv_sec + timer->elapsed_time.tv_usec/1000;
  }

  double Microsecs(struct Timer* timer){
    return 1e6*timer->elapsed_time.tv_sec + timer->elapsed_time.tv_usec;
  }
