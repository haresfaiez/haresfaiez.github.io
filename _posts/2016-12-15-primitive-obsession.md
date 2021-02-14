---
layout:     post
comments:   true
title:      "Primitive Obsession"
date:       2016-12-15 11:49:00 +0100
categories: Naming
tags:       featured
---

Each program is a collection of decisions. It solves a problem, at least.
It communicates the structure of the solution and, perhaps, the reason behind each decision.
A program is, also, a collection of units. Each has a set of responsibilities,
a role, and an implementation.
When the units fit well together, the program communicates the solution well.

The responsibilities of each unit specify the problems the unit solves (what it is doing),
the role specifies its contribution to the program (why it is doing it),
and the implementation describes how well the unit satisfies its responsibilities
(how it is doing it).

By learning the roles of the constructs of the program and witnessing their relationships,
one constructs a mental model of the subject.
Then, by diving into the responsibilities and the implementation,
he understands the thinking that went behind the sturctural decisions.

The role implies the responsibilities, and
the responsibilites, when interpreted in the right way, imply the role.
Although valid,
this correlation limits our ability to think of each unit as a separate construct.
Indeed, when we see the program itself as a part of a bigger system,
it is this very sepration that implies the fitness
of each unit in contexts other than which it was designed for in the first place.

The difference between the responsibilities and the role are expressed
in multiple fashion.
One way to it is "Responsibilities in the core, role specification in the shell";
This is the approach used by functional programming languages.
Each type is a fixed set of values, and when we need to add meaning
to the type, we wrap it inside a new type.
Another way is
"The role in the core, and the specification of the responsibilites in the shell";
This is the approach of class-based object languages.
The interface is a fixed specification of the unit, and the hidden state
varies between different contexts of use.

A type is a specification of a programming unit.
It could be seen from a variety of lenses.
I will look at it as a communication mechanism for the remaining of this post.
Each type allows the programmer to enforce constraints on the role,
the responsibilities, and the implementation.
Choosing what unit to include in the structure
and what constraints to impose on this units
requires continuous refinment and a reflective mindset.
Finding the right abstraction, what information to omit from the specification,
requires maturity, from the programmer, the programming language,
and from the software itself.

I will introduce a primitive type as a type which conveys a little about the unit.
The primitive character, thus, is highly contextual.
And finding an adequate type is more about consistency and coherence
with the other units in the program than it is a subjective view.
Whether the type of a unit is expressive or not depends
on whether an instance of this type makes sense as a collaborator in the program.
It is very hard to keep the specification of a unit implicit
due to the large set of assumptions that could be made
and the growing complexity of the program itself.
Using a predefined type, thus, in the domain logic,
allows for inappropriate interpretation of values.

An even number, for example, can be specified as an integer. We could have:

```javascript
Integer two  = new Integer(2);
Integer four = new Integer(4);
```

When we use those variables, we will not have a guarentee
that either of them is an even number.
The signature of the client will be like this:

```javascript
accept(Integer anEvenNumber)
```

There is a waste of knowledge.
That turns out to be a source of bugs as the signature of the client
goes to higher abstract forms, especially when there is not enough test
coverage in the system to cover all the situations that involve the inital assignment.

It would be better to name it "anEvenNumber".
The name of the argument is better to be focused on the role the argument
plays in the body of the procedure, and not its nature.
Mixing the role and the type of the arguemnt in the name won't
make the code easy to understand.
I see it as a subtle form of the hungarian notation.

Let's think now about modeling even numbers this way:

```javascript
EvenNumber two  = new EvenNumber(1);
EvenNumber four = new EvenNumber(2);
```

The "accept" procedure will be, then:

```javascript
accept(EvenNumber itsRole)
```

And now, the context of the initial computation of the numbers may not be required
for the maintainer of the latter procedure.
The required aspect of it, that of the nature of the numbers is well communicated.


And, yes, we could just use EvenNumber as a wrapper, like this:

```javascript
EvenNumber two  = new EvenNumber(2);
EvenNumber four = new EvenNumber(4);
```

As always, it is a trade-off where the use of the structure influences its
implementation, wich itself changes as the software grows.
