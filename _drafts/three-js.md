* Three.js is ..?



Vocabulary (Claude AI):
* scene: hierarchical container that represents the entire 3D world
* camera: Defines the viewpoint and perspective (PerspectiveCamera: Mimics human eye, OrthographicCamera: Provides a flat)
* frameBuffer: off-screen memory buffer where rendering occurs before being displayed
* renderTarget/renderContext: (viewport/scissor/pixelRatio): destination and configuration
* clippingContext: regions where rendering is restricted or modified
* coordinateSystem: spatial reference for 3D objects
* projectionMatrix: Mathematical transformation that converts 3D coordinates to 2D screen coordinates
* drawingBuffer: Memory area where rendering occurs before being displayed
* renderTarget: Allows rendering to a texture instead of directly to the screen

`renderScene` takes a scene and a camera intsances:

```javascript
_renderScene( scene, camera, useFrameBufferTarget = true ) {
  const frameBufferTarget = this._getFrameBufferTarget();
  this.setRenderTarget(frameBufferTarget);

  const renderContext = this._renderContexts.get( scene, camera, renderTarget );

  const coordinateSystem = this.coordinateSystem;
  camera.coordinateSystem = coordinateSystem;
  camera.updateProjectionMatrix();

  if ( scene.matrixWorldAutoUpdate === true )
    scene.updateMatrixWorld();

  if ( camera.parent === null && camera.matrixWorldAutoUpdate === true )
    camera.updateMatrixWorld();

  this.getDrawingBufferSize( _drawingBufferSize );

  _screen.set( 0, 0, _drawingBufferSize.width, _drawingBufferSize.height );

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

  if ( ! renderContext.clippingContext )
    renderContext.clippingContext = new ClippingContext();

  renderContext.clippingContext.updateGlobal( scene, camera );

  _projScreenMatrix.multiplyMatrices( camera.projectionMatrix, camera.matrixWorldInverse );
  _frustum.setFromProjectionMatrix( _projScreenMatrix, coordinateSystem );

  const renderList = this._renderLists.get( scene, camera );
  renderList.begin();
  this._projectObject( scene, camera, 0, renderList, renderContext.clippingContext );
  renderList.finish();

  this._textures.updateRenderTarget( renderTarget, activeMipmapLevel );
  
  const renderTargetData = this._textures.get( renderTarget );
  renderContext.textures = renderTargetData.textures;
  renderContext.depthTexture = renderTargetData.depthTexture;
  renderContext.width = renderTargetData.width;
  renderContext.height = renderTargetData.height;
  renderContext.renderTarget = renderTarget;
  renderContext.depth = renderTarget.depthBuffer;
  renderContext.stencil = renderTarget.stencilBuffer;

  renderContext.width >>= activeMipmapLevel;
  renderContext.height >>= activeMipmapLevel;
  renderContext.activeCubeFace = activeCubeFace;
  renderContext.activeMipmapLevel = activeMipmapLevel;
  renderContext.occlusionQueryCount = renderList.occlusionQueryCount;

  this._nodes.updateScene( sceneRef );
  this._background.update( sceneRef, renderList, renderContext );

  // begin render pass
  this.backend.beginRender( renderContext );
  // process render lists
  const {    bundles,  lightsNode,   transparentDoublePass: transparentDoublePassObjects,   transparent: transparentObjects,   opaque: opaqueObjects  } = renderList;
  this._renderBundles( bundles, sceneRef, lightsNode );
  this._renderObjects( opaqueObjects, camera, sceneRef, lightsNode );
  this._renderTransparents( transparentObjects, transparentDoublePassObjects, camera, sceneRef, lightsNode );
  // finish render pass
  this.backend.finishRender( renderContext );

  //
  this.setRenderTarget( outputRenderTarget, activeCubeFace, activeMipmapLevel );
  const quad = this._quad;
  if ( this._nodes.hasOutputChange( renderTarget.texture ) ) {
    quad.material.fragmentNode = this._nodes.getOutputNode( renderTarget.texture );
    quad.material.needsUpdate = true;
  }
  this._renderScene( quad, quad.camera, false );
}
```
** explain this ..?

`_renderObjects` renders opaque objects:

```javascript
_renderObjects( renderList, camera, scene, lightsNode, passId = null ) {
  for ( let i = 0, il = renderList.length; i < il; i ++ ) {
    const { object, geometry, material, group, clippingContext } = renderList[ i ];
    this.renderObject( object, scene, camera, geometry, material, group, lightsNode, clippingContext, passId );
  }
}
```

** `renderObject` is ..? [[HEREE??]]