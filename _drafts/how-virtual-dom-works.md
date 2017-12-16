Many web applications now are concieved as an aggregation of components.
Each component owns a part of the web page.
Components are rarely static. They change their style, content, and even their structure.

React is designed such that the views of components are immutable.
From a library client perspective, when something needs to change inside a component,
the library creates the new view of the component, it removes the old view of that component
from the page, and it puts the new view in.
If we apply these operations directly to the DOM, a decrease on the performance of the web
application becomes inevitable.
In fact, each one of these causes the browser to redraw the whole page.

One solution to cope with that cost is the virtual DOM.
"virtual-dom" is an implementation of a collection of ideas that
allows us to be generous with changing the structure of the document
while relying on the library to optimize changes to the original DOM.

Here, I will try to dig inside "virtual-dom", an impelemntation of the virtual DOM.
I will try to go through the implementation of the "diff" algorithm
that generate the patches and the algorithm that applies the patches to
the initial structure.

A "virtual-dom" based application uses the "virtual-dom" API to
modify the structure of the document.
To update the document:
	* Create the result structure
	* Find a set of atomic operations (patches) that transforms the initial
	  structure into the result structure
	* Apply the patches to the existing structure

I will use "primitive DOM" when I talk about the real DOM (the one
used by the browser to display the page) and "virtual DOM" when I talk about
a structure represented by "virtual-dom".

There are two principal operations:

  * **Diff**
  The "diff" algorithm takes two virtual dom elements (the initial and the result,
  I will call them the source and the destination)
  and produces a set of patches.

  The output of this operation is a Json object containing the former
  virtual DOM root element and the array of patches (the differences
  that, when applied in order, gives the latter virtual DOM).

  ```
  Diff = {
   source : VDom,
   patches: Patch[]
  }
  ```
  The keys below the 'a' key are numbers, and the value of each
  key is a diff or a set of diffs.
  While building the diff output, we increment the index when:
    * we remove a child widget (index + 1)
    * we remove a child with direct(non-descendent) hooks (index + 1)
	* we insert a node from b
	* we analyse a child node


  Each patch in the result has a type.
  I will go through the possible types one by one.
    *Text*
  
	*Node*
  
	*Remove*
    Some edge-cases exists while removing a branch(a sub-tree), a VDom element as
    we need a reference to all widget elements (to remove safely in the patch operation,
    because widgets have a destroy function):
      * a widget/text element is removed with a single remove command
  	* a node needs to be cleared first, clear means:
  	  * record a remove command for each widget child
  	  * record a thunk command for each thunk child
  	  * record a props command with undefined hook keys for each sub-[sub-]element with hooks
  	  
      NB: note that for each command record, the index is incremented
  
	*Insert*
  
	*Reorder*
  
	*Props*
    For the difference between two props, we put *Updated* when:
      * the former and the new node have properties with different value
  	* both are object, but with different *.__proto__
  	* the new value is a hook
  	* the difference between the former and the new object as a value if the new is not a hook and the two objects have the same prototype

    When the former and new node have the same tagname, namespace, and key, we compare the properties (Props command) and the children.
  
	*Widget*
  
    *Thunk*
	This used to take control over the diff calculation of
	two elements.
	

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
	  The children diff algorithm, starts by transforming the new tree into a new data structure containing a new organization and how to get from there to the orginal organization:
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
  The "patch" algorithm takes a set of patches and the primitive DOM element associated
  withe the initial virtual DOM structure and produces a primitive DOM element.
  Here, we take the structure resulting from the diff operation
  and we apply it to the real dom.
  We use *Widget* to specify how the translation from the virtual DOM
  to the real DOM should go.
