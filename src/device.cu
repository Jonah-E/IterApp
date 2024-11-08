#include "device.h"
#include "host.h"
#include "utils.h"
#include <stdio.h>
#include <stdlib.h>

#if defined(__HIP)
#include "hip/hip_runtime.h"
#define ACC(x) hip##x
#else
#define ACC(x) cuda##x
#endif

#define printCudaError(cuda_returned_error_code)                               \
  {                                                                            \
    accErrorPrint((cuda_returned_error_code), __FILE__, __LINE__);             \
  }

inline void accErrorPrint(ACC(Error_t) code, const char* file, int line)
{
  fprintf(stderr, "ACC Error: %s (%d) %s %d\n", ACC(GetErrorString)(code), code,
          file, line);
}

static DataType euclicianNormVector(DataType* vectorA, unsigned int length)
{
  DataType diffEu = 0;

  for (int i = 0; i < length; ++i) {
    diffEu += vectorA[i] * vectorA[i];
  }
  diffEu = sqrt(diffEu);

  return diffEu;
}

#include "simple-kernel.cu"

static DataType* gd_vector;
static DataType* device_setup(DataType* h_vector, unsigned int v_len)
{
  ACC(Error_t) device_error;
  device_error = ACC(Malloc)(&gd_vector, sizeof(DataType) * v_len);
  if (device_error != ACC(Success)) {
    printCudaError(device_error);
    return NULL;
  }

  device_error = ACC(Memcpy)(gd_vector, h_vector, sizeof(DataType) * v_len,
                             ACC(MemcpyHostToDevice));
  if (device_error != ACC(Success)) {
    printCudaError(device_error);
    return NULL;
  }

  return gd_vector;
}

void device_teardown(void) { ACC(Free)(gd_vector); }

enum time_categories {
  TOTAL_TIME,
  CUDA_DIFF_TIME,
  GRAPH_CREATION,
  TOTAL_LAUNCH_COST,
  EXEC_TIME,
};
#define TOTAL_NR_TIMES (1 + EXEC_TIME - TOTAL_TIME)
static double time_elapsed[TOTAL_NR_TIMES];
static void reset_times(void)
{
  for (int i = 0; i < TOTAL_NR_TIMES; ++i) {
    time_elapsed[i] = 0.0;
  }
}

#define TPB 1024
int device_kernel_run(const struct options* opt, DataType* d_vector)
{
  dim3 block(TPB);
  dim3 grid((opt->number_of_threads + TPB - 1) / TPB);

#ifdef TIME_DETAILED
  double time_start;
  time_start = getCpuSeconds();
#endif
  for (unsigned int i = 0; i < opt->outer_iterations; ++i) {
    for (unsigned int k = 0; k < opt->number_of_kernels; ++k) {
      vectorIterMult<<<grid, block>>>(d_vector, opt->number_of_threads,
                                      opt->inner_iterations);
    }
  }
#ifdef TIME_DETAILED
  time_elapsed[TOTAL_LAUNCH_COST] = getCpuSeconds() - time_start;
#endif
  ACC(DeviceSynchronize)();
#ifdef TIME_DETAILED
  time_elapsed[EXEC_TIME] = getCpuSeconds() - time_start;
#endif
  return 0;
}

static ACC(Graph_t) g_main_graph;
static ACC(GraphNode_t) * g_nodes;
static ACC(GraphExec_t) g_exec_work_graph;
static ACC(Stream_t) g_stream_for_cuda_graph;

