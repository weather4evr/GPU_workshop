#include "pch.h"

__global__ void mmul( float *A, float *B, float *C, int m, int p, int q)
{
   //Calculate the row and column values based on the block Id, block dimensions and the thread Id.
   int row = blockIdx.y * blockDim.y + threadIdx.y;
   int col = blockIdx.x * blockDim.x + threadIdx.x;
 
   //Multiply Matrices A and B, store results in Matrix C
   float sum = 0.0;
   for(int i = 0; i < p; i++)
   {
      sum += A[row*p+i] * B[i*q+col];
   }
   C[row*q+col] = sum;
}



__host__ void gpuMult(float *h_A, float *h_B, float *gpu_C, const int m, const int p, const int q)
{
  //declare variables to be used by GPU (device) for matrix multiplication
  float *d_A, *d_B, *d_C;

  //Allocate device memory
  cudaMalloc(&d_A, m*p*sizeof(float));
  cudaMalloc(&d_B, p*q*sizeof(float));
  cudaMalloc(&d_C, m*q*sizeof(float));
  cudaCheckErrors("cudaMalloc failure");

  // Copy host matrices A and B to the device using cudaMemcpy
  cudaMemcpy(d_A, h_A, m*p*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, p*q*sizeof(float), cudaMemcpyHostToDevice);
  cudaCheckErrors("cudaMemcpy H2D failture");
  
  // Set block dimensions here
  // Remember: the maximum number of total threads is 1024.
  unsigned int block_size = BLOCK_SIZE; // from pch.h is 32
  dim3 block(block_size, block_size);
  //calculate grid dimensions here
  unsigned int grid_rows = (m + block_size -1)/ block_size; 
  unsigned int grid_cols = (q + block_size -1)/ block_size; 
  dim3 grid(grid_cols, grid_rows);
 
  printf("Kernel launch dimensions: \n");
  printf("\tGrid size  : {%d, %d, %d} blocks.\n",grid.x, grid.y, grid.z);
  printf("\tBlock size : {%d, %d, %d} threads.\n",block.x, block.y, block.z);

  //Launch matrix multiplication kernel (the global function)
  mmul<<<grid,block>>>(d_A,d_B,d_C,m,p,q);

  // block CPU until GPU returns data using cudaDeviceSynchronize 
  cudaDeviceSynchronize();

  // Transfer results from device to host 
  cudaMemcpy(gpu_C, d_C, m*q*sizeof(float), cudaMemcpyDeviceToHost);

  cudaCheckErrors("Kernel execution failure or cudaMemcpy H2D failure");

  // Cleanup - free memory on GPU using cudaFree
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);



  cudaCheckErrors("cudaFree failure");
}
