---
layout: post
comments: true
title:  "How three.js prepares a scene for rendering"
date:   2025-07-13 09:00:00 +0100
tags: featured
---

[Rendering](https://en.wikipedia.org/wiki/3D_rendering)
is the main step of materializing 3D objects.
It's the process by which three.js transforms 3D models into 2D bitmaps.

It's a computation-intensive operation
as the library analyzes all the components of the 3D world.

Even drawing a frame of a simple [cube](https://threejs.org/manual/#en/creating-a-scene)
takes into account the scene, the camera, the lights, and the physics.

## A scene as a tree

To render a scene, three.js prepares a list of the "to-be-rendered" objects
then it creates and executes the shaders that draw this list with the GPU.

The first step is the subject of this post.

As explained in [Creating a scene](https://threejs.org/manual/#en/creating-a-scene),
a basic rendering involves a scene, a camera, a rendering target, and a renderer.

The rendering target, also known as "drawing target", is by default a
[`<canvas>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/canvas)
wrapper.

The [scene](https://threejs.org/docs/?q=scene#api/en/scenes/Scene) is the 3D world.
It's a tree of 3D objects. And the scene object itself is the root.

The [camera](https://threejs.org/manual/#en/cameras) is the viewpoint, the perspective.

It's also a 3D object, but it's not part of the tree.

The renderer is the director.
It's a collection of backend-specific implementations of the rendering steps.

> The aim of the project is to create an easy-to-use, lightweight, cross-browser,
> general-purpose 3D library. The current builds only include WebGL and WebGPU
> renderers but SVG and CSS3D renderers are also available as addons.
>
> -- [three.js](https://github.com/mrdoob/three.js)

Backends themselves might have different steps, but the strategy is usually the same.

The renderer always updates the transformation matrices and then finds out which objects
from the scene are to be shown.

## Projections

The engine updates the
[transformation matrices](https://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/)
of each object as a first step.

Such a structure enables the instant repositioning of the object's
[vertices](https://en.wikipedia.org/wiki/Vertex_(computer_graphics)).
We calculate the new coordinates of a vertex by multiplying the old coordinates by the transformation matrix.

A 3D object has a local transformation matrix and a world transformation matrix.
The local matrix describes the settings of the object relative to its parent object in the tree.
The world matrix describes the settings of the object relative to the root of the tree, the scene.
The latter is the product of the parent's world matrix
and the local transformation matrix.

The local transformation matrix combines the object position (a 3-element vector, that is, the `(x, y, z)` coordinates),
its quaternion (a 4-value object denoting a [Quaternion](https://en.wikipedia.org/wiki/Quaternion) value),
and its scale (also a 3-element vector, the scale along each axis).

Check the [source code](https://github.com/mrdoob/three.js/blob/r176/src/math/Matrix4.js#L1001)
if you wish to learn more about the creation of a transformation matrix.

Instead of translating, rotating, and scaling each vertex separately,
the engine multiplies its coordinates by the transformation matrix.

The renderer traverses the tree in a depth-first approach.
It updates the world transformation matrix of the scene, then its children's world matrices.
And updating a child matrix updates also its grandchildren, and so on.

The camera, not being part of the tree, has different structures.

Before projecting the objects, three.js updates the camera's projection matrix,
its world matrix, and the [frustum](https://en.wikipedia.org/wiki/Viewing_frustum) planes.

The world matrix of a camera is similar to that of a regular 3D object.

By default, the camera does not have a parent object.
Its world matrix is the same as its local matrix.
It combines its position, rotation, and scale.

Such a matrix updates the coordinates of the objects'
vertices in the scene to make it as if the camera moved.

> It you want to view a moutain from another angle, you can either move the camera…
> or move the mountain. While not practical in real life,
> this is really simple and handy in Computer Graphics.
>
> -- [The View matrix](https://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/#the-view-matrix)

In some way, it transforms the world transformation matrix of the objects from being
relative to the global world root to being relative to the camera.

The projection matrix changes the objects' shapes to be relative to the camera viewpoint.
A cube just in front of the camera grows while another one, far behind, becomes smaller.

This matrix is then used to create the frustum.

The frustum decides what's inside the camera's sight,
and more importantly, what's outside of it.

It's an array of six elements.
Each element describes a clipping plane
(left, right, top, bottom, near, and far).
Imagine the view range of the camera as a pyramid.
The camera is at the top and looking down at the base.

Each plane is defined by a 4-element array.
The first 3 elements create a [normal vector](https://en.wikipedia.org/wiki/Normal_(geometry))
that describes the direction of the plane.
It tells how much to move along each axis from any given point to get a vector
that's perpendicular to the plane.
The last element describes the distance of the plane from a selected point
along that direction.

## To-be-rendered objects

Not all objects in the scene tree are rendered.

Each 3D object assigns itself to a couple of layers.
These are used to tell which kind of cameras see it.

A layer is identified by a number between 0 and 31.
Only an object that shares a layer with the camera, which also defines
the layers it sees, is selected for rendering.

Depending on the object's type, the engine decides whether to render
it or not.

If the 3D object is a [light](https://threejs.org/docs/?q=light#api/en/lights/Light),
it's always added to the rendering list.

If it's a regular object such as a [line](https://threejs.org/docs/?q=line#api/en/objects/Line),
a [sprite](https://threejs.org/docs/#api/en/objects/Sprite),
or a [mesh](https://threejs.org/docs/?q=mesh#api/en/objects/Mesh).
The library checks whether it intersects with the frustum.

three.js builds an imaginary shape around
the object, a sphere for example. It maps the coordinates of such a shape into
the global coordinates by multiplying them by the world transformation matrix of the object.
Then, it iterates over the frustum planes and looks for a plane whose
distance from the sphere is smaller than the sphere's radius.

Such distance is calculated by multiplying the 3-element normal vector of the plane by
the sphere's center coordinates.

If the imaginary shape does intersect, the engine multiplies the object's
world matrix with both  the camera's projection matrix
and the inverse of the camera's world matrix.
