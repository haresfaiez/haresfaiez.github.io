---
layout: post
comments: true
title:  "Inside TensorFlow.js prediction: journeys of Tensors"
date:   2024-11-24 10:00:00 +0100
tags: featured
---

TensorFlow is an open-source, stable, and actively maintained solution
for creating and evaluating [ML models](https://en.wikipedia.org/wiki/Machine_learning#Models).

It might not be the perfect codebase to study though.
It was first written in Python then [ported to Typescript](https://github.com/tensorflow/tfjs).
But it's widespread enough to be interesting.

TensorFlow.js works effortlessly on the browser.
And that's a big win as the latter is increasingly
taking over operating system responsibilities.

You can check [Tfjs](https://github.com/tensorflow/tfjs) source code on Github.
Being a port, you'll notice some Python design constraints sneaking into TS code.
The code in this post is a simplification of the actual code.
I tried to keep only the relevant lines.

## Input Tensors

ML [models](https://www.tensorflow.org/js/guide/models_and_layers) are sophisticated "functions".
Their inputs and outputs have explicit shapes and types.
And they can learn.
They improve their inner working as they get more input/output samples.

Tfjs offers interfaces and building blocks to create models,
train them, and directly apply [predefined ones](https://www.tensorflow.org/js/models).

A model is a sequence of layers.

The input is interpreted and formatted by the first layer.
It's passed down to the following layers.
And, it's transformed into output by the last layer.

The layers in between transform, reshape, and filter the data.

We exercise a layer with `predict()`:

```javascript
const prediction = model.predict(inputTensor);
```

Any input needs to be transformed into Tensors before using it for prediction.
The model accepts Tensors as input.

The "Tensor" is the "currency" of communication in Tfjs.

It's a "data unit", information that can be
passed to the model, returned from it,
and passed between its internal components.

"Physically", it's either a simple value, a one-dimensional array,
or a multi-dimensional array of a `dtype` type.

```typescript
class Tensor {
  dataId: DataId;

  id: number; // Unique id of this Tensor

  shape: number[]; // The shape of the Tensor

  dtype: 'float32' | 'int32' | 'bool' | 'complex64' | 'string';

  // ...
  async data() {
    return trackerFn().read(this.dataId);
  }

  // ...
```

The `shape` attribute specifies the dimensions of the array
and the size of each dimension.

To create a `3 x 1` `int32` array, we can use `tensor2d`:

```typescript
const indices = tf.tensor2d([0, 4, 2], [3, 1], 'int32');
```

The second argument describes the dimensions.
The first argument is the value.

`tensor3d` builds a `2 x 2 x 2` 3-dimensional array:

```typescript
const x = tensor3d([[[1, 2], [3, 4]], [[-1, -2], [-3, -4]]]);
```

Here we pass the value.

Two attributes of `Tensor` define the Tensor identity: `id` and `dataId`.

`id` is the tensor unique identifier in the model.

`dataId` is a reference to the data denoted by the Tensor.
Such reference can be shared by multiple Tensors.

The value of the Tensor is not stored inside an instance of this class
because it might be huge.
It can be a big [image](https://js.tensorflow.org/api/1.0.0/#browser.fromPixels) for example.

Tfjs implements its memory management system.
Intensive computation requires delicate memory leaks management and garbage collection routines.
Due to the browser's limited memory, v8 unpredictability, and other backends' limitations,
the memory is maintained by Tfjs' own backend
(WASM, GPU, WebGL, or CPU. More about this in the next post).

Tfjs defines another Tensor-like type to work with Tensors-without-data.

It's used to describe the model inputs and outputs.

For example, we create a model that takes a `2x2` Tensor and we apply the dense layer:

```typescript
const input = tf.input({shape: [3]});  // SymbolicTensor
const dense = tf.layers.dense({units: 2}).apply(input);
const model = tf.model({inputs: input, outputs: dense});
```

Both constants, `input` and `dense` are `SymbolicTensor` instances:

```typescript
export class SymbolicTensor {
  id: number;
  name: string; // The fully scoped name of this Variable
  sourceLayer: Layer; // The Layer that produced this symbolic Tensor.
  inputs: SymbolicTensor[]; // The inputs passed to sourceLayer during prediction.

  // ...
```

`id` is, same as in `Tensor`, a unique Tensor identifier.

`name` is a human-readable identifier that's used for debugging and for tracking Tensors' flow.

`SymbolicTensor` has also other attributes from `Tensor` that describe the
"real" Tensor (the output Tensor when it'll be calculated for example)
such as `shape` and `dtype`.

Tfjs wraps the input Tensor instances inside a `FeedDict` dictionary
before passing it to the layers.

```typescript
/**
 * FeedDict: A mapping from unique SymbolicTensors to feed values for them.
 * A feed value is a concrete value represented as a `Tensor`.
 */
export class FeedDict {
```

This type maps a `SymbolicTensor` to a `Tensor`.

The prediction makes use of both,
`SymbolicTensor` for the name, which can propagate across layers
and `Tensor` for the value, used for prediction.

Tfjs can also apply layers on either real Tensors or SymbolicTensors.
The first is used for normal prediction.
The second can be used to create a model container from a predefined configuration.

A feed is a type that combines both views of a Tensor:

```typescript
interface Feed {
  key: SymbolicTensor;
  value: Tensor;
}
```

## Output Tensors

The input and the output of prediction are arrays of `Tensor` instances.

The model knows the shape of the output when the model is created,
before the prediction starts.

For prediction, Tfjs first initializes the output array (the array of Tensor instances)
from the array of SymbolicTensor instances
(that is, from the model description, which defines the placeholders for the "real" Tensors outputs):

```typescript
const outSymTensorsNames = outputs.map(t => t.name);

const finalOutputs: Tensor[] = [];
for (const outputName of outSymTensorsNames) {
  const nameExistsInInput = inputFeedDict.names().indexOf(outputName) !== -1;
  if (nameExistsInInput) {
    finalOutputs.push(inputFeedDict.getValue(outputName));
  } else {
    finalOutputs.push(null);
  }
}
```

`outputs` is the initial list of output SymbolicTensors (from the model definition).

The logic searches for the output `SymbolicTensor` name in the input
(which is a `FeedDict` instance, that contains the input Tensors instances).
If found, it's dropped into the output.
It's put in the element with the same index.
If not, the Tensor value is initialized to `null`.

The holes (the `null` values) will be filled later, after exercising the layer.

Tfjs then sorts the Tensors identifiers ["Topologically"](https://en.wikipedia.org/wiki/Topology).

A `SymbolicTensor` instance has an array of `SymbolicTensor` inputs
and a `Layer` instance named `sourceLayer`.

The layer applies the inputs to get the Tensor output.

Tensors depend on each other.
An input Tensor can be shared by multiple output Tensors.
And during prediction,
the dependee should be calculated before the dependent, and calculated once.

Tfjs traverses the tree of `SymbolicTensor` instances depth-first
and adds each fresh `SymbolicTensor`
(one whose name has not yet been encountered during the traversal) to the result.

It's a tree where each node is a `SymbolicTensor` and the children are its inputs' `SymbolicTensor` instances.

The sorting outcome is an array of the model output `SymbolicTensor` elements
and their inputs' dependencies (and transitive dependencies) `SymbolicTensors` elements.

Tfjs then applies the source layer of each element in this sorted array on the `feedDict` inputs:

```typescript
const symbolicTensor = sorted[i];

const outputTensors: Tensor[] =
  symbolicTensor
    .sourceLayer
    .apply(feedDictVlalues(symbolicTensor.inputs), /* ... */);
```

`feedDictVlalues` returns the input `Tensor` instances with
the same names as the sorted `SymbolicTensor` inputs.

Each application result, an array of `Tensor` instances, fills some
`null` holes from the output Tensors array (created at the beginning)
and augments the input `feedDict` for the next sorted element application.

```typescript
// 1. Applying the source layer
const outputTensors = symbolicTensor.sourceLayer.apply(inputValues);

const nodeOutputs = getNodeOutputs(symbolicTensor);

// 2. Iterating over the `SymbolicTensor` source layer outputs
for (let i = 0; i < nodeOutputs.length; ++i) {

  // 3. Adding the new Tensor to the input feed
  if (!internalFeedDict.hasKey(nodeOutputs[i])) {
    internalFeedDict.add(nodeOutputs[i], outputTensors[i]);
  }

  // 4. Filling the `null` holes in the final output
  const index = outputNames.indexOf(nodeOutputs[i].name);
  if (index !== -1) {
    finalOutputs[index] = outputTensors[i];
  }
}
```

`getNodeOutputs` extracts the array of SymbolicTensor instances
returned by the source layer application.

They're placeholders for the Tensors returned by that layer.

They're ordered in the same order as the layer Tensors output.

It's used because it has the name and the id of the Tensor.
These values are used to find the index of the Tensor in the final
output, and to put the output Tensor inside `feedDict` for the next application.

## Source layer application

Each output Tensor (modeled by a `SymbolicTensor` instance) is one
of multiple outputs of its `sourceLayer`.

```typescript
class Layer {
  name: string; // Name for this layer. Must be unique within a model.

  inboundNodes: Node[];
  outboundNodes: Node[];

  // ...
```

Inbound nodes and outbound nodes define the flow of Tensors.
The inbound nodes reference the layers that feed inside this layer,
and the outbound nodes describe the layers that depend on it.

A `Node` instance is a joint that connects successive layers:

```typescript
/**
 * Each time a layer is connected to some new input,
 * a node is added to `layer.inboundNodes`.
 *
 * Each time the output of a layer is used by another layer,
 * a node is added to `layer.outboundNodes`.
 *
 */
export class Node {
  inputTensors: SymbolicTensor[]; // List of input Tensors.
  outputTensors: SymbolicTensor[]; // List of output Tensors.
```

`getNodeOutputs`, from the previous section, searches for the node producing
the sorted Tensor inside `symbolicTensor.sourceLayer`.

It looks for the `symbolicTensor.id` inside each inbound node's `outputTensors`.

When the node is found, its `outputTensors` are returned.

The layer itself can be exercised with `apply()`:

```typescript
const outputTensors: Tensor[] = sourceLayer.apply(inputValues, kwargs);
```

`apply()` can also be called directly (without a container model).

This is an example from its documentation:

```js
const flattenLayer = tf.layers.flatten();

// Use tf.layers.input() to obtain a SymbolicTensor as input to apply().
const input = tf.input({shape: [2, 2]});
const output1 = flattenLayer.apply(input);

// output1.shape is [null, 4]. The first dimension is the undetermined
// batch size. The second dimension comes from flattening the [2, 2]
// shape.
console.log(JSON.stringify(output1.shape));
```

This is a simplified implementation of `apply()`:

```typescript
const noneAreSymbolic = checkNoneSymbolic(inputs);

// 1. Bulding
this.build(generic_utils.singletonOrArray(inputShapes));

// 2. Collecting output
if (noneAreSymbolic) {
  return this.call(inputs, kwargs);
} else {
  const inputShape = collectInputShape(inputs);
  const outputShape: Shape[] = this.computeOutputShape(inputShape);
  const outputDType = guessOutputDType(inputs);

  return outputShape
    .map((shape, index) => new SymbolicTensor(outputDType, shape, this, inputs, kwargs, this.name, index));
}
```

`inputs` is the array of given Tensors.

`inputShape` is an array of shapes.
Each element is the value of an input Tensor `shape` attribute.

## Dense layer

During prediction, a layer is built and applied.

Both `build()` and `call()` are defined in the abstract `Layer` class and implemented
inside the specific layer class.

> Dense implements the operation:
> `output = activation(dot(input, kernel) + bias)`
> where activation is the element-wise activation function passed as the activation
> argument, kernel is a weights matrix created by the layer, and bias is a bias
> vector created by the layer (only applicable if `use_bias` is True).
>
> --[Dense](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Dense#used-in-the-notebooks)

`call()` calculates the `output`.
It's essentially matrix multiplication and addition:

```typescript
K.dot(input, this.kernel.read(), fusedActivationName, this.bias.read());
```

`fusedActivationName` is the [activation function](https://www.tensorflow.org/api_docs/python/tf/keras/activations),
it can be `'relu'`, `'linear'`, or `'elu'`.

`K.dot()` is a Tensor multiplication function defined in the backend:

```typescript
/**
 * Multiply two Tensors and returns the result as a Tensor.
 *
 * For 2D Tensors, this is equivalent to matrix multiplication (matMul).
 * For Tensors of higher ranks, it follows the Theano behavior,
 * (e.g. `(2, 3) * (4, 3, 5) -> (2, 4, 5)`).  From the Theano documentation:
 *
 * For N dimensions it is a sum product over the last axis of x and the
 * second-to-last of y:
 */
```

More about this in the next post.

The values of `this.kernel.read()` and `this.bias.read()` are
returned by the kernel initializer and bias initializer when building the layer.

Building a layer indeed means creating the weights.

> Weights control the signal (or the strength of the connection) between two neurons.
> In other words, a weight decides how much influence the input will have on the output.
>
> --[Weights and Biases](https://machine-learning.paperspace.com/wiki/weights-and-biases)

Here's its implementation of `build`:

```typescript
inputShape = getExactlyOneShape(inputShape);

const inputLastDim = inputShape[inputShape.length - 1];
this.kernel = new LayerVariable(
    this.kernelInitializer.apply(
      [inputLastDim, this.units],
    ),
   /* ... */
  );

this.bias = new LayerVariable(
    this.biasInitializer.apply(
      [this.units],
    ),
    /* ... */
  );
```

Tfjs models `kernel` and `bias` as layer variables.

```typescript
/**
 * A `tf.layers.LayerVariable` is similar to a `tf.Tensor` in that it has a
 * dtype and shape, but its value is mutable.  The value is itself represented
 * as a`tf.Tensor`, and can be read with the `read()` method and updated with
 * the `write()` method.
 */
```

`this.units` is passed to the layer during creation.
It specifies the number of neurons in the layer.

The shape of the kernel layer variable is the same as the output shape.

The shape of the bias is a one-dimensional array of `this.units` elements.
It's added as-is to the result.

The default bias initializer is `'zeros'`, which sets all weights to `0`.

The default kernel initializer is essentially:

```typescript
let scale = 1.0 / Math.max(1, (shape[0] + shape[1]) / 2);
return truncatedNormal(shape, 0, Math.sqrt(scale), 'float32', seed);
```

Check [Truncated normal distribution](https://en.wikipedia.org/wiki/Truncated_normal_distribution) for a deep understanding.
