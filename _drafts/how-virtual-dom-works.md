
There are two principal operations:

  * **Diff**
  Here, the library compares two virtual DOMs. That is it, two
  strutures, each representing a DOM snapshot.
  Nothing here has to do with the real DOM.
  *Thunk* is used to take control over the diff calculation of
  two elements.
  The output of this operation is a Json object containing the former
  virtual DOM root element and the array of patches (the differences
  that, when applied in order, gives the latter virtual DOM).
  ```
  {
    a: leftNode,
    0: replaceNode
    1: nodePatch -> replaceNode
	2: thunkSubPatch -> { // Either a or b is a thunk here and there are patches after applying the thunk
	     a: vdom-a,
		 0: replaceNode
	   }
  }
  
  Diff = {
   a    : VDom
   [0..]: Command
  }
  Command = Thunk Diff // difference after applying the thunk
		| Remove Old // Remove the old branch, branch to nothing diff [[ AFTER clear former element ]]
		| Props FormerNode [{hookKey: underfined}...] // assign "undefined" to each hook key [[ WHILE clearing node state ]]
		| Text FormerNode NewNode // When the new element is a VText with a different text [[ BEFORE clearing former element (if it is not a text, obviously since clearing a text is a noop) ]]
		| Widget FormerNode NewNode // The new element is a widget [[ BEFORE clearing the former element if it is not a widget ]]
		| Node FormerNode NewNode // The new element is a node with different (tag, namespace, key) [[ BEFORE clearing the former element ]]
		| Props FormerNode [PropsPatch]
  PropsPatch = Name x (Removed | New Value | Updated Value)
		
  ```
  To find the difference in the children:
    * Reorder the new tree
	* 
	
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
  A F1 K1 F2 F3 K2   K3

  N F4 K1 F5 F6 Null K3 K4 >> return

  B K1 F4 F5 K3 F6 K4     || wanted
  S F4 F5 F6 K3     || simulate

  S F4 F5 F6 Null K3 K4     || simulate

  S F4 K1 F5 F6 Null K3 K4     || simulate
  
  push(K1.key, 0)
  remove(1, K1.key)
  push(K3.key, 3)
  remove(3, Null)
  remove(3, K3.key)
  remove(4, K4.key)
  push(K4.key, 5)
   
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

  For the difference between two props, we put *Updated* when:
    * the former and the new node have properties with different value
	* both are object, but with different *.__proto__
	* the new value is a hook
	* the difference between the former and the new object as a value if the new is not a hook and the two objects have the same prototype

  When the former and new node have the same tagname, namespace, and key, we compare the properties (Props command) and the children.

  Some edge-cases exists while removing a branch(a sub-tree), a VDom element as
  we need a reference to all widget elements (to remove safely in the patch operation,
  because widgets have a destroy function)
  :
    * a widget/text element is removed with a single remove command
	* a node needs to be cleared first, clear means:
	  * record a remove command for each widget child
	  * record a thunk command for each thunk child
	  * record a props command with undefined hook keys for each sub-[sub-]element with hooks
	  
    NB: note that for each command record, the index is incremented

  The keys below the 'a' key are numbers, and the value of each
  key is a diff or a set of diffs.
  While building the diff output, we increment the index when:
    * we remove a child widget (index + 1)
    * we remove a child with direct(non-descendent) hooks (index + 1)
	* we insert a node from b
	* we analyse a child node

  * **Patch**
  Here, we take the structure resulting from the diff operation
  and we apply it to the real dom.
  We use *Widget* to specify how the translation from the virtual DOM
  to the real DOM should go.
