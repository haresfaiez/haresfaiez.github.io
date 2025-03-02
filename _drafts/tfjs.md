# Backends

** Move the rest to _dartfts..?
```typescript
const rowPerThreadA = tileAHight / workgroupSize[1]; // === workPerThread[1]
const colPerThreadA = tileAWidth / workgroupSize[0]; // === workPerThread[0]
// --> rows of B will be multiplied with columns of A (rowsCount(B) === columnsCount(A))
const rowPerThreadB = tileInner / workgroupSize[1]; // === output-tile--X-Axis--colums-(num-per-tile*num-threads) / output-tile--Y-axis--tile-Y-size

const rowPerThread = workPerThread[1]; // Y-axis, rows
const colPerThread = workPerThread[0]; // X-asix, columns
```
** explain this..?
** A tile is ..?
To find out how big is the tile a thread can handle we check
the number of rows with `workPerThread[0] * workgroupSize[0]`,
and the number of columns with `workPerThread[1] * workgroupSize[1]`.
```typescript
// prog
const tileAOuter = workPerThread[1] * workgroupSize[1]; // num-of-elements in a tile built with one-dimension (A outer axis == Y-axis, number of rows, of the output)
const tileBOuter = workPerThread[0] * workgroupSize[0]; // num-of-elements in a tile built with one-dimension (B outer axis == X-axis, number of columns, of the output)

const tileInner = this.workgroupSize[0] * this.elementsPerThread[0]; // num-of-rows (X-axis elements) handled by workgroup in a tile
const tileAWidth = tileInner; // X-axis, columns
const tileAHight = tileAOuter; // Y-axis, rows
```
** explain this ..?
For each axis, the dispatch is calculated as:
```typescript
Math.ceil(
        arrayProduct(dispatchLayoux[currentAxis].map(d => outputShape[d])) /
        (workgroupSize[currentAxisIndex] * elementsPerThread[currentAxisIndex]))
```

## WGSL

** Explain the mapping between workgroups/dispatch values and the tiles here ..? (check _drafts/tfjs.md)
** Main function:
```rust
      @compute
      @workgroup_size(${program.workgroupSize[0]}, ${program.workgroupSize[1]}, ${program.workgroupSize[2]})
      fn _start(@builtin(local_invocation_id) LocalId : vec3<u32>,
                @builtin(global_invocation_id) GlobalId : vec3<u32>,
                @builtin(local_invocation_index) LocalIndex: u32,
                @builtin(workgroup_id) WorkgroupId : vec3<u32>,
                @builtin(num_workgroups) NumWorkgroups : vec3<u32>) {
```
it defines the entrypoint of the shader/program.
that takes a set of built-in varibales that describe the execution context  (think thread id, workgrounp id, ...)
(those defined at the beginning)
and stores them (why..?), then calls `main()` (defined in the userCode?).
** `@workgroup_size` is `this.computePassEncoder.dispatchWorkgroups(program.dispatch[0], program.dispatch[1], program.dispatch[2]);` ..?


A and B matrixes are defined by:
```rust
      @group(0) @binding(0) var<storage, read_write> result:
          array<${dataTypeToGPUType(outputData.dtype, program.outputComponent)}>;

      @group(0) @binding(1) var<storage, read> A:
          array<${dataTypeToGPUType(inputInfo[0].dtype, program.outputComponent)}>;

      @group(0) @binding(2) var<storage, read> B:
          array<${dataTypeToGPUType(inputInfo[1].dtype, program.outputComponent)}>;
```

