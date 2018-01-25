

React calls the diffing algorithm the reconciliation algorithm.

React, too, uses two main modules, the diff and the patch.
diff module Fiber? is called reconlciler (reconcilation) and the patch module
is called renderer and applying a patch is called "flushing".
Although React has many renderers, a DOM renderer for web applications, an Android renderer
and an ios renderer for React native.
React is wired such that you can attach your own renderer.

**Diff module vs. Reconcilation & Fiber**

The building blocks of "virtual-dom" are virtual DOM elements. A virtual DOM element is
a json object that contains the type of the element, its properties, and its children.
The diff module requires one virtual DOM element, the root element.
The tree of elements under the root needs to be complete.
Meanwhile, React reconcilation module takel the root *component*.
A component in React may be a class or a function, never a data structure.
So, when the reconcilation moules receives the root component, it might call
```javascript
component.render()
```
on the root and its children respectively.
This opens a room for optimization that Fiber seeks to leverage.

To create a renderer: 
Reconciler(rendererSettings)

A component in React has a "render()" method. That method returns a virtual a virtual DOM structure.
The reconciler computes the difference between the return and the existing element virtual DOM.
It, finds, a set of transformations.
The reconciler, then, uses the renderer to apply the transformations.
Mainly the messages, are adding and removing children to a component instance.
Mind you, the component class uses the primitive medium api (e.g. the DOM api) to display the component.
The renderer uses the component instances, the Fiber in (attached to the instance), to display the component.

"An element is a plain object describing a component instance or DOM node and its desired properties.
It contains only information about the component type (for example, a Button), its properties (for example, its color), and any child elements inside it.
[...] it is a way to tell React what you want to see on the screen."
[Elements Describe the Tree](https://reactjs.org/blog/2015/12/18/react-components-elements-and-instances.html#elements-describe-the-tree)

An element can be, for example, a DOM element (it maps directly to a HTML tag) or a component element (it maps to a component that have its own mapping to primitive display).
So, a component is aware of the target display, the element is don't.
**The renderer uses the component class/instance to display the view on the screen, it knows whether to expect an element or nothing as a return of render()**
The component may return an element in its render method.
It may as well return nothing and calls the primitive display api directly.

Here is the question now.
The reconciler finds the transformations and calls the renderer.
The render recieve instances of components and either calls methods on them or uses the return of their render() method and dispaly it itself.
How does the reconciler finds the difference between two component instances?

in the config injected into the Reconciler, you manage component instances using the Component class api.
The input is element(s) using React.createElement(), JSX, or an element factory helper.
Here is the thing. There are host components and non-host components. Non-host component are a composition of host and non-host components.
These are managed by react. You only define their structure.
Host components, on the other side, needs to be defined by you.
You use the primitive display api to define how they are rendered.

element:json-> component:class-> instance:object
[user]      -> [reconciler:createInstance] 


input -> reconciler -> output
element:json -> components instances tree:
**componentInstance.children is set by the reconciler**

The question is: if the render method does not return an element, how can we compute the diff?

"In concrete terms, a fiber is a JavaScript object that contains information about a component, its input, and its output."
[Structure of a fiber](https://github.com/acdlite/react-fiber-architecture#structure-of-a-fiber)
fiber = stack frame/instance of a component.

As said here
https://reactjs.org/docs/reconciliation.html
a full diffing requires O(n^3) operations.
https://grfia.dlsi.ua.es/ml/algorithms/references/editsurvey_bille.pdf

- "virtual-dom" uses n types of elements (text, node, widget, ...), while React uses
  types to highlight a difference between tags.
  So we have types: img, button, div.
  
  React has that component/element/instance separation.
  Instances are always handeled by the library.
  Also, on update, React keeps the component state while "virtual-dom" uses widgets to pass
  state.
