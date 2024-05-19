
## Racket runtime environment, virtual machine

** "Racket CS currently supports three compilation modes:"..?

```txt (src/cs/README.txt)
The Racket CS implementation is organized in layers. The immediate
layer over Chez Scheme is called "Rumble", and it implements delimited
continuations, structures, chaperones and impersonators, engines (for
threads), and similar base functionality. The Rumble layer is
implemented in Chez Scheme.

The rest of the layers are implemented in Racket:

   thread
   io
   regexp
   schemify
   expander

Each of those layers is implemented in a sibling directory of this
one. Each layer is expanded (using "expander", of course) and then
compiled to Chez Scheme (using "schemify") to implement Racket.
```

> Racket uses a combination of compilation and interpretation, and it includes a virtual machine (VM) known as the Racket Virtual Machine (RVM). The architecture allows for a mix of compiled and interpreted code, providing a balance between performance and flexibility.

Racket runtime is defined under [bc/](https://github.com/racket/racket/tree/master/racket/src/bc).

> The Racket BC runtime system is implemented in C and provides the compiler from source to bytecode format, the JIT compiler from bytecode to machine code, I/O functionality, threads, and memory management.
> [Overview (BC)](https://docs.racket-lang.org/inside/overview.html)

** [cs/](https://github.com/racket/racket/tree/master/racket/src/cs) is ..?

Racket and Chez Scheme are distinct implementations of the Scheme language..?
> In the context of Racket, "chez-scheme" is also the name of a package that provides an interface to the Chez Scheme compiler within the Racket ecosystem. This allows Racket programmers to use Chez Scheme's compiler, which is a separate Scheme implementation, as part of their Racket development workflow.

> JIT mode --- The compiled form of a module is an S-expression where
> individual `lambda`s are compiled on demand.
> JIT mode does not perform well and probably should be discontinued.
> [ Machine Code versus JIT](https://github.com/racket/racket/tree/master/racket/src/cs)


** [Garbage collection](https://docs.racket-lang.org/reference/eval-model.html) is ..?




Racket code base contains Scheme files that implement core?? features
> In the Racket programming language, files with the extension ".scm" are Scheme source files.
> These files contain code written in the Scheme programming language,
> which is a dialect of Lisp. Racket extends Scheme and provides additional features, libraries, and tools.

** explain the usage of Scheme in Racket ..?

> You should use Racket to write scripts. But what if you need something
> much smaller than Racket for some reason — or what if you're trying
> to script a build of Racket itself? Zuo is a tiny Racket with
> primitives for dealing with files and running processes, and it comes
> with a `make`-like embedded DSL.
>
> README.md

## The expander module

```txt
From Primitives to Modules
--------------------------

The "expander" layer, as turned into a Chez Scheme library by
"expander.sls", synthesizes primitive Racket modules such as
`'#%kernel` and `'#%network`. The content of those primitive _modules_
at the expander layer is based on primitive _instances_ (which are just
hash tables) as populated by tables in the "primitive" directory. For
example, "primitive/network.scm" defines the content of the
`'#network` primitive instance, which is turned into the primitive
`'#%network` module by the expander layer, which is reexported by the
`racket/network` module that is implemented as plain Racket code. The
Racket implementation in "../racket" provides those same primitive
instances to the macro expander.
```

** expander as part of the Racket runtime ..?

The expander is part of Racket interpretation?? with both CS and BC:
> For Racket CS, go to "racket/src/cs" in the repo and run `zuo`. (See also "Running zuo" below.) That will update files in "racket/src/cs/schemified"...
> ...
> For Racket BC, run `zuo` here, which will update the file 
> "racket/src/bc/src/startup.inc".

** "Zuo: A Tiny Racket for Scripting" is ..?
** role of Zuo in Racket ..?

The linket as defined by ChatGPT is
> In Racket, a linklet is a unit of compilation and linking that can be used
> to create standalone executables or libraries. Linklets are a part of Racket's
> approach to incremental compilation and separate compilation.

> They are a mechanism that enables the separation of the compilation process into smaller units, allowing for faster and more efficient compilation of Racket code.

> Racket achieves incremental compilation by using linklets. When a module is compiled, the result is a linklet,
> which is a compact representation of the compiled module. Linklets are stored separately,
> and they contain all the information needed to execute the module.

The entry point to the expainder is the `main.rkt` module.

```md
 main.rkt - installs eval handler, etc.; entry point for directly
            running the expander/compiler/evaluator, and the provided
            variables of this module become the entry points for the
            embedded expander
```

The module provides (aka. exports) variables (their usages..?) and functions (and ..?).

```lisp
;; All bindings provided by this module must correspond to variables
;; (as opposed to syntax). Provided functions must not accept keyword
;; arguments, both because keyword support involves syntax bindings
;; and because an embedding context won't be able to supply keyword
;; arguments.
```

** why only variables..? because it's an "expander" ..?

Functions that accept keyword arguments are named arguments.
Keyword arguments are not possible because they're implemented using syntax transformer,
which is defined by the module itself??.

** The interface provided by `main.rkt` is ...?

** when we `require` a Racket file multiple times, do the statements re-execute or not..?
> Internal effects are exemplified by mutation.
> ...
> External effects are exemplified by input/output (I/O).
> ...
> An effect is discarded when it is no longer detectable... Because external effects are intrinsically observable outside Racket, they are irreversible and cannot be discarded.
> ...
> In particular, if module A is shared by the phase 1 portion of modules X and Y, then any internal effects while X is compiled are not visible during the compilation of Y, regardless of whether X and Y are compiled during the same execution of Racket’s runtime system and regardless of the order of compilation.
> https://docs.racket-lang.org/reference/eval-model.html#%28tech._instantiation%29

** when is `main.rkt` imported in a normal Racket script..?



`core-forms` is used inside `declare-core-module!`, defined in `namespace/core.rkt`.

During the initialization inside `expander/main.rkt`, there's a call:

```lisp
(declare-core-module! ns)
```
** `ns` is ..?

`declare-core-module!` skeleton is:

```lisp
(define (declare-core-module! ns)
  (declare-module!
    ns
    (make-module ...)
    core-module-name
    )
  )
```

`core-module-name` is defined at the beginning of the file, see above.
`ns` is the value used for `declare-core-module!` call previously.

`make-module` defines a `(module ...)` s-expression.
** Such expression defines a module whose name is ..?

** this module is used by ..? to ..?

The module is defined with `provides`, `phase-level-linklet-info-callback`,
and `instantiate-phase-callback`.

`provides` defines the bindings??(procedures..?) that'll be exported from the module.
The modules exports the core primitives and the core forms.
For each element inside `core-primitives` and `core-forms`, it evaluates:

```lisp
(define b (make-module-binding core-mpi 0 sym))
(values sym (cond
              [syntax? (provided b #f #t)]
              [(protected-core? val) (provided b #t #f)]
              [else b]))
```
** explain this ..?
** `syntakx?` is an iterator defined as `[syntax? (in-list '(#f #t))]` ..?
** is it because for primitives it's `#f` and for forms it's a syntax transformation so `#t` ..?

** `phase-level-linklet-info-callback` passed to create a module is ..?

** `instantiate-phase-callback` passed to create a module is ..?

** An example from `module.rkt` is ..?

** An example from `top.rkt` is ..?

** The initialization and the configuration of namespace is ..?
```lisp
(namespace-init!)
(install-error-syntax->string-handler!)

(set-load-configure-expand!
 (lambda (mpi ns)
   (let ([config-m (module-path-index-join '(submod "." configure-expand) mpi)])
     (if (module-declared? config-m #t)
         (parameterize ([current-namespace ns])
           (let ([enter (dynamic-require config-m 'enter-parameterization)]
                 [exit (dynamic-require config-m 'exit-parameterization)])
             (unless (and (procedure? enter)
                          (procedure-arity-includes? enter 0))
               (raise-result-error 'configure-expand "(procedure-arity-includes/c 0)" enter))
             (unless (and (procedure? enter)
                          (procedure-arity-includes? exit 0))
               (raise-result-error 'configure-expand "(procedure-arity-includes/c 0)" exit))
             (values enter exit)))
         (values current-parameterization
                 current-parameterization)))))
```

** `(namespace-init!)` is ..?

**`(install-error-syntax->string-handler!)` is ..?

** `(set-load-configure-expand! ...` is ..?
Calling `add-core-form!` adds a new from to the first hashset:

```lisp
(define-syntax-rule (add-core-form! sym proc)
  ;; The `void` wrapper suppress a `print-values` wrapper:
  (void (add-core-form!* sym proc))
  )
  
(define (add-core-form!* sym proc)
  (add-core-binding! sym)
  (set! core-forms (hash-set core-forms sym proc))
  )
```
** explain this..?

At the beginning of this file, the expander defines hashsets for forms and primitives:

```lisp
;; Core forms and primitives are added by `require`s in "expander.rkt"

;; Accumulate added core forms and primitives:
(define core-forms #hasheq())
(define core-primitives #hasheq())
```

** explain how this value is persisted between `require`s..?

** `hasheq` is ..?

`core.rkt` contains also at the top:

```lisp
;; Accumulate all core bindings in `core-scope`, so we can
;; easily generate a reference to a core form using `core-stx`:
(define core-scope (new-multi-scope))
(define core-stx (add-scope empty-syntax core-scope))

(define core-module-name (make-resolved-module-path '#%core))
(define core-mpi (module-path-index-join ''#%core #f))

;; The expander needs to synthesize some core references

(define-place-local id-cache-0 (make-hasheq))
(define-place-local id-cache-1 (make-hasheq))

(define (core-place-init!)
  (set! id-cache-0 (make-hasheq))
  (set! id-cache-1 (make-hasheq)))
```
** explain this..?

When importing the main module, it registers core forms and core primitives,
then initiliazes and configure the namespace?? (which namespace..?).

The registrations are managed by internal modules:

```lisp
;; Register core forms:
(require "expand/expr.rkt"
         "expand/module.rkt"
         "expand/top.rkt")

;; Register core primitives:
(require "boot/core-primitive.rkt")
```

All of `expr.rkt`, `module.rkt`, and `top.rkt` contain only binding with `(define...)`
and evaluations of `(add-core-form ...)`.



A transformer in Racket is close(similar??) to a "macro" in Lisp.

> Every binding has a phase level in which it can be referenced, where a phase level normally corresponds to an integer (but the special label phase level does not correspond to an integer). Phase level 0 corresponds to the run time of the enclosing module (or the run time of top-level expressions). Bindings in phase level 0 constitute the base environment. Phase level 1 corresponds to the time during which the enclosing module (or top-level expression) is expanded; bindings in phase level 1 constitute the transformer environment. Phase level -1 corresponds to the run time of a different module for which the enclosing module is imported for use at phase level 1 (relative to the importing module); bindings in phase level -1 constitute the template environment. The label phase level does not correspond to any execution time; it is used to track bindings (e.g., to identifiers within documentation) without implying an execution dependency.

>An identifier can have different bindings in different phase levels. More precisely, the scope set associated with a form can be different at different phase levels; a top-level or module context implies a distinct scope at every phase level, while scopes from macro expansion or other syntactic forms are added to a form’s scope sets at all phases. The context of each binding and reference determines the phase level whose scope set is relevant.
>
> https://docs.racket-lang.org/reference/syntax-model.html#%28tech._phase._level%29


## Appendix: all calls to `expand`
#<syntax (#%app (let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote ot...>
expand/
#<syntax (let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other))))...>
expand-id-application-form/
#<syntax (let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other))))...>
expand/
#<syntax (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))))>
expand-id-application-form/
#<syntax (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))))>
expand/
#<syntax (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))))>
expand-id-application-form/
#<syntax (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))))>
expand/
#<syntax (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))>
expand-id-application-form/
#<syntax (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))>
expand/
#<syntax (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))>
expand-id-application-form/
#<syntax (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))))>

expand/
#<syntax (car (cdr (syntax-e stx)))>
expand-id-application-form/
#<syntax (car (cdr (syntax-e stx)))>
expand-implicit/
#%app
#<syntax (car (cdr (syntax-e stx)))>
add-core-form!/
#<syntax (#%app car (cdr (syntax-e stx)))>
expand/
#<syntax car>
expand/
#<syntax (cdr (syntax-e stx))>
expand-id-application-form/
#<syntax (cdr (syntax-e stx))>
expand-implicit/
#%app
#<syntax (cdr (syntax-e stx))>
add-core-form!/
#<syntax (#%app cdr (syntax-e stx))>
expand/
#<syntax cdr>
expand/
#<syntax (syntax-e stx)>
expand-id-application-form/
#<syntax (syntax-e stx)>
expand-implicit/
#%app
#<syntax (syntax-e stx)>
add-core-form!/
#<syntax (#%app syntax-e stx)>
expand/
#<syntax syntax-e>
expand/
#<syntax stx>
expand/
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand-id-application-form/
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand-implicit/
#%app
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand/
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand-id-application-form/
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand-implicit/
#%app
#<syntax (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
add-core-form!/
#<syntax (#%app datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
expand/
#<syntax datum->syntax>
expand/
#<syntax (quote-syntax here)>
expand-id-application-form/
#<syntax (quote-syntax here)>
expand/
#<syntax (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))>
expand-id-application-form/
#<syntax (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))>
expand-implicit/
#%app
#<syntax (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))>
add-core-form!/
#<syntax (#%app list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))>
expand/
#<syntax list>
expand/
#<syntax (quote lambda)>
expand-id-application-form/
#<syntax (quote lambda)>
expand/
#<syntax (quote (x))>
expand-id-application-form/
#<syntax (quote (x))>
expand/
#<syntax (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))>
expand-id-application-form/
#<syntax (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))>
expand-implicit/
#%app
#<syntax (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))>
add-core-form!/
#<syntax (#%app list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))>
expand/
#<syntax list>
expand/
#<syntax (quote let-values)>
expand-id-application-form/
#<syntax (quote let-values)>
expand/
#<syntax (list (list (list misc-id) (quote (quote other))))>
expand-id-application-form/
#<syntax (list (list (list misc-id) (quote (quote other))))>
expand-implicit/
#%app
#<syntax (list (list (list misc-id) (quote (quote other))))>
add-core-form!/
#<syntax (#%app list (list (list misc-id) (quote (quote other))))>
expand/
#<syntax list>
expand/
#<syntax (list (list misc-id) (quote (quote other)))>
expand-id-application-form/
#<syntax (list (list misc-id) (quote (quote other)))>
expand-implicit/
#%app
#<syntax (list (list misc-id) (quote (quote other)))>
add-core-form!/
#<syntax (#%app list (list misc-id) (quote (quote other)))>
expand/
#<syntax list>
expand/
#<syntax (list misc-id)>
expand-id-application-form/
#<syntax (list misc-id)>
expand-implicit/
#%app
#<syntax (list misc-id)>
add-core-form!/
#<syntax (#%app list misc-id)>
expand/
#<syntax list>
expand/
#<syntax misc-id>
expand/
#<syntax (quote (quote other))>
expand-id-application-form/
#<syntax (quote (quote other))>
expand/
#<syntax (quote x)>
expand-id-application-form/
#<syntax (quote x)>
expand/
#<syntax (lambda (stx) (let-values (((misc-id) (#%app car (#%app cdr (#%app syntax-e stx))))) (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quot...>
expand-id-application-form/
#<syntax (lambda (stx) (let-values (((misc-id) (#%app car (#%app cdr (#%app syntax-e stx))))) (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quot...>
expand/
#<syntax (let-values (((misc-id) (#%app car (#%app cdr (#%app syntax-e stx))))) (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (q...>
expand-id-application-form/
#<syntax (let-values (((misc-id) (#%app car (#%app cdr (#%app syntax-e stx))))) (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (q...>
expand/
#<syntax (#%app car (#%app cdr (#%app syntax-e stx)))>
expand-id-application-form/
#<syntax (#%app car (#%app cdr (#%app syntax-e stx)))>
add-core-form!/
#<syntax (#%app car (#%app cdr (#%app syntax-e stx)))>
expand/
#<syntax car>
expand/
#<syntax (#%app cdr (#%app syntax-e stx))>
expand-id-application-form/
#<syntax (#%app cdr (#%app syntax-e stx))>
add-core-form!/
#<syntax (#%app cdr (#%app syntax-e stx))>
expand/
#<syntax cdr>
expand/
#<syntax (#%app syntax-e stx)>
expand-id-application-form/
#<syntax (#%app syntax-e stx)>
add-core-form!/
#<syntax (#%app syntax-e stx)>
expand/
#<syntax syntax-e>
expand/
#<syntax stx>
expand/
#<syntax (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))))>
expand-id-application-form/
#<syntax (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))))>
add-core-form!/
#<syntax (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))))>
expand/
#<syntax datum->syntax>
expand/
#<syntax (quote-syntax here)>
expand-id-application-form/
#<syntax (quote-syntax here)>
expand/
#<syntax (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x)))>
expand-id-application-form/
#<syntax (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x)))>
add-core-form!/
#<syntax (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x)))>
expand/
#<syntax list>
expand/
#<syntax (quote lambda)>
expand-id-application-form/
#<syntax (quote lambda)>
expand/
#<syntax (quote (x))>
expand-id-application-form/
#<syntax (quote (x))>
expand/
#<syntax (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))>
expand-id-application-form/
#<syntax (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))>
add-core-form!/
#<syntax (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))>
expand/
#<syntax list>
expand/
#<syntax (quote let-values)>
expand-id-application-form/
#<syntax (quote let-values)>
expand/
#<syntax (#%app list (#%app list (#%app list misc-id) (quote (quote other))))>
expand-id-application-form/
#<syntax (#%app list (#%app list (#%app list misc-id) (quote (quote other))))>
add-core-form!/
#<syntax (#%app list (#%app list (#%app list misc-id) (quote (quote other))))>
expand/
#<syntax list>
expand/
#<syntax (#%app list (#%app list misc-id) (quote (quote other)))>
expand-id-application-form/
#<syntax (#%app list (#%app list misc-id) (quote (quote other)))>
add-core-form!/
#<syntax (#%app list (#%app list misc-id) (quote (quote other)))>
expand/
#<syntax list>
expand/
#<syntax (#%app list misc-id)>
expand-id-application-form/
#<syntax (#%app list misc-id)>
add-core-form!/
#<syntax (#%app list misc-id)>
expand/
#<syntax list>
expand/
#<syntax misc-id>
expand/
#<syntax (quote (quote other))>
expand-id-application-form/
#<syntax (quote (quote other))>
expand/
#<syntax (quote x)>
expand-id-application-form/
#<syntax (quote x)>
expand/
#<syntax (identity x)>
expand-id-application-form/
#<syntax (identity x)>
expand/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand-id-application-form/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand-id-application-form/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand/
#<syntax (let-values (((x) (quote other))) x)>
expand-id-application-form/
#<syntax (let-values (((x) (quote other))) x)>
expand/
#<syntax (let-values (((x) (quote other))) x)>
expand-id-application-form/
#<syntax (let-values (((x) (quote other))) x)>
expand/
#<syntax (quote other)>
expand-id-application-form/
#<syntax (quote other)>
expand/
#<syntax x>
expand/
#<syntax x>
expand/
#<syntax (quote ok)>
expand-id-application-form/
#<syntax (quote ok)>
#<syntax (#%app (let-values () (let-values () (lambda (x) (let-values (((x) (quote other))) x)))) (quote ok))>

## Compilation (outside the scope of the post?)

`expander` defines a `compile` binding?/proc? to compile an expression.
** where's this `racket/src/expander/eval/main.rkt/compile` is used ..? and how..?

The compilation is mainly done by `per-top-level`:

```lisp
;; Top-level compilation and evaluation, which involves partial
;; expansion to detect `begin` and `begin-for-syntax` to interleave
;; expansions
(define (per-top-level given-s ns
                       #:single single        ; handle discovered form; #f => stop after immediate
                       #:combine [combine #f] ; how to cons a recur result, or not
                       #:wrap [wrap #f]       ; how to wrap a list of recur results, or not
                       #:just-once? [just-once? #f] ; single expansion step
                       #:quick-immediate? [quick-immediate? #t]
                       #:serializable? [serializable? #f] ; for module+submodule expansion
                       #:observer observer)
```

First, `per-top-level` initializes:

```lisp
  (define s (maybe-intro given-s ns))
  (define ctx (make-expand-context ns #:observer observer))
  (define phase (namespace-phase ns))
```

The expression is passed as `given-s`.
`maybe-intro` is:

```lisp
(define (maybe-intro s ns)
  (if (syntax? s)
      s
      (namespace-syntax-introduce (datum->syntax #f s) ns)
      )
  )
```

** `s`, the value used later inside `per-top-level` is ..?

** `define ctx` is ..?

** `define phase` is ..?

Then a recursive execution of an inline proc?/fun? starts:

```lisp
(let loop ([s s] [phase phase] [ns ns] [as-tail? #t])
  ;; ...
  )
```
** explain this..?


Then:
```lisp
(if (and (= 1 (length cs))
           (not (compiled-multiple-top? (car cs))))
      (car cs)
      (compiled-tops->compiled-top cs
                                   #:to-correlated-linklet? to-correlated-linklet?
                                   #:merge-serialization? serializable?
                                   #:namespace ns))
```
** explain this..?

** `compiled-expression?` check is ..?

** `syntax?` check is ..?

** The evaluation of the compiled expression is done with `(eval ready-c ns)` ..?

## core form expansion

If we log all the evaluations of the core form expansion function, we get:
```
#<syntax (#%app (let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote ot...>
#<syntax (#%app car (cdr (syntax-e stx)))>
#<syntax (#%app cdr (syntax-e stx))>
#<syntax (#%app syntax-e stx)>
#<syntax (#%app datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))>
#<syntax (#%app list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x)))>
#<syntax (#%app list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))>
#<syntax (#%app list (list (list misc-id) (quote (quote other))))>
#<syntax (#%app list (list misc-id) (quote (quote other)))>
#<syntax (#%app list misc-id)>
#<syntax (#%app car (#%app cdr (#%app syntax-e stx)))>
#<syntax (#%app cdr (#%app syntax-e stx))>
#<syntax (#%app syntax-e stx)>
#<syntax (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))))>
#<syntax (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x)))>
#<syntax (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quote other)))) (quote x))>
#<syntax (#%app list (#%app list (#%app list misc-id) (quote (quote other))))>
#<syntax (#%app list (#%app list misc-id) (quote (quote other)))>
#<syntax (#%app list misc-id)>
#<syntax (#%app (let-values () (let-values () (lambda (x) (let-values (((x) (quote other))) x)))) (quote ok))>
```

### Expanding lambda

Then expand is called with:
```
#<syntax (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other)))) (quote x))))))>
```
** why..?

The `lambda` core form is defined in `expr.rkt`:
```lisp
(add-core-form!
 'lambda
  (lambda (s ctx)
  ...
```
** explain this..?

Then, the recursion continues.

This happens:
```
expand/
#<syntax (car (cdr (syntax-e stx)))>
expand-id-application-form/
#<syntax (car (cdr (syntax-e stx)))>
expand-implicit/
#%app
#<syntax (car (cdr (syntax-e stx)))>
add-core-form!/
#<syntax (#%app car (cdr (syntax-e stx)))>
```
** explain this..?

Then this (`#%app` are introduced):
```
expand/
#<syntax (lambda (stx) (let-values (((misc-id) (#%app car (#%app cdr (#%app syntax-e stx))))) (#%app datum->syntax (quote-syntax here) (#%app list (quote lambda) (quote (x)) (#%app list (quote let-values) (#%app list (#%app list (#%app list misc-id) (quote (quot...>
```



### End result evaluation

And finally:
```
expand/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand-id-application-form/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand/
#<syntax (let-values (((x) (quote other))) x)>
expand-id-application-form/
#<syntax (let-values (((x) (quote other))) x)>
expand/
#<syntax (let-values (((x) (quote other))) x)>
expand-id-application-form/
#<syntax (let-values (((x) (quote other))) x)>
expand/
#<syntax (quote other)>
expand-id-application-form/
#<syntax (quote other)>
expand/
#<syntax x>
expand/
#<syntax x>
expand/
#<syntax (quote ok)>
expand-id-application-form/
#<syntax (quote ok)>
#<syntax (#%app (let-values () (let-values () (lambda (x) (let-values (((x) (quote other))) x)))) (quote ok))>
```
** explain this..?

### Syntax expansion, `identity`


Then macro expansion:
```
expand/
#<syntax (identity x)>
expand-id-application-form/
#<syntax (identity x)>
expand/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
expand-id-application-form/
#<syntax (lambda (x) (let-values (((x) (quote other))) x))>
```
Here `dispatch` delegates to `dispatch-transformer`,
because `(transformer? t)` is true.
** explain this..?

## (+ 1 1)


Inside this, the expansion is defined by:

```lisp
(define exp-e (expand-expression e #:namespace ns))
```

`e` is `(+ 1 1)`. `ns` is `demo-ns`, the namespace of the demo module.

`expand-expression` expands the expression:

```lisp
(define (expand-expression e #:namespace [ns demo-ns])
  (expand
    (namespace-syntax-introduce (datum->syntax #f e) ns)
    ns
    )
  )
```
** explain this ..?

** `namespace-syntax-introduce` and `datum->syntax` do ..?


`namespace-syntax-introduce` is:
> Returns a syntax object like stx, except that namespace’s bindings are included in the syntax object’s lexical information
```lisp
(define/who (namespace-syntax-introduce s [ns (current-namespace)])
```
** explain this..?


It's defined by a symbol and a procedure (`add-core-form` is defined in `namespace/core.rkt`):

```lisp
(add-core-form!
 'lambda
  (lambda (s ctx)
    (
      ;;; ...
    ))
```
** explain this..?

This form defines `'lambda` syntax abbreviation.
It's from `expand/expr.rkt`.

`add-core-form` is defined (really..?) as:
```racket
(define-syntax-rule (add-core-form! sym proc)
  ;; The `void` wrapper suppress a `print-values` wrapper:
  (void (add-core-form!* sym proc)))
  
(define (add-core-form!* sym proc)
  (add-core-binding! sym)
  (set! core-forms (hash-set core-forms
                             sym
                             proc)))
```
** explain this..?
** why we can use `define-syntax-rule` before expanding ..?
** other usages of `add-core-form!`, like `'quote`, `'if`, `'#%top`..?


`transformer?` is defined as:
```lisp
(define (transformer? t) (or (procedure? t)
                             (set!-transformer? t)
                             (rename-transformer? t)))
```
** explain this ..?

** A core form, that is an expression whose head is `'core-form` is ..?:
```lisp
(define (make-? tag) (lambda (v) (and (pair? v) (eq? tag (car v)))))
(define core-form? (make-? 'core-form))
```
** explain this..?

The definition attaches a symbol to a function.
That function is called by `core-form-expander`.

`core-form-expander`, which is defined inside `(add-core-form! '#%app (lambda (s ctx)...`,
gets two arguments: an expression and an application context.

*********** SHOULD WE KEEP THIS
> its lexical information can be combined with the global table of bindings to determine its binding (if any) at each phase level.

** A phase is ..? (check `phase.rkt` and the usages of its functions ..?)
** Each binding belongs to a phase..?
> Every binding has a phase level in which it can be referenced
** find otu where phase is incremented/decremented in the code..?

Bindings are phase-related.

`new-scope` is defined as:

```lisp
;; Each new scope increments the counter, so we can check whether one
;; scope is newer than another.
(define-place-local id-counter 0)
(define (new-scope-id!)
  (set! id-counter (add1 id-counter))
  id-counter)

;; HERE:
(define (new-scope kind)
  (scope (new-scope-id!) kind empty-binding-table))
```
*********** END

Another example from `demo.rkt` is:

```lisp
'(let-values ()
  (define-syntaxes (identity)
    (lambda (stx)
      (let-values ([(misc-id) (car (cdr (syntax-e stx)))])
        (datum->syntax
        (quote-syntax here)
        (list 'lambda '(x)
              (list 'let-values (list
                                  (list (list misc-id) ''other))
                    'x))))))
  (identity x))
```

It expands to:

```lisp
;;; ...
```

The expression, when transformed into a syntax, becomes:

```lisp
#<syntax ((let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote...
```

## Apllication expander

The strategy handler starts by creating a `binding`:

```lisp
(define binding (resolve+shift id (expand-context-phase ctx)
                                  #:ambiguous-value 'ambiguous
                                  #:immediate? #t))
```

The binding is:

```lisp
#(struct:simple-module-binding #<module-path-index:'#%runtime> 0 + #<module-path-index:'#%kernel>)
```

Then it evaluates:
```lisp
(define-values (t primitive? insp-of-t protected?)
       (lookup binding ctx id
               #:in (and alternate-id (car (syntax-e s)))
               #:out-of-context-as-variable? (expand-context-in-local-expand? ctx)))
```
** explain this..?

AS `t` is a variable, the function returns:

```lisp
(expand-implicit '#%app (substitute-alternate-id s alternate-id) ctx id)
```
** `(substitute-alternate-id s alternate-id)` is ..? `#<syntax (+ 1 1)>` ..?
** explain `expand-implicit` ..?

`expand-implicit` creates a syntax object from `s`:

```lisp
(define id (datum->syntax s sym))
```
`sym` is `'#%app`.

** Finally, after the expander figures out what the subject is ..?

```lisp
;; An "application" form that doesn't start with an identifier, so use implicit `#%app`
(expand-implicit '#%app s ctx #f)
```
** Implicit expansion is ..?

And because `sym` is an application, the next expression is returned:

```lisp
(dispatch-core-form t (make-explicit ctx sym s) ctx)
```

`make-explicit` changes the expression from
`#<syntax #<syntax ((let-values () (define-syntaxes (identity) (lambda (stx)...`
to
`#<syntax #<syntax (#%app (let-values () (define-syntaxes (identity) (lambda (stx)...`.
** how ..? validate this..?

`dispatch-core-form` is documented as a `Call a core-form expander (e.g., \``lambda``)`.

Which in turn returns:

```lisp
((core-form-expander t) s ctx)
```
`t` is the value created here above.

The result of this is the expanded, that is `exp-es` is:

```lisp
(#<syntax (quote ok)>)
```
** ssure ..?

************************** DEBUGGING OUTPUT
** `es` is ..?`
```lisp
(define-match m s '(#%app e ...))
(define es (m 'e))
```

`(car es)` is:

```
#<syntax (let-values () (define-syntaxes (identity) (lambda (stx) (let-values (((misc-id) (car (cdr (syntax-e stx))))) (datum->syntax (quote-syntax here) (list (quote lambda) (quote (x)) (list (quote let-values) (list (list (list misc-id) (quote (quote other))))...>
```

`exp-rator` value will be:
```
#<syntax (let-values () (let-values () (lambda (x) (let-values (((x) (quote other))) x))))>
```

`(cdr es)` is:

```lisp
(#<syntax (quote ok)>)
```

`exp-es` value will be:

```lisp
#<syntax (quote ok)>
```

`expr-ctx` is `#<expand-context>`.
** explain `as-expression-context`..?
**************************

*************** SUMMIRAZE/MOVE/REMOVE
The head extracted in the previous step is in the form:

```lisp
#<syntax (let-values () (define-syntaxes (identity) 
```
Calling `expand` with it calls `expand-id-application-form` in turn,
which ends up evaluating (** why..?):

```lisp
;; Find out whether it's bound as a variable, syntax, or core form
(define-values (t primitive? insp-of-t protected?)
  (lookup binding ctx id
          #:in (and alternate-id (car (syntax-e s)))
          #:out-of-context-as-variable? (expand-context-in-local-expand? ctx)))
;; ...
(dispatch-core-form t s ctx)
```

`t` indeed is `#(struct:core-form #<procedure:...der/expand/expr.rkt:175:2> let-values)`.
It's the core form expander of a `let-values` expression.
And it's defined next to the `app` core form definition, with a function named `make-let-values-form`.

The documentation of the function says:
```lisp
;; Common expansion for `let[rec]-[syntaxes+]values`
```
** explain the form ..?

`make-let-values-form` a factory for core form expanders.
It's used to create three core forms (`let-values`, `letrec-values`, and `letrec-syntaxes+values`).
`let-values` form is defined as:

```lisp
(add-core-form!
 'let-values
 (make-let-values-form #:log-tag 'prim-let-values))
```

It takes three boolean arguments: `syntaxes?`, `rec?`, and `split-by-reference`.
** explain them..?

It returns the expander. That is, it returns a function that takes an expression
and a context and returns (**what..?)
*************** END > SUMMIRAZE/MOVE/REMOVE


## Let-values expansion



First, the exander initializes:

```lisp
(define sc (and (not (expand-context-parsing-expanded? ctx)) (new-scope 'local)))
(define phase (expand-context-phase ctx))
```

`expand-context` structure has a property named `parsing-expanded`,
it's true when `to-parsed?` is true.
`phase` is also a property inside `expand-context`.
`sc` means `scope`.

Then the expander `adds the new scope to each binding identifier`:

```lisp
(define-match val-m s #:unless syntaxes?
  '(let-values ([(id:val ...) val-rhs] ...)
      body ...+))

(define val-idss (let ([val-idss (if syntaxes? (stx-m 'id:val) (val-m 'id:val))])
          (if sc
              (for/list ([ids (in-list val-idss)])
                (for/list ([id (in-list ids)])
                  (add-scope id sc)))
              val-idss)))

(define val-clauses ; for syntax tracking
      (define-match m s '(_ (clause ...) . _))
      (m 'clause)
    )

(check-no-duplicate-ids (list trans-idss val-idss) phase s)
```

The next step is
`binding each left-hand identifier and generate a corresponding key fo the expand-time environment`:

```lisp
    (define counter (root-expand-context-counter ctx))
    (define local-sym (and (expand-context-normalize-locals? ctx) 'loc))
    (define val-keyss (for/list ([ids (in-list val-idss)])
                        (for/list ([id (in-list ids)])
                          (if sc
                              (add-local-binding! id phase counter
                                                  #:frame-id frame-id #:in s
                                                  #:local-sym local-sym)
                              (existing-binding-key id  (expand-context-phase ctx))))))
```

`expand-context` has a field `normalize-locals`: `normalize-locals? ; forget original local-variable names`.
`local-sym` is always false. `counter` is incremented each time.

** `existing-binding-key` is ..?

Then the new scope is added to the body:

```lisp
(define bodys (let ([bodys (val-m 'body)])
    (if sc
        (for/list ([body (in-list bodys)])
              (add-scope body sc))
        bodys))
)
```



Then, it extends the environment, that is, it `Fill expansion-time environment`:

```lisp
(define rec-env
      (for/fold ([env (expand-context-env ctx)]) ([keys (in-list val-keyss)]
                                                  [ids (in-list val-idss)]
                                                  #:when #t
                                                  [key (in-list keys)]
                                                  [id (in-list ids)])
        (env-extend env key (local-variable id))))
```

This creates an environment `rec-env`.

The steps of its body are:
```lisp
 ; accumulates info on referenced variables [*]
    ;; Add the new scope to each binding identifier: [*]
    ;; Bind each left-hand identifier and generate a corresponding key fo the expand-time environment:
    ;; Add new scope to body:
    ;; Fill expansion-time environment:
    ;; Expand right-hand sides and body
```


*********************************** APPENDIX LET_VALUES EXPANDER
```lisp
;; EXP: #f if expand target is a parsed expression || `#<syntax let-values>`
(define letrec-values-id (and (not (expand-context-to-parsed? ctx)) (val-m 'let-values) ))

;; EXP: selectively retain parts of a syntax object based on specified conditions
(define rebuild-s (keep-as-needed ctx s #:keep-for-error? #t))

;; EXP: datum->syntax ... (syntax-e val-id) || val-ids
(define val-name-idss (if (expand-context-to-parsed? ctx) (for/list ([val-ids (in-list val-idss)]) (for/list ([val-id (in-list val-ids)]) (datum->syntax #f (syntax-e val-id) val-id val-id))) val-idss))
```
Finally:

```lisp
;; EXP: 
(define result-s
  ;; EXP: expanded let-values' values
  (define clauses
        (for/list ([ids (in-list val-name-idss)]
                  [keys (in-list val-keyss)]
                  [rhs (in-list val-rhss)]
                  [clause (in-list val-clauses)])
          (define exp-rhs (expand rhs (as-named-context expr-ctx ids)))
          (if (expand-context-to-parsed? ctx) (list keys exp-rhs) (datum->syntax #f `[,ids ,exp-rhs] clause clause) )))
      ;; EXP: expand body   
      ;; EXP: expand each body element within rec-ctx || ....
      (define exp-body 
        (cond
            [(expand-context-parsing-expanded? ctx) (for/list ([body (in-list bodys)]) (expand body rec-ctx))]
            [else
              (define body-ctx (struct*-copy expand-context rec-ctx [reference-records orig-rrs]))
              (expand-body bodys (as-tail-context body-ctx #:wrt ctx) #:source rebuild-s)])
      )
      ;; EXP: result
      (if (expand-context-to-parsed? ctx) (parsed-let-values rebuild-s val-name-idss clauses exp-body) (rebuild rebuild-s `(,letrec-values-id ,clauses ,@exp-body)) )
)

;; EXP: return value
(if (expand-context-to-parsed? ctx)
    result-s
    (attach-disappeared-transformer-bindings result-s trans-idss))
```

*********************************** END // APPENDIX LET_VALUES EXPANDER


## Transformer expansion


*********** SUMMIRIZE/MOVE/REMOVE

When the expander encounters a transformer, that is, a manually defined
** syntax object, it delegates to ``..?

The last expression inside the body of `let-values` is:

```lisp
(identity x)
```

`identity` is not a core form. It's a transformer.

Racket uses `dispatch-transformer` instead of `dispatch-core-form`.

`dispatch-transformer` documentation says:

```lisp
;; Call a macro expander, taking into account whether it works
;; in the current context, whether to expand just once, etc.
```
** explain this..?
  
`t` is created at the beginning of the expression expansion:

```lisp
;; Find out whether it's bound as a variable, syntax, or core form
(define-values (t primitive? insp-of-t protected?)
  (lookup binding ctx id
          #:in (and alternate-id (car (syntax-e s)))
          #:out-of-context-as-variable? (expand-context-in-local-expand? ctx)))
```
** explain this..?

Same with `binding`:

```lisp
(define binding (resolve+shift id (expand-context-phase ctx)
                                  #:ambiguous-value 'ambiguous
                              
                                  #:immediate? #t))
```
** explain this..?
*********** END > SUMMIRIZE/MOVE/REMOVE

The expander evaluates:

 * `t` is `#<procedure>`
 * `insp-of-t` is `#f`
 * `s` is `#<syntax (identity x)>`
 * `id` is `#<syntax identity>`, the evaluation of `(define id (car (syntax-e s)))`
 * `ctx` is `#<expand-context>`
 * `binding` is `#<full-local-binding>`
** how binding is computed..?

And:
 * `exp-s` is `#<syntax (lambda (x) (let-values (((x) (quote other))) x))>`
 * `re-ctx` is ..?

The documentation of `apply-transformer` is:

```lisp
;; Given a macro transformer `t`, apply it --- adding appropriate
;; scopes to represent the expansion step; the `insp-of-t` inspector
;; is the inspector of the module that defines `t`, which gives its
;; privilege for accessing bindings
(define (apply-transformer t insp-of-t s id ctx binding #:origin-id [origin-id #f])
  ;; ...
```
** explain the description..?
And it keeps track for the before-expansion scopes:
```lisp
;; Keep old def-ctx-scopes box, so that we don't lose them at the point where expansion stops
[def-ctx-scopes (expand-context-def-ctx-scopes ctx)]
```



```lisp
(add-local-binding! id phase counter #:frame-id frame-id #:in s #:local-sym local-sym)
```
`counter` is an index that's incremented each time the scope is created.
** validate this..? `(define counter (root-expand-context-counter ctx))`
** explain this..?

On the other hand, `add-scope` adds scopes dynamically to expressions.
** We call `add-scope` to ..?
** its usages ..?