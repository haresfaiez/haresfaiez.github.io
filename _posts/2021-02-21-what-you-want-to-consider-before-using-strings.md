---
layout:   post
comments: true
title:    "What you want to consider before using strings"
date:     2021-02-21 22:01:00 +0100
tags:     featured
---

> *String* : a cord usually used to bind, fasten, or tie —often used attributively
>
> [Merriam-Webster](https://www.merriam-webster.com/dictionary/string)

Strings are the swiss army knife of programming. They can replace any other type.
The programs we write themselves are string inputs to compilers and interpreters.
But unlike numbers, strings are not primitive.
Processors can't concatenate them the same way they sum numbers.
Languages do some plumbing  so that strings behave as primitive values and so that comparing,
concatenating, and slicing them does not incur performance penalties.

Languages differ in how they represent strings.
Although they usually represent them as sequences of bytes or sets of linked
sequences of bytes, they keep different kinds of information about them.
Some languages, like C, require that the bytes be linear and
keep a pointer toward the first byte.
Other languages, like Java and Rust,
keep metadata like the length and the capacity in addition to the pointer inside an inner structure.

## Obscure code
Complexity shifts. The more liberal strings are, the more complicated their interpretation will be.
In domains rich with rules and computations, strings are usually a code smell.

Consider these examples:

```typescript
type Role = Author | Reviewer

function addFeedback(author: Role, rating: ArticleRating) {
 // ...

function watchArticle(watcher: Role) {
 // ...
```

```
function addFeedback(author: String, rating: String) {
 // ...

function watchArticle(watcher: String) {
 // ...
```

When we want to add a new role, the first version makes it clear that two functions
are affected.
In statically typed languages, we will have to recompile the modules of both functions.
And, if we don't account for the new variant in a match operation, compilation fails.
The second version meanwhile complicates such change.
`watcher` might contain something other than a role in some scenarios.
We need to analyze a lot of code to make sure the change is safe.

In commercial applications, the second version invites auxiliary work.
People come and leave all the time.
The domain logic grows more complicated as new requirements come in.
And, bugs surface unnoticed edge cases.
All that increases the cost of keeping functions in the second version focused exponentially.
Eventually, validation logic will crip in and duplication will thrive under the carpet.

When functions accept and return strings, navigating the code using the editor also becomes hard.
Tools miss information that may support maintainers in avoiding duplication and unnecessary
validation.
We cannot find all functions that use the role automatically.
We can only search by argument names, which is fallible.

## A huge state-space
The state-space of a string variable is huge.
Strings are usually encoded as UTF-8 or UTF-16.
[UTF-8](https://en.wikipedia.org/wiki/UTF-8) uses one to four bytes to encode each code unit.
Each character needs between 1 and 32 bits.
The domain of a function that accepts two four-character strings will have at least 2048 elements.
[UTF-16](https://en.wikipedia.org/wiki/UTF-16) itself
allocates 16-bit for each code unit with 1 to 16 bits for each character.

The maximum length of strings is also huge.

> ECMAScript 2016 (ed. 7) established a maximum length of 2^53 - 1 elements.
> Previously, no maximum length was specified.
>
> [String length](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/length)

We don't need to test for all string variations, but there are many edge cases to check against
and to handle well (either by adapting them to fit the accepted domain or by rejecting them with
potentially informative error messages).
Think about lower/uppercases, leading/trailing space, punctuation,...
As [M. Finagle](https://en.wikipedia.org/wiki/Finagle%27s_law) would have said,
it is not clever to ignore invalid input in a function that accepts strings just because
we are in control of the code and we made sure no invalid input gets there.

## Mutable vs. immutable types
Usually, the memory needed for a string value can neither be inferred at compile-time, nor at
the moment of defining a string.
The challenge for language designers is how to allow programmers to gracefully manage strings
without leaking memory. Solutions vary widely.

Most dynamically typed languages accept the declining performance
and use sophisticated algorithms to allocate and re-allocate memory on the fly.

Some statically typed languages provide two string types,
one for immutable strings and one for mutable ones.
We create, then manage, strings using the mutable type.
Then, we convert them to the immutable to pass them around and compare them.

Java has `String` and `StringBuilder` which
> Unlike strings, every string builder also has a capacity, the number of character
> spaces that have been allocated. The capacity, which is returned by the capacity() method,
> is always greater than or equal to the length (usually greater than) and will automatically
> expand as necessary to accommodate additions to the string builder.
> 
> [Buffers](https://docs.oracle.com/javase/tutorial/java/data/buffers.html)

.Net Api also provides a [StringBuilder](https://docs.microsoft.com/en-us/dotnet/api/system.text.stringbuilder?view=net-5.0).

In C++, `std::string` is responsible for memory management operations.
`char*`, on the other side, references the beginning of the string and is used to pass strings around.

Rust has `str`, `&str`, and `String`.
`String` is mutable and `str` is immutable.
`&str` and `String` are fat pointers (pointer + associated metadata).
`&str` contains a reference to the beginning of a string and its size.
`String` contains the capacity too.

## In code vs. in the user interface
There is a gap between how we manage string values and how those values look to end-users.
A string without encoding is just a sequence of bytes. A valid code point in one encoding
might correspond to a different character in another encoding.
It might even not correspond to any valid code point
(see [Mojibake](https://en.wikipedia.org/wiki/Mojibake)).
We need to encode each string with the target system in mind before sending it.

Some code points correspond to [non-printable characters](https://web.itu.edu.tr/sgunduz/courses/mikroisl/ascii.html).
Some [homoglyphs](https://en.wikipedia.org/wiki/Homoglyph) might show the same grapheme for different
code units,
[orthographic ligatures](https://en.wikipedia.org/wiki/Orthographic_ligature)
might join distinct successive characters.

For inputs, it is a good practice to guide users and provide custom inputs
instead of free text inputs in interfaces.
What users put in text inputs ends up as values we pass around in the code.
We can simplify the code by reducing the possible values.

Although it is easier for users to put their birthday into free text than to select the values
from dropdowns, the probability of input errors increases, the cost of validating and
interpreting what is written is huge.
Sometimes, it is even impossible to understand what
the user means as the input can be interpreted in many ways.

There are many situations to check:
 * out-of-range values
 * full vs. abbreviated months names and years
 * months numbers vs. months names
 * periods or spaces to separate date components
 * what kind/length of space would that be
 * European-style and US-style dates
 * uppercase vs. lowercase names
 * XSS and vulnerabilities
 * input language

We may add a note to tell users the format and the rules we expect. But, nobody read those.
