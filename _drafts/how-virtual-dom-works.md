Many web applications, now, are concieved as an aggregation of components.
Each component owns a part of the screen.
Components are rarely static. They change style, content, and structure.

React is designed such that the view associated with each component is immutable.
When something changes in a component, the library removes the old view from the page,
creates a new view for the component, and puts the new view in.
When applied direclty to the DOM, the first and the last operation incurs
a significant cost.
In fact, each of these causes the browser to redraw the whole page.

One solution to cope with that cost is the virtual DOM.
Virtual DOM allows us to be generous with regard to changing
the structure of the document while optimizing the modification of the primitive DOM.
A virtual DOM-based application uses the virtual DOM API to
modify the structure of the document.

I use "primitive DOM", here, when I talk about the real DOM (the one
used by the browser to display the page) and "virtual DOM" when I talk about
the structure represented by "virtual-dom".

To update the document:
	* Create the virtual DOM of the result structure
	* Find the set of atomic operations (patches) that transforms the initial
	  primitive DOM into a result primitive DOM structure
	* Apply the patches to the existing primitive DOM

I will try to dig inside "virtual-dom", an impelemntation of the virtual DOM.
I will go through the implementation of the "diff" module
that generates a set of patches and the "patch" module that applies the patches to
the initial structure.

There are two principal operations:

  * **Diff**
  The "diff" module takes two virtual dom elements (the initial and the result,
  I call them the source and the destination) and produces a set of patches.

  The output of this operation is a Json object containing the source
  virtual DOM element and the array of patches (the differences
  that, when applied in order, transforms the source to the destination).
  A virtual DOM element may have properties and children.

  ```
  Diff = {
   source : VDom,
   patches: Transformation[]
  }
  ```

  There are 6+1 types of transformations:
    *Text*
	This is used when the second element is a text.
	When we compare any source element to a text element, we remove the whole source
	and we put the destination text instead.
 
	*Node*
	This is used to insert a new node, when the destination element is a node.
	A node element might contains properties and children.
	So, when the source element node and the destination element node are different
	or the source is not a node at all, we use this transformation.
	When the source root element and the destination root element are the same,
	we go on and look at the difference between their properties and children.
	A *Node* transformation does not allow the replacement of a source node by
	a destination node. It just append a node.
	We use a collection of *Remove* transformations and one *Node* transformation
	if we need to replace a source node with a different destination node.
 
	*Remove*
	You might be wondering why we need multiple *Remove* transformations
	when we need to replace one node with another.
	One *Remove* transformation is needed to destroy an element and its children.
	But, when the source element contains some widget elements somewhere between its
	children, one *Remove* transformation per widget is required.
	Indeed, a widget element is destroyed by calling their "destroy" method.
 
	*Insert*
	This transformation is used when we have a destination Virtual DOM element,
	but no source Virtual DOM element.
	The subject of the insertion can be a node, a text, or a widget.
	The difference between the effect of *Insert* and other transformations
	such as *Node*, *Text*, and *Widget* is in the effect during the patch phase.
	*Insert* trigger in an "domParent.appendChild" while others calls for a
	"domParent.replaceElement", taking the former element into account.
  
	*Order*
	To understand what *Order* means, we need to take a look at the piece of code responsible
	for calculating the difference between the children of two similar elements.
	A source element and a destination element are considered the same if both have the
	same tagname, key, and namespace.****
	Here are two facts about the implementation:
	  * A virtual DOM element, as is a primitive DOM element, is a tree.
	    Physically, "virtual-dom" puts the children of an element in an array inside
	    the element data structure.
	  * Some elements have a key that identify each element globally. When we modify an
	    element with some children that have keys, we need to compare the children with the
	    same key against each other when we calculate the difference.
	The difference between the children of two elements is calculated by iterating over each
	children array and comparing the elements with the same indexes in the two arrays.
	In order to compare two elements with the same key with each other, we need them at
	the same index. Hence, we change the order of the destination element children and
	we add the operations that transform the reordered arrays to the given destination
	element array as an *Order* transformation.
	Here is an example: ****
  
	*Props*
    When the source and the destination elements are similar -that is it, they have the same tagname,
	namespace, and key, we compare the properties in addition to their children.
    For the difference between two props, we put *Updated* when:
      * the former and the new node have properties with different value
  	* both are object, but with different *.__proto__
  	* the new value is a hook
  	* the difference between the former and the new object as a value if the new is not a hook and the two objects have the same prototype

	*Widget*
	This is used when the destination element is a widget.
  
    *Thunk*
	This type is handled differently. Indeed, ...
	This used to take control over the diff calculation of
	two elements.
	*Remove* could be used on all element types except *Thunk*.
	

  ```
  Patch = Thunk Diff // difference after applying the thunk
		| Remove Old // Remove the old branch, branch to nothing diff [[ AFTER clear former element ]]
		| Text FormerNode NewNode // When the new element is a VText with a different text [[ BEFORE clearing former element (if it is not a text, obviously since clearing a text is a noop) ]]
		| Widget FormerNode NewNode // The new element is a widget [[ BEFORE clearing the former element if it is not a widget ]]
		| Node FormerNode NewNode // The new element is a node with different (tag, namespace, key) [[ BEFORE clearing the former element ]]
		| Props FormerNode [{hookKey: underfined}...] // assign "undefined" to each hook key [[ WHILE clearing node state ]]
		| Props FormerNode [PropsPatch]
  PropsPatch = Name x (Removed | New Value | Updated Value)
		
  ```
  To find the difference in the children:
    * Reorder the new tree
	  Some nodes have a key(a unique identifier), the element that have a key and that exists in the initial and the result
	  tree must stay the same. We move them, and we don't recreate them.
	  The children diff module, starts by transforming the new tree into a new data structure containing a new organization and how to get from there to the orginal organization:
	    {new element with the indexes of  keyed elements follows the initial tree, {moves to tranform the left-side tree into the result tree}}
	  So that diff are run for elements with teh same keys (as we use two arrays for trees) than, in the patch, we reorder the trees.
	
  The reorder return the following structure: 
  ```
  {
    children: Ordered-b-childen
	moves: {
	  removes: {from: indexInSimulte(simulate is newChild without null entries), key: itemKey(vDom element key)}[],
	  inserts: {key: keyInTheInitialTree(vDom key in bChildren), to: }[]
	}
  }
  ```
    * The result of the reorder is a set of commands you apply to the newChildren to got the tree-b
  
    * push remove when:
	  * the tree-result element is null
	  * the tree-result element has a key, but the tree-b element don't
	  
    * push insert when:
	  * the tree-result element has
	  * the tree-b element has a key, but the tree-result element don't
  
  How reorder works:
    * Make tree-a and tree-b symmetric (same element with same key at the same index) in tree-result
	* add elements that exists solely in tree-b (keyed and extra-free elements) to tree-result
	* compare tree-result and tree-b
  
  To reorder the new tree:
    * return the new tree and no moves if none of the two trees contains a key-associated child
	* 0. Create a children array from the latter elements, but in the order(same key at the same index) of the former
	  1. Replace removed keys and gaps with null in the latter array (end up with a result array with the same size as the former array)
	  2. Add extra elements that exists only in the result array


  * **Patch**
  The "patch" module takes a set of patches and the primitive DOM element associated
  with the source virtual DOM element and produces a primitive DOM associated with
  the destination virtual DOM element.
  We use *Widget* to specify how the translation from the virtual DOM
  to the real DOM should go.
