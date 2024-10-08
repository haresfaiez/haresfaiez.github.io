---
layout: post
comments: true
title:  "Code entropy in action, Needleant alpha release"
date:   2024-08-24 22:00:00 +0100
tags: featured
---

> "As far as we were aware, we simply made up the language as we went along.
> We did not regard language design as a difficult problem, merely a simple
> prelude to the real problem: designing a compiler that could produce efficient programs."
>
> -- [John Backus](https://en.wikipedia.org/wiki/John_Backus)

That has been said in the 50s, thought of in the 40s maybe, ... around that era.

And probably there's still some truth to it ... or, well, maybe ... it's still true.

Code is a medium for communicating thoughts.

Teams and programmers invent solutions all the time.

They come up with new rules about software behavior,
new colors for the buttons, tools, languages, lists of deployment steps,
and so on.

These are contextual changes.
They mean something within a context (usually the mental model held by the authors).
And they communicate the decisions made in that frame.

Think about them as messages.

They're destined for the next maintainers.

They facilitate the recipient's interactions with the machines by offering context,
abstracting error-prone and repetitive tasks,
and creating abstraction levels to free humans from thinking about "irrelevant" details
(or making things more confusing for them, but that's a topic for another day).

The main vehicle of programmers' communications is source code.

It's structured text.

Structured text is, at the same time, expressive (for us to understand),
cheap (for us to edit), and scalable (we have the tools to manage large amounts of it).

IDEs make messages more intelligible to recipients.

Compilers and tests check whether it's safe to forward a received message to the computer.

Browsers offer users an interactive medium through which they "see" the messages, and "reply" to us.

## Code entropy

The abstract thinking about what information is,
and how best to persist and transmit it,
is a key part of the study of computation.

It's labeled as ["Information science"](https://en.wikipedia.org/wiki/Information_science).

"Entropy", although it's a "stretchable" term, is a pivotal measure in this science.

> In information theory, the entropy of a random variable is the average level
> of "information", "surprise", or "uncertainty" inherent to the variable's possible outcomes.
>
> -- [Entropy (information theory)](https://en.wikipedia.org/wiki/Entropy_(information_theory))

As an attempt to build a bridge between "Code as a communication medium" and "Entropy as a measurement of information",
I created [Needleant](https://www.npmjs.com/package/needleant) to measure Javascript source code entropy.

The library aims to provide a relative idea of how much information a code snippet contains:

```javascript
const code = 'const a = 4;'
const analysis = new NeedleAnt(code).entropy()
const entropyValue = analysis.calculate() // 0.5
```

It may answer questions such as:

* How much entropy does a commit or a pull request add or remove?
* Which alternative of the two possible solutions introduces less entropy?
* Which library is more coherent (has a less "surprising" API)?
* How many parameters does an API need, relative to what a close API needs?
* What's the entropy of test code logic compared to the code itself?

The package is still in its alpha stage.

The [source code](https://github.com/haresfaiez/needleant) is on GitHub.
You might want to take a look, suggest improvements, report bugs,
or even implement some stuff yourself.

Try it with a [sample editor](/needleant.html).

It calculates the total entropy after each code change.
When you focus on a token, it highlights the
tokens that can be used instead.

## Scope as an alphabet

Each expression is a combination of the identifiers available in the scope
and the primitives offered by the programming language.

It's a sentence written in this alphabet.
The state space for an identifier is its scope.

The probability that a return value be a given identifier
can be a function of which other identifiers are available,
how often the chosen value is used,
and the distance between the assignment/definition and the usage.

The less a variable is used, the more surprising its usage.

Defining new variables increases the expression entropy.

Having a complicated expression with many nesting levels also increases its entropy.

The same thing goes for expressions and coding patterns.
If the code always uses a map/filter/forEach to update array elements,
it'll be surprising to use a for-loop every once in a while.

All these are basic heuristics for calculating probabilities.

Needlant currently calculates the probability of having an exact token from its
alternatives using a [Discrete uniform distribution](https://en.wikipedia.org/wiki/Discrete_uniform_distribution).

Custom strategies and an API for choosing and creating
strategies will land before the first major release.
