---
layout: post
comments: true
title:  "Acorn internals, main concepts"
date:   2020-06-28 12:46:00 +0100
tags: featured
---

[Acorn](https://github.com/acornjs/acorn) is a JavaScript-based JavaScript parser.
It is easy to understand and to extend due to its small size.
There is a relatively small number of concepts you need to get familiar with it to augment its parsing operations
and to enrich its subject language. I'll get into most of them here.


## Parser
To parse a program, you might use `Acorn.parse` and give it the input code string:

{% highlight javascript %}
import Acorn from 'acorn'
const parsed = Acorn.parse('var i = 1');
{% endhighlight %}

The result for this example is:

{% highlight javascript %}
Node {
  type: 'Program',
  start: 0,
  end: 9,
  body:[{
    type: 'VariableDeclaration',
    start: 0,
    end: 9,
    declarations: [{
      type: 'VariableDeclarator',
      start: 4,
      end: 9,
      id: {type: 'Identifier', start: 4, end: 5, name: 'i'},
      init: {type: 'Literal', start: 8, end: 9, value: 1, raw: '1'}
    }],
    kind: 'var'
  }],
  sourceType: 'script'
}

{% endhighlight %}

Acorn puts all operations in one class, `Parser`. It is a parser and a tokenizer.
It is defined in `state.js` then enriched by other modules.
`Acorn.parse` is a static method that creates a `Parser` instance then uses it to parse the input.

`Parser` constructor takes a set of options, a source code to parse or the name of a Javascript file, and the starting position.
It also accepts an AST to which it adds the result of parsing the given source.

Options specify the valid input. They decide whether to accept import statements in the middle of the code,
whether to accept `await` and `return` statements at the top-level, whether to use strict mode rules or not
and a couple of other similar settings.

Options also define callbacks that are called by Acorn during different stages of parsing.
This allows you to define a function that is called after reading a token or after parsing a node or a comment.


## Parsing the top level
That top-level node is either created by `parseTopLevel` itself or it is taken from the AST given by the options.
In both situations, the result of the parsing is an AST whose root is a node with the type `'Program'`.
`Parser` has a method `parse` that uses `parseTopLevel` to loop over and parse top-level statements in the input,
then to collect their nodes under the top-level node.

Each node has a type, a position index, and type-specific attributes
(like `body` for a block statement, `condition` `consequent` and `alternate` for an if statement,
`declarations` in the variable declaration, ...).
Acorn models node types as `string`.
This makes sense as each type is used once and is highly correlated to the method using it.

Acorn defines a parsing method for each type of node.
`parseForStatement` parses for loops and returns a `ForStatement` node, `parseIfStatement` parses a conditional if statement,
`parseReturnStatement` a return statement, and so on.

Each parsing method takes an empty node, a node that contains only the first character position.
It sets its type and its type-specific attributes and returns it back.


## Tokens
`Parser` keeps track of the current token being parsed and the previously parsed token.
`parseStatement` relies on those attributes to create the next node in the tree.

It stores the current line in `curLine`, the current line beginning in `lineStart`, the token type in `type`,
and the token value `value`.
Then, it uses `pos` for the current position in the input, `start`/`end` for the token boundaries in the source,
and `lastTokEnd` for the last token end position.

`Parser` navigates the code using `next` and `nextToken`.
`next` stores the last token and calls `nextToken`, which tries to find the next token.
`nextToken` skips over insignificant white space and sets `start` to the current position.
Then, depending on the first token character, it advances until the end of a recognized token.
It increments `this.pos` by 1 if the code is one byte, and by 2 if it takes 2 bytes (when the code point is above `0xfff`).

Acorn decides whether the current token is a word or not by checking its first character using `isIdentifierStart`.
Different methods are used to proceed in each condition.
For a word, `readWord` is used. It reads the token and tries to match it against a keyword or a reserved word and a type.
When no predefined word and type is found, it sets the token type to `name`.
This is the type of variables and classes identifiers.
For example, if the word is `while`, `readWord` returns `_while` token type, which evaluates to 'while'.
Token types are defined in `tokentype.js`.
Acorn creates a `RegExp` that checks a token against version-specific ECMAScript keywords.


If the current character cannot be the beginning of a word, `getTokenFromCode` handles it.
If the token is a punctuation mark, it creates a token with `finishToken`.
Otherwise, it delegates to other helpers that read long tokens.
It delegates to `readString` when it encounters `'` or a `'`, `readNumber` when it finds a digit, and so on.

Ther characters and the functions used for each are:

{% highlight javascript %}
// The interpretation of a dot depends on whether it is followed
// by a digit or another two dots.
'.'->  readToken_dot

'/' -> readToken_slash
'%*' -> readToken_mult_modulo_exp
'|&' -> readToken_pipe_amp
'^' -> readToken_caret
'+-' -> readToken_plus_min
'<>' -> readToken_lt_gt
'=!' -> readToken_eq_excl
'?' -> readToken_question
'~' -> finishOp.
{% endhighlight %}

In addition to a type, a token also has a context.
Acorn keeps track of the current context and its parents in a stack.

Token contexts are defined by their first token. `TokenContext` constructor is defined as follows:

{% highlight javascript %}
class TokContext {
  constructor(token, isExpr, preserveSpace, override, generator)
{% endhighlight %}

Contexts are defined in `tokencontext.js` as follows:

{% highlight javascript %}
b_stat    : new TokContext('{', false)
b_expr    : new TokContext('{', true)
b_tmpl    : new TokContext('${', false)
p_stat    : new TokContext('(', false)
p_expr    : new TokContext('(', true)
q_tmpl    : new TokContext('`', true, true, p => p.tryReadTemplateToken())
f_stat    : new TokContext('function', false)
f_expr    : new TokContext('function', true)
f_expr_gen: new TokContext('function', true, false, null, true)
f_gen     : new TokContext('function', false, false, null, true)
{% endhighlight %}

When parsing `function compute(a) { return (a - 1) * 2; }`, the context at different times stack will be:

{% highlight javascript %}
// when the tokenizer is reading the function argument
[
{ token: '{', isExpr: false, preserveSpace: false, generator: false },
{ token: 'function', isExpr: false, preserveSpace: false, generator: false },
{ token: '(', isExpr: true, preserveSpace: false, generator: false }
]

// when the tokenizer is reading the 'a - 1' part of the return expression
[
{ token: '{', isExpr: false, preserveSpace: false, generator: false },
{ token: 'function', isExpr: false, preserveSpace: false, generator: false },
{ token: '{', isExpr: false, preserveSpace: false, generator: false },
{ token: '(', isExpr: true, preserveSpace: false, generator: false }
]
{% endhighlight %}

The top-level context (and the first added item to the stack) is always a block context.
It is defined in `Parser` constructor using `initalContext`.


## Parser.parseStatement
`parseStatement` creates a node from the current token, the one created by `next`.
It is called by successively `parseTopLevel` as long as no token with the type `tt.eof` is found.
To zoom out, `parse` first calls `next` then `parseTopLevel`.
`parseTopLevel` calls `parseStatement` for each top-level statement and adds the result to the top-level node body.
`parseStatement` uses a helper method that calls `next` in the end so that the next call to `parseStament`
gets the token that follows the last node as a current token.

Each parsing method is specific to a type of statement.
The only pattern shared by most of them is reading a semicolon.

Acorn uses `this.eat(tt.semi)` (), `this.insertSemicolon()` (), and `this.semicolon` ().

`eat` is a:

{% highlight javascript %}
// Predicate that tests whether the next token is of the given
// type, and if yes, consumes it as a side effect. (by calling this.next())
{% endhighlight %}

Here is an example from `parseForStatement`:

{% highlight javascript %}
  node.init = init
  this.expect(tt.semi)
  node.test = this.type === tt.semi ? null : this.parseExpression()
  this.expect(tt.semi)
  node.update = this.type === tt.parenR ? null : this.parseExpression()
  this.expect(tt.parenR)
  node.body = this.parseStatement('for')
{% endhighlight %}


`insertSemicolon`:

{% highlight javascript %}
// Consume a semicolon, or, failing that, see if we are allowed to
// pretend that there is a semicolon at this position.
{% endhighlight %}

It is defined as follows


{% highlight javascript %}
pp.semicolon = function() {
  if (!this.eat(tt.semi) && !this.insertSemicolon()) this.unexpected()
}
{% endhighlight %}

`semicolon` meanwhile checks whether we are allowed to insert a semicolon after the current token.
It is true if we are at the end of the file, in a `}`, or if
 `lineBreak.test(this.input.slice(this.lastTokEnd, this.start))`.
The last call checks that the last token ends at the end of a line by checking whether a line break exists
between the last token ending position and the start of the current token.


## Scope
`Parser` keeps track of the current scope and its parents in `scopeStack`.
In the constructor, `Parser` initializes `scopeStack` and calls `this.enterScope(SCOPE_TOP)`.
Then `scope.js` module defines getters that check the scope of the current token.

Acorn models scopes using bitsets and uses logical-end to compare them.
Scopes are defined in `src/scopeflags`. Each scpe is a binary with a shifted 1:

{% highlight javascript %}
    SCOPE_TOP = 1,
    SCOPE_FUNCTION = 2,
    SCOPE_VAR = SCOPE_TOP | SCOPE_FUNCTION,
    SCOPE_ASYNC = 4,
    SCOPE_GENERATOR = 8,
    SCOPE_ARROW = 16,
    SCOPE_SIMPLE_CATCH = 32,
    SCOPE_SUPER = 64,
    SCOPE_DIRECT_SUPER = 128

export function functionFlags(async, generator) {
  return SCOPE_FUNCTION | (async ? SCOPE_ASYNC : 0) | (generator ? SCOPE_GENERATOR : 0)
}
{% endhighlight %}

A scope with value `0` is neither of those. `0` is used when the current statement introduces a new lexical scope.
It is used in `parseForStatement`, `parseSwitchStatement`, to parse a non-simple catch block in `parseTryStatement`,
and in `parseBlock` when `createNewLexicalScope` is true.
These helpers use `enterScope` to create a new scope.

Acorn usually calls `this.enterScope` before parsing the body of the statement, and `this.exitScope` after parsing the body.

The following pattern is used in multiple parsing helpers:

{% highlight javascript %}
this.enterScope(/* flags */);
node.body = this.parseBlock()
this.exitScope()
{% endhighlight %}

`enterScope` and `exitScope` are defined as follows:

{% highlight javascript %}
pp.enterScope = function(flags) {
  this.scopeStack.push(new Scope(flags))
}

pp.exitScope = function() {
  this.scopeStack.pop()
}
{% endhighlight %}

A `ScopeStack` frame, an instance of `Scope`, contains a list of variables,
a list of lexically-declared names, and a list of `FunctionDeclaration` names.
As the parsing goes on, `declareName` is used to add names (like variable declarations) to the current scope.
