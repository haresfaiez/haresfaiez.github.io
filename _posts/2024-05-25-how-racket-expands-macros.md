---
layout: post
comments: true
title:  "How Racket expands macros"
date:   2024-05-19 11:00:00 +0100
tags: featured
---

> [...] while Racket is not Lisp (in the specific Common Lisp sense),
> it is a Lisp (in the familial sense). Its core ideas—and core virtues—are shared with Lisp.
> So talking about Racket means talking about Lisp.
>
> [— Why Racket? Why Lisp?](https://beautifulracket.com/appendix/why-racket-why-lisp.html)

[Racket](https://racket-lang.org) is marketed as a "the Language-Oriented Programming Language".
Check out its home page. There are plenty of tutorials, books, and papers.

As a Lispy language, [macros](https://en.wikipedia.org/wiki/Macro_(computer_science))-like structures, or "syntax objects" as they're named in Racket,
are first-class constructs.

> A syntax object combines a simpler Racket value, such as a symbol or pair,
> with lexical information, source-location information, syntax properties,
> and whether the syntax object is tainted.
>
> [— Syntax objects](https://docs.racket-lang.org/reference/syntax-model.html#(part._stxobj-model))

Values can be either datums or syntaxes.

A datum as a concept is very similar to an [s-expression](https://en.wikipedia.org/wiki/S-expression) in Lisp.
It's a piece of information, a valid head-tail structure, a list.

A syntax, on the other hand, is a "rich" datum.
It's reified with a data structure named `syntax`:

```lisp
(struct syntax ([content* #:mutable] ; datum and nested syntax objects; mutated for lazy propagation
                scopes  ; scopes that apply at all phases
                shifted-multi-scopes ; scopes with a distinct identity at each phase; maybe a fallback search
                mpi-shifts ; chain of module-path-index substitutions
                srcloc  ; source location
                props   ; properties
                inspector) ; inspector for access to protected bindings
    ;; ....
```

`content` is the raw expression, the source of the syntax.
A syntax object is itself a datum.
But, not every datum is a syntax.
The latter includes more contextual information.

Racket defines a predicate `syntax?` to test whether a given expression is datum or a syntax object.
And, it defines a function
[`datum->syntax`](https://docs.racket-lang.org/reference/stxops.html#%28def._%28%28quote._~23~25kernel%29._datum-~3esyntax%29%29)
to convert an s-expression into a syntax object.

The latter walks over a given expression to make sure every sub-expression is a syntax object.
The traversal follows a depth-first strategy.
Syntaxes are kept as they are.
Datums are mapped to new `syntax` instances.
It puts the expression inside the `content` attribute and it copies the scopes from a fixed given context.

The field named `scopes`, inside `syntax` data structure, is documented as a "set of scope sets".
It comprises lexical information.

Scopes, too, are first-class constructs in Racket.
An element of such a set is an instance of a `scope` data structure:

```lisp
(struct scope (id             ; internal scope identity as an exact rational; used for sorting
               kind           ; 'macro for macro-introduction scopes, otherwise treated as debug info
               [binding-table #:mutable]) ; see "binding-table.rkt"
                ;; ....
```

`binding-table` contains a map where each key is a pair
of a [symbol](https://docs.racket-lang.org/reference/symbols.html) and a set of scopes,
and each value is a binding structure.

Scopes are distinguished by their bindings.
A binding is identified by a symbol and a set of scopes.

The binding inside each map value is also a symbol.
But, it's a unique one. It's different from the symbol used in the map key.
The same symbol could mean different things in different scopes of the same syntax.

The symbol in the key is the symbol used in the expression.

The symbol in the value depends on the nature of the binding.

There are multiple types of bindings: local bindings, module bindings, ...

Bindings created and added to the syntax scopes during expansion are usually local bindings.
Their unique symbols (the values inside the binding map) might look like `x_1` and `x_2`.
Each one is a mapping of `x` within a unique set of scopes.

## Identifying an expander

Racket defines a set of expanders that transform input expressions (that is, syntaxes, rich datums)
into compilation-ready fully-parsed expressions.
The outcome of the expansion process is always a structure destined for the compiler.
It's un-ambiguous and fully expanded. The compiler transforms it into lower-level formats.

The language defines many "core forms" expanders and one "transformer" expander.

A transformer is a macro.

We define it with `define-syntax`.

`format_and_print` below is a syntax transformer that formats and prints a given string then returns it:

```lisp
(define-syntax-rule (format_and_print str)
  (begin
    (printf "~a\n" str)
    str))
```

On the other side, a core form expander specifies the expansion logic for primitive constructs of Racket.

`lambda` for example is a core form that defines functions:

```lisp
(define my-function1 (lambda (x) (+ x 1)))
```

The compiler cannot understand this syntax.
It's up to the expander to transform it into an intelligible data structure.

Such an expander creates a new scope, adds the arguments as bindings to this scope,
adds the scope to the contextual set of scopes, and expands the lambda body within this set.
It returns a custom structure with the expanded body.

Another core form is the identifier "application".

Its expander transforms the following expression (which evaluates to `2`):

```lisp
(+ 1 1)
```

into:

```lisp
#<syntax (#%app + (quote 1) (quote 1))>
```

`1` is quoted as it should be passed as a literal value to the compiler.
It cannot be expanded further.

`#%app` is a symbol used internally by Racket's compiler to denote a function application.

Generally speaking, Racket expands all syntax objects in the same way.

Given a datum, the expander transforms it into a syntax,
then depending on the nature of the `content` field value,
a different expansion strategy is followed.

The expander uses helper functions such as `core-form?`, `transformer?`, `symbol?`, and `syntax-identifier?`
to find out the nature of the expression.
These are predicates.
Each one of them takes a datum and returns a boolean value.

The sum expression above is a pair whose head is a syntax identifier:

```lisp
(define (syntax-identifier? s) ; assumes that `s` is syntax
  (symbol? (syntax-content s)))
```

`s` is the head of the expression, that is `+`.
`syntax-content` returns the `content` attribute from the syntax object `s`.

The expander looks for a binding for the function `+` inside the syntax object scopes.
It finds a symbol named `+` inside a module named `runtime`.

The expander uses the application core form expander to expand it.

This is essentially the expander body:

```lisp
(define expr-ctx (as-expression-context ctx)) ;; prepare expansion context
(define exp-rator (expand (car es) expr-ctx)) ;; expanding the head
(define exp-es (for/list ([e (in-list (cdr es))]) (expand e expr-ctx))) ;; expanding the tail

;; returned value (composed from the expanded head and the expanded tail):
(rebuild rebuild-s (cons (m '#%app) (cons exp-rator exp-es)))
```

It prepares a context,
splits the expression into a head and a tail,
expands each,
and joins the results.

Rebuilding at the end prepares a structure for the compiler.

`es` is `+ 1 1`.

Its head is `+`.
It's already expanded.
Its tail is `1 1`.
It's expanded into:

```lisp
(quote 1) (quote 1)
```

The context used for the expansion is created by:

```lisp
(as-expression-context ctx)
```

A context is an essential concept of syntax expansion.
The expander itself gets an instance of `expand-context` together with the syntax-to-expand.

Down the expansion process, new contexts are created and updated, then passed
down to children expanders.

An expansion context contains information about how to resolve the encountered binding
and where to put the introduced bindings.

## Binding expansion

Another core form in Racket is the `let-values` form.

It introduces bindings, such as `x` here:

```lisp
(let-values ([(x) (values 10)])
  (displayln x))
```

The expander of a `let-values` form creates a new scope
(a new `scope` structure) and adds it to the scopes of the given syntax.

It then adds it to each identifier syntax object.
It creates a new binding for each identifier and puts it inside this scope.
And, it adds the same scope to each body syntax object.

Then, to prepare for the expansion, it creates an expansion context.
This one is a copy of the current expansion scope, but with the just-created scope.

Finally, the expander expands the right-hand sides (the identifiers initializations) and the body within this new context.

## Transformer expansion

To expand a manually defined macro, the expander finds the transformer definition, applies it,
and expands the transformed syntax.

The expander creates two new scopes.

The first scope manages the lexical definitions of the macro expansion itself.
It keeps track of the variables used during expansion and discarded afterward.

The second scope, named `use-scope`, manages the lexical definitions of the context of expansion.
The latter makes sure that identifiers introduced by the macro into the surrounding code are interpreted correctly.

It adds both scopes to the subject syntax object scopes.

The expander creates a temporary expansion environment, within which it applies the transformation.
This environment contains a new expansion context, one which is created with the recently built scopes.

This environment is used for getting and setting definitions during macro expansion.

The execution of the macro itself is done by:

```lisp
(call-with-continuation-barrier (lambda () (t use-s)))
```

`t` is the transformer.
`use-s` is the syntax-to-expand with the created scopes.

> A continuation is an abstract representation of the control state of a computer program.
>
> [— Continuation](https://en.wikipedia.org/wiki/Continuation)

The continuation barrier hides identifiers captured during the syntax transformation from the expansion process.
It makes sure that what's defined inside the macro does not interfere with the current scope, nor override parts of the existing environment.
