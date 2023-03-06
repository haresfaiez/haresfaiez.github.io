---
layout:   post
comments: true
title:    "How Monaco handles file content: Initialization"
date:     2022-10-16 12:02:00 +0100
tags:     featured
---

[Monaco](https://github.com/microsoft/monaco-editor) is an open-source online editor.
You can try it [here](https://microsoft.github.io/monaco-editor/playground.html).
Its core is quite extensible.
Contributors made interesting decisions to provide fluid experiences.
The core creates a minimal editor,
the equivalent of a tab body in common editors.
We plug in addons to open files, analyze their content,
and define language syntax.

Getting files ready for change is critical.
We navigate projects frequently to build mental pictures.
We need code to be colored, indentation levels to be specified,
and brackets to be matched as soon as possible.


## Storing the code
`TextModel` is the main class here.
It takes a source code string and puts it inside a `Buffer` instance,
without splitting it into lines.
To access a line, it uses `String.substring(lineStartIndex, lineStartIndex + lineLength)`.
The model also iterates over the code character by character looking for line endings.
It stores the line indexes inside the same `Buffer` instance.

Code later is changed with structured operations.
Each one of them is composed of a text string and a range.
The range specifies the boundaries.
It contains two pairs of line-column indexes.
The text replaces the content between the boundaries.

To apply editions, the buffer starts by normalizing line endings.
Then, if some ranges overlap, it merges them.
It builds undo operations. These are used to cancel current updates.
Finally, it changes the content.


## Storing metadata about the code
In addition to `Buffer`, `TextModel` calculates snapshots of the code.

### Tokens model
The initialization process builds a tokens model in the background.
The tokenization process extracts tokens line by line, using
a language-specific tokenizer.
We get an array of lines at the end.
Each element in it references the tokens of a line.

Taking into account that a token might span across multiple lines,
a token is defined as a two-elements array.
The first element tracks the index of the token in the line,
and the second one represents metadata about the token.
Token metadata is a bit string with information about its type.

### Brackets model
The initialization process builds a brackets model in two iterations.
The process for creating both versions is the same
and the output is always a brackets pairs tree.

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

A `FastTokenizer` is used during the first iteration.
A language-specific tokenizer is used during the second.
In a such tree, a head is a pair of opening-closing brackets,
(their line-column indexes inside the buffer).
Its children are subtrees representing enclosed pairs of brackets.

During tokenization, the tokenizer assigns an id to each opening bracket token and attaches
the ids of previously opened brackets to each closing bracket token.
To create a brackets tree, the parser reads the tokens one by one.
When it encounters an opening bracket,
it keeps it as a head and starts building subtrees until it encounters
the closing bracket referencing the same id.
It then continues building a node for the head and moves on to adjacent heads.

### Indentation guides model
Unlike other models, this one does not keep track of any values.
It's used by the view model to compute indentation levels on the fly.
Its main functions return the indentation levels in a given
range of lines and figure out the number of lines with the next indentation level
after a given line.


## Notes on the code
The design makes it complicated to know what's happening.
To instantiate the buffer, a factory creates a builder that creates a factory that creates the buffer.
Most classes share a lot of attributes.
A huge part of the code is just creating classes with values received in the parameters.

Some methods execute a few lines and then delegate to a private method with a similar name.
The builder, `PieceTreeTextBufferBuilder` has methods named `acceptChunk`, `_acceptChunk1`,
`_acceptChunk2`, `finish`, and `_finish`.

Updating the buffer is done mostly in one giant method with over 171 lines.
`PieceTreeTextBuffer.applyEdits` covers the steps mentioned previously.
Each step has a distinct bloc with quite a complicated logic and interacting objects.
Here also, we delegate changing the buffer to a helper method, `this._doApplyEdits`, which itself
delegates insert/delete atomic operations to a `PieceTreeBase` instance.

I have seen these patterns a lot. I used them. Sometimes, I regret designing systems this way.
Other times, such patterns offer great flexibility for future change.
It's not simple to judge whether they are the right decisions or not.

From the point of view of someone exploring the code, having small classes and short methods,
a logic that's scattered everywhere, many names to memorize, and many concepts,
is a burden.
On the other side, having one big method makes it hard to understand what's happening without checking
the whole method.
