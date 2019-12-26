---
layout:   post
comments: true
title:    "UglifyJS internals, overview"
date:     2019-12-25 18:11:00 +0100
tags:     featured
---

[UglifyJS](https://github.com/mishoo/UglifyJS2) is Javascript source code optimizer.
It compresses Javascript source files so that code travels faster across the network.
UglifyJS takes as an input the content of a file, the aggregation of the content of many files,
or a string, and gives back the compressed code and a source-map file.

As I am exploring the library code, I am writing this post to clarify the big picture of
how Uglify works. I will iterate on it as understand the code more.
The detailed documentation of UglifyJS is on [Mihai Bazon's blog](http://lisperator.net/uglifyjs/).
It gives you a closer look at the implementation of the concepts explained here.

## AST
UglifyJS builds an [Abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) (AST)
 to represent the source code. It is a convenient structure to operate on the input.

UglifyJS defines a class named `AST_${typeName}` for each AST node type.
For example, the definition of a function is represented by an instance of `AST_SymbolDefun`,
and a node representing a string literal is an instance of `AST_String`.
You can find the definition of AST node types and their documentation under
[`lib/ast.js`](https://github.com/mishoo/UglifyJS2/blob/master/lib/ast.js).

AST node types have properties and methods.
Some properties and methods are shared between all AST node types, like `start`, `end`,
`walk()`, and `clone()`.
Others, like `getProperty()` on `AST_PropAccess`, are type-specific.

AST node types are organized into a hierarchy to eliminate code duplication and
to simplify the code checking for the type of node instances.
The root of this hierarchy is `AST_Node`.
It has two properties, `start` and `end`, which represent the boundaries
of the node in the source code.
But, it should not be instantiated. Only the leaves should be.
For example, a string literal `AST_String` and a number literal `AST_Number`
have the same parent `AST_Constant`.

To create an AST node, you instantiate a specific AST node type with the required properties.
The string literal has two properties on its own.
A value; the string itself, and a quote (`"` or `'`); the quotation used in the input.

So, to represent the string
```
"Hello Uglify!"
```
you need
```
new AST_String({
  value : 'Hello Uglify!',
  quote : '"',
  start: new AST_Token({...}),
  end: new AST_Token({...})
})
```


And to represent
```
{a: 2}
```
you need
```
new AST_Object({
  properties: [
    new AST_ObjectKeyVal({ 
      key: 'a',
      value: new AST_Number({ value: 2 }),
      quote: null 
    })
  ],
  start: new AST_Token({...}),
  end: new AST_Token({...})
})
```


## TreeWalker
A `TreeWalker` is a [visitor](https://en.wikipedia.org/wiki/Visitor_pattern) that, given a node,
visits its children recursively and calls a callback function (called `visit`) passing the visited child.

To visit a node and its sub-tree you call `_visit`:
```
treeWalker = new TreeWalker(visit)
treeWalker._visit(targetNode)
```

This is equivalent to calling `walk` or `_walk` on `targetNode`
```
treeWalker = new TreeWalker(visit)
targetNode._walk(treeWalker)
```


A tree walker is usually passed into `AST_Node.walk` to extract information from the node sub-tree.

Here, a `visit` function collects all string literals into an array called `allStrings`.
```
function visit(node) {
  if (node instanceof AST_String) {
     allStrings.push(node.value);
  }
}
```


UglifyJS uses a tree walker to collect all the names of properties.
```
topLevel = new AST_TopLevel({...})
...
topLevel.walk(new TreeWalker(function(node) {
    if (node instanceof AST_ObjectKeyVal) {
        add(node.key)
    } else if (node instanceof AST_ObjectProperty) {
        add(node.key.name)
    } else if (node instanceof AST_Dot) {
        add(node.property)
    } else if (node instanceof AST_Sub) {
        addStrings(node.property, add)
    } else if (node instanceof AST_Call
        && node.expression.print_to_string() == "Object.defineProperty") {
        addStrings(node.args[1], add)
    }
}))
```

Under the hood, `AST_Node.walk` calls `TreeWalker._visit(this, descend)`,
or `TreeWalker._visit(this)` if the node cannot have children.
`descend` calls `_walk` on each child.

For node types that cannot have children, `walk` is defined as
```
_walk: function(visitor) {
        return visitor._visit(this)
    }
```

For node types who may have children, the node passes in a `descend` function.
For `AST_Binary`, a binary expression like `a + b`,
which have two children `left` and `right`.
It is defined as
```
_walk: function(visitor) {
        return visitor._visit(this, function() {
            this.left._walk(visitor)
            this.right._walk(visitor)
        })
    }
```

There are two strategies to navigate a node sub-tree.
Either the visitor takes control of descending or it is `visit` function.
In both cases, it is `visit` that decides whether or not to visit
the children of the current node by returning a boolean result.
So, you can navigate the sub-tree with a mixed strategy too.

`visit` takes the current node and its `descend` function and returns a truthy value when we don't
want the visitor to go down the children of the current node, or falsy value if we do.
If we return a truthy value, `visit` takes care of calling `descend` if needed.


## TreeTransformer
A `TreeTransformer` is a `TreeWalker` that modifies the sub-tree.
It is usually passed to `AST_Node.transform` to modify the children of the node.

To `descend` is to `transform` children.
AS in `_walk`, `transform` is a `noop` for nodes that cannot have children,
and it sets each child to the result of calling transform on it otherwise.

`TreeTransformer` has `before` and `after` functions. `before` plays the role of `_visit` in a tree walker.
It receives a `descend` function and returns a truthy value we don't want the tree
transformer to descend (and thus to transform) to children and `undefined` when we do.

So for `AST_Binary`, `transform` changes `left` and `right` to the result of `transform`.
```
AST_Binary.DEFMETHOD("transform", function(tw, in_list) {
  var x, y
  // ...
  if (tw.before) x = tw.before(this, descend, in_list)
  if (typeof x === "undefined") {
    x = this

    this.left = this.left.transform(tw)
    this.right = this.right.transform(tw)

    if (tw.after) {
      y = tw.after(this, in_list)
      if (typeof y !== "undefined") x = y
    }
  }
  // ...
  return x
})
```

As in the example above, transform returns the value of the transformed node.
The returned value is either the result of `before`, the node itself, or the result of `after`.
This is not the case with a tree walker, which does not care about the result of descending.


## Tokenizer
`Tokenizer` splits the input into a list of tokens.

It creates a function `next_token` which reads the input character per character and  returns
the next token each time you call it. A token is an instance of `AST_Token`.

For example, if we apply `Tokenizer` like this
```
const next_token = tokenizer('var a = 2;')
```

We get the tokens one by one as we call `next_token`
```
// Call 1
AST_Token { type: 'keyword',  value: 'var',  line: 1,  col: 0,  pos: 0 }

// Call 2
AST_Token { type: 'name',  value: 'a',  line: 1,  col: 4,  pos: 4 }

// Call 3
AST_Token { type: 'operator',  value: '=',  line: 1,  col: 6,  pos: 6 }

// Call 4
AST_Token { type: 'num',  value: 2,  line: 1,  col: 8,  pos: 8 }

// Call 5
AST_Token { type: 'punc',  value: ';',  line: 1,  col: 9,  pos: 9 }
```

Then, we get an end-of-file token each time call `next_token` 
```
AST_Token { type: 'eof',  value: undefined,  line: 1,  col: 10,  pos: 10 }
```

I removed non-relevant properties of `AST_Token` for brievity.

The types of tokens returned from `next_token` are:
  * `regexp` for a regex, the value is an instance of `RegExp`
  * `string` for a string, the value is the string itself.
  * `punc` for a punctuation mark, the value is the mark; `.`, or `,`, ...
  * `comment` for comments. There are 5 types of comments, each has an index. The token
    type of each is "comment" followed by the type index. `comment1` for single-line comments,
    `comment2` for multi-line comments, and so on. The types of comments are:
        `//` single line, `/*` multiline, `<!--` HTML5 opening, `-->` HTML5 closing, and `#!` shebang
  * `num` for a numeric value, the value is the number
  * `atom` for the values `false`, `true`, and `null`
  * `operator` for operators like `=`, `+`, ..., the value is the operator.
     Operators can be words (`in`, `instanceof`, `typeof`, `new`, `void`, `delete`).
  * `keyword` when the word is a keyword but not an operator, like `return`, `instanceof`, `break`, ...
    Note that operators that are words (like ...) are keywords, but not all keywords are operators.
  * `name` for an identifier, when a word is either a name of an object property,
    or  is neither an atom nor a keyword.


## Parser
`Parser` transforms source code into an AST.
It uses `Tokenizer` to read the input token by token.
And for each token, it creates a node as an instance of the specific AST type.

For example, when the token is string literal, `Parser` creates an `AST_String`:
```
const token = next_token()

if (token.type === "string") {
  new AST_String({
      start : token,
      end   : token,
      value : token.value,
      quote : token.quote
  })
}
```


## Minifier
`minify` is the core of UglifyJS. It takes an input a optimizes it.
It uses all the other components, the parser, the compressor, the mangler, and the source
map generator.

`minify` takes the input and a set of options.
The input can be either an instance of `AST_TopLevel`, a file path, or a list of paths
of different files.
Options define which operations to execute and which to ignore.

`minify` returns a structure that contains the AST of the input, a string of the minified
source code, a source-map, an array of warnings, and profiling information about the duration
of the performed operations.

The main operations:
  * create AST from the input
  * compress the AST
  * mangle identifiers
  * mangle object properties
  * create an `OutputStream` and generate the output string


## OutputStream
`OutputStream` is a factory for UglifyJS output code.
It builds a string named `OUTPUT`, which you get by calling `outputStream.get()`
or `outputStream.toString`.

`OUTPUT` is the output of applying to UglifyJS to an input source code.
`OutputStream` provides multiple methods to build `OUTPUT`, like `outputStream.comma()` to
add a comma, `outputStream.colon()` to add a colon,
`outputStream.with_indent(fn)` to add an indentation before each following line, and many others.

As it builds `OUTPUT`, `OutputStream` keeps a state and updates it each
time we add something.
This state maintains where and how to write the next characters in the output,
the indentation level, source-map information, and a filter of which comments to discard.

Not all provided methods change `OUTPUT` directly.
Only `insert_newlines`, `print`, and `newline` do.
Others rely on these to build `OUTPUT` and to update the state.
So, `space` calls `print(' ')`, `comma` calls `print(',')`, and so on.


## SourceMap
`SourceMap` is a wrapper around [fitzgen's source-map library](https://github.com/mozilla/source-map).
It generates a source-map for UglifyJS output.
With this map, we restore the original source code from the output.

It is, first, built by `OutputStream`.
Then, `minify` either adds it to the output if it needs to be inlined,
or adds a reference to it in the output if the source-map needs to be in a separate file.
The location of the source-map depends on the options of the minification.


## Compressor
This is a complicated component and I will dedicate a separate post for it alone.
>  The compressor is a tree transformer which reduces the code size by applying various optimizations on the AST:
> * join consecutive var/const statements.
> * join consecutive simple statements into sequences using the “comma operator”.
> * discard unused variables/functions.
> * optimize if-s and conditional expressions.
> * evaluate constant expressions.
> * drop unreachable code.
> * ... and quite a few others.

[Mihai Bazon's blog](http://lisperator.net/uglifyjs/)