```rust
var<workgroup> mm_Asub : array<array<f32, ${tileAWidth}>, ${tileAHight}>;
var<workgroup> mm_Bsub : array<array<f32, ${tileBOuter}>, ${tileInner}>;

fn main() {
  let batch = i32(globalId.z);
  let batchA = batch % uniforms.aShape[0];
  let batchB = batch % uniforms.bShape[0];
  let numTiles = (uniforms.dimInner - 1) / ${tileInner} + 1;
  var kStart = 0;

  // define result (f(tile) === f(thread))
  var acc : array<array<f32, ${colPerThread}>, ${rowPerThread}>;

  // init result
  // Without this initialization strange values show up in acc.
  for (var innerRow = 0; innerRow < ${rowPerThread}; innerRow++) {
    for (var innerCol = 0; innerCol < ${colPerThread}; innerCol++) {
      acc[innerRow][innerCol] = 0.0;
    }
  }

  let tileRow = i32(localId.y) * ${rowPerThread};
  let tileCol = i32(localId.x) * ${colPerThread};

  let globalRow = i32(globalId.y) * ${rowPerThread};
  let globalCol = i32(globalId.x) * ${colPerThread};
  let globalRowStart = i32(workgroupId.y) * ${tileAOuter};

  let tileRowA = i32(localId.y) * ${rowPerThreadA};
  let tileColA = i32(localId.x) * ${colPerThreadA};
  let tileRowB = i32(localId.y) * ${rowPerThreadB};

  // Loop over shared dimension.
  for (var t = 0; t < numTiles; t++) {
    kStart = kStart + ${tileInner};
    workgroupBarrier();

    // Compute acc values for a single thread.
    var BCached : array<f32, ${colPerThread}>;
    for (var k = 0; k < ${tileInner}; k++) {
      for (var inner = 0; inner < ${colPerThread}; inner++) {
        BCached[inner] = mm_Bsub[k][tileCol + inner];
      }

      for (var innerRow = 0; innerRow < ${rowPerThread}; innerRow++) {
        let ACached = mm_Asub[tileRow + innerRow][k];
        for (var innerCol = 0; innerCol < ${colPerThread}; innerCol++) {
          acc[innerRow][innerCol] = fma(ACached, BCached[innerCol], acc[innerRow][innerCol]);
        }
      }
    }

    workgroupBarrier();
  }

  for (var innerRow = 0; innerRow < ${rowPerThread}; innerRow++) {
    for (var innerCol = 0; innerCol < ${colPerThread}; innerCol++) {
      mm_write(batch, globalRow + innerRow, globalCol + innerCol, acc[innerRow][innerCol]);
    }
  }
}
```

Tfjs first checks the "fit" between the multiplication result dimensions and the tiles.
This means:
```rust
  getShapeFit(dimAOuter: number, dimBOuter: number, dimInner: number):
      boolean[] {
    const tileAOuter = this.workgroupSize[1] * this.elementsPerThread[1];
    const tileBOuter = this.workgroupSize[0] * this.elementsPerThread[0];

    if (!this.isVec4 && this.isVectorA) {
      // For makeVectorMatrixProductSource
      this.tileInner = this.workgroupSize[0] * 4;
    } else {
      this.tileInner = tileBOuter;
    }

    const fitAOuter = dimAOuter % tileAOuter === 0;
    const fitBOuter = dimBOuter % tileBOuter === 0;
    const fitInner = dimInner % this.tileInner === 0;
    return [fitAOuter, fitBOuter, fitInner];
  }
```
This takes the A and B outer dimensions and the shared dimension.
It returns a 3-elements boolean array that decribe whether the dimensions
of the output tensor can be "perfectly" split into tiles.

These values are used to build reading and writing functions.

Here we assume none fits.
** If one of the fit-array elements is true..? what changes..?

`mm_readA` and `mm_readB`, and `mm_write` are defined by:

```rust
fn mm_readA(batch: i32, row: i32, col: i32) -> f32 {
  var value = f32(0.0);
  if(row < uniforms.aShape[1] && col < uniforms.aShape[2]) { // Removed if fitOuter and fitInner are both true
    value = getA(batch, row, col);
  }
  return value;
}

fn mm_readB(batch: i32, row: i32, col: i32) -> f32 {
  var value = f32(0.0);
  value = getB(batch, row, col);
  return value;
}

fn mm_write(batch: i32, row: i32, col: i32, valueIn: f32) {
  if (row < uniforms.dimAOuter && col < uniforms.dimBOuter) { // Removed if fitOuter and fitInner are both true
    var value = valueIn;
    let coords = vec3<i32>(batch, row, col);
    // ${hasBias ? 'value = value + getBiasByOutputCoords(coords);' : ''}
    // ${activation ? 'value = activation(value, coords);' : ''}
    setOutputAtCoords(coords[0], coords[1], coords[2], value);
  }
}
```


