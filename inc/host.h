#ifndef __HOST_H_
#define __HOST_H_

#ifdef __cplusplus
extern "C" {
#endif
#include "utils.h"

DataType* host_setup(unsigned int v_len, unsigned int seed);
void host_teardown(void);

int cpu_kernel_run(const struct options *opt, DataType *h_vector);
#ifdef __cplusplus
}
#endif
#endif /*__HOST_H_*/
