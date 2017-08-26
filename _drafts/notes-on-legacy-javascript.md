*if the code works well*
- replace global access with setter/getter
- don't isolate a unit with more than 3 arguments (count each global access as an argument)
- collect if you need more arguments
- function (defer evaluation) is a way to design with caring about state  (hidden coupling, anyone?)
- changing the scope without changing behaviour is a fine
- using currying to set each argument at a different level/scope
- keep the state access/modification at one module, refactor else to stateless functions (make the state transition/patterns clear)
- function (defer evaluation) is a way to design with caring about state  (hidden coupling, anyone?)
- use partial application when the arguments are no cohesive
- functions are options
- keep reference/direct access when needed

*isolation*
- don't isolate big chunks of code at once. (It is costly to get sub-pieces back.)
- isolate big chunks only with the intent to inline them back as soon as you finish working on them []
- There a level of each refactoring, it is defined by the collaborating units
- keep duplication (or introduce it intentionally) to refactor with a cohesive set of decisions
- don't remove duplication early (the last change resort is removing duplication, start with isolation)
- isolate -> introduce duplication [-> remove duplication]
- collect when the pattern is repeated more than twice
- duplicate then remove/refine piece by piece and test

*state*
- it is hard to keep it in mind
- be skeptical about executing the code in your head

*side effects*
- it is ok to keep non-observable side effects (e.g, log, non-shared/controlled notification)

*connascence*
- coupling is about knowledge not references

*making things explicit*
- start with naming/reanaming units
- name -> isolate -> name -> inline -> name
- be liberal in isolation, be conservative in collection
- use collector object to not end up with too much arguments (not often) [the object will rarely end up having a meaningful contribution]

*heuristics*
- high/low risk high/low benefit
- start anywhere (there is no starting point)
- handle data integrity at the edges
- use declarative data validation
- check at the boundaries assume locally (don't test with each local access)
- start with a direction (be open to change it, allow for options)
