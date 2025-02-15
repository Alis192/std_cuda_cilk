#include <iostream>
#include <vector>
#include <cmath>
#include <cuda_runtime.h>

using namespace std;

__global__ void bucketMeanKernel(const double* data, double* bucketMeans, int bucketSize, int dataSize) {
    int bucketIndex = blockIdx.x;
    int startIdx = bucketIndex * bucketSize;
    int endIdx = min(startIdx + bucketSize, dataSize);

    double sum = 0.0;
    for (int i = startIdx; i < endIdx; ++i) {
        sum += data[i];
    }
    bucketMeans[bucketIndex] = sum / (endIdx - startIdx);
}

__global__ void bucketVarianceKernel(const double* data, const double* bucketMeans, double* bucketVariances, int bucketSize, int dataSize) {
    int bucketIndex = blockIdx.x;
    int startIdx = bucketIndex * bucketSize;
    int endIdx = min(startIdx + bucketSize, dataSize);

    double sum = 0.0;
    for (int i = startIdx; i < endIdx; ++i) {
        double diff = data[i] - bucketMeans[bucketIndex];
        sum += diff * diff;
    }
    bucketVariances[bucketIndex] = sum / (endIdx - startIdx);
}

// Prepare the dataset by randomly generating data points
double* prepare(int dataSize) {
    double* data = new double[dataSize];
    for (int i = 0; i < dataSize; ++i) {
        data[i] = static_cast<double>(rand()) / RAND_MAX * 100.0; // Random numbers between 0 and 100
    }
    double* d_data;
    cudaMalloc(&d_data, dataSize * sizeof(double));
    cudaMemcpy(d_data, data, dataSize * sizeof(double), cudaMemcpyHostToDevice);
    delete[] data; // Free the host memory
    return d_data;
}

// Compute the standard deviation
double compute(const double* data, int dataSize, int threadsPerBlock, float &elapsedTime, int &bucketSize, int &numberOfBuckets) {
    bucketSize = 16; // We adjust appropriate bucket size
    numberOfBuckets = (dataSize + bucketSize - 1) / bucketSize;
    
    double* d_bucketMeans, *d_bucketVariances;
    double* h_bucketMeans = new double[numberOfBuckets];
    double* h_bucketVariances = new double[numberOfBuckets];

    cudaMalloc(&d_bucketMeans, numberOfBuckets * sizeof(double));
    cudaMalloc(&d_bucketVariances, numberOfBuckets * sizeof(double));

    // Start timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Launch kernels
    bucketMeanKernel<<<numberOfBuckets, threadsPerBlock>>>(data, d_bucketMeans, bucketSize, dataSize);
    cudaDeviceSynchronize();

    bucketVarianceKernel<<<numberOfBuckets, threadsPerBlock>>>(data, d_bucketMeans, d_bucketVariances, bucketSize, dataSize);
    cudaDeviceSynchronize();

    // Stop timing
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTime, start, stop);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    // Copy results back to host
    cudaMemcpy(h_bucketMeans, d_bucketMeans, numberOfBuckets * sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_bucketVariances, d_bucketVariances, numberOfBuckets * sizeof(double), cudaMemcpyDeviceToHost);

    // Final calculation of variance on host
    double variance = 0.0;
    for (int i = 0; i < numberOfBuckets; ++i) {
        variance += h_bucketVariances[i];
    }
    variance /= numberOfBuckets;

    // Clean up
    cudaFree(d_bucketMeans);
    cudaFree(d_bucketVariances);
    delete[] h_bucketMeans;
    delete[] h_bucketVariances;

    // Return the standard deviation
    return sqrt(variance);
}

// Report the results including bucket size and number of buckets
void report(int threadsPerBlock, double stdDev, float elapsedTime, int bucketSize, int numberOfBuckets) {
    cout << "Calculating standard deviation with " << threadsPerBlock << " threads per block." << endl;
    cout << "Bucket Size: " << bucketSize << ", Number of Buckets: " << numberOfBuckets << endl;
    cout << "Standard Deviation (CUDA): " << stdDev << endl;
    cout << "Execution Time (Threads Per Block: " << threadsPerBlock << "): " << elapsedTime << " ms" << endl << endl;
}

int main(int argc, char *argv[]) {
    // Check if the dataSize argument is provided
    if (argc != 2) {
        cerr << "Usage: " << argv[0] << " <dataSize>" << endl;
        return 1; // Return an error code
    }

    // Convert the argument to an integer
    int dataSize = atoi(argv[1]);
    if (dataSize <= 0) {
        cerr << "Error: dataSize must be a positive integer." << endl;
        return 1; // Return an error code
    }

    double* data = prepare(dataSize);

    vector<int> threadsPerBlockConfigs = {32, 64, 96, 128};
    for (int threadsPerBlock : threadsPerBlockConfigs) {
        float elapsedTime;
        int bucketSize, numberOfBuckets;
        double stdDev = compute(data, dataSize, threadsPerBlock, elapsedTime, bucketSize, numberOfBuckets);
        report(threadsPerBlock, stdDev, elapsedTime, bucketSize, numberOfBuckets);
    }

    cudaFree(data); // Free the allocated memory
    return 0;
}