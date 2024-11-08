#include <stdbool.h>
#include <stdio.h>

#include "device.h"
#include "options.h"

int main(int argc, char* argv[])
{
  struct options opts;
  int return_status;

  return_status = parse_arguments(&opts, argc, argv);
  if (0 != return_status) {
    printf("Error parsing arguments.\n");
    return -1;
  }
  if (opts.print_options)
    print_options(&opts);

  return_status = device_run(&opts);

  return 0;
}
