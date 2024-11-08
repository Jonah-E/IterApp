#!/usr/bin/env bash

make -B time_detailed

./tests/run_increase_nodes "_detailed"

./tests/run_increase_iterations "_detailed"

make -B iterapp

./tests/run_increase_nodes "_standard"

./tests/run_increase_iterations "_standard"
