# Standard Deviation — CUDA & Cilk

Parallel Computation of Standard Deviation with CUDA and Cilk algorithm implementations.

```zsh
git clone https://github.com/eakriulin/std_cuda_cilk.git
cd std_cuda_cilk
```

## Authors

- [Alakbar Damirov](https://github.com/Alis192) — CUDA implementation
- [Eugene Kriulin](https://github.com/eakriulin) — Cilk implementation

## CUDA

To run the CUDA implementation of the standard deviation calculation, follow these steps.

### Prerequisites

- Ensure you have a CUDA-capable GPU installed on your server.
- Install the [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads). Ensure that the installed version is compatible with your GPU and the CUDA code.

### Compilation

1. Navigate to the directory containing the CUDA code:

    ```bash
    cd path/to/cuda_code_directory
    ```

2. Compile the CUDA program using the "nvcc" compiler. Replace "std_cuda.cu" with the actual name of the CUDA file:

    ```bash
    nvcc -o std_cuda std_cuda.cu
    ```

   This command will compile the CUDA code and generate an executable named "std_cuda".

### Running the Program

- Run the compiled CUDA program. You can specify the dataset size and number of threads per block as a command-line argument. For example, to generate a dataset of 5,000,000 values and calculating standard deviation using 64 threads per block:

    ```bash
    ./std_cuda 5000000 64
    ``````

- The program will generate a pseudo-random dataset of specified size, calculate its standard deviation, and output result along with execution time.

### Note

- The dataset is generated pseudo-randomly with fixed seed to ensure repeatability between runs, allowing for consistent performance measurements.
- You can modify dataset size by changing argument provided to executable.

## Cilk

To run the Cilk implementation of the standard deviation calculation, follow these steps.

### Prerequisites

- [Install OpenCilk](https://www.opencilk.org/doc/users-guide/install/).

### Running the Program

- Run the Cilk version with the [Cilkscale tool](https://www.opencilk.org/doc/users-guide/cilkscale/#how-to-run). You can change the size of the input by varying the value provided in `--args`. For example, the following command tells the program to generate the dataset of 5.000.000 pseudo random values and run the standard deviation algorithm on it:

    ```zsh
    python3 /opt/opencilk/share/Cilkscale_vis/cilkscale.py -c ./stdcilk_cs -b ./stdcilk_cs_benchmark -ocsv ./cstable_std.csv -oplot ./csplot_std.pdf --args 5000000
    ```

### Note

- At each run, the dataset is being generated pseudo randomly. To ensure repeatability, the random seed does not get changed between the runs, which allows to produce the same pseudo random values.
- It is possible to vary the input size to test the performance.
