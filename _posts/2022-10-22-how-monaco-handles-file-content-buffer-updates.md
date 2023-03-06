---
layout:   post
comments: true
title:    "How Monaco handles file content: Buffer updates"
date:     2022-12-04 19:38:00 +0100
tags:     featured
---

Code in Monaco is stored as a tree inside
the [buffer](/2022/10/16/how-monaco-handles-file-content-initialization.html).
Initially, the tree contains one node that manages the given text.
Later, as the user writes code, more nodes are added.
Insertions and removals are structured.
Each one of them is defined by a range and a text string.
Updates are factored into deletions and insertions.

Here's a simplified version of how Javascript formatters work.
They ask a language service for the formatted lines, and they build an array of edits:
```javascript
const edits = jsLanguageService.getFormattingEditsForRange(
  jsDocument.uri,
  jsDocument.offsetAt(range.start),
  jsDocument.offsetAt(range.end)
);

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
The content is structured as a [red-black tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree).
This tree is created with one node.
As the code changes, children are spawned.
Left-side children manage the first lines,
parents manage the next,
and right-side children take care of the last ones.

A node finds the next lines by calling `this.next()`,
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

A node does not store the lines inside a string.
The implementation favors performance.
It tries to avoid extensive string manipulation.
The class keeps track of an array of strings, named `_buffers`.
Each node references an element inside that array, an index of the first
character inside that element, and a length.

A node also contains
`lf_left` (the number of line feeds inside the left child)
and `size_left` (the number of characters inside the left child),
the length of the code it manages, and the indexes of its line beginnings.
Such attributes simplify the lookup for the node managing a given offset.

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
Tree-related operations, such as removing/inserting a node
and balancing a part of the tree, are idiomatic
[red-black tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree#Operations) operations.

Delete and insert operations change the shape of the tree.
If we add a line at the beginning,
we'll have to update `lf_left` and`left_size` of its ancestors after inserting its new node.
And when we delete the tail of a node,
we have to update the number of lines and the size of the code in that node.


## Deletion
```javascript
delete(offset: number, cnt: number)
```

Deletion is simpler than insertion. There are fewer constraints to consider.
If the removal target fits well within a node boundary, we remove the node.
If it's at the beginning or the ending of the region managed by a node,
we update the start index or the length referencing the element inside `_buffers`.

If the deletion target is in the middle of the region referenced by a node,
the node is split in two.
We remove it and insert two nodes in place.
One will contain the code preceding the deletion,
and the other the code following it.

If a deletion involves more than one node,
it will be transformed into three atomic operations:
one to remove the tail of the first node,
one to remove the head of the last node,
and one to remove the nodes in between.


## Insertion
```javascript
insert(offset: number, value: string, eolNormalized: boolean = false)
```

As with deletion, the first step is to find which node manages the target offset.
Usually, the value is not so long and we proceed to insert it directly.
If not, if the value is longer than `AverageBufferSize` (Defined as `65535`),
we split it into smaller parts and we insert them one by one.

The tree defines two methods for adding nodes, `rbInsertRight` and `rbInsertLeft`.
As their names suggest, the first inserts a node as a right child,
and the second inserts it as a left child.
The first inserts a text after a given offset. The second one inserts it before.
Both take as input a node from the tree and a string.

Internally, each of them creates a `TreeNode`, puts it in the tree, updates
children/parent references of the surrounding nodes, updates parents' metadata,
and balances the tree.
In most cases, we use `rbInsertRight`.
We use `rbInsertLeft` only when the tree is empty and when we need to insert text
just before the beginning of a node.

If the offset is exactly at the ending, we create a new node with value and insert it.
If the offset is in the middle, we delete the code after the offset inside that node.
We create a node with the deleted value.
Then, we insert a node with the deleted value and another with the passed value after the target node.
