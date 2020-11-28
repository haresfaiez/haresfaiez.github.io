---
layout:   post
comments: true
title:    "Advantages of S-expressions over JSON"
date:     2020-11-28 21:47:00 +0100
tags:     featured
---

Although well-established in different programming circles,
JSON and S-expression (or sexpr) are well-known data formats.
JSON was commoditized by Javascript. It owns the biggest market share nowadays.
APIs, databases, and configuration files use it heavily.
Sexpr meanwhile is common between functional languages,
especially Lispy languages such as Clojure and Racket.
Data formats: JSON, sexpr, and XML, RDF, and the others, are isomorphic.
The difference is not one of ability, but one of fitness in context.

[JSON](https://www.json.org/json-en.html) is well known. I assume you know enough about it.

> S-expressions (or symbolic expressions, abbreviated as sexprs) are a notation for nested list
> (tree-structured) data, invented for and popularized by the programming language Lisp, which uses
> them for source code as well as data.
> In the usual parenthesized syntax of Lisp, an S-expression is classically defined as
> an atom, or an expression of the form (x . y) where x and y are S-expressions.
> [Wikipedia](https://en.wikipedia.org/wiki/S-expression)

```scheme
(user
  (name
    (first 'Faiez')
    (last 'Hares')
  )
  (handle '@faiezhares')
)
```
This is an sexpr.
We put the types (`user`/`name`/`handle`/...) in the heads and the values in the tails.

Another [example](https://reagent-project.github.io/) is a DOM element in Clojure:

```clojure
[:div
   [:p "I am a component!"]
   [:p.someclass
    "I have " [:strong "bold"]
    [:span {:style {:color "red"}} " and red "] "text."]
]
```
We use the head for the tag name and we use the tail for attributes and children.

## Metadata
Metadata is data that describes data.

```javascript
{ name: 'Faiez' }
```
This is one-level metadata, one key for one value.
`name` is metadata and `Faiez` is data. Metadata levels can go up.
Keys themselves then are described by other values, and these values too are described by other values.

JSON does not offer a straightforward way to express metadata other than keys.
To extend the previous example, by describing how to validate the name for example,
either we use an object in place of the value, or we add keys adjacent to `name`.

Sexprs, on the other side, encourage many meta-levels by not separating keys from values.
It's all values that describe other values.
We may define composite keys or parametrized keys, we may reserve more than one element at the beginning
of each list for the key, or we may reserve the first element for the value and keep the tail for the metadata.
We are free to divide and combine data as we wish.
We can even express the combination we choose with ease.

An sexpr can have duplicate keys.
Used effectively, this allows us to shift complexity to the receiver and to be more liberal
in how we build expressions, especially when we aggregate many sources.
See [Robustness principle](https://en.wikipedia.org/wiki/Robustness_principle).

This flexibility gives way to rich and simple models.

Compare this

```scheme
(name 
  (with-whitespace (max 2) (default ' '))
  ((full parsed stored) value)
)
```

to this
```javascript
{
  name: {
    whitespace: {
      max: 2,
      default : ' '
    },
    full: value,
    parsed: true,
    stored: true
  }
}
```

And this
```scheme
(name 
  ((separator '.') (spaces-between-separators 3) (max-separators 2))
  (main sufficient-to-identify 'first-name')
  (main 'last-name')
  (sub by-wife by-brother 'another-name')
  (sub nick-name (max-length 10) nick-name)
)
```

to this:

```javascript
{
  name: {
    config: [
      { separator: '.', maxSeparators : 20, spacesBetweenSeparators: 3 }
    ],
    values: {
      main: [
        { isSufficientToIdentify: true, value: 'first-name' },
        'last-name',
      ],
      sub: [
        { usedBy: ['wife', 'brother'] value: 'another-name' },
        { type: 'nickName', maxLength: 10, value: 'nick-name' }
      ]
    }
  }
}

```

## Validation
I mean high-level validation, not the jungles of byte tweaking.
The one where we decide to accept, reject, or to transform data structured under our target format.
Data validation is important if we are to receive information from outside our system.
Whether from a user, an API, or a database, it is usually a good idea to detect
invalid and insecure data early to avoid null checks and format validations
around every corner of our code.

In JSON, we often have an expectation of which keys and values there are and where.
Values are identified by paths. If we find nothing in a path
or if we fail to complete it, then the value is missing.
Discoverability is hindered as the only means to explore content are things like `Object.keys`
and `Object.values`, which are not the idiomatic ways to handle JSON objects.

This is beneficial when we deal with coarse-grained APIs or when we need to apply a non-linear transformation
of the input into a domain model. If we have to pick values one
by one to build a legible structure incrementally, then JSON is the way to go.

In Sexprs, we talk more about interpretation and evaluation than validation.
How the interpretation goes is manifested by Lisp interpreters.
Sexprs are built from lists and lists cannot be accessed randomly.
The way to get to some target is to iterate over the items that precede it.
Lists are ordered though, so we can rely on that to simplify the interpretation.

The good news is that evaluation can be lazy. 
We don't need to interpret the whole input to build a new model.
We can ignore entire lists and lazily evaluate them as we need.

Think about it this way,
"calculate the total prices of blue balls" is simpler with an sexpr.
"give me the username from this user object" is simpler with JSON.

## Map, filter, and project
"Map" and "filter" are natural list operations.
They can be done over sexprs as well as over JSON arrays, but not over objects.
The primitive operation in both is the traversal.
In sexprs, navigation across all dimensions (toward siblings or children) is primitive.
It is a matter of how to read and evaluate what is next.
If we manage to build a coherent model,
list operations become its natural extension.

For example, not all elements mapped over need to be at the same level.

If we have the next model
```scheme
(
  (user (name "Faiez"))
  (admin
    (global
      (name (composite "M." "Gustave"))
      (name (composite "Mme." "D."))
    )
  )
  (supervisor (name "Jackie"))
)
```
and we want to extract names, we can easily transform it into
```scheme
(name "Faiez")
(name "M. Gustave")
(name "Mme. D.")
(name "Jackie")
```

Doing the same thing with JSON is quite challenging as we need to access each name
directly.

Projection too might become natural in sexprs.
If we impose constraints that transform lists into tuples,
we can manipulate them as entries in a relational database.

Transforming a model into another without manually extracting and filling
objects is a main advantage of list-based structures.
These operations are powerful. They compose well. They are easy to test and evolve.
And, they are naturally reusable.
But, they need coherent models and consistent evolution to leverage their power.

## Composition
Composition, too, is a frictionless operation for lists.
An sexpr is a collection of sexprs.
We put two sexprs next to each other, we add parentheses, and we get a new sexpr.
In the worst case, we define a key to `combine` the two.
In general, set theory operations such as union, intersection, difference,
and cartesian product translate well to sexprs.

Another kind of composition is merging objects.
Sexprs offer more flexibility in defining keys and values.
We can define multiple keys for a value and we can easily extend a key-value with
more values.
We can naturally combine multiple objects with rich metadata.
