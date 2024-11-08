
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

/* Support function to generate a random number in a given range.
 * Based on the solution presented in the following forum thread:
 * http://ubuntuforums.org/showthread.php?t=1717717&p=10618266#post10618266*/
static DataType randfrom(DataType min, DataType max)
{
  DataType range = (max - min);
  DataType div = RAND_MAX / range;
  return min + (rand() / div);
}

/* Populate a given vector memory location with values from a given range.*/
void generateRandVector(DataType* v, int v_len, DataType min, DataType max,
                        unsigned int seed)
{
  if (0 == seed)
    srand(time(NULL));
  else
    srand(seed);

  for (int i = 0; i < v_len; ++i) {
    v[i] = randfrom(min, max);
  }
}

/*Get the current CPU time in seconds as a double.*/
double getCpuSeconds(void)
{
  struct timeval tp;
  gettimeofday(&tp, NULL);
  return ((double) tp.tv_sec + (double) tp.tv_usec * 1.e-6);
}

/* Print the measured times:
 * Header:
 *   build, mode, threads, launches, nodes, iterations, total, cuda_diff, graph_creation, total_launch, exec, results
 */
void print_times(const struct options* opt, double* times, unsigned int len,
                 DataType results)
{
  int mode = 0;
  if (opt->run_graph) {
    mode = 1;
  } else if (opt->run_cpu) {
    mode = -1;
  }
  printf("%s, %d, %d, %d, %d, %d", BUILD_VERSION, mode, opt->number_of_threads,
         opt->outer_iterations, opt->number_of_kernels, opt->inner_iterations);
  for (unsigned int i = 0; i < len; ++i) {
    printf(", %lf", times[i]);
  }
  printf(", %lf\n", results);
}