```typescript
function makeShader(inputInfo: InputInfo[], outputData: {dtype: DataType, shape: number[]},program: WebGPUProgram): string {
    // getCoordsDataType -> i32/vec2,3..6

    // insertAlignment -> replaces:
    //        // insert alignment when current pattern is vec5 or vec6
    //             replace(/(\w+)\s*:\s*vec(5|6)/g, (match) => '@align(16) ' + match);
    //       // insert alignment when previous pattern is vec5 or vec6
    //             replace(/vec(5|6)\s*,\s*(\w+)/g, (_, p1, p2) => `vec${p1}, @align(16) ${p2}`);

    // dataTypeToGPUType -> float,int32 -> "vecN?<"? + "f/i32" + ?">"


  const prefixSnippets = `
      var<private> localId: vec3<u32>;
      var<private> localIndex: u32;
      var<private> globalId: vec3<u32>;
      var<private> numWorkgroups: vec3<u32>;
      var<private> workgroupId: vec3<u32>;

      struct Uniforms {
        NAN : f32,
        INFINITY : f32,

        aShape : vec3<i32>,
        aShapeStrides: vec2<i32>,

        bShape : vec2<i32>,
        bShapeStrides: i32,

        outShape : vec3<i32>,
        outShapeStrides: vec2<i32>,
      };

      @group(0) @binding(0) var<storage, read_write> result:
          array<${dataTypeToGPUType(outputData.dtype, program.outputComponent)}>;

      @group(0) @binding(1) var<storage, read> A:
          array<${dataTypeToGPUType(inputInfo[0].dtype, program.outputComponent)}>;

      @group(0) @binding(2) var<storage, read> B:
          array<${dataTypeToGPUType(inputInfo[1].dtype, program.outputComponent)}>;

      @group(0) @binding(3) var<uniform> uniforms: Uniforms;

      fn isinf(val: f32) -> bool { return abs(val) == uniforms.INFINITY; }
    `;

  const sources = [
    commonSnippet,
    prefixSnippets,

    // getCoordsFromIndexSnippet --> defines get[?V_name]CoordsFromIndex
    getCoordsFromIndexSnippet(outputData.shape),

    // getOutputCoordsSnippet --> defines getOutputCoords
    getOutputCoordsSnippet(outputData.shape, program.dispatchLayout),
    // getOutputIndexFromCoordsSnippet -> creates WGSL function (outRank)
    //     if outRank === 3: `fn getOutputIndexFromCoords(coords : vec3<i32>) -> i32 { return dot(coords, vec3<i32>(uniforms.outShapeStrides.x, uniforms.outShapeStrides.y, 1));
    getOutputIndexFromCoordsSnippet(outputData.shape.length),
    // setOutputSnippet --> defines setOutputAtCoords,Index,I32** (used inside write_A)
    setOutputSnippet(outputData.shape, outputData.dtype, program.outputComponent),

    // getCoordsFromIndexSnippet --> defines get[?V_name]CoordsFromIndex
    getCoordsFromIndexSnippet(inputInfo[0].shape, 'A'),
    getCoordsFromIndexSnippet(inputInfo[1].shape, 'B'),

    // getInputAtCoordsSnippet --> define getA/getB...
    getInputAtCoordsSnippet(inputInfo[0], program.outputComponent),// + getInputByOutputSnippet(inputInfo[0], outputData.shape, program.outputComponent, false),
    getInputAtCoordsSnippet(inputInfo[1], program.outputComponent),// + getInputByOutputSnippet(inputInfo[1], outputData.shape, program.outputComponent, false),
  ];

  sources.push(program.getUserCode());

  sources.push(
    `
      @compute
      @workgroup_size(${program.workgroupSize[0]}, ${program.workgroupSize[1]}, ${program.workgroupSize[2]})
      fn _start(@builtin(local_invocation_id) LocalId : vec3<u32>,
                @builtin(global_invocation_id) GlobalId : vec3<u32>,
                @builtin(local_invocation_index) LocalIndex: u32,
                @builtin(workgroup_id) WorkgroupId : vec3<u32>,
                @builtin(num_workgroups) NumWorkgroups : vec3<u32>) {
        localId = LocalId;
        localIndex = LocalIndex;
        globalId = GlobalId;
        numWorkgroups = NumWorkgroups;
        workgroupId = WorkgroupId;

        main();
      }
    `
  );

  const source = sources.join('\n');
  return source;
}
```

Tfjs executes the shader with
`recordAndSubmit` mainly sends the program/shader to the gpu for execution:
```typescript
this.commandEncoder = this.device.createCommandEncoder();
this.computePassEncoder = this.commandEncoder.beginComputePass({});
this.computePassEncoder.setPipeline(program.pipeline);
this.computePassEncoder.setBindGroup(0, bindGroup);
this.computePassEncoder.dispatchWorkgroups(program.dispatch[0], program.dispatch[1], program.dispatch[2]);
this.queue.submit([this.commandEncoder.finish()]);
```
** These methods are defined by the browser API ..?

** `getA(batch, row, col)` is ..?
** `getB(batch, row, col)` is ..?
```typescript
function getInputAtCoordsSnippet(inputInfo: InputInfo, component: number): string {
  const texName = inputInfo.name;
  const rank = inputInfo.shape.length;
  const type = getCoordsDataType(rank);
  const funcName = 'get' + texName.charAt(0).toUpperCase() + texName.slice(1);
  const dims = ['d0', 'd1', 'd2', 'd3', 'd4', 'd5'].slice(0, rank);
  const inputs = dims.map(d => `${d} : i32`).join(', ');

  const shapeStr =
      `uniforms.${texName.charAt(0).toLowerCase() + texName.slice(1)}Shape`;
  let rankStr = `${rank}D`;
  return `
    fn ${funcName}(${inputs}) -> ${typeSnippet(component)} {
      return ${typeSnippet(component)}(${texName}[getIndexFromCoords${rankStr}(${type}(${dims.join(',')}), ${shapeStr})${component === 1 ? '' : ` / ${component}`}]);
    }
   `;
}
```

writing tensor/matrix, that is  `setOutputAtCoords` is:
** `setOutputAtCoords(coords[0], coords[1], coords[2], value)` is ..?
```typescript
    // getOutputIndexFromCoordsSnippet -> creates WGSL function (outRank)
    //     if outRank === 3: `fn getOutputIndexFromCoords(coords : vec3<i32>) -> i32 { return dot(coords, vec3<i32>(uniforms.outShapeStrides.x, uniforms.outShapeStrides.y, 1));

