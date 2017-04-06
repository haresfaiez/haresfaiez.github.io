Avoid the state trap

I can say the most tricky code to refactor is the one that involves
state mutation.
It is easy to make mistakes uncaught by tests in such situations.
The work of excuting the logic should be done in the mind of the programmer.

So, I think we should omit state before starting the refactoring steps.

Thinking about refactoring should happend at the structural level-
the organisational level- and not at the execution -the runtime-
level.
If we think about behaviour, even if it is about preserving the
behaviour of the system inact, we lost.
That is well sound because by the moment we try to think about
runtime, we get bitten by the state trap.
And reasoning about state is not simple, and it hardly works well
for complex situation.

There is so much nuance in here.
Let's move to a case:

we have this loop:

while(it.is(hot)) {
  i.shouldGet(water);
}

If we think in terms of run-time here, we would make it first:

var shouldGetWater = it.is(hot);
if(shouldGetWater) {
  i.shouldGet(water);
}
then,

Let's try now to 

if (it.is(hot)) {
  i.shouldGet(water);

  while(it.is(hot)) {
	i.shouldGet(water);
  }
}

