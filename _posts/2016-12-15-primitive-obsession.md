---
layout: post
comments: true
title:  "Primitive Obsession"
date:   2016-12-15 11:49:00 +0100
categories: Naming
tags: featured
---

Every programming unit is a model.
It maps back to a real world object, an action, an idea,
or a set of thoughts we haven't find a name for yet.
We can reach it by sending messages
or we can move it around and use it to alter the control flow of the program.
It is a matter of distributing responsibilities between the composing elements of the program
and the level to which each component is ready to give up control.

A type is a set of constraints.
A specification, a set of invariants, or a set of rules that need to be respected 
by the user of the subject programming unit.
The level to which we can leverage the checking of these constraints to the language
depends on the power of the tools and the simplicity of the syntax.
More important is the level of certainty we want to guarantee for the users of that unit.
For a highly constrained unit, the more the afferent coupling the unit have,
the harder changing its implementation will be.

To keep the program intellectually manageable,
and to allow more opportunities for future changes,
it is important to offer each user the least possible information he needs 
to know about a unit.
This could mean using multiple types for one model,
then, a person could be its age, its job, its name, its identity, ...

A problem occurs when we use predefined types such as integer, boolean, and string
to convey a program concept, a model.
The evaluation context carries semantics and constraints about the result.
It is very hard to keep that implicit knowledge in mind
due to the large set of assumptions that could be made
and the growing complexity of the program itself.
It will be lost if it is not conveyed by the type.
Using a predefined type, thus, omits knowledge about the evaluation context,
by allowing inappropriate interpretation about a certain value.

An even number, for example, can be modeled as an integer. We could have:

```
Integer two  = new Integer(2);
Integer four = new Integer(4);
```

When we use those variables, we will not have a guarentee
that either of them is an even number.
The signature of the client will be like this:

```
accept(Integer anEvenNumber)
```

There is a waste of knowledge.
That turns out to be a source of bugs as the signature of the client
goes to higher abstract forms, especially when there is not enough test
coverage in the system to cover the the situations that involves the inital assignment.

It would be better to name it "anEvenNumber".
Except  that the name of the argument is better to be focused on the role the argument
plays in the body of the procedure, and not its nature.
Mixing the role and the type of the arguemnt in the name won't
make the code easy to understand.
I see it as a subtle form of the hungarian notation.

Let's think now about modeling even numbers this way:

```
EvenNumber two  = new EvenNumber(1);
EvenNumber four = new EvenNumber(2);
```

The "accept" procedure will be:

```
accept(EvenNumber itsRole)
```

And now, the context of the initial computation of the numbers may not be wholly required.
The required aspect of it, that of the nature of two and four is well communicated.
And, yes, you could just use EvenNumber as a wrapper, like this:

```
EvenNumber two  = new EvenNumber(2);
EvenNumber four = new EvenNumber(4);
```

But, here, we have an implicit duplication in the nature of the argument.
But, as always, it is a trade-off where the use of the structure influences its internal
implementation, wich itself changes as the software grows.
