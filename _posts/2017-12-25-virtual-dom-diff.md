---
layout: post
comments: true
title:  "Virtual DOM internals, the diff module"
date:   2017-12-25 10:25:00 +0100
tags: featured
---
Many web applications now are concieved as an aggregation of components
where each component owns a part of the screen.
Components are rarely static. They change look, content, and structure.

Some front-end tools and frameworks are designed such that the view of a component
is immutable. When an aspect of the component changes, its content is being modified for
example or its style is being updated.
The library starts by creating a new view of the component independently from
the existing view. It, only, uses the input given to it by the programmer at the creation time.
See, creating the component for the first time or for the nth time is the same.
Then, it removes the existing view. After that, it puts the created view in.
When applied direclty to the DOM, the the two last operations incur a significant performance
cost. Indeed, each of these operations forces the browser to redraw the whole page.

To cope with such cost, libraries uses the ideas behind virtual DOM.
Virtual DOM allows programmers to be generous with regard to changing the structure of the
document. In the meantime, it mitigates the performance cost.

To update a document using a virtual DOM library, you need the initial virtual DOM structure
or an empty structure if you are about to create the component for the first time. Then :

  1. Create the result element as a virtual DOM structure.
  2. Find the set of atomic operations (patches) that transform the initial
     virtual DOM element to a result virtual DOM element.
  3. Apply the patches to the existing primitive DOM element.

I will talk, here, about "virtual-dom", an impelemntation of virtual DOM.
There are two main modules to "virtual-dom".
The other modules either support these, or decorate them through legible interfaces.
I start by taking a look at the implementation of the "diff" module that generates the set of
patches. Then, in the next post, I dig inside the "patch" module that applies the patches to
the initial primitive DOM.

I don't intend to cover all the details of "virtual-dom". To get the most of these posts, I
suggest that you open the "virtual-dom" implementation and documentation, and keep
them is sight as you go through. My goal is to support you understand the implementation of the
library.

I use "primitive DOM", here, when I talk about the real DOM (the one used by the browser to
draw a page) and "virtual DOM" when I talk about the structure representing the "virtual-dom".

## The diff module

The "diff" module takes two virtual dom elements (the initial and the result,
I call them the source and the destination) and produces a set of patches (transformations),
that, when applied in order, transforms the source into the destination.

The output is a Json object containing the source virtual DOM element
and an array of transformations.

```javascript
difference =
  { source
  , transformations
  }
```

There are 7+1 types for **Transformation**:

### Text
This is used when the second element is a plain text.
When we compare a source element to a text element, we remove the source, no matter
what its type is, and we put the destination text instead.

### Node
This is used when the destination element is a node.
A virtual DOM node translates directly to a HTML element.
The diff module uses a **Node** transformation whenever the source element is different than
the destination node.
If the source and the destination are the same, then "virtual-dom" examines
the differences between their properties and their children.
Note that similar elements must have the same tagname, key, and namespace.

### Widget
This is used when the destination element is a widget, no matter what the source element is.
A widget is a black box for the diff module. It is unpacked only by the patch module.

### Remove
As the name suggests, this transformation is used to remove an element.
The element may be a text, a node, or a widget.
Only one **Remove** transformation is needed to destroy a node and its children.

As opposed to text and node elements, a widget is not removed from the view using
"parent.removeChild". A widget implements a "Widget.destroy" method that removes its view
from the screen.
One **Remove** transformation is required per widget.
The diff module uses multiple **Remove** transformations to destroy a node that contains
some widgets between its children.

### Insert
This transformation is used when there is no source element.
The destination can be of any type.
**Insert** differs from other transformations such as **Node**, **Text**, and **Widget**
in the effect during the patch phase.
**Insert** triggers a
```javascript
parent.appendChild
```
operation, while the others result in a
```javascript
parent.replaceElement
```
taking the primitive source element as an argument.

### Order
before introducing the meaning of **Order**, let's take a closer look at the implementation
of virtual DOM trees:

  1. A virtual DOM element, as is a primitive DOM element, is a tree. "virtual-dom" stores the
     children of an element as an array. Each element of the array is, itself, a virtual DOM
	 element, and thus, can have children in its own.
  2. Some elements have keys that identify each from its siblings.

The difference between the children of two elements is calculated by iterating over each
element's children.
Children at the same index of each array are compared against each other using the same
logic used for their parents.
This is why elements with the same key needs to be at the same index.
Hence, "virtual-dom" starts by reordering of the destination's children array to put
each element with a key at the same index as the element with the same key in the source's
children's array.
It, then, adds the operations that transform the restores the reordered array
to the initial destination array as an **Order** transformation.

### Props
When the source and the destination are similar, "virtual-dom" compares their properties.
"virtual-dom" stores properties as a Json. The order of the properties does not matter.

So for an image element, we might have the following virtual DOM element:

```javascript
Logo =
{ type      : "VNode"
, properties:
  { src: "logo.jpg",
    alt: "Company name"
  }
}
```

There are three types of properties:

  1. Regular: This is a key-value property. A property where the value is a text.
              "src" and "alt" in the previous example belongs to this category.
              "virtual-dom" adds the destination value to the diff result if the source and
              the destination have the same regular property. Elsewhere, it puts the value
              "undefined" as a hint to remove the property from the primitive DOM element.
  2. Object : A property might have sub-properties. A "style", for example, is an object where
              each CSS descriptor is an entry pair. "attributes", also,
			  is another object property.
              Objects are iterated over and entries with the same key are compared against each
              others.
              We will get back to these special properties in the following post.
              Indeed, The diff module treats them as black boxes.
  3. Hook   : A hook property is used to execute routines after adding and removing an element.
              They have nothing to do with the primitive DOM.
              Removing hooks is about invoking their "unhook" method, while adding
              a hook is about executing its "hook" method.
              Hooks are, always, removed by the diff module.
              If the destination has a hook with the same name, "virtual-dom" inserts it again.

### Thunk
This is the "+1" type.
While the widget takes control over the patch process,
a thunk is used to take control over the diff process.
A thunk has a render method that takes the previous virtual dom element (in case there is one)
and returns the destination virtual dom element.
So, when the source or the destination is a thunk, "virtual-dom" starts by
executing its/their "render" method(s). Then, it uses the rendered result(s) instead
of the element in the diff process.
This is why we cannot have a **Remove** transformation over a thunk.
Thunk is used mainly to pass state over successive modifications of an element.
	
