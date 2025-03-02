---
layout: post
comments: true
title:  "Matrix multiplication in TensorFlow.js WebGPU backend"
date:   2025-03-02 10:00:00 +0100
tags: featured
---

This post is a follow-up of [Tensorflow.js Tensors introduction](/2024/11/24/inside-tfjs-prediction-journeys-of-tensors.html).

Under the hood, a layer execution is a multiplication of an input Tensor
by a matrix of training weights.

Such operation is implemented using the low-level functions of the backend API.
The library specifies such functions signatures using Javascript standard types
and leaves it up to the programmer to implement them efficiently.

Tfjs defines a couple of backends, a CPU backend for example, which runs on a Javascript virtual machine,
and a GPU backend, which builds [WGSL](https://www.w3.org/TR/WGSL/)
programs then runs them with [WebGPU Api](https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API).

## Matrix multiplication on the GPU

`K.dot()` is the entry function for matrix multiplication.
It's high-level. It's not implemented directly by a backend.
It merely validates the input, reshapes and normalizes the matrix,
and calls helper functions.

Its documentation says:

```typescript
/**
 * For 2D tensors, this is equivalent to matrix multiplication.
 * [...]
 * From the Theano documentation:
 * For N dimensions it is a sum product over the last axis of x and the
 * second-to-last of y
```

`k.dot` reshapes the multiplication components into 2-dimensional matrixes.

If they're already 2-dimensional, it proceeds to call the low-level backend functions.

If not, it reshapes them, invokes the low-level multiplication
logic then reshapes the result back to the expected output shape.

If the multiplicant matrix dimensions are `[3, 2, 5]`, it's transformed into
a two-dimensions matrix `[6, 5]`.
And if the multiplicator shape is `[4, 2, 5, 3]`, it's first transposed into
a matrix of shape `[5, 4, 2 ,3]`, then flattened into a two-dimensions matrix `[5, 24]`.

Reshaping and transposition are part of the backend API as well.

It's not clear to me yet why this transformation happens.
As we'll see below, the multiplication in the WebGPU backend works seamlessly with higher dimensions matrixes.

It seems like it's a port from Theano implementation.
Let me know if I'm missing something.

The low-level behaviour of a WebGPU backend reshapes any given Tensors into 3-dimensions ones,
picks a matrix multiplication algorithm, executes it, and reshapes the 3-dimensions
product back into the expected output shape.

This is meant to maximize the utilization of the GPU.

The three dimensions describe the output dimension, the input dimension,
and the "non-transitive" dimension.

An input shape is a common dimension, that is a dimension that will disappear after
the multiplication.
An output shape is a dimension that stays at the boundaries.

If we multiply `[4, 5]` by `[5, 9]`. `5` is the input shape.
`4` and `9` are the output shapes of `A` and `B`.
The product shape will be `[4, 9]`.

If a matrix is of a higher dimension, the others, "non-transitive" dimensions,
are flattened into one dimension.

The shape of `A` will be:

```md
[
  Number of elements in non-transitive dimensions,
  Size of pre-last A dimension,
  Size of last A dimension
]
```

For `B`, it'll be:

```md
[
  Number of elements in non-transitive dimensions,
  Size of pre-last B dimension,
  Size of last B dimension
]
```

And, the shape of the product will be:

```md
[
  Maximum between the number of elements in non-transitive dimensions between A and B,
  Size of pre-last A dimension,
  Size of last B dimension
]
```

The GPU program created by Tfjs decomposes the result matrix into 2-dimensions slices, named "tiles".

These can be computed in parallel.
Each thread computes one.

Finally, they're combined back into a 3-dimensions matrix.

The dimensions of the tiles are subjective.
The library hard-codes optimal numbers that perform well in most cases.

Threads in GPU programs are combined into workgroups.
A workgroup, also called a "thread group", is a collection of threads that work together on a portion of the problem.

Each workgroup works on a part of the result matrix.
Each multiplies a part of A with a part of B.
And each thread within the group multiplies a sub-part of A with a sub-part of B.

A WebGPU program defines how many threads will be part of a workgroup
in a 3-elements array. Each element describes the number of threads for an axis.

One will tell how many threads will work on the "x" axis.
This is the axis that describes the last dimension of B.
Each of these threads will take a sub-part, or a "slice", of B.

Another will tell how many threads will be on the "y" axis.
This is the pre-last dimension of A.
Each of these threads will take a slice of A.

And the same for the "z" axis.

A program defines an array named `elementsPerThread`, also typed as `[number, number, number]`,
which tells how many elements (how big is the sub-part, how many rows and columns) each thread takes.

Tfjs chooses a multiplication algorithm, or "strategy", according to the shape and the optimal number of threads.

The used value inside `MatMulPackedProgram`, the default multiplication algorithm, are hard-coded experimental values:

```typescript
// These are experimental values. Usually, we need to adjust the work group
// size based on the input shapes to improve the EU occupancy.
// TODO: WebGPU limits the maximum allowed shared memory size as 16K. To make
// sure it doesn't exceed this limitations. Temporarily reduce the work group
// size to [8, 8, 1] and the work per thread size is [4, 4, 1]. But we should
// revisit it and find the balance between work group size and work per thread
// size.
const workgroupSize: [number, number, number] = [8, 8, 1];
const elementsPerThread: [number, number, number] = [4, 4, 1];
```

To figure out how many elements each workgroup will handle, we can multiply the elements
of the same index between the two arrays.

If we multiply all elements, we'll end up with a "tile", here:

```typescript
[32, 32, 1]
```

Or, shortly, "32x32".

## Building a shader

A WebGPU program is called a "shader".

> WebGPU Shading Language (WGSL) is the shader language for WebGPU.
> That is, an application using the WebGPU API uses WGSL to express
> the programs, known as shaders, that run on the GPU.
>
> -- [WebGPU Shading Language](https://en.wikipedia.org/wiki/Shading_language#WebGPU_Shading_Language)

Tfjs defines a set of matrix multiplication algorithms:

```typescript
export enum MatMulProgramType {
  MatMulReduceProgram,
  MatMulSplitKProgram,
  MatMulSmallOutputSizeProgram,
  MatMulPackedProgram,
  MatMulMax
}
```

Each algorithm implements an interface describing a WebGPU program,
[`WebGPUProgram`](https://github.com/tensorflow/tfjs/blob/master/tfjs-backend-webgpu/src/webgpu_program.ts).

The library, for example, chooses the program named `MatMulReduceProgram` when
both the number of elements in the matrixes multiplication is equals-or-less than 128,
and when the number of workgroups needed for handling 32*32 tiles is very small.

Each program defines a method `getUserCode`,
which creates the WGSL program by concatenating strings
and returns GPU-executable code, that is a shader, that loads the input,
executes the multiplication, and writes the result.

The mapping of inputs and outputs is guaranteed by a binding step.

Binding means describing the variables the shader will access.
Tfjs specifies bindings for the output Tensor, the input Tensors, and other
global variables the program will need.

The global variables are called ["uniforms"](https://webgpufundamentals.org/webgpu/lessons/webgpu-uniforms.html).
They include for example the shapes of the Tensors and constants such as `NAN` and `INFINITY` that bound
the computation.

Bindings are combined into binding groups and organized into a binding layout.

For example, the definition of the input and output matrixes in the program build for
the multiplication is:

```rust
@group(0) @binding(0) var<storage, read_write> result:
    array<${dataTypeToGPUType(outputData.dtype, program.outputComponent)}>;

@group(0) @binding(1) var<storage, read> A:
    array<${dataTypeToGPUType(inputInfo[0].dtype, program.outputComponent)}>;

@group(0) @binding(2) var<storage, read> B:
    array<${dataTypeToGPUType(inputInfo[1].dtype, program.outputComponent)}>;
```

`0` is the binding group index. `0`, `1`, and `2`, passed here to `@binding()`, are the indexes
of the matrixes inside the binding layout.

Tensors themselves are stored inside a [`WeakMap`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap).

Its keys are Tensors identifiers and its values are `TensorData` instances:

```typescript
export type BackendValues = Float32Array|Int32Array|Uint8Array|Uint8Array[];

type TensorData = {
  values: BackendValues,
  dtype: DataType,
  shape: number[],
  refCount: number,
  resource?: GPUBuffer|GPUTexture|GPUExternalTexture,
  // ...
}
```

We said in the previous post that Tensors have unique identifiers.

Each time a Tensor is created, the library adds it to this map.
You can read in-depth how to call a Tensor factory in the
[function documentation](https://github.com/tensorflow/tfjs/blob/master/tfjs-core/src/ops/tensor.ts)
itself.

Under the hood, the WebGPU backend validates the type,
the permission to read and use the buffer flags inside a shader,
and the ability of the buffer to handle the expected Tensor size,
that is, it makes sure that:

```typescript
bufferSize < (tensorElementSize * elementsCountAccordingToShape)
```

Tfjs uploads the data to the GPU if not been uploaded already.

It sets `values` to `null` and `resource` to a buffer instance when the data is on the GPU.
Buffers are created with [GPUDevice.createBuffer()](https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBuffer).

The [resource](https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API#representing_pipeline_resources) property is used to create bindings.

Matrixes are stored as linear sequences in memory.

```typescript
// Experiments show that sequential access is more friendly for Intel GPUs.
```

There's a mapping of each matrix position to an element in the flat array.

If the arrays are 3-dimensional,
the function that calculates the index of a multiplication output element is:

```rust
fn getOutputIndexFromCoords(coords : vec3<i32>) -> i32 {
  return dot(coords, vec3<i32>(uniforms.outShapeStrides.x, uniforms.outShapeStrides.y, 1));
}
```

`coords` is a vector specifying a 3-dimensional position.

[`dot()`](https://www.w3.org/TR/WGSL/#dot-builtin) is a built-in function that returns the product of two vectors.

A "stride" means a step in memory between two successive elements in the axis.
It's computed before shader execution for the other axis.

It's implicitly `1` for the last axis as the elements are stored sequentially in memory.

To move from an element in the x-axis to the next for example,
we need to jump:

```typescript
Y-axis-elements-count * Z-axis-elements-count
```

elements in the flattened array.

The mapping function between a position in an input Tensor
and an element in the linear representation inside the shader WGSL code is:

```rust
fn getIndexFromCoords3D(coords : vec3<i32>, shape : vec3<i32>) -> i32 {
  return dot(coords, vec3<i32>(shape.y * shape.z, shape.z, 1));
}
```

`shape` is the shape of the target Tensor.

Putting local optimizations by different algorithms apart,
the program handles the input tile by tile.

Its logic iterates over the tiles and reads the associated tile from each of A and B into a temporal
matrix variable.
Then, it calculates the product using [`fma`](https://www.w3.org/TR/WGSL/#fma-builtin), a primitive function.
