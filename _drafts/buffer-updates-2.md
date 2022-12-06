---
layout:   post
comments: true
title:    "How Monaco handles file content: Buffer updates"
date:     2022-12-04 19:38:00 +0100
tags:     featured
---

Responsiveness is a critical feature of editors.
We expect tokens to be formatted and colored instantly
after writing the code.
In Monaco, updates are structured.
Each one is defined by a range and a new text.

These updates can be validated and then passed to `pushEditOperations`.
A worker will execute them asynchronously when available.
They can also be passed to `applyEdits`,
which applies them instantly,
but without adding them to the undo/redo stack.
We'll talk about these more in a future post.

As an example, here's a simplistic version of how Javascript formatters code.
They interact with a language service and then build an array of edits:
```javascript
const edits = jsLanguageService.getFormattingEditsForRange(
  jsDocument.uri,
  jsDocument.offsetAt(range.start),
  jsDocument.offsetAt(range.end)
); // More about language services in a future post

for (const edit of edits) {
  result.push({
    range: Range.create(
      jsDocument.positionAt(edit.span.start),
      jsDocument.positionAt(edit.span.start + (edit.span.length || 0))
    ),
    newText: edit.newText
  });
}
```


## PieceTreeBase

The content is structured as a red-black tree.
Each node manages a couple of lines.
The tree is created with one node.
As the code changes, children are spawned.
Left-side children manage the first lines,
parents manage the next,
and right-side children take care of the last.

A node finds the next lines with the method `next`,
which can be implemented as:
```javascript
public next(): TreeNode {
  if (this.right) {
    return leftest(this.right);
  }

  let node = this;
  while (node.parent) {
    if (node.parent.left === node) {
      break;
    }
    node = node.parent;
  }
  return node.parent;
}

```

The implementation avoids extensive string manipulation.
A node does not store the code lines string.
The tree keeps track of an array of strings, named `_buffers`.
Each node references an element in this array, an index of the first
character in that element, and a length.
That way, two nodes may reference the same element,
each managing a part.

A node also contains
`lf_left` (the number of line feeds inside the left child)
and `size_left` (the number of characters inside the left child),
the length of the code it manages, and the indexes of line beginnings.
Such attributes simplify the lookup for the node managing a given offset.

Deletion and insertion operations on offsets to reference target areas.
We need methods to map between offsets and the lines/columns.
To find the coordinates of a given offset, we look for a node
where `size_left` is less than the target offset but where `size_left + codeLength`
is greater.
The line will be the sum of `lf_left` and the number of lines from the beginning
of the node to the target offset.
The column will be the remaining characters inside that line.

Going the opposite way is also simple. We rely on `lf_left` to find
the node managing a given line.
We return the sum of `size_left`,
the index of the line containing the offset, and the column index.

These operations are fast.
Most searches are binary searches.
Finding a node can be an `O(log(n))` operation.
Tree-related operations such as removing/inserting a node
and balancing a part of the tree are idiomatic red-black tree operations.


## Deletion

```javascript
delete(offset: number, cnt: number)
```

Deletion is simpler than insertion. There are fewer constraints to consider.
If the removal target fits well with node boundaries,
the node is removed.
If it happens to be at the beginning
or the ending of the region managed by a node,
we update the start index or the length referencing `_buffers` element.

A quite complicated situation occurs when the deletion target is in the middle of
the region referenced by a node.
Here the node is split in two. Internally, it's removed.
Two nodes are created and inserted next to their parent.
One will contain the code preceding the deletion,
and the other the code following it.

If a deletion involves more than one node,
it will be transformed into three atomic operations:
one to remove the tail of the first node,
another to remove the head of the last node,
and then last one to remove the nodes in between.


## Insertion

```javascript
insert(offset: number, value: string, eolNormalized: boolean = false)
```

Usually, the value is not so long and insert it directly.
If not, we split it into smaller parts,
and we insert them one by one.

As the comment says, if the value is longer than `AverageBufferSize` (Defined as `65535`)
```javascript
// the content is large, operations like substring,
// charCode becomes slow // so here we split it into
// smaller chunks, just like what we did for CR/LF normalization
```

As with deletion, the first step is to find which node manages the given offset.
If the offset is exactly at the ending, we create a new node with value
and insert it.
If the offset is in the middle,
we delete the code after the offset in that node.
We create a node with the deleted value and insert it after the target node.
Then, we insert the passed value also after the target node as well.

The tree defines two methods for adding nodes, `rbInsertRight` and `rbInsertLeft`.
The first inserts a text after a given offset, and the second inserts it before.
Both accept a node from the tree and content to insert.
As their names suggest, the first inserts a node as a right child,
and the second inserts it as a left child.

Internally, each of them creates a `TreeNode`, puts it in the tree, updates
children/parent references of the surrounding nodes, updates parents' metadata,
and balances the tree.
In most cases, we use `rbInsertRight`.
We use `rbInsertLeft` only when the tree is empty or when we need to insert text
just before the beginning of a node.

## Normalizing line endings
An important observation is that the code responsible for managing line endings
is intertwined with the logic. It's not easy to reason about how line endings
are normalized. Logic is everywhere.
And, it has a huge performance cost.

After updating a node,
if the updated node ends with `CR` and its previous node starts with `LF`,
we call `validateCRLFWithNextNode`. We pass it to the node preceding a deleted node
or a node we just deleted the tail.

If the node ends with `CR` and its next node starts with `LF`,
we call `validateCRLFWithPrevNode`.
This method is used frequently.
We call it with the node we just deleted the head,
with the next node of a just-deleted node,
with the last inserted node when deleting code from the middle of a node,
and with the last inserted node after inserting text to node beginning or end.

Both functions remove the last character of the first node
and the first character in the next one.
Then, they insert a new node referencing a normalized line ending in between.


## Keeping metadata up-to-date

Delete and insert operations change the shape of the tree.
If we add a line at the beginning, we'll create a node and insert it into the left-most
child of the tree.
We'll have to update `lf_left` and`left_size` in its parents.
Same when we delete the tail of a node,
we have to update the number of lines and the size of the code in that node.

`updateTreeMetadata` and `recomputeTreeMetadata` update
parents metadata (`lf_left` and `left_size`) of a given node.
We call `updateTreeMetadata` when we know the amounts with which to change
the metadata, and we call `recomputeTreeMetadata` when we don't.

`recomputeTreeMetadata` looks for a parent of the node whose a left-child of its parent.
It updates `lf_left` and `size_left` of the grandparents.
We always call it with a just-inserted node
or with a node taking the position of a just-deleted node.
As in both situations, we don't know the length delta difference.

`updateTreeMetadata` is called with a node, a delta for the number of added characters,
and a difference in the line count.
It adds the deltas to `lf_left` and `size_left` of the parents recursively as long as
the parents are left-side children of their parents.


-## Cache
-
-At the end of both delete and insert operations, we call this._searchCache.validate??
-
-- When we update search cache?
-- why do we nede/use this._lastChangeBufferPos?
-the cache is an array of cache entries. Each entry contains mainly a node, its first
-character offset in the whole buffer.
-This cache can be used to fasten the operation of getting the node responsible
-for a given offset in the buffer whitout iterating over the whole tree.
-when the cache is updated?