function setOutputSnippet( outShape: number[], outBufferType: DataType, component: number): string {
  const outRank = outShape.length;
  const gpuType = dataTypeToGPUType(outBufferType, component);// dataTypeToGPUType -> float,int32 -> "vecN?<"? + "f/i32" + ?">"
    const dims = ['d0', 'd1', 'd2', 'd3', 'd4', 'd5'].slice(0, outRank);
    const type = getCoordsDataType(outRank);
  let snippet =
    `fn setOutputAtIndex(flatIndex : i32, value : ${typeSnippet(component)}) {
        result[flatIndex] = ${gpuType}(value);
      }

      fn setOutputAtCoords(${dims.map(d => `${d} : i32`).join(', ')}, value : ${typeSnippet(component)}) {
        let flatIndex = getOutputIndexFromCoords(${type}(${dims.join(', ')}));
        setOutputAtIndex(flatIndex${component === 1 ? '' : ` / ${component}`}, value);
      }
    `;
}
```


Tfjs compiles the shader and sends it to the GPU using the native browser API.

`createShaderModule()` and `createComputePipeline()` compile the WGSL program.

> The `createShaderModule()` method of the `GPUDevice` interface creates
> a `GPUShaderModule` from a string of WGSL source code.
>
> -- [createShaderModule](https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createShaderModule)

And,

> The `createComputePipeline()` method of the `GPUDevice` interface creates
> a `GPUComputePipeline` that can control the compute shader stage and be used in a `GPUComputePassEncoder`.
>
> -- [createComputePipeline](https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createComputePipeline)

To execute the shader, Tfjs creates a [`GPUCommandEncoder`](https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder)
instance with the compiled pipeline instance and puts it in the GPU queue.


## Mapping between Tensor and TensorInfo

** How the input tensors are copied?? to the GPU..? how the result is copied?? back..?
** Binding is ..? it's needed to ..? `this.computePassEncoder.setBindGroup(0, bindGroup);` ..?
> The GPUBindGroup interface of the WebGPU API is based on a GPUBindGroupLayout and defines
> a set of resources to be bound together in a group and how those resources are used in shader stages.
>
> -- https://developer.mozilla.org/en-US/docs/Web/API/GPUBindGroup
Here, the code calls:
> The setBindGroup() method of the GPUComputePassEncoder interface sets the GPUBindGroup
> to use for subsequent compute commands, for a given index.
>
> https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/setBindGroup
** Why binding is needed..? why binding is not homogonous ..?
** How / Why it's used ..?
`recordAndSubmit` prepares the binding group before executing the pipline (or is it a program ..? why..?):
```typescript
// There are six kinds of uniforms: NAN, INFINITY, shapes, shape strides, program size, program defined uniforms.
let programUniform: ProgramUniform = [];
let bufferShapes: number[][] = [];
const uniformsType = 'int32';

