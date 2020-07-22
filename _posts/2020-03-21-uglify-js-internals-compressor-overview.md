---
layout:   post
comments: true
title:    "UglifyJS internals, Compressor overview"
date:     2020-03-21 20:47:00 +0100
tags:     featured
---

I started delving into [UglifyJS](https://github.com/mishoo/UglifyJS2/) internals a couple of months ago.
I [wrote](/2019/12/25/uglifyjs-internals-overview.html) about the building blocks in the previous post.
`Compressor` remains the most complicated module of the library.

It minimizes the number of nodes in the result AST.
UglifyJS parses the input file and hands the result to `Compressor`, which creates the optimized AST.
The `Output` module transforms that into a shorter code.

I will introduce different parts of the module below.
While the code remains the single source of truth, you may learn about how `Compressor` plays with nodes.
I will keep updating this post as I learn more about the library. You are welcome to send suggestions and improvements in
the meantime.

## Usage
`Compressor` depends only on `AST_Node` and its subtypes. You give it an instance of `AST_TopLevel`.
It gives you back an optimized one.

To compress a `node` you write:

{% highlight javascript %}
compressor = new Compressor(options)
compressedNode = compressor.compress(node)
{% endhighlight %}

UglifyJS compresses the code after it parses the input into an `AST_TopLevel` node and before it mangles the names.
In the minification module, the minifier checks for the `compress` option then optimizes the parse result.

{% highlight javascript %}
if (options.compress)
   toplevel = new Compressor(options.compress).compress(toplevel);

{% endhighlight %}

That is the only use of `Compressor` in UglifyJS.
Even in the test harness, `Compressor` is considered a part of the minification. It has no tests of its own.

## Overview

`Compressor` is a `TreeTransformer`, and thus a `TreeWalker`.

When we call `Compressor.compress` with an `AST_TopLevel` node, the `Compressor` resolves definitions in that scope
and children scopes and sets up scope details for all nodes in the tree using `AST_Scope.figure_out_scope`.
Then, it attempts to compress and recompress the tree a given number of times.
It executes and re-executes the compression command until the code is compressed or the ceil of tries is reached.
It stops when two successive compressions give the same number of nodes, or when the number of executions the number reaches
the maximum number passes set by `options.passes`.

To compress a node, `Compressor` compresses the leaves, then their parents successively, until it reaches the root.
`Compressor` is a `TreeTransformer`. It has a `before` method where it optimize the node and returns the result.


## Options
`Compressor` has its set of [options](https://github.com/mishoo/UglifyJS2#compress-options), which
we inject into its constructor. They drive most decisions in the compression logic.
The constructor accepts the options object and creates its proper options object that sets default values
for undefined options. Inside the compression logic, it queries the options using its method `Compressor.option(name)`.

For example:
{% highlight javascript %}
// Treat parameters as collapsible in IIFE, i.e.
//   function(a, b){ ... }(x());
// would be translated into equivalent assignments:
//   var a = x(), b = undefined;
if (stat_index == 0 && compressor.option("unused")) extract_args();
{% endhighlight %}


The constructor of `Compressor` accepts two arguments. The `options` object and `falseByDefault`.
The second argument is a boolean that, when truthy, tells the `Compressor` to act conservatively.

Not all options are used in the same shape in which they are received.
The following options are mapped to different formats to simplify their consumption:
 * `global_defs`:

   Global definitions are received as an [object](https://github.com/mishoo/UglifyJS2#conditional-compilation-api).
   `Compressor` loops through this object and evaluates properties whose key starts with `@`.
   This option is used to resolve definitions in the top level node and to send a warning when a global definition is
   being mutated or redefined.
   This is done using `AST_TopLevel.resolve_defines`, which is called at the beginning of the compression.

 * `keep_fargs`:

   This option may either be `"strict"`, `true`, or `false`.
   It tells `Compressor` whether to keep unused function arguments or to discard them.
   `Compressor` defines a predicate `Compressor.drop_fargs` that discards arguments when the value of `keep_fargs` is false,
   and keeps them when the value is true.
   If the value is "strict" however, the result of the predicate depends on the definition of the function and its parent node.

   `Compressor.drop_fargs` is called in `AST_Scope.drop_unused` at the end of the compression of a node,
   and in `AST_Sub.optimize` (`AST_Sub` in an index-style property access, i.e. `a["foo"]`) to see whether the optimization
   logic should define missing arguments for the function.
   The last is needed when `drop_unused` return true and the body of the function accesses
   `arguments[index]` where `index` is greater than the number of defined arguments.

 * `top_retain`:

   This is a list of toplevel functions and variables that `Compressor` should keep, even when unused.
   For so, it defines a predicate that given a definition, returns whether the definition can be removed or not.

 * `pure_funcs`:

   It contains the list of functions to be assumed pure.
   The `Compressor` defines a predicate `Compressor.pure_funcs` that, given an `AST_Call`, tells whether to
   assume that the call is pure or not.
   `Compressor` often tries to remove statements that have no side effects and that the code has no use of
   their result. AS it checks different node types for side effects, it uses `Compressor.pure_funcs` for calls.


## Optimization

`Compressor` defines a method `optimize` for each `AST_Node`, which returns either an optimized `AST_Node`,
the same node if there is nothing to optimize, or an `AST_EmptyStatement` if the node should be discarded.
`Compressor` discards a node in many settings:
when it is already empty, like an `AST_Block` with no statements, when an option asks for it,
like an `AST_Debugger` node when `options.drop_debugger` is truthy, a redefined directive, a `return;` at the end of a function, ...

I will introduce `tighten_body`, the optimization logic for an array of statements, an array of `AST_statement` nodes.
It includes many patterns and it manipulates the code in interesting ways.
All of `AST_Block`, `AST_BlockStatement`, and `AST_Lambda`, and `AST_Try` `optimize` use `tighten_body` to optimize their body.

Each contains:
{% highlight javascript %}
self.body = tighten_body(self.body, compressor);
{% endhighlight %}


`tighten_body` contains the following loop:
{% highlight javascript %}
do {
    CHANGED = false;
    eliminate_spurious_blocks(statements);
    if (compressor.option("dead_code")) {
        eliminate_dead_code(statements, compressor);
    }
    if (compressor.option("if_return")) {
        handle_if_return(statements, compressor);
    }
    if (compressor.sequences_limit > 0) {
        sequencesize(statements, compressor);
        sequencesize_2(statements, compressor);
    }
    if (compressor.option("join_vars")) {
        join_consecutive_vars(statements);
    }
    if (compressor.option("collapse_vars")) {
        collapse(statements, compressor);
    }
} while (CHANGED && max_iter-- > 0);
{% endhighlight %}

### `eliminate_spurious_blocks`
It removes all `AST_EmptyStatement`, flattens the body of `AST_BlockStatement`, and removes duplicated directives.
Flattening works if `AST_BlockStatement` contains a statement that is also an `AST_BlockStatement`.
It removes it, and puts its statements in the body of the original block.

### `eliminate_dead_code`
It looks for jumps, `return`, `throw`, `break`, or `continue`.
When it finds an unreachable code, it uses a `TreeWalker` to navigate it, moves variables and functions declarations
up, and removes what remains.
It removes initialization for variables too, moving only the declaration up.

### `handle_if_return`
This function deals with early jumps within the if statements in the given block.

Each if statement has three components, a condition (a predicate), a body to be executed if the condition is satisfied,
and an optional alternative to be executed if the condition is not.

A jump is a `break;` or a `continue;`. Both interrupts the control flow.

`handle_if_return` walks the statements backward to optimize each statement using the optimized next ones.
This helps when you are dealing with early jumps.

It:
 * removes the following statements when block being optimized is a function and there is an `AST_Return`
 followed only by variables declarations (without initialization).

 * transforms an `AST_Return`.value == `AST_UnaryPrefix` with "void" value into a simple statement with
 `AST_Return`.value.expression as the body.

 * negates the condition and reverts the body and the alternative when;

   1 - The body contains a jump (`break` or `continue`) that jumps back to the beginning of the block being optimized.

   2 - The if statement has no alternative, it is followed by a jump, and the negated condition is shorter than normal condition.

   3 - The alternative contains a jump back to the beginning of the block being optimized.

   In 1- and 3-, it removes the non-function-definitions that follow the conditional and put them in
   the branch free from a jump (body in 1- and alternative in 3-). 

 * compresses if statements where the body contains only a return statement and the alternative is empty as follow:
   {% highlight javascript %}
   // if (foo()) return; return; ==> foo(); return;
   // if (foo()) return x; return y; ==> return foo() ? x : y;
   // if (foo()) return x; [ return ; ] ==> return foo() ? x : undefined;
   // if (a) return b; if (c) return d; e; ==> return a ? b : c ? d : void e;
   {% endhighlight %}

## `sequencesize`
It joins consecutive `AST_SimpleStatement`, or a list of `AST_SimpleStatement` interrupted only by declarations
(`AST_Defun` or `AST_Definitions` with `declarations_only`) into one `AST_Sequence`.
An `AST_Sequence` is a statement that contains an array of expressions.

`sequencesize` removes expressions in the middle that does not affect the return value of the sequence and have no side effects.

## `sequencesize_2`
It tries to put each `AST_SimpleStatement` (a statement consisting of one expression, we call it `prev`) into the following
`AST_StatementWithBody` (a statement that has a body) as follow:
  * `AST_Exit` (`return` or `throw`): changes the value to an `AST_Sequence` including `prev` and the value
  * `AST_ForIn`: adds `prev` to the definition of object we are looping through (creating an `AST_Sequnce`)
  * `AST_If`: adds `prev` to the condition (creating an `AST_Sequnce`)
  * `AST_Switch`: adds `prev` to the "switch" discriminant (creating an `AST_Sequnce`)
  * `AST_With`: adds prev to the expression (creating an `AST_Sequnce`)
  * `AST_For`:
     It puts `prev` in the loop init code if init is not an instance of `AST_Definitions` or the loop has no init code,
     creating an `AST_Sequnce`.
     When the init is an `AST_Definitions`, there may be problems with the result sequence.
     It avoids adding `prev` to the init code if `prev` contains a function definition (it won't be accessible) or
     an expression with an `in` operator (it causes issues with the following expression in a sequence)

     {% highlight javascript %}
     `for(console.log('hi'), var i = 0;;;) {}` // `SyntaxError: Unexpected token var`
     `for(console.log('hi'), i = 0;;;) {}` // works
     {% endhighlight %}

### `join_consecutive_vars` 
This is not far from the previous function.
It modifies the same types of `AST_StatementWithBody` as `sequencesize_2` in the same way.
But, instead of joining statements, it joins variable assignments using `join_assigns`.

`join_assigns` takes `prev` and an `AST_Assign` or an `AST_Sequence`, and returns an array of expressions.
`Compressor` uses `join_assigns_exprs` to build an `AST_Sequence` using that array.
If prev is `AST_Definitions`, try to `trim_assigns` into last `AST_VarDef` of it `exprs` (move assignments to prev)
otherwise (none moved or `prev` is not `AST_Definitions`),
find an expression of `AST_Assign`, operator = "=", .left is `AST_SymbolRef`, and there is
nothing to `trim_assigns` from the following expressions. If there is, return;

`trim_assigns` helps when the `prev` is an assignment of an object's property.
It accepts an `AST_VarDef` name and value, and an array of `AST_Assign`.
It walks the array from beginning to end, when it finds an assignment to a property of the given `AST_VarDef` name
that does not change a property in the given `AST_VarDef` value, it adds the assignment into the `AST_VarDef` value.

### `collapse`
"This is left as an exercise for the reader" 😈. [Have fun!](https://github.com/mishoo/UglifyJS2/blob/master/lib/compress.js#L1123).