ACC(Error_t) device_graph_setup(const struct options* opt, DataType** d_vector)
{
#ifdef TIME_DETAILED
  double time_start = getCpuSeconds();
#endif
  ACC(Error_t) device_error;
  device_error = ACC(GraphCreate)(&g_main_graph, 0);
  if (ACC(Success) != device_error) {
    printCudaError(device_error);
    return device_error;
  }

  dim3 block(TPB);
  dim3 grid((opt->number_of_threads + TPB - 1) / TPB);

  void* ka_kernel[] = {(void*) d_vector, (void*) &opt->number_of_threads,
                       (void*) &opt->inner_iterations};
  ACC(KernelNodeParams) np_kernel = {0};
  np_kernel.func = (void*) vectorIterMult;
  np_kernel.gridDim = grid;
  np_kernel.blockDim = block;
  np_kernel.kernelParams = ka_kernel;

  ACC(GraphNode_t)* last_node = NULL;
  unsigned int num_dependencies = 0;
  g_nodes = (ACC(GraphNode_t)*) malloc(opt->number_of_kernels *
                                       sizeof(ACC(GraphNode_t)));
  for (unsigned int i = 0; i < opt->number_of_kernels; ++i) {
    device_error = ACC(GraphAddKernelNode)(&g_nodes[i], g_main_graph, last_node,
                                           num_dependencies, &np_kernel);

    if (ACC(Success) != device_error) {
      printCudaError(device_error);
      return device_error;
    }
    last_node = &g_nodes[i];
    num_dependencies = 1;
  }

  device_error =
      ACC(GraphInstantiateWithFlags)(&g_exec_work_graph, g_main_graph, 0);
  if (ACC(Success) != device_error) {
    printCudaError(device_error);
    return device_error;
  }

  device_error = ACC(StreamCreateWithFlags)(&g_stream_for_cuda_graph,
                                            ACC(StreamNonBlocking));
  if (ACC(Success) != device_error) {
    printCudaError(device_error);
    return device_error;
  }
  device_error = ACC(GraphUpload)(g_exec_work_graph, g_stream_for_cuda_graph);
  if (ACC(Success) != device_error) {
    printCudaError(device_error);
    return device_error;
  }
#ifdef TIME_DETAILED
  time_elapsed[GRAPH_CREATION] = getCpuSeconds() - time_start;
#endif
  return ACC(Success);
}

ACC(Error_t) device_graph_run(const struct options* opt)
{
#ifdef TIME_DETAILED
  double time_start;
  time_start = getCpuSeconds();
#endif
  for (unsigned int i = 0; i < opt->outer_iterations; ++i) {
    ACC(GraphLaunch)(g_exec_work_graph, g_stream_for_cuda_graph);
  }
#ifdef TIME_DETAILED
  time_elapsed[TOTAL_LAUNCH_COST] = getCpuSeconds() - time_start;
#endif
  ACC(StreamSynchronize)(g_stream_for_cuda_graph);
#ifdef TIME_DETAILED
  time_elapsed[EXEC_TIME] = getCpuSeconds() - time_start;
#endif
#ifdef MEM_CHECK
#if defined(__HIP)
  system("rocm-smi --showmeminfo vram");
#else
  system("nvidia-smi --query-gpu=memory.used --format=csv --id=0");
#endif
#endif
  return ACC(Success);
}

void device_graph_teardown(void)
{
  ACC(StreamDestroy)(g_stream_for_cuda_graph);
  ACC(GraphExecDestroy)(g_exec_work_graph);
  ACC(GraphDestroy)(g_main_graph);
  free(g_nodes);
}

int device_run(const struct options* opt)
{
  ACC(Error_t) device_error;
  double time_start[2] = {0, 0};
  reset_times();
  time_start[0] = getCpuSeconds();

  /* Generate host data. */
  DataType* h_vector;
  h_vector = host_setup(opt->number_of_threads, opt->seed);
  if (NULL == h_vector) {
    return -1;
  }

  DataType* d_vector;
  if (opt->run_cpu) {
    cpu_kernel_run(opt, h_vector);
  } else {
    /* Setup device resources. */
    d_vector = device_setup(h_vector, opt->number_of_threads);
    if (NULL == d_vector) {
      device_teardown();
      host_teardown();
      return -1;
    }

    time_start[1] = getCpuSeconds();
    if (opt->run_graph) {
      device_error = device_graph_setup(opt, &d_vector);
      if (ACC(Success) == device_error) {
        device_graph_run(opt);
      }
    } else {
      device_kernel_run(opt, d_vector);
    }
    time_elapsed[CUDA_DIFF_TIME] = getCpuSeconds() - time_start[1];

    device_error = ACC(Memcpy)(h_vector, d_vector,
                               sizeof(DataType) * opt->number_of_threads,
                               ACC(MemcpyDeviceToHost));
    if (device_error != ACC(Success)) {
      printCudaError(device_error);
    }

    /* teardown device resources. */
    device_teardown();
    if (opt->run_graph) {
      device_graph_teardown();
    }
  }

  DataType result = euclicianNormVector(h_vector, opt->number_of_threads);

  /* teardown host resources. */
  host_teardown();

  time_elapsed[TOTAL_TIME] = getCpuSeconds() - time_start[0];

  print_times(opt, time_elapsed, TOTAL_NR_TIMES, result);
  return 0;
}
