---
layout: post
comments: true
title:  "Virtual DOM internals, the patch module"
date:   2018-01-06 23:00:00 +0100
tags: featured
---
I introduced "virtual-dom" in the last post. I said that it has two main modules. I focused on
the first there, the diff module. Here, I will take a closer look at the patch module.
The patch module takes a set of transformations from the diff module output and builds
a destination primitive DOM element.

## Interpreting the diff module output

I said that the diff output contains the source virtual DOM element and a set of
transformations. Each transformation, is composed from an index and a set of operations.
Normally, each transformation has only one operation.
But, in some situations, more than a single operation is used to transform a node.
For example, to replace a widget with a text, we need a **Remove** operation for
the widget and a **Text** operation for the text. 

In fact, there are four situations where a transfarmation should have an array of operations.

  1. Either the source or the destination is a widget.
  2. The source element needs to be removed and there are some hooks attached to it.
  3. More than one child element need to be inserted to an element.
  4. A child element needs to be inserted and its parent requires reordering.
  
Transformations are ordered by index. There is a one-to-one mapping between each node
and a transformation, and thus between each node and an index.
The higher the element is in the source DOM tree, the lowest its index will be.

Transformation index has three purposes. First, it maps a source Virtual DOM node to a
transformation. Second, it implies the order in which the transformations are executed.
Finally, it establishes a one-to-one mapping between the source virtual DOM elements and their
equivalent primitive DOM elements.

"virtual-dom" starts the patch process by finding a mapping between the source
virtual DOM tree and the source primitive DOM tree.
It iterates over the virtual DOM tree and looks for the primitive DOM element associated
to each virtual DOM element.
This is why modifying the primitive DOM directly is not a good idea.
Because, in that case, the mapping fails.
Then, "virtual-dom" iterates over the ordered transformations and calls the DOM
method(s) required for each operation on the primitive DOM element.

## Element creation

Another part of the patch module is the virtual DOM-to-primitve DOM transformation.
This sub-module is used by the patch process above. But, it may be used independently.
Three steps are required to create a primitive DOM element from a virtual DOM element.

###Create the element

The are three types of element: a text element, a widget element, and a node element.
A node element and a text element are created using the DOM api.
A widget element is created by invoking its "init" method. That method returns a primitive DOM
element.

### Apply the properties to the element
A property is either a text, a Json object, or a hook.
There is one type of transformation associated with properties transformation, which is
**Props**.
So, removing, modifying, and adding properties to an element fit in a single transformation.

A hook are not registered into the primitive DOM. It is kept at the virtual DOM level.
A hook is inserted by calling its "hook" method, and removed by calling its "unhook" method.
This is another reason why keeping the source virtual DOM element is important.
It is impossible to generate virtual DOM tree from a primitive DOM tree.

Normally, properties are added using
```javascript
node[propertykey] = properyValue;
```
They are removed by choosing a null object, an empty string, or a javascript "null" as value.

When the property key is "attributes" or "style", "virtual-dom" treats them differently.
"attributes" are added using 
```javascript
node.setAttribute
```
and removed using
```javascript
node.removeAttribute
```
"style" are treated one-by-one instead of one whole property.

When the diff module compares a property object on the source to an object property associated
with the same key and the same "__proto" attribute on the destination, the diff module puts the
difference between the objects in the result.
That is it, it puts the destination value when an object attribute is modified or added and
chooses "undefined" as a value when the attribute is removed from the destination.

Object properties are added as a nested objects to the primitive DOM node.
If we have the property "key" and the value 

```javascript
{foo: 'bar'}
```

"virtual-dom" adds it as

```javascript
destinationNode['key']['foo'] = 'bar';
```

### Create the children using the same process

If the element being created is a node and it have children, the patch module creates each
of its children using the same three-steps process used for creating the element itself.
