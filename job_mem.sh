#!/usr/bin/env bash

echo "Running memory measurments"
make -B mem_check

./tests/run_mem

echo "Done!"
