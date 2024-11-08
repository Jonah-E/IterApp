#include "options.h"
#include <argp.h>
#include <stdlib.h>

const char* argp_program_version = BUILD_VERSION;
// const char *argp_program_bug_address = "<your@email.address>";
static char doc[] = "";
static char args_doc[] = "";
static struct argp_option arguments[] = {
    {"", 'p', 0, 0, "Print options."},
    {"graph", 'g', 0, 0, "Execute graph version."},
    {"cpu", 'c', 0, 0, "Execute cpu version."},
    {"threads", 't', "threads", 0, "Number of threads to run."},
    {"inner", 'i', "inner", 0,
     "Nummer of iterations in of the multiplication to run in the kernel."},
    {"outer", 'o', "outer", 0, "Number of times to rerun the workflow."},
    {"kernels", 'k', "kernels", 0,
     "Number of kernels to launch per iterations."},
    {0}};

static void reset_options(struct options* opt)
{
  opt->number_of_threads = 1;
  opt->inner_iterations = 50000;
  opt->outer_iterations = 1;
  opt->number_of_kernels = 1;
  opt->run_graph = false;
  opt->run_cpu = false;
  opt->print_options = false;
  opt->seed = 1;
}

static error_t parse_opt(int key, char* arg, struct argp_state* state)
{
  struct options* opt = state->input;

  switch (key) {
  case 'p':
    opt->print_options = true;
    break;
  case 'g':
    opt->run_graph = true;
    break;
  case 'c':
    opt->run_cpu = true;
    break;
  case 't':
    opt->number_of_threads = atoi(arg);
    break;
  case 'i':
    opt->inner_iterations = atoi(arg);
    break;
  case 'o':
    opt->outer_iterations = atoi(arg);
    break;
  case 'k':
    opt->number_of_kernels = atoi(arg);
    break;
  case ARGP_KEY_ARG:
    return 0;
  default:
    return ARGP_ERR_UNKNOWN;
  }
  return 0;
}

static struct argp argp = {arguments, parse_opt, args_doc, doc, 0, 0, 0};

void print_options(const struct options* opt)
{
  printf("Options: \n"
         "\trun_graph = %s\n"
         "\trun_cpu = %s\n"
         "\tnumber_of_threads = %d\n"
         "\tinner_iterations = %d\n"
         "\touter_iterations = %d\n"
         "\tnumber_of_kernels = %d\n",
         opt->run_graph ? "True" : "False", opt->run_cpu ? "True" : "False",
         opt->number_of_threads, opt->inner_iterations, opt->outer_iterations,
         opt->number_of_kernels);
}

int parse_arguments(struct options* opt, int argc, char* argv[])
{
  error_t pars_error;
  reset_options(opt);
  pars_error = argp_parse(&argp, argc, argv, 0, 0, opt);

  if (pars_error)
    return -1;

  return 0;
}
