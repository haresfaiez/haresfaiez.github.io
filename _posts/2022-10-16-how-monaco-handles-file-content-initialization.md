---
layout:   post
comments: true
title:    "How Monaco handles file content: Initialization"
date:     2022-10-16 12:02:00 +0100
tags:     featured
---

[Monaco](https://github.com/microsoft/monaco-editor) is an open-source online editor.
You can try it [here](https://microsoft.github.io/monaco-editor/index.html).
Its core is quite extensible.
Keeping that in mind, contributors made interesting decisions to provide fluid experiences.
The core creates a minimal editor,
the equivalent of a tab body in common editors.
We can later plug addons to open files, analyze their content,
and define programming language syntaxes.

## Storing the code

Getting a newly opened file ready for change is a critical feature.
When we code or explore a new codebase, we go up and down regularly to build mental pictures.
There must be a way to get fast feedback.

`TextModel` is the default class for creating the core.
It takes a string containing a code source and maps it to a buffer instance.
Internally, the code is kept as a single string.
The model does not split it into lines.
To access a line, it uses `String.substring`.

During initialization, the model iterates over the code character by character
and looks for line beginnings. It stores the indexes of all the lines inside an array.
Then, it normalizes line endings to either `\r` or `\r\n`.
The array of indexes and the normalized string are the main attributes of the buffer.

To change the code, the buffer accepts a list of operations.
Each one is composed of a new text and a range.
The range contains two pairs of line-column indexes of the boundaries.
The text is a string that replaces the content inside the boundaries.

During an update, the buffer first normalizes the line ending.
Then if some operations range overlap, it merges them into operations with larger ranges.
It builds undo operations that can be used to cancel the current update.
Finally, it changes the current content.

The code for the last step is this:
```
if (op.text) {
  // replacement
  this._pieceTree.delete(op.rangeOffset, op.rangeLength);
  this._pieceTree.insert(op.rangeOffset, op.text, true);
} else {
  // deletion
  this._pieceTree.delete(op.rangeOffset, op.rangeLength);
}
```

`pieceTree` is a tree that contains the buffer chunks.
During initialization, this tree usually contains one chunk for the given source code.
We'll talk more about this tree in the next post.

### Notes on the code

The design of the code makes it complicated to know what's happening.
To instantiate the buffer, a factory creates a builder that creates a factory that creates the buffer.
Most of the classes share many attributes.
A huge part is just creating classes with values received in the parameters.

Some methods execute a few lines and then delegate to a private method with a similar name.
The builder, `PieceTreeTextBufferBuilder`, itself has methods like `acceptChunk`, `_acceptChunk1`,
`_acceptChunk2`, `finish`, and `_finish`.

Updating the buffer is done mostly in one giant method with over 171 lines.
`PieceTreeTextBuffer.applyEdits` covers the steps mentioned previously.
Each step has a distinct bloc with quite a complicated logic and interacting objects.
Here also, we delegate changing the buffer text to a helper method, `this._doApplyEdits`, which itself
delegates insert/delete atomic operations to a PieceTreeBase instance.

I have seen these patterns a lot. I used them. Sometimes, I regret designing systems that way.
Other times, such patterns offer great flexibility for future change.
It's not simple to judge whether they are the right decisions or not.

From the point of view of someone exploring the code, having small classes and methods,
a logic that's scattered everywhere, many names to memorize, and many concepts
are a burden.
On the other side, having one big method makes it hard to understand what's happening without checking
the whole method.

## Storing metadata about the code

In addition to the buffer, TextModel calculates snapshot values from the buffer.

### Tokens model

The initialization process pairs opening-closing brackets
and builds a tokens model in the background.
The tokenization process extracts tokens line by line using
a programming language-specific tokenizer.
As a result, we'll have an array of lines.
Each element keeps track of the tokens inside a line.

Taking into account that a token might span across multiple lines,
a token will be defined as a two-elements array.
A first element tracks the index of the token in the line,
and a second one represents metadata about the token.
Token metadata is a bit string with information about the token type and language.

### Brackets model

The initialization process builds a tree in two iterations.
The process for creating both versions is the same.
The output is always a brackets pairs tree.

As the documentation says:
```
There are two trees:
 * The initial tree that has no token information and is used for
   performant initial bracket colorization.
 * The tree that used token information to detect bracket pairs.

To prevent flickering, we only switch from the initial tree to
tree with token information when tokenization completes.
Since the text can be edited while background tokenization is
in progress, we need to update both trees.
```

In a such tree, each head is a pair of opening-closing brackets,
(their line-column indexes in the buffer to be accurate).
The children are subtrees representing enclosed pairs of brackets.

During tokenization, the tokenizer assigns an id to each opening bracket token and attaches
the ids of previously opened brackets to each closing bracket token.
To create a brackets tree, the parser reads the tokens one by one.
When it encounters an opening bracket,
it keeps it as a head and starts building subtrees until it encounters
the closing bracket referencing the same id.
It then builds a node and moves on to adjacent heads.

A `FastTokenizer` is used to build the first iteration.
A language-specific tokenizer is used for the second.
We'll talk about tokenizers and language addons in a future post.

### Indentation guides model

Unlike other models, this model does not keep track of values
but calculates them on the fly.
It's used by the view model to display code
as it computes the indentation level in given lines.

Its main functions are the indentation levels of the lines in a given
range of code and figuring out the range of the next indentation level for
a given line.
