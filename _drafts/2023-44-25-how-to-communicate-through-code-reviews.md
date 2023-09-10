---
layout:   post
comments: true
title:    "How to communicate through code: reviews"
date:     2023-11-25 12:02:00 +0100
tags:     featured
---

title: Can code speak for itself? Reviews
title: Can code see the world: reviews
title: Can code be readable?: reviews
title: Can we communicate through code?: reviews
title: Source code as a communication medium: reviews
title: Fixing bugs by fighting windmills: reviews
title: Can code be "right"? Can code lie?
title: Source code as "pattern encoding"?

You know Don Quixote,
the guy who though of windmills as giants and went on fighting them.
Sometimes I think of fixing bugs as conquering a windmills.
You can claim victory. But, what's "victory"?
We fix the behaviour, not the concept, not the model,
not the thinking that went that went behind the bug.
Can you count how many times you renamed variables/functions/classes after fixing a bug?

The questions can be either about the function:
"How is a component HTML built? And why it changes background in here but not there?",
or about the implementation
"Where this event is handler? And what happen wher it's emitted?".
To answer these questions, we should go deep in the code, follow usages, look for names,
and maybe also learning about third-party libraries.

But, in the end, it's about reconstructing the image the progammer encoded.
Sometimes, the author keeps control and can answer these questions.
Other times, it can tell you the rules or the image he was trying to encode.
In most codebases, this image might tell you nothing.
When for example, the author tells that we fire a certain event at a certain time,
it might tell you nothing about why we use it to change the background of another
component.

Naming is hard. This has been a fact since the early days of modern
programming languages, and will stay true as we're heading into the integration
of AI into our tools.
I think so.
After all, programming is theory-building. It's knowledge structuring.
Designing programs by writing Javascript or by curating samples
for machines is still a question of what software should do,
what it enables, and what it should not do.
In other words, what the user expects the software to do,
what he/she instructs the application to do,
and when he/she should choose another application.

The future could be somewhere where we design interfaces
and not worry about the internal structure.
But, we will have to give some input to the machine so that
an interface appears to the user, at least for next years.
We will need to write hashing algorithms.
We will tell the computer to not go over a certain cost threashold.
That's programming.

When preprang a previous post, I found in the code `mouse.leftbutton`.
I tried to follow the logic of the function.
I failed. I logic makes sense only if its `mouse.rightbutton`.
"left" for whom? My "left"? the screen "left"? The mouse "left"?
Left is contextual.
Such problems exist in the language. And, they propagate to code,
to interfaces, and to the deterministic machines we build.

When we write code, we use a natural language.
Natural languages are "messy".
Verbs like "share" or "follow" have different meanings
that those of fifty years ago.
"share" itself can have different meanings for different applications.
I can share a post. I can share an account. I can share my screen.
I can share food. I can share sharing...
So what's "sharing"?

We can go deeper here.
During domain modeling, certain concepts can have different meaning
between subdomains.
A marketing facture is not the same think as a deployment facture.
If we look for occurence of the string "facture" in the code
and find all usages.
Can we build an accurate mental image if we don't know that many types
of facture exists.
And knowing which types of factures exist, and where in code they're created
and calculated, do we need to search for "facture" usages?

Code is made of concepts. Some are implicit. Others are explicit.
And, yes documentation is part of the code.
It's also code. It's unstructured code, which non-tetstable,
not type-checked, non-searchable, non-debuggable, not easily refactored...
And, it's made of implicit and explicit concepts
 Writing more documentation is a lost fight.
A programmer defines them and puts them into source code, as functions names or as naming conventions.
Other programmer tries to build models to answer their questions.
We talk about productivity, effectiveness, efficiency, simplicity,
expressiviness, complexity, explicit/implicit dependencies,
explicit/implicit domain knowledge. But, I think we don't focus enough on the nature
of what we build.

I just finished reading reading two books that touch on language and understanding.
They sparkles some insights into how we understand the world
and thus how we put the text we read in a source code into a personalized context.
I'll try to reflect on what they say about naming and modeling the world in the code.

These are not book reviews or summaries.
They're just thoughts that occured to me after reading the books.
You might learn something different.
So read it if you think their subjects are important.

While writing this, I tried to keep these questions in mind:
* Can we express our whole view of the solution design in the code?
* Can structuring the code contribute to understanding?
* What can we do when expressiveness conflict with reusability, loose coupling, ...?
* What is the difference between code and text files?
* Is text the best medium for writing code? Is it the best also for reading it?
* Why IDE matters?


