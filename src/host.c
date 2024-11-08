#include "host.h"
#include <stdlib.h>

static DataType* gh_vector;
DataType* host_setup(unsigned int v_len, unsigned int seed)
{
  gh_vector = (DataType*) malloc(v_len * sizeof(DataType));

  if (gh_vector != NULL)
    generateRandVector(gh_vector, v_len, 0, 0.1, seed);

  return gh_vector;
}

void host_teardown(void) { free(gh_vector); }

/* CPU version of above kernel */
void cpu_vectorIterMult(DataType* v, unsigned int v_len, unsigned int iter,
                        const int idx)
{
  for (int x = 0; x < idx; ++x) {
    for (unsigned int i = 0; i < iter; ++i) {
      v[x] = 1.00005 * v[x];
    }
  }
}

int cpu_kernel_run(const struct options* opt, DataType* h_vector)
{

  for (unsigned int i = 0; i < opt->outer_iterations; ++i) {
    for (unsigned int k = 0; k < opt->number_of_kernels; ++k) {
      cpu_vectorIterMult(h_vector, opt->number_of_threads,
                         opt->inner_iterations, opt->number_of_threads);
    }
  }

  return 0;
}
