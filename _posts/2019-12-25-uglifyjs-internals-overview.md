---
layout:   post
comments: true
title:    "UglifyJS internals, overview"
date:     2019-12-25 18:11:00 +0100
tags:     featured
---

[UglifyJS](https://github.com/mishoo/UglifyJS2) is Javascript source code optimizer.
It compresses Javascript files so that code travels faster across the network.

## AST
Given a Javascript file, UglifyJS parses the content and builds an
[Abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) (AST).
Each node of the AST holds the definition and the context of a token in the program.
The definition contains the type (function, variable, constant, object, ...),
the required attributes for the type (the name of a variable or a function, the arguments
of a function definition, ...), and the children.
The context describes the usage of the token in the program.

A variable definition node has a list of nodes that read and modify that variable. This is part of the node
context. UglifyJS may remove the definition while compressing if the list is empty.
Similarly, when the children of a statement node are pure variable declarations and its parent is a function
definition, the compressor can safely delete it.
These operations are hard to perform when the code is represented as a string.

Types are defined in [`lib/ast.js`](https://github.com/mishoo/UglifyJS2/blob/master/lib/ast.js).
UglifyJS defines a class for each type.
`AST_SymbolDefun` represents a function definition. `AST_String` is a string literal.
All class names start with `AST_`.

Types are organized into a hierarchy.
`AST_Number` and `AST_String` are `AST_Constant`, `AST_False` and `AST_True` are `AST_Boolean`.
`AST_Null` is an `AST_Atom`. `AST_Atom` itself is an `AST_Constant`, and so on.
`AST_Node` is the root of this hierarchy. All nodes inherit it directly or indirectly.

These types are extensible.
They are defined with initial properties and methods in `lib/ast`. Then, other modules decorate them with
new methods.
`AST_Node` is defined with `start`, `end` (both represent the boundaries of the node in the source code),
`walk()`, and `clone()`. Then, the compressor attaches the method `optimize` and other helpers to it.

To create a node, you need to instantiate its class with the required parameters.
A string literal has also two properties;
a value; the string itself, and a quote (`"` or `'`); the quotation used in the input.

So to represent the string
{% highlight javascript %}
"Hello Uglify!"
{% endhighlight %}

you need
{% highlight javascript %}
new AST_String({
  value : 'Hello Uglify!',
  quote : '"',
  start: new AST_Token({...}),
  end: new AST_Token({...})
})
{% endhighlight %}

An object requires a list of properties. To represent the object
{% highlight javascript %}
{a: 2}
{% endhighlight %}

you need
{% highlight javascript %}
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
{% endhighlight %}

To distinguish between types. UglifyJS uses `instanceof`.
The  the following pattern exists everywhere:
{% highlight javascript %}
function transformNode(node) {
  if (node instanceof AST_Defun)
     ...
  if (node instanceof AST_String)
     ...
  if (node instanceof AST_Number)
     ...
}
{% endhighlight %}

## Scope

Parallel to the AST, there is a tree of lexical scopes.
When an AST node introduces a lexical scope, it inherits `AST_Scope`.
You filter out the nodes that do not inherit `AST_Scope` in an AST, and you get the scopes tree.
Two types inherit `AST_Scope`; `AST_Toplevel` and `AST_Lambda`.

`AST_Toplevel` is the root node of every AST and `AST_Lambda` is a function definition.
The latter is inherited by `AST_Accessor` (a getter/setter function),
`AST_Function` (a function expression), and `AST_Defun` (a function definition).
A Function definition is a statement and a function expression is an expression.
The compressor optimizes them differently and the parser requires a name for the function statement
but not for the expression. It is more convenient to separate them.

The documentation defines the properties `AST_Scope` as:
{% highlight javascript %}
variables: "[Object/S] a map of name -> SymbolDef for all variables/functions defined in this scope",
functions: "[Object/S] like `variables`, but only lists function declarations",
uses_with: "[boolean/S] tells whether this scope uses the `with` statement",
uses_eval: "[boolean/S] tells whether this scope contains a direct call to the global `eval`",
parent_scope: "[AST_Scope?/S] link to the parent scope",
enclosed: "[SymbolDef*/S] a list of all symbol definitions that are accessed from this scope or any subscopes",
cname: "[integer/S] current index for mangling variables (used internally by the mangler)",
{% endhighlight %}

`AST_Toplevel` also defines `globals` (a list for undeclared names).
`AST_Lambda` defines the name of the function, a list of its arguments, and `uses_arguments` (a boolean that
is true when the function accesses the arguments array).

Other than those nodes, only `AST_Symbol` knows about `AST_Scope` because it holds a reference to its scope.
An `AST_Symbol` is either an accessor, a declaration of a variable, a function name, a function argument,
a definition of the error in a catch block, a reference to a symbol/label, the keyword `this`, or a loop label.

UglifyJS defines `AST_Scope` operations in
[`lib/scope.js`](https://github.com/mishoo/UglifyJS2/blob/master/lib/scope.js).
These operations enrich the description of existing scopes
by defining new variables or by exploring the surrounding and adding information to the context.

## TreeWalker
A `TreeWalker` is a [visitor](https://en.wikipedia.org/wiki/Visitor_pattern) that, given a node,
visits its children recursively and calls a callback function (called `visit`) passing the visited child.

To visit a node and its sub-tree you call `_visit`:
{% highlight javascript %}
treeWalker = new TreeWalker(visit)
treeWalker._visit(targetNode)
{% endhighlight %}

This is equivalent to calling `walk` or `_walk` on `targetNode`
{% highlight javascript %}
treeWalker = new TreeWalker(visit)
targetNode._walk(treeWalker)
{% endhighlight %}


A tree walker is usually passed into `AST_Node.walk` to extract information from the node sub-tree.

Here, a `visit` function collects all string literals into an array called `allStrings`.
{% highlight javascript %}
function visit(node) {
  if (node instanceof AST_String) {
     allStrings.push(node.value);
  }
}
{% endhighlight %}


UglifyJS uses a tree walker to collect all the names of properties.
{% highlight javascript %}
topLevel = new AST_Toplevel({...})
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
{% endhighlight %}

Under the hood, `AST_Node.walk` calls `TreeWalker._visit(this, descend)`,
or `TreeWalker._visit(this)` if the node cannot have children.
`descend` calls `_walk` on each child.

For node types that cannot have children, `walk` is defined as
{% highlight javascript %}
_walk: function(visitor) {
        return visitor._visit(this)
    }
{% endhighlight %}

For node types who may have children, the node passes in a `descend` function.
For `AST_Binary`, a binary expression like `a + b`,
which have two children `left` and `right`.
It is defined as
{% highlight javascript %}
_walk: function(visitor) {
        return visitor._visit(this, function() {
            this.left._walk(visitor)
            this.right._walk(visitor)
        })
    }
{% endhighlight %}

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
{% highlight javascript %}
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
{% endhighlight %}

As in the example above, transform returns the value of the transformed node.
The returned value is either the result of `before`, the node itself, or the result of `after`.
This is not the case with a tree walker, which does not care about the result of descending.


## Tokenizer
`Tokenizer` splits the input into a list of tokens.

It creates a function `next_token` which reads the input character per character and  returns
the next token each time you call it. A token is an instance of `AST_Token`.

For example, if we apply `Tokenizer` like this
{% highlight javascript %}
const next_token = tokenizer('var a = 2;')
{% endhighlight %}

We get the tokens one by one as we call `next_token`
{% highlight javascript %}
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
{% endhighlight %}

Then, we get an end-of-file token each time call `next_token` 
{% highlight javascript %}
AST_Token { type: 'eof',  value: undefined,  line: 1,  col: 10,  pos: 10 }
{% endhighlight %}

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
{% highlight javascript %}
const token = next_token()

if (token.type === "string") {
  new AST_String({
      start : token,
      end   : token,
      value : token.value,
      quote : token.quote
  })
}
{% endhighlight %}


## Minifier
`minify` is the core of UglifyJS. It takes an input a optimizes it.
It uses all the other components, the parser, the compressor, the mangler, and the source
map generator.

`minify` takes the input and a set of options.
The input can be either an instance of `AST_Toplevel`, a file path, or a list of paths
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
