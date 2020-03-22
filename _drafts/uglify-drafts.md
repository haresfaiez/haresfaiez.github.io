# uglify

* compress.js
  - defines a method "optimize" on [5]
  - defines a method "reduce_vars" on [6]
  - defines "methods to evaluate a constant expression"
    * defines evaluate and is_constant on AST_Node
      evaluate:
        > If the node has been successfully reduced to a constant,
        > then its value is returned; otherwise the element itself
        > is returned.
        > They can be distinguished as constant value is never a
        > descendant of AST_Node.
    * defines a method "_eval" on [7]
  - defines a method "drop_side_effect_free" on [8] that
    > remove side-effect-free parts which only affects return value
  - defines a method "drop_unused" on AST_Scope
  - defines other methods on different AST_x types [9]
  - [INCOMPLETE: what each method does]

  * output.js
    - define code generators

  // def method add_source_map -> output.add_mapping(this.start, Nothing|(this.key.name | this.key))
    function DEFMAP(nodetype, generator) { 
    DEFMAP([
        AST_Array,
        AST_BlockStatement,
        AST_Catch,
        AST_Constant,
        AST_Debugger,
        AST_Definitions,
        AST_Directive,
        AST_Finally,
        AST_Jump,
        AST_Lambda,
        AST_New,
        AST_Object,
        AST_StatementWithBody,
        AST_Symbol,
        AST_Switch,
        AST_SwitchBranch,
        AST_Try,
    DEFMAP([
        AST_ObjectGetter,
        AST_ObjectSetter,
     ], function(output) {
        output.add_mapping(this.start, this.key.name);
    });
    DEFMAP([ AST_ObjectProperty ], function(output) {
        output.add_mapping(this.start, this.key);
    });
    /* -----[ utils ]----- */
    AST_NODE::print(Stream) -> add node to stream,
    AST_NODE::print_to_string -> create a stream with only this node, and return s.get

    define a method `need_parens(OutputStream)` that returns whether the element needs parens? or not.
    For example, "a function expression needs parens around it when it's provably the first
    token to appear in a statement.", so we define `need_parens` on AST_Function that return `true`
    if `!output.has_parens() && first_in_statement(output)`.
    Here `output.has_parens` ??
    and `first_in_statement(Stack)` "return true if the node at the top of the stack (that means the
    innermost node in the current output) is lexically the first in a statement."??

    /* -----[ statements ]----- */
    AST_StatementWithBody.DEFMETHOD("_do_print_body", function(output) { //make_block(this.body, output) if output.option.braces | this.body.print(output)
    /* -----[ functions ]----- */
    AST_Lambda.DEFMETHOD("_do_print", function(output, nokeyword) { //output.print|output.space

    Define printers.
    define `_codegen` for printable AST node types, and assign a `generator(Self, OutputStream)` to each.
    // fn at 1 pattern:
    // calls to output.print|print_string/output.space/output.with_parent/output.semicolon
    // and self.*.print(output)

  *scope.js
  attaches to AST_* functions useful for scope-ish operations [3]
  
AST_Toplevel : figure_out_scope
AST_Toplevel : def_global
AST_Scope : init_scope_vars
AST_Lambda : init_scope_vars
AST_Symbol : mark_enclosed
AST_Symbol : reference
AST_Scope : find_variable
AST_Scope : def_function
AST_Scope : def_variable
AST_Lambda : resolve
AST_Scope : resolve
AST_Toplevel : resolve
AST_Symbol : unmangleable
AST_Label : unmangleable
AST_Symbol : unreferenced
AST_Symbol : definition
AST_Symbol : global
AST_Toplevel : mangle_names
AST_Toplevel : find_colliding_names
AST_Toplevel : expand_names
AST_Node : tail_node
AST_Sequence : tail_node
AST_Toplevel : compute_char_frequency

  AST_Toplevel.DEFMETHOD("figure_out_scope", function(options) { // used in Compressor::compress
options = defaults(options, { cache: null, ie8: false });
// pass 1: setup scope chaining and handle definitions
scope // upper scope
defun // upper function definition

// WALKER
AST_Catch -> // calls init_scope_vars
AST_Scope -> // calls init_scope_vars
AST_Symbol -> // sets the scope to the scope of parent

AST_SymbolDefun -> // defines a function in the parent function scope (defun.parent_scope )
AST_SymbolLambda -> // defines a function in the current function scope (defun)
AST_SymbolVar -> // defines a variable in the current function scope(defun)
AST_SymbolCatch -> // scope.def_variable(node).defun = defun;

// pass 2: find back references and eval
self.globals = new Dictionary(); // init TopLevel.globals

AST_LoopControl // (break or continue): add current node to its definition->references
AST_SymbolRef // reference to some symbol: set thedef(symbol definiotn) to scope.find_variable || def_global

// ensure mangling works if catch reuses a scope variable
 AST_SymbolCatch // Symbol naming the exception in catch:
// find scope where the symbol is first defined and put it in each sub-scope.enclosed
  // loop currentScope -> scopeWhereNodeDefined(=def) and forEach s->push(s.enclosed, def)
  // s.enclosed: ">a list of all symbol definitions that are accessed from this scope or any subscopes"
});

AST_Toplevel.DEFMETHOD("def_global", // form node.name return a global SymbolDef if exists or set one
    // vars associated with scope in AST_Scope
variables // map name to AST_SymbolVar (variables defined in this scope; includes functions)
functions // map name to AST_SymbolDefun (functions defined in this scope)
uses_with // will be set to true if this or some nested scope uses the `with` statement
uses_eval // will be set to true if this or nested scope uses the global `eval`
parent_scope // the parent scope
enclosed // a list of variables from this or outer scope(s) that are referenced from this or inner scopes
cname // the current index for mangling functions/variables

AST_Scope.DEFMETHOD("init_scope_vars", // init scope vars

AST_Lambda.DEFMETHOD("init_scope_vars", // init scope vars, and define variable "arguments" as AST_SymbolFunarg

AST_Scope.DEFMETHOD("find_variable", function(name) // find var by name in current or parent scope

AST_Scope.DEFMETHOD("def_variable", // mutate the var if exist or
                    // (create a new SymbolDef and set this.variables)

AST_Scope.DEFMETHOD("def_function", function(symbol, init) // calls def_variable and set this.functions

  - [INCOMPLETE] remaining fns doc

[2]:
is_letter(code)
is_surrogate_pair_head(code)
is_surrogate_pair_tail(code)
is_digit(code)
is_alphanumeric_char(code)
is_unicode_digit(code)
is_unicode_combining_mark(ch)
is_unicode_connector_punctuation(ch)
is_identifier_start(code)
is_identifier_char(ch)
is_identifier_string(str)
parse_js_number(num)
JS_Parse_Error(message, filename, line, col, pos)
js_error(message, filename, line, col, pos)
is_token(token, type, val)

tokenizer($TEXT, filename, html5_comments, shebang)
    peek()
    next(signal_eof, in_string)
    forward(i)
    looking_at(str)
    find_eol()
    find(what, signal_eof)
    start_token()
    token(type, value, is_comment)
    skip_whitespace()
    read_while(pred)
    parse_error(err)
    read_num(prefix)
    read_escaped_char(in_string)
    read_octal_escape_sequence(ch)
    hex_bytes(n)
    skip_line_comment(type)
    read_name()
    read_operator(prefix)
        grow(op)
    handle_slash()
    handle_dot()
    read_word()
    with_eof_error(eof_error, cont)
    next_token(force_regexp)

parse($TEXT, options)
    is(type, value)
    peek()
    next()
    prev()
    croak(msg, line, col, pos)
    token_error(token, msg)
    token_to_string(type, value)
    unexpected(token)
    expect_token(type, val)
    expect(punc)
    has_newline_before(token)
    can_insert_semicolon()
    semicolon(optional)
    parenthesised()
    embed_tokens(parser)
    handle_regexp()
    labeled_statement()
    simple_statement(tmp)
    break_cont(type)
    if_()
    for_()
    regular_for(init)
    for_in(init)
    block_(strict_defun)
    switch_body_()
    try_()
    as_atom_node()
    expr_list(closing, allow_trailing_comma, allow_empty)
    as_property_name()
    as_name()
    _make_symbol(type)
    strict_verify_symbol(sym)
    as_symbol(type, noerror)
    mark_pure(call)
    make_unary(ctor, token, expr)
    expr_ops(no_in)
    is_assignable(expr)
    in_loop(cont)


[4]:
AST_Node
AST_LabeledStatement
AST_SimpleStatement
AST_Block
AST_Do
AST_While
AST_For
AST_ForIn
AST_With
AST_Exit
AST_LoopControl
AST_If
AST_Switch
AST_Case
AST_Try
AST_Catch
AST_Definitions
AST_VarDef
AST_Lambda
AST_Call
AST_Sequence
AST_Dot
AST_Sub
AST_Unary
AST_Binary
AST_Conditional
AST_Array
AST_Object
AST_ObjectProperty

[5]:
AST_Node
AST_Directive
AST_Debugger
AST_LabeledStatement
AST_Block
AST_BlockStatement
AST_Lambda
AST_SimpleStatement
AST_While
AST_Do
AST_For
AST_If
AST_Switch
AST_Try
AST_Definitions
AST_Call
AST_New
AST_Sequence
AST_UnaryPostfix
AST_UnaryPrefix
AST_Binary
AST_SymbolRef
AST_Undefined
AST_Infinity
AST_NaN
AST_Assign
AST_Conditional
AST_Boolean
AST_Sub
AST_Dot
AST_Return

[6]:
AST_Node
AST_Accessor
AST_Assign
AST_Binary
AST_Call
AST_Case
AST_Conditional
AST_Default
AST_Defun
AST_Do
AST_For
AST_ForIn
AST_Function
AST_If
AST_LabeledStatement
AST_SymbolCatch
AST_SymbolRef
AST_Toplevel
AST_Try
AST_Unary
AST_VarDef
AST_While

[7]:
AST_Statement
AST_Lambda
AST_Node
AST_Constant
AST_Function
AST_Array
AST_Object
AST_UnaryPrefix
AST_Binary
AST_Conditional
AST_SymbolRef
AST_PropAccess
AST_Call
AST_New

[8]:
AST_Node
AST_Accessor
AST_Array
AST_Assign
AST_Binary
AST_Call
AST_Conditional
AST_Constant
AST_Dot
AST_Function
AST_Object
AST_ObjectProperty
AST_Sequence
AST_Sub
AST_SymbolRef
AST_This
AST_Unary

[9]:
AST_Node.DEFMETHOD("equivalent_to"
AST_Scope.DEFMETHOD("process_expression"
AST_Toplevel.DEFMETHOD("reset_opt_flags"
AST_Symbol.DEFMETHOD("fixed_value"
AST_SymbolRef.DEFMETHOD("is_immutable"
AST_SymbolRef.DEFMETHOD("is_declared"

  def(AST_Node, return_false);
  def(AST_Array, return_true);
  def(AST_Assign
  def(AST_Lambda, return_true);
  def(AST_Object, return_true);
  def(AST_RegExp, return_true);
  def(AST_Sequence
  def(AST_SymbolRef
  node.DEFMETHOD("is_truthy", func);

  AST_Node.DEFMETHOD("may_throw_on_access"

  def(AST_Node, is_strict);
  def(AST_Array, return_false);
  def(AST_Assign
  def(AST_Binary
  def(AST_Conditional
  def(AST_Constant, return_false);
  def(AST_Dot
  def(AST_Lambda, return_false);
  def(AST_Null, return_true);
  def(AST_Object
AST_Binary.DEFMETHOD("transform", function(tw, in_list) {
  var x, y;
  tw.push(this);
  if (tw.before) x = tw.before(this, descend, in_list);
  if (typeof x === "undefined") {
    x = this;

    this.left = this.left.transform(tw);
    this.right = this.right.transform(tw);

    if (tw.after) {
      y = tw.after(this, in_list);
      if (typeof y !== "undefined") x = y;
    }
  }
  tw.pop();
  return x;
});
  def(AST_Sequence
  def(AST_SymbolRef
  def(AST_UnaryPrefix
  def(AST_UnaryPostfix, return_false);
  def(AST_Undefined, return_true);
  node.DEFMETHOD("_dot_throw", func);

  def(AST_Node, return_false);
  def(AST_Array, return_true);
  def(AST_Assign
  def(AST_Binary
  def(AST_Conditional
  def(AST_Constant, return_true);
  def(AST_Lambda, return_true);
  def(AST_Object, return_true);
  def(AST_Sequence
  def(AST_SymbolRef
  def(AST_UnaryPrefix
  def(AST_UnaryPostfix, return_true);
  def(AST_Undefined, return_false);
  node.DEFMETHOD("is_defined", func);

  def(AST_Node, return_false);
  def(AST_Assign
  def(AST_Binary
  def(AST_Boolean, return_true);
  def(AST_Call
  def(AST_Conditional
  def(AST_New, return_false);
  def(AST_Sequence
  def(AST_SymbolRef
  def(AST_UnaryPrefix
  node.DEFMETHOD("is_boolean", func);

  def(AST_Node, return_false);
  def(AST_Assign
  def(AST_Binary
  def(AST_Call
  def(AST_Conditional
  def(AST_New, return_false);
  def(AST_Number, return_true);
  def(AST_Sequence
  def(AST_SymbolRef
  def(AST_Unary
  node.DEFMETHOD("is_number", func);

  def(AST_Node, return_false);
  def(AST_Assign
  def(AST_Binary
  def(AST_Call
  def(AST_Conditional
  def(AST_Sequence
  def(AST_String, return_true);
  def(AST_SymbolRef
  def(AST_UnaryPrefix
  node.DEFMETHOD("is_string", func);

  AST_Toplevel.DEFMETHOD("resolve_defines"

  def(AST_Node, noop);
  def(AST_Dot
  def(AST_SymbolDeclaration
  def(AST_SymbolRef
  node.DEFMETHOD("_find_defs", func);

  def(AST_Node
  def(AST_Statement
  def(AST_Function
  def(AST_UnaryPrefix
  def(AST_Sequence
  def(AST_Conditional
  def(AST_Binary
  node.DEFMETHOD("negate"

AST_Call.DEFMETHOD("is_expr_pure"

AST_Node.DEFMETHOD("is_call_pure", return_false);

AST_Call.DEFMETHOD("is_call_pure"

def(AST_Node, return_true);
def(AST_Array
def(AST_Assign, return_true);
def(AST_Binary
def(AST_Block
def(AST_Call
def(AST_Case
def(AST_Conditional
def(AST_Constant, return_false);
def(AST_Definitions
def(AST_Dot
def(AST_EmptyStatement, return_false);
def(AST_If
def(AST_LabeledStatement
def(AST_Lambda, return_false);
def(AST_Object
def(AST_ObjectProperty
def(AST_Sub
def(AST_Sequence
def(AST_SimpleStatement
def(AST_Switch
def(AST_SymbolDeclaration, return_false);
def(AST_SymbolRef
def(AST_This, return_false);
def(AST_Try
def(AST_Unary
def(AST_VarDef
node.DEFMETHOD("has_side_effects", func);

def(AST_Node, return_true);
def(AST_Constant, return_false);
def(AST_EmptyStatement, return_false);
def(AST_Lambda, return_false);
def(AST_SymbolDeclaration, return_false);
def(AST_This, return_false);
def(AST_Array
def(AST_Assign
def(AST_Binary
def(AST_Block
def(AST_Call
def(AST_Case
def(AST_Conditional
def(AST_Definitions
def(AST_Dot
def(AST_If
def(AST_LabeledStatement
def(AST_Object
def(AST_ObjectProperty
def(AST_Return
def(AST_Sequence
def(AST_SimpleStatement
def(AST_Sub
def(AST_Switch
def(AST_SymbolRef
def(AST_Try
def(AST_Unary
def(AST_VarDef
node.DEFMETHOD("may_throw", func);

def(AST_Node, return_false);
def(AST_Array
def(AST_Binary
def(AST_Constant, return_true);
def(AST_Lambda
def(AST_Object
def(AST_ObjectProperty
def(AST_Unary
node.DEFMETHOD("is_constant_expression", func);

def(AST_Statement, return_null);
def(AST_Jump, return_this);
def(AST_BlockStatement, block_aborts);
def(AST_SwitchBranch, block_aborts);
def(AST_If
node.DEFMETHOD("aborts", func);

AST_Scope.DEFMETHOD("hoist_declarations"
AST_Scope.DEFMETHOD("var_names"
AST_Scope.DEFMETHOD("make_var_name"
AST_Scope.DEFMETHOD("hoist_properties"
AST_Definitions.DEFMETHOD("remove_initializers"
AST_Definitions.DEFMETHOD("to_assignments"
AST_Call.DEFMETHOD("lift_sequences"
AST_Unary.DEFMETHOD("lift_sequences"
AST_Binary.DEFMETHOD("lift_sequences"
AST_Scope.DEFMETHOD("contains_this"
AST_PropAccess.DEFMETHOD("flatten_object"


# Uglify compress

# Intro
 - usage
```
const falseByDefault = true;
compressor = new Compressor(options, falseByDefault)
outputTopLevelAst = compressor.compress(toplevelAST)
```
compress accepts an AST_TopLevel

 - [options](https://github.com/mishoo/UglifyJS2#compress-options)
 Compressor is controlled by options, ??how
options.boolean/assignements/conditionals
each of these is true by default unless explicitly set

Compressor uses a default value when the option it does not receivea a value for an option.
This default value depends on the second argument `falseByDefault`. When `true`, `Compressor`
performas conservatively. It keeps? ...9

The options are used to make decisions in the compression operation.
For example, Compressor has a function `tighten_body` that compressor the body of
a block of code (conditional, function, loops, ...)

```
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
```

Not all options are used as received. The following options are mapped to different formats that
simplifies consumption.
 * global_defs:
 `@` are removed from keys and expressions are evaluated.
 These are used in `AST_TopLevel.resolve_defines` called in the beginning of `Compressor.compress`, which warns
 when redifining or mutating a global defintion, or replaces the access to a global defintion with the evaluation of the expression
 in the options.

 * keep_fargs
 defnie a predicate `Compressor.drop_fargs` to keep unused function arguments or to discard them.
 When the value of `keep_fargs` is `'strict'`.
 When the function has a name, the compressor depends on `AST_SymbolRef.fixed`, `AST_SymbolDef.direct_acess`,
 and `AST_SymbolDef.escape` which are defined by `AST_Node.reduce_vars`.
 `AST_Node.reduce_vars` is called by `AST_TopLevel.reset_opt_flags` if options.reduce_vars is truthy.
 And `AST_TopLevel.reset_opt_flags` is called in the beginning of each compression pass.

 `Compressor.drop_fargs` then is used in `AST_Scope.drop_unused` that drops unused declarations.
 to check if the Compressor should remove unused arguments.

 and in `AST_Sub.optimize`: if `options.arguments` is set, and there is an `arguments[index]` in the function.
When the `index` overflows the function arguments.

Compressor checks if `drop_fargs(function, parent)` is true, and if it is the case, adds arguments before
`index` to fill the void.
`AST_SUB` is an
> "Index-style property access, i.e. `a[\"foo\"]`"

 * pure_funcs
 Define a predicate `Compressor.pure_funcs` that given an `AST_Call`, returns wether `Compressor` should
 assume the call to be pure or not.
 It is used in `AST_Call.is_expr_pure`.

 * top_retain
 Define a predicate that given a definition, returns whether the definiton can be removed or not.
 It is used in `AST_Scope.drop_unused` when the scope is an `AST_TopLevel`.

 * toplevel


  - creation

  - it is a `TreeTransformer` and thus a `TreeWalker`. It has
`before` and `after` methods.
  `visit` callback, a stack for visited nodes and `directives`?

  - Compressor is a visitor
  Compressor#before(Node, Descend)

# Optimizers
 - optimize(Node) -> Node || Self

We focus on the implementation of the `Node.optimize` for important nodes.



# Reflections
- modularity is about mental load, not correctness.
If you need to put all dependencies before you to learn about a function, cost increases.
You need to maximize the probability that what you assume about the dependencies is right.
This one way types help, good design, desgin patterns helps too.

Assume the worst from code using you, "be liberal in what you accept".
Even all pathes succeeds, separate. Tradeoff?

It is not the name that is documenation, but the usage of the function/variable.
Usage gives you better idea about the variable than the description and name (both support understanding).
Make it easy to learn about a fuction (examples, scope, definition location, ...)

Diagrams are for reasoning, evaluating tradeoffs, not understanding (they don't scale, they model your thinking, not
the code, you will always miss cases/states).
The best way to understand the code is to automate generation of views.




## Reflections
-- different lines of a same fn have different weight
if you focus on critical lines of a fn, you can understand
it without knowing what each line does
i.e. transfrom(new TreeTransformer or ..(new TreeWalker
have significant weight (and maybe with the aggregation of something)

-- changing a variable costs understanding more than reading itxthe less a variable is changed/assigned the easier it is to understand its contribution to the program,
its read usage matters less
if we have a variable safe_ids and only changed in the function `mark`/safe_to_assign
tw.safe_ids[def.id] = safe;/ = false;
and most of its use are checks for equality
- in emacs the file does not need to exist once, you can open it in different windows to visiualize
different areas. You can open different Emacs session to modify it differently


## How I worked
- extract structure/form
-- dependencies on AST:
grep -r AST_ compress.js compress-optimizers.js | wc -l
1184
-- it all definitons
grep -ir defmethod compress.js compress-optimizers.js
-- group definitions, try to impose a structure
the grouping is best to follow the use of fns. I don t understand
the use well enough still.
The structuring won t be permanent. I want to build a map/view of
the compression system.
I split them into two groups query and command.
-- split compress.js into sub-modules then incrementally split those into sub-sub modules
criteriea for splitting, method definiton, a module per method definition



# uglify retro

- Lessons learned on reading code
  - notice a pattern:
    select code/mapping, move it to a file in /tmp, view it otherwise/filter noise out, throw it away
  - map the list of AST_x definitions to a list of entries
    name: vars : ... : parent
    then use that to find inheritence chaines, query-replace-regexp: :.*: -> <
  - Tmux/Emacs/Git-using-cmd are the best
    navigation, buffers, text-manipulation, highlights, scriptiing
    program the exploration environment as well as
    emacs tools occur, grep mode
    when you copy/paste from code, Emacs keeps the colors
    insert-file-literally and copy rings
    different states of the same file opened together in different Emacs instances
    and same modified file opened at different positions inside different buffers in the same
    Emacs instance
  - you will see that in a file defining function, there is an other dimension/pattern, filter
  the file based on that. e.g. in compress.js Uglify defines methods on node types, but the definition
  has patterns there is a def and then def(AST_nodes) (essence) and then helper methods (glue)
  remove the glue and focus on the essence
  to get a better view, you may use cmds such as `grep -i 'def(\|defmethod(' compress.js > /tmp/other_defs`
  then work on the tmp file
  - start by removing helper fns to see the API
  - use behavior as an anchor to navigate structure, if you don't know where a fn is used or how
    it contributes to the result, don't spend too much on it
  - don't assume you know what the fn does from the name
  - as you read a conditional, remove what you integrate into your mental model
    if you have if(x) { y } else if(z) { w } else { b }, remove the first condition or put a comment
    in your language
  - create your language
  - for each fn, there is an essence and a glue, focus on the essence
  - delete edge cases and error handling
  - think about inline first
  - when the file is large, open it different buffer for better visualization
  - move the file to /tmp and keep only kep lines (lines having key decisions)
  - find where something is used
  - inline short functions/decompress code
  - get out of the syntax, invent your language
  - rearrange lines of code and definitons
  - do not try to hold too much in your head
  - use tools to simplify what you learn
  - importance of preparation; take time and prepare a holistic view
  - /tmp:
  /tmp/compress.drop_side_effect_free.js [error opening dir]
/tmp/compress.drop_unused.js [error opening dir]
/tmp/compress._eval.js [error opening dir]
/tmp/compress.optimize.js [error opening dir]
/tmp/compress.proto.js [error opening dir]
/tmp/compress.reduce_vars.js [error opening dir]



# tightenbody

// even if you don't want duplication of code, duplication of patterns should be obivous,
// if you have if () { a;b; c; } the else should not be else { b; c; a; }

starts by finding the enclosing `AST_Scope` (`AST_TopLevel` or `AST_Lambda`).

The core of `tighten_body` is this loop
```
  var CHANGED, max_iter = 10;
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
```
 * `eliminate_spurious_blocks` removes `AST_EmptyStatement`, flattens the body of `AST_BlockStatement, and
   collects directives and removes duplicated ones.
 * `eliminate_dead_code` ??? and looks for a jump (`return`, `throw`, `break`, or `continue`).
 If it finds one, it uses a `TreeWalker` to walk down each of the following satatements, adding any definition
 (`AST_Definitions`, `AST_Defun`) to the statements list. It remove initializations for `AST_Definitions`.
 * `handle_if_return` walks the statement backward (from last to first) (explain why? to optmize based on next statement).
   - removes all next statements when it is in a function, it finds an `AST_Return` followed only by varibales
   definitions (without initialization).
   - transforms an `AST_Return`.value == `AST_UnaryPrefix` with "void" value into a simple statement with
   `AST_Return`.value.expression as the body.
   -  conditional = condition + body + alternative
        revert the conditional body and alternative if (in that order):
         1 - the body contains a jump (break or continue) with "self" as the target
         2 - it has no alternative (if(a) {b}), followed by a jump, and negatedStr.length <= conditionStr.length
         3 - the alternative contains a jump (break or continue) with "self" as the target
        in 1- and 3-, we remove non-function-definitions following the conditional and put them in
        the branch without jump (body in 1- and alternative in 3-). We keep function-definiton statements
        "self" is the node we are compressing
        And in three cases, compress the if statement again by calling stat.transform(compressor)
        example...
   - it compresses cases where the statement is a condition where it has no alternative and its body contains only
   a return statement.
   ```
   // if (foo()) return; return; ==> foo(); return;
   // if (foo()) return x; return y; ==> return foo() ? x : y;
   // if (foo()) return x; [ return ; ] ==> return foo() ? x : undefined;
   // if (a) return b; if (c) return d; e; ==> return a ? b : c ? d : void e;
   ```
 * if `sequence_limit > 0`
   * `sequencesize`
     This does nothing if the `statements.length < 2`.
     Otherwise, collect consecutive `AST_SimpleStatement` (or interrputed only with an `AST_Defun` or `AST_Definitions` with
     `declarations_only`) into one `AST_Sequence` after dropping removing `AST_nodes` that have no side effects
     (like `5 + 2;`) (that have no effects on the return value of the built `AST_Sequence` and (no outside effect??)) from them.
   * `sequencesize_2`
   this walks the statements forward. For each statement
     1-  if `options.conditionals` is set.
      // moves `AST_Var` declarations in `AST_If` body and alternative before the conditional if the body and alternative
      // left, each contains only one statement.
      // That is: 
      //           if block is an `AST_BlockStatement` and its body (other than declarations_only AST_Var), it has
      //           no more than one other statement.
      // Do it by replacing the `AST_If` statement by many `AST_Var` statements following by an `AST_If`.
     2- tries to merge `AST_SimpleStatement` ("statement consisting of an expression") with a following
     `AST_StatementWithBody` if possible:
       * `AST_Exit` => (`return` or `throw`) change value to an `AST_Sequence` with `prev`
       *  `AST_ForIn` add prev to the object we are looping through
       *  `AST_If` add prev to the condition
       *  `AST_Switch` add prev to the "switch" discriminant
       *  `AST_With` add prev to the expression
       * `AST_For` =>
          // if loop has init code not instance of `AST_Definitions` or have no init code
          // `for(console.log('hey'), var i = 0;;;) {}` // => `SyntaxError: Unexpected token var`
          // `for(console.log('hey'), i = 0;;;) {}` // => works
          //    THEN
               // prev = null if prevous changed AST_If || stat instanceof AST_SimpleStatement ? stat : null;
               // put `prev` in sequence before init code as init(make one `AST_Sequence` from (prev: AST_SimpleStatement)
               // `prev.body` and `right`), or use `prev` as the init code if the loop has no init code
               // if abort === false
               // None of
               // abort == true => any in descendent tree of prev.body is an `AST_Scope` (an `AST_Lambda` because
               // the function won't be accessible anymore) or an instance of `AST_Binary` with `in` as operator.
               // Unless separaed with a parentheses, an "in" statement parsing
               // fails with
               //```
               //for (f = 3, 1 in [], i = 0; i < 10; ++i) {console.log(i);}
               //     ^^^^^^^^
   
               //SyntaxError: Invalid left-hand side in for-loop
               //```
               // considering `f = 3, 1` a single expression
 * `join_consecutive_vars` 
   walks through the statements forward.
   For each statement,
   * If an `AST_For`
      ** If we can `join_assigns`(prev, stat.init), then change stat.init => sequence of (stat.init & prev)
      ** If `prev` is an `AST_Var` and the loop has no `init` or `init.TYPE == prev.TYPE`
          // if stat.init (change concat stat and prev definitions in prev then change xstat.init to prev)
          // or put only prev in
      ** If  loop has init code and `stat.init.TYPE` equals last declaration type and `stat.init` is declarations only
          // concat stat.init definitions into last def definitions and set stat.init to null
    * If an `AST_SimpleStatement`, replace the body with a sequence got by joining prev and `stat.body`
    *    If the actual statement is an `AST_Definitions`:
         ** join definitions with prev if prev have the same type as the current statement
         ** join definitions with last `AST_Definitions` statement if it has the same statement as
           the current statement and the current statement has only declarations
         ** set the current statement as the last `AST_Definitions` otherwise
    * For these, try to change the target with `join_assigns_exprs(target)
    AST_ForIn-> object
AST_If-> condition
AST_Exit-> value
AST_Switch-> expression
AST_With-> expression

           Helpers to `join_consecutive_vars`
                 /*
       * `trim_assigns` gets an `AST_VarDef`.name its an `AST_VarDef`.value, and an array of [`AST_Assign`]
       * it walks the array from beginning to end, when it finds an assignement to a property of the `AST_VarDef`.name
       * and nono of the assigned value properties does not conflict with `AST_Def`.value, it adds that assignement
       * to `AST_VarDef`.value
       */
      function trim_assigns(name, value, exprs) 

      // body: AST_Assign | AST_Sequence -> exprs
      // if prev is `AST_Definitions`, try to `trim_assigns` into last `AST_VarDef` of it `exprs` (move assignements to prev)
      // otherwise (none moved or previ is not `AST_Definitions`),
      // find an expression of `AST_Assign`, operator = "=", .left is `AST_SymbolRef`, and there is
      // nothing to `trim_assigns` from the following expressions. If thereis, return;
      function join_assigns(defn, body) {

        // if `join_assigns` optimizes the code, create an `AST_Sequence` and make sure the last expression
        // of the sequence is the last expression of `value` argument
      function join_assigns_expr(value) {

 * `collapse`