---
layout:   post
comments: true
title:    "Indentation internals in Emacs"
date:     2023-12-01 12:02:00 +0100
tags:     featured
---

Lisp will not respect many of what we know as "best practice".
You'll encounter things like this

> KEYS-AND-BODY should have the form of a property list, with the exception
> that the tail -- the body -- is a list of forms that does not start with a
> keyword.

** why we sturcture it this way...?

** different priorities ?? habitable software?? debuggable? expandable?

## Emacs automated tests

** to start testing, we pass a parameter `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))`.

## Javascript indentation test

** `js-tests.el` is ..?

`js-deftest-indent` is macro that creates tests for Javascript files indentation.
It's used like:

```lisp
(js-deftest-indent "js-chain.js")
(js-deftest-indent "js-indent-align-list-continuation-nil.js")
```

It's defined as:

```lisp
(defmacro js-deftest-indent (file)
  `(ert-deftest ,(intern (format "js-indent-test/%s" file)) ()
     :tags '(:expensive-test)
     (let ((buf (find-file-noselect (ert-resource-file ,file))))
       (unwind-protect
           (with-current-buffer buf
             (let ((orig (buffer-string)))
               (js-tests--remove-indentation)
               ;; Indent and check that we get the original text.
               (indent-region (point-min) (point-max))
               (should (equal (buffer-string) orig))
               ;; Verify idempotency.
               (indent-region (point-min) (point-max))
               (should (equal (buffer-string) orig))))
         (kill-buffer buf)))))
