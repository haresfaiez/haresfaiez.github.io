


If we assume the camera uses [perspective projection](https://en.wikipedia.org/wiki/Perspective_(graphical)),
the projection matrix is a `4 x 4` matrix that transforms vertices' shapes from the scene 3D space.

A vertex that's close to the camera will be bigger that the one behind.

** how `_projScreenMatrix` and `_frustum` are used inside `_projectObject`..?

** If visible, the engine does ... and adds it to the list..?

```javascript
/**
 * There is no unique mapping of render objects to 3D objects in the
 * scene since render objects also depend from the used material,
 * the current render context and the current scene's lighting.
 */
```
** reword this..?

** other objects added to `renderList` inside `_projectObject` ..?

** `renderList.sort( this._opaqueSort, this._transparentSort );` is ..?

## Drawing the objects

> A texture is an OpenGL Object that contains one or more images that all have the same image format.
>
> A texture can be used in two ways: it can be the source of a texture access from a Shader,
> or it can be used as a render target.
>
> -- [Texture](https://www.khronos.org/opengl/wiki/Texture)

A texture describes the cover of the object. Think about images and videos as sources.

The render target has at least one texture.
WebGPU always renders to a texture.

three.js uploads such texture to the GPU first.

Uploading a texture essentially creates a sampler 
** `WebGPUTextureUtils.createSampler` is ..?
** `WebGPUTextureUtils.createTexture` is ..?

 and optionally one depth texture.

** Updating the background is..?
```javascript
  this._background.update( sceneRef, renderList, renderContext );
```
** explain this..?

** `this.backend.beginRender( renderContext )` is ..?

** `currentPass` is ..? its usages are ..?
`renderContextData.currentPass` is created inside `Backend.beginRender()`,
`renderContextData.currentPass` is created with:
```javascript
const encoder = device.createCommandEncoder( { label: 'renderContext_' + renderContext.id } );
const currentPass = encoder.beginRenderPass( descriptor );
// ...
renderContextData.currentPass = currentPass;
```
** explain this..?
** It creates ..? https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/beginRenderPass
`renderContextData.currentPass` is an instance of [`GPURenderPassEncoder`](https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder):
> The GPURenderPassEncoder interface of the WebGPU API encodes commands related
> to controlling the vertex and fragment shader stages, as issued by a GPURenderPipeline.
> It forms part of the overall encoding activity of a GPUCommandEncoder.
** `descriptor` is ..? (inside `src/renderers/webgpu/WebGPUBackend.js` -> `beginRender()`)
** how and why each attribute in `descriptor` is added..?

** why is it named a "pass"..? and not just "encoder"..?

`this._renderObjects( opaqueObjects, camera, sceneRef, lightsNode )` renders opaque objects.
** better framing/transition ..? more details ..?

** `renderObject` calls either `_renderObjectDirect()` or `_createObjectPipeline` ..? diff..?
** `_renderObjectDirect` is/does ..?
** `this._objects.get()` is ..? it does ..?
** If the renderObject does not exist, it ..? what if not existant ..?
It creates a new `RenderObject` instance with the arguments. (see the class documentation above).

** There are 3 rendering strategies: "Uses multi-draw calls, Indexed drawing, Indirect drawing" ..?

We'll focus on the "indirect drawing" strategy.

** We'll not handle drawing with "// occlusion queries" and "// stencil" ..?
** Also without "// index"  ..? "An index buffer is a list of indices that tell the GPU which vertices to reuse when drawing triangles." ..?
** Also we'll assume that the currentSet? contains the right pipeline ..? "// pipeline" ..?
** Also we'll not consider optimizations and perf. improvements ..?
** There are ..? example ..? internals..?

Here's the essential logic of the `draw()` method:

```javascript
draw( renderObject, info ) {
  const renderContextData = this.get(renderObject.context);

  // bind groups
  const bindings = renderObject.getBindings();
  for ( let i = 0, l = bindings.length; i < l; i ++ ) {
    const bindGroup = bindings[ i ];
    const bindingsData = this.get( bindGroup );
    renderContextData.currentPass.setBindGroup( bindGroup.index, bindingsData.group );
  }

  // vertex buffers
  const vertexBuffers = renderObject.getVertexBuffers();
  for ( let i = 0, l = vertexBuffers.length; i < l; i ++ ) {
    const vertexBuffer = vertexBuffers[ i ];
    const buffer = this.get( vertexBuffer ).buffer;
    renderContextData.currentPass.setVertexBuffer( i, buffer );
  }

  // draw (indirect)
  const { vertexCount, instanceCount, firstVertex } = renderObject.getDrawParameters();
  renderContextData.currentPass.draw( vertexCount, instanceCount, firstVertex, 0 );
}
```
** explain this..? (see below)
** vertex buffer/stage vs. fragment buffer/stage is ..? (see [GPURenderPassEncoder](https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder))

This function copies/assigns these values to the current `passEncoderGPU`.

** usage of `renderContextData.currentPass` in `draw()` above ..? why ...?

`renderObject`, passed to `draw()` above, is an instance of `RenderObject`.

The "RenderObject" contains a list/array of bindings and a list/array of vertexBuffers.

** A bindingGroup is ..?
** Add doc of `setBindGroup` ..?

** A vertexBuffer is ..?
** Add doc of `setVertexBuffer` ..?

** Diff between them ..? Why separating them..?

** `getBindings()`, `getVertexBuffers()`, and `getDrawParameters()` in `RenderObject` are ..?

** how this work with the cube example..?

** `this.backend.finishRender( renderContext )` is ..?

A render pipeline rendering has two main stages:
```javascript
/**
A render pipeline renders graphics to GPUTexture attachments, typically intended for display in a <canvas>
element, but it could also render to textures used for other purposes that never appear onscreen.
It has two main stages:

    A vertex stage, in which a vertex shader takes positioning data fed into the GPU and uses
    it to position a series of vertices in 3D space by applying specified effects like rotation,
    translation, or perspective. The vertices are then assembled into primitives such as triangles
    (the basic building block of rendered graphics) and rasterized by the GPU to figure out what
    pixels each one should cover on the drawing canvas.

    A fragment stage, in which a fragment shader computes the color for each pixel covered by
    the primitives produced by the vertex shader. These computations frequently use inputs such
    as images (in the form of textures) that provide surface details and the position and color of virtual lights.

>> [GPURenderPassEncoder](https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder)
*/
```

The render target has at least one default texture.

A depth texture is a special texture, based on a bitmap, that describe how
far each pixel is from the camera.
The render target decides whether to use such buffer or not for rendering.

Updating / uploading a texture is ..

** a sampler is ..?

The WebGPU renderer draws the scene in two stages.
First, into a temporary internal buffer, then into the rendering target element.
** This is because ..?
```javascript
/**
 * Returns an internal render target which is used when computing the output tone mapping
 * and color space conversion. Unlike in `WebGLRenderer`, this is done in a separate render
 * pass and not inline to achieve more correct results.
```
** "tone mapping" and color "space conversion" are ..?

** The first stage target is `this._getFrameBufferTarget()` ..?
A texture is used as a render target in the first stage.
When the output is first rendered offscreen,
libraries attach textures to the render target and draws the output on it,
that is ["Render To Texture"](https://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/).
** what's special in this texture..? compared to others ..?

The second stage target is a HTML element.

The rendering process itself is the same for both targets. (true..?)

The library attaches a texture and a depth texture to the render target.
This is common for all backends.

The renderer uses the backend instance to sample each texture and upload it to the gpu.The renderer first draws into a temporary internal buffer.

** This internal buffer is ..? `Renderer._getFrameBufferTarget()` does ..?

** This is because ..?
```javascript
/**
 * Returns an internal render target which is used when computing the output tone mapping
 * and color space conversion. Unlike in `WebGLRenderer`, this is done in a separate render
 * pass and not inline to achieve more correct results.
```
** "tone mapping" and color "space conversion" are ..?

The rendering process itself is the same for both targets. (true..?)
** Later, the rendering is done to the canvas (when `useFrameBufferTarget` is `false`)..?
** how ..? the difference between the two is ..?



## Annex



```md
Vocab (ChatGPT):
Vertex	A point in 3D space (part of a shape).
Shader	A GPU program that processes vertices and pixels.
Texture	An image applied to a 3D model.
Fragment	A "potential" pixel before being finalized.
GPUTexture	A GPU memory buffer storing the final image.
Rasterization	Converts triangles into pixels.
```


** The render context is ..?
```javascript
const renderContext = this._renderContexts.get( scene, camera, renderTarget );

renderContext.viewportValue.copy( renderTarget.viewport ).multiplyScalar( pixelRatio ).floor();
renderContext.viewportValue.width >>= activeMipmapLevel;
renderContext.viewportValue.height >>= activeMipmapLevel;
renderContext.viewportValue.minDepth = renderTarget.viewport.minDepth;
renderContext.viewportValue.maxDepth = renderTarget.viewport.maxDepth;

renderContext.viewport = renderContext.viewportValue.equals( _screen ) === false;

renderContext.scissorValue.copy( renderTarget.scissor ).multiplyScalar( pixelRatio ).floor();
renderContext.scissor = this._scissorTest && renderContext.scissorValue.equals( _screen ) === false;
renderContext.scissorValue.width >>= activeMipmapLevel;
renderContext.scissorValue.height >>= activeMipmapLevel;

renderContext.clippingContext = new ClippingContext();
renderContext.clippingContext.updateGlobal( scene, camera );
```
** explain this ..? shortly ..?



`Render.init()` should be called before rendering..?
Essentially, it's:
```javascript
let backend = this.backend;
await backend.init( this );

this._nodes = new Nodes( this, backend );
this._animation = new Animation( this._nodes, this.info );
this._attributes = new Attributes( backend );
this._background = new Background( this, this._nodes );
this._geometries = new Geometries( this._attributes, this.info );
this._textures = new Textures( this, backend, this.info );
this._pipelines = new Pipelines( backend, this._nodes );
this._bindings = new Bindings( backend, this._nodes, this._textures, this._attributes, this._pipelines, this.info );
this._objects = new RenderObjects( this, this._nodes, this._geometries, this._pipelines, this._bindings, this.info );
this._renderLists = new RenderLists( this.lighting );
this._bundles = new RenderBundles();
this._renderContexts = new RenderContexts();
//
this._animation.start();
```
** explain this..?

** Rendering is ...?
Three.js separates the rendering logic from the drawing logic.

```javascript
/**
 * In general, the basic process of the renderer is:
 *
 * - Analyze the 3D objects in the scene and generate render lists containing render items.
 * - Process the render lists by calling one or more render commands for each render item.
 * - For each render command, request a render object and perform the draw.
 */
```

The latter is implemented by the backend, such as WebGPU and WebGL 2.



