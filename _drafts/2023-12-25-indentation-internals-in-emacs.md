---
layout:   post
comments: true
title:    "Indentation internals in Emacs"
date:     2023-12-22 12:02:00 +0100
tags:     featured
---


* to start testing, we pass a parameter `(not (or (tag :expensive-test) (tag :unstable) (tag :nativecomp)))`.

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

The name of the test is `js-indent-test/file-name.js`.
It's stored as a symbol in the symbol registery.
Inside `ert-deftest`, the structure is transformed using `ert--parse-keys-and-body` to
```lisp
((&key (expected-result nil expected-result-supplied-p)
               (tags nil tags-supplied-p))
```

After simplification `ert-deftest` evaluates to:
```lisp
`(cl-macrolet ((skip-unless (form) `(ert--skip-unless ,form)))
    (ert-set-test ',name
                  (make-ert-test
                    :name ',name
                    :documentation documentation
                    :expected-result-type expected-result
                    :tags tags
                    :body (lambda () ,@body)
                    :file-name ,(or (macroexp-file-name) buffer-file-name)
                  )
    )
    ',name
 )
```

*** cl-macs.el `defmacro cl-macrolet (bindings &rest body...` is ...?
`skip-unless` macro is created to be used by the test body, as in
*** is it handled by internal regression testing framework ...?
```lisp
(ert-deftest file-notify-test04-autorevert ()
  "Check autorevert via file notification."
  :tags '(:expensive-test)
  (skip-unless (file-notify--test-local-enabled))
```
*** `ert--skip-unless` is ...?

Without edge cases, `ert-set-test` is
```lisp
(defun ert-set-test (symbol definition)
  (define-symbol-prop symbol 'ert--test definition)
  definition)
```

*** `define-symbol-prop` is ...?
```lisp
(defun define-symbol-prop (symbol prop val)
  "Define the property PROP of SYMBOL to be VAL.
This is to `put' what `defalias' is to `fset'."
```

*** ?? sets these values `macroexp-file-name` and `buffer-file-name` ...?

## Annex
`make-ert-test`:
In Emacs Lisp, the make-ert-test function is a part of the
built-in ERT (Emacs Lisp Regression Testing) framework.
It is used to create test cases for automated testing in Emacs.

`lambda ()`:
lambda: It is a special form in Emacs Lisp used for creating anonymous functions.
(): It specifies an empty argument list, indicating that the function takes no arguments.

`\``:
In Emacs Lisp, the backtick () is used to indicate the beginning of a
special type of list called a "backquoted list" or "quasiquote."
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

`&body`:
In Emacs Lisp, &body is a special lambda list keyword used in function definitions.
It allows a function to accept an arbitrary number of expressions as arguments,
which are then treated as a body of code within the function.
The &body keyword, on the other hand, is used in macro definitions.
It allows a macro to accept a body of code as an argument,
which is treated as a list of expressions to be evaluated in the macro expansion.

':
In Emacs Lisp, the single quote (') is a shorthand notation for the quote special form.
It is used to prevent the evaluation of an expression and treat it as a literal value instead.

`let`:
let special form is used to create local variables within a specific lexical scope.
It allows you to define variables that are accessible only within a certain block of code.

`cl-destructuring-bind`:
cl-destructuring-bind is a macro provided by the cl-lib library.
It allows you to destructure complex data structures, such as lists or vectors,
and bind their elements to variables in a convenient and concise way.

`keywordp`:
A keyword in Emacs Lisp is a symbol that starts with a colon (:) character.
Keywords are typically used as markers or indicators in
Lisp code and are often used as keys in property lists or as arguments to functions.