ifdef USE_HIP
NVCC = hipcc
NVCCFLAGS += --offload-arch=gfx90a
FLAGS += -D__HIP
else
CUDAPATH?=/usr/local/cuda
NVCC = nvcc
NVCCFLAGS += -arch=native -I$(CUDAPATH)/include -L$(CUDAPATH)/lib
endif

SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = .

C_FILES = iterapp.c \
	host.c \
	options.c \
	utils.c

CU_FILES = device.cu

OBJ_FILES = $(C_FILES:.c=_c.o) $(CU_FILES:.cu=_cu.o)
OBJ_PATHS = $(addprefix $(OBJ_DIR)/, $(OBJ_FILES))

CC = gcc

GIT_COMMIT := $(shell git rev-parse HEAD | cut -c 1-8)

FLAGS += -I./inc
CCFLAGS +=  -DBUILD_VERSION="\"$(GIT_COMMIT)\""

ifneq (, $(shell which bear))
	BEAR := bear --append --
else
	BEAR :=
endif

$(shell mkdir -p $(OBJ_DIR) $(BIN_DIR))

all:
	$(BEAR) make iterapp

.PHONY: clean iterapp time_detailed mem_check help

help:
	@echo "To compile for HIP, run `make USE_HIP=1`"

time_detailed: NVCCFLAGS+=-DTIME_DETAILED=1
time_detailed: iterapp

mem_check: NVCCFLAGS+=-DMEM_CHECK=1
mem_check: iterapp

iterapp: $(OBJ_PATHS)
	echo $(OBJ_PATHS)
	$(NVCC) $(NVCCFLAGS) -o $@ $^

$(OBJ_DIR)/%_c.o: $(SRC_DIR)/%.c
	$(CC) $(CCFLAGS) $(FLAGS) -c $< -o $@

$(OBJ_DIR)/%_cu.o: $(SRC_DIR)/%.cu FORCE
	$(NVCC) $(NVCCFLAGS) $(FLAGS) -c $< -o $@

FORCE:

clean:
	rm iterapp **/*.o