programUniform.push({type: 'float32', data: [NaN]}, {type: 'float32', data: [Infinity]});
bufferShapes = inputs.concat(output).map(d => d.shape);
const uniformsType = 'int32';
bufferShapes.map(d => {
  programUniform.push({type: uniformsType, data: d});
  const strides = util.computeStrides(d);
  programUniform.push({type: uniformsType, data: strides});
});

if (program.size) {
  const size = util.sizeFromShape(program.outputShape);
  programUniform.push({
    type: uniformsType,
    data: [program.outputComponent ? size / program.outputComponent : size]
  });
}

programUniform = [...programUniform, ...programDefinedUniform];

const bindings = [
  this.tensorToBinding(output),
  ...inputs.map(t => this.tensorToBinding(t)),
  this.makeUniforms(programUniform)
];

const bindGroup = this.device.createBindGroup({
  layout: program.pipeline.getBindGroupLayout(0),
  entries: bindings.map((b, i) => ({binding: i, resource: b})),
});
```
** explain this ..? how/why ..?

Kernel execution is:

This ends up returning this invocation:

```typescript
getKernel(kernelParams.kernelName, this.backendName)
  .kernelFunc({kernelParams.inputs, kernelParams.attrs, backend: this.backend})
  .map((outInfo: TensorInfo) => this.makeTensorFromTensorInfo(outInfo));
```

`kernelFunc` runs the function and returns an array of `TensorInfo`
`makeTensorFromTensorInfo` transforms a `TensorInfo` into a `Tensor`
** `makeTensorFromTensorInfo` does ..?

** why do we need to "encode" the commands before sending them to the GPU ..? `this.computePassEncoder = this.commandEncoder.beginComputePass({});` ..?
** why does the GPU needs a queue ..? can it be done directly without queue ..? `this.queue.submit([this.commandEncoder.finish()]);` ..?
```md
ChatGPT:
  * Individual operations (like matrix multiplications or texture sampling) need to be optimized for execution in parallel.
  * If commands were executed immediately, we couldn’t efficiently batch them, leading to high communication overhead between the CPU and GPU.

Instead, WebGPU records commands first then submits them in bulk, improving efficiency.
```

** A "ComputePass" is ..? `this.computePassEncoder = this.commandEncoder.beginComputePass({});` ..?
> The beginComputePass() method of the GPUCommandEncoder interface starts encoding a compute pass,
> returning a GPUComputePassEncoder that can be used to control computation.
>
> -- https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/beginComputePass



## Memory management in TF (C++, ...)




## Node backend

** `tfjs-node-gpu/README.md` is ..?
** `https://github.com/tensorflow/tfjs/blob/master/tfjs-node/README.md` is ..?



# NEXT POST



The data is fetched when `read()` is called:

```typescript
class Engine {
  // ...

  read(dataId: DataId): Promise<BackendValues> {
    // Route the read to the correct backend.
    const info = this.state.tensorInfo.get(dataId);
    return info.backend.read(dataId);
  }

  // ...
```

** Explain the differences ..? and where the data is kept..?
** how this Tensor is created during input ..?



```typescript
const inboundNodes = symbolicTensor.sourceLayer.inboundNodes;

for (let i = 0; i < inboundNodes.length; ++i) {
  for (const outputTensor of inboundNodes[i].outputTensors) {
    if (outputTensor.id === symbolicTensor.id) {
      result = inboundNodes[i].outputTensors;
      break;
    }
  }
}
return result;
```

...



It takes and returns values of the same type:

```typescript
Tensor|Tensor[]|SymbolicTensor|SymbolicTensor[]
```

The input must either be a list of `Tensor` or a list of `SymbolicTensor`, never a mixture.
** why..?


Utilites are [HHERE??]:
```typescript
/**
 * Creates a `tf.Tensor` with values sampled from a truncated normal distribution.
 *
 * ```js
 * tf.truncatedNormal([2, 2]).print();
 * ```
 *
 * The generated values follow a normal distribution with specified mean and
 * standard deviation, except that values whose magnitude is more than 2
 * standard deviations from the mean are dropped and re-picked.
 *
 * @param shape An array of integers defining the output Tensor shape.
 * @param mean The mean of the normal distribution.
 * @param stdDev The standard deviation of the normal distribution.
 * @param dtype The data type of the output Tensor.
 * @param seed The seed for the random number generator.
 *
 * @doc {heading: 'Tensors', subheading: 'Creation'}
 */
function truncatedNormal_<R extends Rank>(
    shape: ShapeMap[R], mean = 0, stdDev = 1, dtype?: 'float32'|'int32',
    seed?: number): Tensor<R> {

const randGauss =
      new MPRandGauss(mean, stdDev, dtype, true /* truncated */, seed);
  const res = buffer(shape, dtype);
  for (let i = 0; i < res.values.length; i++) {
    res.values[i] = randGauss.nextValue();
  }
  return res.toTensor();
}
```