```

### Test definition

** `defun` is ..? and how the second argument is a doc string ..?

** A macro in Lisp is a ...?
** why do we a macro and not a function, here? and in general?

A test in [ERT](https://www.gnu.org/software/emacs/manual/html_mono/ert.html) is defined by `ert-deftest`.

`ert-deftest` is defined, together with other testing utilities, inside a module named `ert`.
It's also a macro.
It takes a name, an empty element `()`??, docstring keys??, and a test body.
** `cl-defmacro ert-deftest` is ..?

The name in our example is:

```lisp
,(intern (format "js-indent-test/%s" file))
```

> When a list is backquoted, the expressions preceded by a comma are evaluated,
> and their values are inserted into the resulting list.

This expression will be inlined during macro expansion into a string containing
`"js-indent-test/"` followed by the file name.
The comma inlines this so that we have:

```lisp
(ert-deftest "js-indent-test/my-file-name.js"
```

instead of:

```lisp
(ert-deftest ("js-indent-test/my-file-name.js")
```

The first line of `ert-deftest` definition is:

```lisp
(cl-defmacro ert-deftest (name () &body docstring-keys-and-body)
```

Essentially, the macro gets two arguments: `name` and `docstring-keys-and-body`.

** why are docstring keys and body combined ..?

```lisp
BODY is evaluated as a `progn' when the test is run.  It should
signal a condition on failure or just return if the test passes.
```
** explain this..?

```lisp
Macros in BODY are expanded when the test is defined, not when it
is run.  If a macro (possibly with side effects) is to be tested,
it has to be wrapped in `(eval (quote ...))'.
```
** explain this..?

`docstring-keys-and-body` is a list where the first element is
`:tags`, the second is tags value, and the third is the test body.

** In list, a word preceded by the symbel `:` is named a "keywords"?/. Usages ..?
`keyword`:
A keyword in Emacs Lisp is a symbol that starts with a colon (:) character.
Keywords are typically used as markers or indicators in
Lisp code and are often used as keys in property lists or as arguments to functions.

** `tags` are ..?
** tags usage is ..?

The doc string are added to a value named `documentation` as:

```lisp
let ((documentation nil)
        (documentation-supplied-p nil))
    (when (stringp (car docstring-keys-and-body))
      (setq documentation (pop docstring-keys-and-body)
            documentation-supplied-p t))
```
** explain this ..?


**** ANNEX *****
`make-ert-test`:
In Emacs Lisp, the make-ert-test function is a part of the
built-in ERT (Emacs Lisp Regression Testing) framework.
It is used to create test cases for automated testing in Emacs.

`lambda ()`:
lambda: It is a special form in Emacs Lisp used for creating anonymous functions.
(): It specifies an empty argument list, indicating that the function takes no arguments.

`:
In Emacs Lisp, the backtick () is used to indicate the beginning of
a special type of list called a "backquoted list" or "quasiquote."
It is used in combination with comma (,) and comma-at (,@`)
to control the evaluation of expressions within the list.
When a list is backquoted, the expressions preceded by a comma are evaluated,
and their values are inserted into the resulting list.
Expressions preceded by comma-at are also evaluated, but instead of
being inserted as separate elements, they are spliced into the resulting list.

`intern`:
The intern function takes a string argument representing the symbol name and
returns the corresponding symbol object. If the symbol with the given name
already exists in the symbol table, intern returns that symbol. Otherwise,
it creates a new symbol with the given name and adds it to the symbol table.

':
In Emacs Lisp, the single quote (') is a shorthand notation for the quote special form.
It is used to prevent the evaluation of an expression and treat it as a literal value instead.

`&body`:
In Emacs Lisp, &body is a special lambda list keyword used in function definitions.
It allows a function to accept an arbitrary number of expressions as arguments,
which are then treated as a body of code within the function.
The &body keyword, on the other hand, is used in macro definitions.
It allows a macro to accept a body of code as an argument,
which is treated as a list of expressions to be evaluated in the macro expansion.

`let`:
let special form is used to create local variables within a specific lexical scope.
It allows you to define variables that are accessible only within a certain block of code.

****** END-ANNEX ******

** `docstring-keys-and-body` at this point contains the options and the test body..?

The test body is defined and returned:

```lisp
(cl-destructuring-bind
  ((&key (expected-result nil expected-result-supplied-p)
          (tags nil tags-supplied-p))
    body)

  (ert--parse-keys-and-body docstring-keys-and-body)

  `(cl-macrolet
      (
        (skip-when (form) `(ert--skip-when ,form))
        (skip-unless (form) `(ert--skip-unless ,form))
      )

      (ert-set-test
        ',name

        (make-ert-test
          :name ',name
          ,@(when documentation-supplied-p
              `(:documentation ,documentation))
          ,@(when expected-result-supplied-p
              `(:expected-result-type ,expected-result))
          ,@(when tags-supplied-p
              `(:tags ,tags))
          ;; Add `nil' after the body to enable compiler warnings
          ;; about unused computations at the end.
          :body (lambda () ,@body nil)
          :file-name ,(or (macroexp-file-name) buffer-file-name)
        )
      )

      ',name
  )
)
```

** `cl-destructuring-bind` is ..?
```lisp
(defmacro cl-destructuring-bind (args expr &rest body)
  "Bind the variables in ARGS to the result of EXPR and execute BODY."
```

`ert--parse-keys-and-body` separates the docstrings from the body.
** Internally, it ..?
```lisp
(defun ert--parse-keys-and-body (keys-and-body)
  "Split KEYS-AND-BODY into keyword-and-value pairs and the remaining body.

KEYS-AND-BODY should have the form of a property list, with the
exception that only keywords are permitted as keys and that the
tail -- the body -- is a list of forms that does not start with a
keyword.

Returns a two-element list containing the keys-and-values plist
and the body."
```

** how pattern-matching work for assigning values of this ..?
```lisp
(&key (expected-result nil expected-result-supplied-p)
          (tags nil tags-supplied-p))
```

The returned value is the result of executing the `cl-macrolet` macro.

** `cl-macrolet` is ..?
```lisp
(defmacro cl-macrolet (bindings &rest body)
  "Make temporary macro definitions.
This is like `cl-flet', but for macros instead of functions.

\(fn ((NAME ARGLIST BODY...) ...) FORM...)"
```

```chatpgt
cl-macrolet: This is a macro for defining local macros. It allows you to define temporary macros that are only visible within the body of cl-macrolet. In this case, two macros are defined: skip-when and skip-unless. These macros are likely used to conditionally skip the test based on certain conditions.
```

** the difference between a normal macro and a temporal macro is ..?
** how `skip-when` and `skip-unless` are used inside tests ..?
*** is it handled by internal regression testing framework ...?
```lisp
(ert-deftest file-notify-test04-autorevert ()
  "Check autorevert via file notification."
  :tags '(:expensive-test)
  (skip-unless (file-notify--test-local-enabled))
```
*** `ert--skip-unless` is ...?

** `ert-set-test` creates the test, internally it ..?
```lisp
(defun ert-set-test (symbol definition)
  "Make SYMBOL name the test DEFINITION, and return DEFINITION."
```
** `(define-symbol-prop symbol 'ert--test definition)` is ..?
*** `define-symbol-prop` is ...?
```lisp
(defun define-symbol-prop (symbol prop val)
  "Define the property PROP of SYMBOL to be VAL. This is to `put' what `defalias' is to `fset'."
```
** why should we defined a symbol for the test..?

** why do we use `',` in the symbol name `',name` ..?

** This means, the returned value is the result of `make-ert-test` evaluation? applied to `',name`..?

** why do we have the second `name` here ..?
```lisp
`(cl-macrolet ((skip-unless (form) `(ert--skip-unless ,form)))
    (ert-set-test ',name
                  ...
    )
    ',name
 )
```

The creation of test checks whether some elements exist before adding them to the test meta data.
** It uses `,@(when ...`..?

If all metadata is present, the test definition will be:

```lisp
(make-ert-test
  :name ',name
  :documentation documentation
  :expected-result-type expected-result
  :tags tags
  :body (lambda () ,@body)
  :file-name ,(or (macroexp-file-name) buffer-file-name)
)
```

** `,@body` is ..?

** `,(or (macroexp-file-name) buffer-file-name))` is ..?

*** ?? sets these values `macroexp-file-name` and `buffer-file-name` ...?

### Test body

The indentation test body is:

```lisp
(let

  ((buf (find-file-noselect (ert-resource-file ,file))))

  (unwind-protect
    (with-current-buffer buf
      (let ((orig (buffer-string)))
        (js-tests--remove-indentation)
        ;; Indent and check that we get the original text.
        (indent-region (point-min) (point-max))
        (should (equal (buffer-string) orig))
        ;; Verify idempotency.
        (indent-region (point-min) (point-max))
        (should (equal (buffer-string) orig))
      )
    )
    (kill-buffer buf)
  )
)
```

`file` is the file name passed at the beginning.
The test puts the file content inside a `but` variable.
It removes its indentation, indents it, and compares the result
with the original content.
Then, it checks indentation idempotence.
It re-indents the indented file and checks that the content does
not change.

We use double-parentheses for `let` first argument.
The first is meant to enclose all the definition.
Each definition is encloused on its own.

`buf` will contains the evaluation of:

```lisp
(find-file-noselect (ert-resource-file ,file))
```

** `ert-resource-file` is ..?

`find-file-noselect` defnition starts with:

```lisp
(defun find-file-noselect (filename &optional nowarn rawfile wildcards)
  "Read file FILENAME into a buffer and return the buffer.
```

> chatgpt:
In Emacs Lisp, the &optional keyword is used to indicate that the following parameters are optional in a function definition

** finding a file vs selecting/not-selecting it ..?

** `files.el` is ..?

`find-file-noselect` execution path can be:

```lisp
(defun find-file-noselect (filename &optional nowarn rawfile wildcards)
  (setq filename (abbreviate-file-name (expand-file-name filename)))
  (let*
    (
      (buf (get-file-buffer filename))
      (truename (abbreviate-file-name (file-truename filename)))
      (attributes (file-attributes truename))
      (number (file-attribute-file-identifier attributes))


      ;; Create a new buffer. (See: create-file-buffer)
      (lastname (file-name-nondirectory (directory-file-name filename)))
      ;; FILENAME is a root directory
      (lastname (if (string= lastname "") filename lastname))
      (lastname
        (cond
          ((not (and uniquify-trailing-separator-p (file-directory-p filename))) lastname)
          ((eq uniquify-buffer-name-style 'forward) (file-name-as-directory lastname))
          ((eq uniquify-buffer-name-style 'reverse) (concat (or uniquify-separator "\\") lastname))
          (t lastname)
        )
      )
    )
    ;; Create a new buffer. (See: create-file-buffer)
    (setq buf (generate-new-buffer lastname))
    (uniquify--create-file-buffer-advice buf filename lastname)
    ;; find-file-noselect-1 may use a different buffer.
    (find-file-noselect-1 buf filename nowarn rawfile truename number)
  )
)
```

`create-file-buffer` takes a file name and returns a buffer instance.
It `Create a suitably named buffer for visiting FILENAME, and return it`.
This call is inlined in the code snippet here.

** `lastname` is ..? [HHERE]

** `generate-new-buffer` is ..?

** `uniquify--create-file-buffer-advice` is ..?


** `find-file-noselect-1` is ..?

** `(unwind-protect....)` is ..?

## Identation internals

## LSP integration (Rust-analyzer)
https://github.com/rust-lang/rust-analyzer
