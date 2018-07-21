#ifndef CAPIENV_H
#define CAPIENV_H

#include <linux/types.h>

#define APP_NAME              "test_afu"

#define CACHELINE_BYTES       128                   // 0x80
#define MMIO_ADDR             0x3fffff8             // 0x3fffff8 >> 2 = 0xfffffe

#ifdef  SIM
  #define DEVICE              "/dev/cxl/afu0.0d"
#else
  #define DEVICE              "/dev/cxl/afu1.0d"
#endif


typedef struct
{
	__u64 size;
	void *stripe1;
	void *stripe2;
	void *parity;
	__u64 done;
} parity_request;



#endif
