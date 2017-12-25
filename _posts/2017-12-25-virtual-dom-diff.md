---
layout: post
comments: true
title:  "Virtual DOM internals, the diff module"
date:   2017-12-25 10:25:00 +0100
tags: featured
---
Many web applications, now, are concieved as an aggregation of components.
Each component owns a part of the screen.
Components are rarely static. They change their look, content, and structure.

React is designed such that the view of each component is immutable.
When something changes in a component, the library removes the old view from the page,
builds a new view from scratch, and puts the new view in.
When applied direclty to the DOM, the first and the last operations incur
a significant cost.
In fact, each of them forces the browser to redraw the whole page.

To cope with that cost, React uses Virtual DOM.
Virtual DOM allows developers to be generous with regard to changing
the structure of the document.
In the meantime, it optimizes the modification of the primitive DOM.

To update the document using a Virtual DOM library:

  1. Create the result element as a Virtual DOM structure.
  2. Find the set of atomic operations (patches) that transforms the initial
    Virtual DOM element to a result Virtual DOM element.
  3. Apply the patches to the existing primitive DOM element.

I will talk, here, about "virtual-dom", an impelemntation of Virtual DOM.
There are two principal modules to "virtual-dom".
The other modules either support them, or decorate them through more legible interfaces.
I start by taking a look at the implementation of the "diff" module
that generates the set of patches.
Then, in the next post, I will dig inside the "patch" module that applies the
patches to the initial primitive DOM.

I use "primitive DOM", here, when I talk about the real DOM (the one
used by the browser to draw the page) and "Virtual DOM" when I talk about
the structure representing the "virtual-dom".

## The diff module

The "diff" module takes two Virtual dom elements (the initial and the result,
I call them the source and the destination) and produces a set of patches
(the differences that, when applied in order, transforms the source into the destination).

The output is a Json object containing the source Virtual DOM element and an array of patches.

```haskell
Diff = Diff
  { source :: VDom
  , patches:: Transformation[]
  }
```

There are 6+1 possible types for each **Transformation**:

### Text
This is used when the second element is a plain text.
When we compare a source element to a text element, we remove the source, no matter
what its type is, and we put the destination text instead.

### Node
This is used when the destination element is a node; a tagname, a set of properties,
and children.
A Virtual DOM node translates directly to a HTML element.
The diff module adds a **Node** transformation whenever the source element is different than
the destination element and the destination element is a node.
Note that similar elements must have the same tagname, key, and namespace.
If the source and destination are the same, then we add the differences between their
properties and their children.

### Remove
As the name suggests, this transformation is used to remove an element of any type.
Only one **Remove** transformation is needed to destroy an element and its children
in case it is a node.
The diff module uses multiple **Remove** transformations when the element contains
widgets between its children.
As opposed to text and node elements, a widget is not removed from the view using
"parent.removeChild". Each widget implements a "Widget.destroy" that remove the view
of itself from the screen.
One **Remove** transformation is required per widget.

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
To understand what **Order** means, we need to take a look at the code responsible
for calculating the difference between the children of two similar elements.

Here are two facts to know about the implementation:

  1. A Virtual DOM element, as is a primitive DOM element, is a tree.
     Physically, "virtual-dom" stores the children of an element as an array inside
     the element's data structure.
	 Each element of the array is itself an element, and thus, can have children itself.
  2. Some elements have a key identifies them globally. When we modify an
     element with some children that have keys, we compare the children with the
     same key against each other.

The difference between the children of two elements is calculated by iterating over each
the elements at the same index of each element array against each other.
This is why elements with the same key needs to be at the same index.
Hence, "virtual-dom" starts by reordering of the destination's children array to put
each element with a key at the right index.
It, then, adds the operations that transform the reordered arrays to the given destination
array as an **Order** transformation.

### Props
When the source and the destination are similar, "virtual-dom" compares their properties
in addition to their children.
"virtual-dom" models properties as Json object within the subject element's data structure.
The order of the properties does not matter.

So for an image element, we might have the next Virtual DOM structure:

```javascript
Logo =
{ type      : "VNode"
, properties:
  { src: "./logo.jpg",
    alt: "Company name"
  }
}
```

There are three different types of properties:

  1. Simple: This is a key-value property, like "src" and "alt" in the previous example.
             "virtual-dom" adds the destination value to the diff result if the source and
  	  	     the destination have the property. Elsewhere, it selects "undefined" as a hint
			 to remove the property from the element.
  2. Object: A property might have sub-properties. A "style", for example, is an object where
             each CSS descriptor is a key-value pair. "attributes" is another object property.
			 Objects are compared element by element.
			 We will get back to these special properties in the following post.
			 The diff module treats them as black boxes.
  3. Hook  : A hook property is used to execute routines after adding an element and
             after removing it. They are not adding to the primitive DOM.
			 Removing hooks properties is about invoking their "unhook" method, while adding
			 a hook preperty is about executing its "hook" method.
			 Hooks are always removed by the diff module.
			 If the destination has a hook with the same property key, "virtual-dom"
			 inserts it again.

### Widget
This is used when the destination element is a widget,
no matter what the source element is.
A widget is a black box for the diff module.
It is handled only by the patch module.

### Thunk
This is the "+1" type.
While the widget takes control over the patch process,
a thunk is used to take control over the diff process.
A thunk has a render method that takes the previous Virtual dom element(if it exists)
and returns the new Virtual dom element.
So, when the source or the destination is a thunk, "virtual-dom" starts by
executing its/their "render" method(s). Then, it uses the result(s) as a subtitute
for the element in the diff process.
This is why we cannot have a **Remove** transformation over a thunk.
Thunk is used primarely to pass state over successive modifications of an element.
	
