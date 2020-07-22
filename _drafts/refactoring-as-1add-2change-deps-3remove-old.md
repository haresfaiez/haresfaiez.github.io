# froces, thoughtuful design
# anchors (complex examples followed by simpler ones, )
# plan all your refactoring ahead, play it in your mind, draw a clear picture of the destination design.
  Then, assume the code has changed and write a test. Do it outside in if you will.
# forces (
  - least amout of change to reach to the target
  - larger context (two levels usage, other use of current/parent) => integrity/state space
  )
# Think behavior when deciding where you want to end up, think structure when deciding how to get there.
  And vice-versa. It is a loop.
# Use what exisits to the limits
# Have one step between the called and the calee. Any intermediate function will hinder the refactoring.
  You will need to deal with the joint(intermediate function(s)) first.
  (Expand/Extract may help)

 * Test new behavior on new code, implement new code, change the code progressively, remove old code
 => new abstraction level?

    ** Pass in new information

 * extract relevant code from existing code, test and improve extracted code, replace call to old code with call to new code,
   remove old code
 => making the old model absolute?
   ** Cover yourself with tests before you start
   ** You need to have a very good idea about what the new code requires
   ** It is a game of abstraction levels, you rise it, aplly your changes, then you lower it again.
   ** The important thing to keep in mind is that you are rising levels of abstraction. Be aware of rising just
      a corner.
      The design as a whole should maintain integrity.
   ** example: extract function, handle new cases in it (by rising abstraction levels of arguments or by accepting new arguments
   or by treating some range of values differently, or join it with another function), then use it in other locations.
   Then you might remove the inital function (wich may now act as a meaningless bridge) and use the new.
   ** extract argument to replace existing argument. Create a mapping from old to new.
   Create a function that accepts the old and the new argument and called by the old the old.
   Keep them both, never replace, always add-update-removeUnused.
   Somtimes you won't like to move the whole body of the old function to the new. You can do it bit by bit.
   If you have a source fn handling 3 conditions. You might want to keep two and modify the third.
   You move the two to the new fn, and delegate to it.
   You test-and-add the third. (this is the case when the third involves a recursive call)

 * change/decorate/update call sites, extract common code, inline/use old code in new or remove it
 => example you have the call chain play->turn->init, init returns Movement and the other two accepts a list
 of Movement. You want to change Movement to Transition.
 You start with the leaves and you navigate up.
 init is used by play, so make turn agnostic to Movement and Transition different. Make it treat them similarily.
 Then change init result type or extract a new initTransition and inline init.
 You need to have tests.
   (-) hard to do right when types are complicated. Makes the code more confusing and the transition is not eloquent.

  ** may have some cost when the call sites change is costly

 * move what changes together together, move what else to create clear boundaries/symmetry/(integrity)
   ** two parts of the code uses (this.selectedProject || getAllProjects().format()) and getAllProjects is heavy
   ** move others to have clear boundary (the created object deals with all requests to project-related stuff)

 * Make two different implementation similar (accept same input/types and have same output/types)
   (maybe also make one use the other in some/all cases).
   ** use one in an other and inline
   ** (then? unify keep only delegation to other implementation)
   ** then, inline
   !! It is not more work, it is safe, it is uncovering omissions in the model and better ways to model things
   (consider it like tests, they appear to be more work and costly to maintain, but they save you at unexpected time).

 * Expand/Extract (or widen/reduce) (you can see it as a combination of the above)
   Make two things have different meanings locally and same meaning outside.
   (example: End | Moved to). Extract to return each a apart (different meaning->add tests) and keep the original function
   to call the extracted and map the new to the old.
   Inline the latter (or change the call to the inner fn progressively) incrementally and differentiate in the calling code.
   Do it the Mekado method way, start from the leaves and go up progessively, and be ready to accept feedback and back off.
   Expand the match(result interpretation) duplicating the reaction and keep (with changing call target) black-box call.
   Be aware of fn calling the joints. Change the call in joints progressively and do the expand for leaves of fn calling
   the joints.
   Or do the inverse.
   This can be an indirect refactoring, those who need to know about it are not caller/callee, but creator/user.
   When you have A->B->C->D->E. May be only A, C and E need to know.
   Do not forget the tests.
   You cannot use first strategy because the progressive change will go through all joints.
   You leverage the fact that joints don't care about the result.
   If they care, you have a bigger problem, make it so they don't care.

 * Global change
   You want to replace a type with an other globally. Build a bridge between the two types (postel's law; make the new type
   = old type + some additions). Start with the leaves and go up, replacing the arguments/return values one at a time.

 * Add optional execution path/copy-adapt-tests/make it normal execution path/remove old
   a=b,c->d=f->x=y ==> you want to move b to x.

 * You can have a combination.
   ** Extract some helpers in the existing code.
   ** duplicate their use in the using code.
   ** change as needed.
 * You can have nested refactorings (graph in mikado method)

 * You can apply them recursively

 * Do not cheat on sturcture to gain behavior (have fn: Source -> Destination -> Result and give it same value for source
   and destination to model initialization) the fact (that initialization exists and that it is different) will be lost,
   the model will be lying and will diverge over time (ripple effect through the code), and you end up paying for it
   in different locations and under different names. (complete, accurate, obvious, implicit, simple to reason about model
   about all else).
   (isolate it if you can't/do not have time).
   Then, that is more state space -> more bugs and more cases to handle (which may result in undefined behavior).
   This also you can fuck it up even with a strong typing system.
   Better yet, change the code/model so that such hack has no meanings; cannot be created and have no special meaning.

 * Do not switch to a new implementation witout a test of each class of inputs.
   You may have a test for a couple of classes initially and you think to yourself it will be enough.
   It won't, and this is why we have test, because you believe something works (logically) but it does not.
   If you know why not, the test won't fail.

 * Move variable to an upper (lower?) scope so you don't need to pass it to the current scope.
   So, pass less to the current scope, only what the callers knows well.
   Create a function that returns another functions, call the upper function where you create/get the arguments
   and pass the partial function down.
   Call the partial function when you create/get the other arguments.
   You might as well make the partial function a sub-function of the upper one, and remove arguments entirely.

* Avoid mapping. aka avoid logical and easy answers that push complexity to further steps and lets you start now.
With mapping the problem of changing types seems do go away, you need to change A -> B.
make a: B -> A, m: A -> B. Use a(b(A)), then make it a(b), then b.
It works only when B is an exetension of A.
You end up with treating B as an A, the model is not optimal.
If a function does not care whether it is a B or an A, it should not know that such type exists.
Treat them as free type variables at least.
You are hiding the change and you discover mismathces and failures later in the process.
You may miss critical tests.
You cannot do it for the function actually using A.
The change is wholly layared: change all A in the program to a(b(A)) first, which not incremental change.
A change of type is a change of the program model. If the type is chattered all across the codebase,
that chattering need to be dealt with first. Otherwise you the change will be messy and will have
unintended side effects.
You cannot reason logically about the computer if the reasoning is not validated by a compiler/checker.
Your model cannot be complete.

* Change should be bottom up
update the leaf and its parent, one at a time.
That way the change ripple organicaly to the top.
You may need to minimize the change by refactoring to a structure where
knowledge about A and B is minimal.

* When you replacing a type with an exetended, start by putting null values (this can be bad if not well controlled)
in extra fields.
Then change them incrementally.

!!!!! --> The tree is not the tree of call where the leaves are the called function.
It is a tree of use, where the leaves create the type and their parent use it.
A parent then can be a leaf, (but this is an edge case as it breakes the levelness of abstraction??)
Start by changing the leaves, when you have a parent with two leaves that means more work.
Create node clones, the clone uses the new type. Then change the parent to accept the new type
and pass on the old type. and so on.

Pivot on the first using function, change downstream (called fns) and keep upstream (calling fns).

* Questions to ask before refactoring:
  ** is all pathes covered by tests?
  ** does current test express the variants better?
  ** what additional state space/behavior are we injecting?
  ** how other methods methods will use the code? what should they know?
  ** can further-upward dependencies use the new code without redirection?
  ** any effect on conceptual integrity?
  ** where should we put the new code?
  ** can the code be merged with other (potentially unrelated) existing code?