The expression is:

** kernel/bias initializer role is ..?
The default kernel initializer is `'glorotNormal'`.
** kernel initializer === initial weights ..?
Initializers can also be passed al arguments.
Its `apply()` method is essentially:
## Transformation

`build()` method calls `call()` method of the layer.
This latter contains the layer logic.
It's also implemented by concrete layer, not by the abstract `Layer` classe.

For the dense layer:

```typescript
override call(inputs: Tensor|Tensor[], kwargs: Kwargs): Tensor|Tensor[] {
    // Dense layer accepts only a single input.
    const input = getExactlyOneTensor(inputs);
    const fusedActivationName = mapActivationToFusedKernel(this.activation.getClassName());

    let output: Tensor;
    if (fusedActivationName != null) {
      output = K.dot(
          input, this.kernel.read(), fusedActivationName,
          this.bias ? this.bias.read() : null);
    } else {
      output = K.dot(input, this.kernel.read());
      if (this.bias != null) {
        output = K.biasAdd(output, this.bias.read());
      }
      if (this.activation != null) {
        output = this.activation.apply(output);
      }
    }

    return output;
  }
```
** explain this..?

`K` here is the backend.
** it can be either gpu or cpu?
** It's changed by calling `setBackend()`..?

Tfjs is where heavy computation operations are defined.
** For example `K.dot` here, which do ..?
** example operations..?
We'll talk Tfjs backend in the future post.

** Study shapes (arary, matrix, lists) in the logics ..?

** study `call` of another couple of layers..?

```typescript
/// ... ELSEWEHER
/*
  Add an inbound node to the layer, so that it keeps track
  of the call and of all new variables created during the call.
  This also updates the layer history of the output tensor(s).
  If the input tensor(s) had no previous history,
  this does nothing.
*/
this.addInboundNode(inputs, output, null, null, inputShape, outputShape, kwargs);
```

** explain this..?

## WebGL backend

## Protecting against memory leaks

```javascript
 * Executes the provided function `fn` and after it is executed, cleans up all
 * intermediate tensors allocated by `fn` except those returned by `fn`.
 * `fn` must not return a Promise (async functions not allowed). The returned
 * result can be a complex object.
 *
 * Using this method helps avoid memory leaks. In general, wrap calls to
 * operations in `tf.tidy` for automatic memory cleanup.
```
** explain tidy() ..?

** usage of `tft.tidy(...` insside `predictLoop`..?

** Inside `exectue()`:
```typescript
    if (!training) {
      // Clean up Tensors that are no longer needed.
      dispose(tensorsToDispose);
    }
  }
  // NOTE(cais): Unlike intermediate tensors, we don't discard mask
  // tensors as we go, because these tensors are sometimes passed over a
  // series of mutliple layers, i.e., not obeying the immediate input
  // relations in the graph. If this becomes a memory-usage concern,
  // we can improve this in the future.
  internalFeedDict.disposeMasks();
```
** explain each of these..?

** Also in `execute()`, study the usages of `    const tensorsToDispose: Tensor[] = [];`..?


# Batching



Tenserflow.js splits the input tensors first into batches.
It then goes on batch by batch, mapping inputs to outputs.
And finally, it combines the outputs.

This is the main logic for handling each batch:

```typescript
// 1. Construct array of `SymbolicTensor` elements
const feeds = [];
for (let i = 0; i < eachBatch.length; ++i) {
  feeds.push({key: this.inputs[i], value: eachBatch[i]});
}

// 2. Execute the model for the batch
execute(this.outputs, new FeedDict(feeds));
```

First thing here, Tfjs builds a `FeedDict` instance using
an array of `SymbolicTensor` elements.

** how batches are created..? how the input is split..? axis..?
** study `sliceArrays` (used inisde `LayersModel`/`predictLoop`/`sliceArrays(ins, batchStart, batchEnd)`) ..?

At the end:
```typescript
return outsBatches.map(batches => tfc.concat(batches, 0));
```
** [CHAT GPT]: Finally, the outputs for all batches are concatenated along the first dimension (axis 0), returning the final output tensors.
** what's a batch? and how batch concatenation works(does batches handle different params or different output instances) ?
** ..?

The second step represents the evaluation of the model for an input batch.