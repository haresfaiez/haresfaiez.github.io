---
layout:   post
comments: true
title:    "RESSA, Rusty EcmaScript Syntax Analyzer, overview"
date:     2021-06-07 18:00:00 +0100
tags:     featured
---

[RESSA](https://github.com/FreeMasen/RESSA) is a Rusty EcmaScript Syntax Analyzer.
It is a member of a family of tools that manage javascript source code.
These are [RESS](https://github.com/rusty-ecma/RESS), a scanner
responsible for reading and tokenizing EcmaScript source code,
[resast](https://github.com/rusty-ecma/resast), a collection of ECMAScript
AST node types, and [RESW](https://github.com/rusty-ecma/RESW),
an experimental crate for writing javascript code from resast nodes.

## Parser usage
Here is how we parse a hello world function:
```rust
let js = "function helloWorld() { alert('Hello world'); }";
let mut builder = Builder::new();
let mut parser = builder
     .js(js)
     .module(false)
     .build()
     .unwrap();
let ast = parser.parse();
```

We create a builder, we use it to create a parser, then we call `parse` and get the AST.

`Parser` is the main component of RESSA. It navigates the code token by token
and builds the AST.
We might as well create it with default settings and avoid the builder using `Parser::new()`.

The builder is a fluent interface. It takes parameters that guide the parsing.
`is_module` here configures the parser to expect an ES6 module.
When false, the parsing fails if it encounters an import statement.
According to this value also, the result will either be
a `Program::Mod` or a `Program::Script` variant of the `Program` enum.

`Parser` implements the `Iterator` trait.
If we call `parser.next()` many times instead of `parser.parse()`,
the parser keeps returning values of `ProgramPart`.
`parse` indeed calls
[Iterator#collect](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect)
to collect these parts and use them to create a `Program` instance:

```rust
pub fn parse(&mut self) -> Res<Program> {
    if self.context.is_module {
        self.context.strict = true;
    }
    let body: Res<Vec<ProgramPart>> = self.collect();
    Ok(if self.context.is_module {
        Program::Mod(body?)
    } else {
        Program::Script(body?)
    })
}
```

## Sub-parsers
Parsing methods return values of `Res<T>`, which is an alias for the `Result`
type:
```rust
Res<T> = Result<T, Error>
```
`T` is the node type. Each sub-parser sets its subject.
It is `Expr` for `parse_expression`, `Stmt` for `parse_statement`,
`Program` for `parse`, and so on.
Each token type (like `Expr` and `Stmt`) is enum defined inside resast.

`stmt` for example, is defined as:
```rust
pub enum Stmt<'a> {
    Expr(Expr<'a>),
    Block(BlockStmt<'a>),
    Empty,
    Debugger,
    With(WithStmt<'a>),
    Return(Option<Expr<'a>>),
    //...
```

`ProgramPart` is:
```rust
pub enum ProgramPart<'a> {
    /// A Directive like 'use strict';
    Dir(Dir<'a>),
    /// A variable, function or module declaration
    Decl(Decl<'a>),
    /// Any other kind of statement
    Stmt(Stmt<'a>),
}
```

Building an ast node follows the next pattern.
Here we build a loop node:
```rust
// first, we use helpers to parse constituants
let list = self.parse_variable_decl_list(true)?;
let init = some(loopinit::variable(kind, list));

let test = some(self.parse_expression()?);

let update = some(self.parse_expression()?)if;

// here, we parse the body
// we call parse_statement to parse the body.
// we consider the body as one block statement.
let body = self.parse_statement(some(stmtctx::for))?;

// then, we instantiate the forstmt struct
ok(forstmt { init, test, update, body: box::new(body) })
```

I simplified the code by removing edge cases, error conditions, and debug statements.
But, that is how we instantiate structs recursively and build the ast.

## Errors
`error` module defines parsing errors.
There is an `Error` enum with parsing errors as variants.

Error propagation is natural in Rust with the interrogation mark.
Each parsing method returns a `Result<T, Error>` intsance.
Wehen the parsing suceeds, it returns an ast node inside the `Ok` variant:
```rust
Ok(Expr::Spread(Box::new(arg)))
```

otherwise, it returns an error inside an `Err` variant:
```rust
if !self.context.is_module {
    return Err(Error::UseOfModuleFeatureOutsideOfModule(
        self.current_position,
        "es6 import syntax".to_string(),
    ));
}
```

## Scopes
`Parser` has `lexical_names` attribute, which is an instance of `DuplicateNameDetector`.

```rust
pub struct DuplicateNameDetector<'a> {
    pub states: Vec<Scope>,
    lex: LexMap<'a>,
    var: VarMap<'a>,
    func: LexMap<'a>,
    first_lexes: Vec<Option<Cow<'a, str>>>,
    /// Hashmap of identifiers exported
    /// from this module and a flag for if they
    /// have a corresponding declaration
    undefined_module_exports: HashSet<Cow<'a, str>>,
    exports: HashSet<Cow<'a, str>>,
}
```

It tracks lexical scopes inside `states`.
Each state is a variant of the `Scope` enum:

```rust
pub enum Scope {
    Top,
    FuncTop,
    SimpleCatch,
    For,
    Catch,
    Switch,
    Block,
}
```
This stack is managed by `new_child` and `remove_child`.
Those are, in turn, used by parser methods `add_scope` and `remove_scope`,
which are called by the parser when entering a node that creates a new lexical scope.

In `parse_func`, which creates a function AST node, here is a simplified version of what happens:

```rust
fn parse_func(
    &mut self,
) -> Res<Func<'b>> {
    self.add_scope(lexical_names::Scope::FuncTop);
    let params = self.parse_func_params()?;
    let body = self.parse_function_source_el()?;
    self.remove_scope();
    let f = Func {
        id,
        params: params.params,
        body,
        is_async,
        generator: is_gen,
    };
    Ok(f)
}
```

`DuplicateNameDetector` keeps identifiers inside `lex`, `var`, and `func` while assuring the unicity of identifiers.

`func` is a map of functions.
`lex` is a map of let or const and let-defined variables.
`var` is a map of var-defined variables.

The parsing fails if we try to add a new scope element that has the same name
as an existing one.
`DuplicateNameDetector.declare`, which adds a new element to the current scope,
is implemented as follows (simplified version):

```rust
pub fn declare(
    &mut self,
    i: Cow<'a, str>,
    kind: DeclKind,
    pos: Position
)
    -> Res<()> {
    match kind {
        DeclKind::Lex(is_module) => {
            self.check_var(i.clone(), pos)?;
            self.check_func(i.clone(), pos)?;
            self.add_lex(i, pos)
        }
        DeclKind::Func(is_module) => {
            self.check_lex(i.clone(), pos)?;
            if !state.funcs_as_var(is_module) {
                self.check_var(i.clone(), pos)?;
            }
            self.add_func(i, pos)
        }
        DeclKind::SimpleCatch => {
            self.lex.insert(i.clone(), pos);
            Ok(())
        }
    }
}
```

If `check_var` or `check_func` returns an error,
`declare` and the parser itself return it.
