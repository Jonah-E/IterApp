# Iterative Application Skeleton (IterApp)

This is a skeleton application showcasing how an application which iteratively launces
kernels to the GPU can be converted to using CUDA Graph. Additionally it serves the purpose
of comparing the executors of the two versions.

# Pre-requisites

The application requires the CUDA toolkit to be installed, [https://developer.nvidia.com/cuda-toolkit](https://developer.nvidia.com/cuda-toolkit).

For visualization of measurments there are a python script in the `scripts` folder. The required module for this is listed in the `reqirements.txt` file. It is recomended to use an virtual environment when installing the requirements. To create a virtual environment and install the requirements, use the following commands.

````
python3 -m venv venv
source venv/bin/activate
pip install -r scripts/reqirements.txt
````

## Alternative

The application can also compiled for AMD hardware utilizing the HIP API.

# Building and running tests.

To run the execution tests simply run the `job.sh` script:

````
./job.sh
````

this will create an `output` directroy containing all the execution measurments.

To create the visualization plots, you can run the command

````
python3 scripts/plots.py output/
````

**NOTE:** Don't forget to activate the virtual environment (if it is not already active) using the command `source venv/bin/active`

## Alternative

To build for HIP, add `USE_HIP=1` to all `make` commands.
