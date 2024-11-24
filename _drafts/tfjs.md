
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