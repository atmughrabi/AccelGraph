#ifndef LIBCXL_H
#define LIBCXL_H

#include <stdint.h>

#define CXL_MMIO_BIG_ENDIAN 0x1

struct cxl_afu_h
{
    int active;
};

int cxl_mmio_install_sigbus_handler(void);
struct cxl_afu_h *cxl_afu_open_dev(char *path);
int cxl_afu_attach(struct cxl_afu_h *afu, uint64_t wed);
void cxl_afu_free(struct cxl_afu_h *afu);
int cxl_mmio_map(struct cxl_afu_h *afu, uint32_t flags);
int cxl_mmio_unmap(struct cxl_afu_h *afu);
int cxl_mmio_write64(struct cxl_afu_h *afu, uint64_t offset, uint64_t data);
int cxl_mmio_read64(struct cxl_afu_h *afu, uint64_t offset, uint64_t *data);

#endif