## Data and reality ("named" as a relationship)
* The proposition stated by the book is to propose a new data model...?
* A model where relationships?? are the center...?

"the existence of entities is typically not modeled independently, but is implied by their participation in various relationships."

"This book projects a philosophy that life and reality are at bottom amorphous, disordered, contradictory, inconsistent, nonrational, and non-objective."


* is the new model only for date or it does extend to domain model/ui ...?
* is "named" a relationship ...? (can it change in the future) ...? what happens when it does ...?
* can two entities share a name ...?
* existence test is ...?
* can we really define a concept...? (what's life)
* can someone with no prior knowledge of the code understand the concept ...?
* type vs value ...? (why do we need types, and why mulitple types for a value) ...?
* can a value in software exist without relationships ...?
* what's the boundaries of an entity (can we have multiple entities for the same person) ...?
* what happens if we change the meaning of a concept (prev. employee, -> now. contractor/in-house) ...?
* will it that be solved with a new boolean field ...? what happens after many such changes ...?
* Data collection and survival bias ...?
* collect data as victim of survival bias ...?




You can’t match on the basis of the same people occurring in two columns, if they are represented by employee numbers in one and social security numbers in the other. 

can you enforce what's written in a field corresponds to a city?
you can't. what's a city, is "Joe birth place" a valid answer.

In general, criticisms and comparisons should begin by clarifying whether the subject in question is a data model or an implementation. 

The approach still suffers from some of the record structure problems, e.g., those having to do with synonyms and with the representation of relationships having multiple entity types per domain (as mentioned in section 8.8.4). 

section 8.8.4

relationship as first class citizens of the model
"th named relationships, the syntax and semantics of queries can be made simple and uniform, independent of the method of representing relationships..."

how to find employees in Stockholm
if tables are
employees -> department -> city

there's a relationship between employees and city, but it's not explicit?

"Of all the kinds of records in which employees might occur, which type is to be considered the definitive list of employees? What is going to serve as the defining list for an existence test (section 2.4)? Conceptually, at least, it would help to always have a notion of an existence list, whose purpose is to exhibit the currently known set of members of that type. Put another way, one ought to be able to assert the existence of something separately from providing assorted facts about it."

"The descriptions of most models begin by making distinctions, between such constructs as entities, relationships, attributes, names, types, collections, etc. These are implicitly taken to be mutually exclusive concepts, more or less. We start instead from a unifying premise: all of these constructs are in fact entities. Each of these phenomena, and each of their instances, is a distinct integral concept, capable of being represented as a unit item in a model. 

...

There are four kinds of objects: simple ones, and the three kinds described in subsequent sections ⎯ symbols, relationships, and executables. 

the new data model
"Relationship occurrences, on the other hand, are well defined in this model."

"Thus we may informally speak of “objects of type X”, understanding that we mean objects related by a “has type” relation to an object named X, where X in turn is an object whose type is “type” (i.e., X is a type). And even that’s not the full refinement: “an object named X” is vernacular for “object related by a ‘has name’ relation to symbol ‘X’“ .... and furthermore, the phrase “related by a ‘has name’ relation” refines to mean an instance of a relation that is itself related by the ‘has name’ relation to the symbol ‘has name’.... and so on."

"The base model provides a medium for very precise definition of the other concepts. Thus, when many of the dilemmas described in this book arise, they can often be resolved by referring to (or agreeing on) precise definitions in terms of primitives. "

"Thus, for example, type and attribute can appear to be distinct in the vernacular, but both be defined in terms of relationships. "

"The simplest notion for naming is that there are two objects in the system, a nameless element that is the actual representative (surrogate) for something in the real world, and another object that is a symbol. A naming relationship connects these two, as in [Hall 76]. The surrogate may be so connected to several symbols, serving as synonyms or aliases, or even as descriptions. An implementation need not supply two such distinguishable objects; this device merely serves to describe the semantics of the model. 

...

The requirement to have a name, or a unique name, can be imposed in various implementations, or when used in conjunction with particular data processing systems. But they are not intrinsic requirements of the model. "

"Perhaps this model ought to have a name, for handy reference. Any model worth its salt ought to have a catchy acronym. Sometimes I call it STAR, standing for “Strings (or Symbols), Things, And Relationships”. But it could also be ROSE: “Relationships, Objects, Symbols, and Executables”. "

"Existence is established when one of these symbol paths leads to an object in this set (and equality is established when two of these symbol paths leads to the same object). "

"Language has an enormous influence on our perception of reality. Not only does it affect how and what we think about, but also how we perceive things in the first place. Rather than serving merely as a passive vehicle for containing our thoughts, language has an active influence on the shape of our thoughts."

"Views can be reconciled with different degrees of success to serve different purposes. By reconciliation I mean a state in which the parties involved have negligible differences in that portion of their world views that is relevant to the purpose at hand."

>>> screenshots

11. Elementary concepts: another model?
thus far we have been largly criticcal, and negative.
We have identified without really suggesting solutions.
Can we identify an appropriate set of elementary concepts that will on the one hand serve as a general bae fo rmodeling information (in our limited use of that term), and on the otehr hand be an appropriate base for computerize dimplementations? Let us try.
What follows here is a sketch of work in progres, some basic ides about the "right" set of constructs for such a model.
Much work remains to be done - including an attempt to define more precisely the criteria by which the model is "right" in the first place.
I will begin (shortly) with some partially worked out ideas for a specific model, so that we know at the outset what conclusions I wsh to justify. Then some motivations and comments will follow.
The model is not intended for modeling reality as such. I t is rather an idealived system for processing information, which hopefully shas some very useful characteristics for modeling reality. It is highly abstract, and can be implemented (realized) in real systems in many ways - just as the abstract concept of "tent" can be represented may ways in machines. Also in its pure form the model has certain properties that provent it from ever being implemented perfectly- just as the infinite set of real numbers can never all be represented in a finite computer. For example, some things in the model are infinite, and some things exist without ever being created. Such thigns can be approximated in real systems.


SIMPLICIY IS
this split-level approach has samo disadvantages. Since the direct
intent of the user is not transimtted to the underlying system, the system may not be ablo to optimize and perform the function in the best possible way. In the averaging example above, the system executing the first statement is likely to take two passes through the list, once to accumulate the sum and again to count the elements. If the system understood "average" directly, it would do both in one pass.
In a nutshell simplicity can mean either a small vocabulary or concise descriptions. Both have their value.
Incidentally, let me mention still a third kind of simplicity, which may be even more important that the other two in the area of data description.
This is "familiarity". The easiest system to learn and use correctly may well be the one that is closest to something already known, regardless of how objectively complex that may be. It i precisely this phenomenon, for example, which makes the metric system of measurement much less simple for me (and many of my readers) to use, although it is obviously simpler by any objective criterion. The trouble with this approach, of course, is that it is subjective and depends very much on who the users are. How to dyou measure it? And does it require supporting a number of systems, each "familiar" to a different group of users?
And teher is this hazard: the apparent familiarity can also lead users astray, in those cases where the system does not behave the same as the thing they are familiar with.


PURE vs. PSEUDO_BINARY
Thus the similarity between pure and pseudo binaries is very superficial.
While there is a trivial resemblance in the formats of their pictures, there really is a deep semantic difference between the two: pseudo binaries are in fact supporting n-ary relationships, whle pure binaries require decompositions into pairwise relationships. The pure binary approach denies the existence of relationships involving more than two things at a time.
In that view, the shipping of parts to a warehouse by a supplier is not a single indivible fact. It must be viewed instead as a composition of smaller facts. eg, fact1: parts are shipped to warehouses. fact2: suppliers perfom fact. 1 In contrast the pseudo binary view acknowledges the existence of a single complex fact, and simple draws a picture connecting the fact with each of its participants. Despite the pejorative connotations of the term, I hope it's clear that I prefer the "pseudo" binary model.



Having named relationships as an integral part of the model is much the same idea as perceiving the model as a set of functions.

IMPLICIT RELATIONSHIPS
there is a disadvantage to systems that deal only in named relationships. They limit the user to followoing paths that have been previously declared by a data administrator, and make it difficult to follow paths implicit in other data stored in the system.
As mentioned in section 4.6, if two entities are related to a third in any way, then that in itself constitutes a relationship among the first two. One employee might work in the same department as another. The secretary of a department probably serves as secretary for each employee in that department.
Attributes can provide such links in the same way as relationships. If an employee works at a certain location, this implies that his depratment has someone working at that location. If we have a mechanism for establishing that two attributes are ~in the same domain~, then we can infer a relationship between entities having the same value of such attributes. E.g. we could infer that a supplier and a warehouse are in the same city.
Both the domain and the role of the attributes must be considered to avoid misunderstanding the significance of the implied relationship. If an employee was hired on the date his manager graduated college, wu mustn't infer they were hired on the same dato, or bord on the same date.


CHARACTERS OF THE NEW MODEL (BOTTOM_TO_TOP)
* context of system organization: repository, interface, processor
* descirptions not segregated from data. They reside in the same repository and are interconnected
* semantics to be specified for surrogates includes a description of the existence tests and the equality tests
* does have a type phenomenon. It allowv types to overlap (an object can be of multiple types)
* it does not take type, attribute, set, or naming rules to be primary constructs
* its primary constructs are objects, relationships, symbols, and executable objects
* it supports many-to-many relationships directly
* distinguishes between the objects (surrogates) that represent entities and the symbols that name entities
* differs from any form of relational model in that relationship occurence is an aggregation of surrogates, not symbols
* mech like a binary relational model, in the sense of ...
* much like an irreducible n-ary model

# Metaphors we live by
* The book proposes a new view of reality other than that of objective/subjective ...?

* It states that only physically experienced concepts are defined through experience.
All other concepts we have are metaphors of these concepts.
Up/down -> happy=up/sad=down.

I heard about the book from Kent Beck on twitter a long time ago.
As in software, we don't experience concepts. But, we try to name them after concepts
we are familiar with.
"sharing" a post on social media is like sharing a physical picture with friends,
showing it to them.
This means we can think of the right metaphors that apply to the code.
We can think of the best metaphor after which we design our code.

Metaphors are good to replace three or four-words names.
Instead of naming a class `MoneyCalculator` with methods like `result()`,
`add(MoneyAmount amount)`, `remove(MoneyAmount amount)`,
we can call it `Wallet` with methods like `total()`,
`put(Sum )`, and `take`.
It might appear un-natural. But, if you communicate it well with the team,
it will work.
We have many such metaphors in the way: this basked,...
But, they are useful in the code as well.

Getting the metaphor right is complicated.
A lot can go wrong.
By studying metaphors we use from day day, we get better at inventing them.

* what's the boundaries of an entity (can we have multiple entities for the same person) ...?
* When a line is really a line ...?
* the abstract notions of point/line/...?

# How Not To Be Wrong


- ?? (can we think of job interviews/products in the same way as elections?)

- metaphors: spherical geometry ``

- condorsey/conversey paradox: candidates
* be aware of aggregation (probabilities,....)
* vote with 2 vs 3 options: what if instead of choosing one president, your order 3ones and calculate a score at the end (will the result be the same?)
* inconsistency of aggregate judgement
* no correlation does not mean no relation, maybe there's a relationship that cannot be detected by correlation 
* correlation is not transitive: rich people -> rich state, rich state -> democrat, BUT rich people -//> democrats 
* correlation as cos of points vector
* correlation makes data compression easier 
* an ellipse as a graph of correlation 
* is entrepreneurship a tax on the stupid?
* right code == f(randomness, structure)* using code to pick lottery numbers 
* expected utility theory vs known/unknown risk/uncertainty 
* using projective geometry to win lottery 
* lower variance (salesman problem) using geometry (converging rail roads)
* two kids with same birthday at party :
p(same-bd/two-kids) =/= p (two-kids/same-bd) =/?= sum p(other-kd-too / kd-has-bd)

* Bayesian probability with oxpected value does not work for unknown unknowns?* variance: if you're retirement plan is exciting, you're doing it wrong* probability of two people with the same b day in a party is numberOfPairs/numberOfDays
==> probability that two pairs have the same value is over 70% even for small number of subjects 
* when expected value is positive, people are conservative. when it's negative, people take risk
* expected utility theory 
* choose the option with highest experted utility* utility is subjective measure 
* expected value (lottery)
* designing an argument with Bayesian probabilities ( f (prior theories beliefs) )
* probability as a degree of belief?
* relying on no hypothesis significance test is the opposite of using Bayesian theory?
* Bayesian theory: prior/ posterior probability (how prior influences posterior)
* predicting weather -> mathematical notion of chaos. (human behaviour too)
* statical significance -> tells you what to do next
* if you're making decisions based on an academic paper, you're making the same mistake as plane analysis, other papers proving the same did not pass significance test. you're lucky but don't know it
* threshold problem in academic papers

* law of large number* bias (postmortem bias)* null hypothesis* p-value* significance test
* significance hypothesis test


## Reflexions/phonix in a graveyard
- reflection on what software is
- what happens if a software/idea dies
- is software really a "part" of our lives, a "part" of us/behaviour, or is it a tool
- why you should never own software
- how to lie with data
- immutability is in the eye of the beholder
- can we talk about immutability of effect/behaviour/solution
- probablity/rare events/uncertainty/the fate in life vs. in interaction w/ software