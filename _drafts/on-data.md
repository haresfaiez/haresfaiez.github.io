Title: Having the courage to grow software in a world we don't understand

#Right-margin-notice
This post will be update over time. It will edit the content every time I learn something
that I think fits in, or I get deeper into the subject.
Every edition will have a unique link. And, an edition will be accessible from all other
editions.
You will find the editions at the end of the post.

In the last year, the audiobooks I listened to were all about data.
I repeat each book at least twice and I try to listened to another book before
I relisten to one book. That is not to say I get them throuly. This why I am writing
this by the way. To reflect on them. I would like to get your feedback about my interpretation.
The books are: Antifragile, NNT; Fooled by randomness, NNT; Skin in the game, NNT;
The excellence divident, Tom Peter; The book of why, ...; Ego is the enemy, Ryan Holiday;
Karate?
I am not so sure I would have made it through the last year without them.
All I can tell is, well, the ideas there got popped up in my head in the right situations.
I will try to narrow down how the ideas in these books affected how I see my daily life
as a programmer.

The conclusion I drew from all this? Well,
"[...] we are a
bunch of idiots who know nothing and are mistake prone, but [some of us] happen
to be endowed with the rare privilege of knowing it."
NNT, Fooled by randomness

# How to make it without reading a book
We have two brains. A rational brain and ??? brain.
The main mission of the rational brain is to rationalize when the other brain does.
But, sometimes, really rare times, the rational brain changes how the ?? brain
works.

I write code for living. 


# Why group thinking matters
You think together not because your imaginary theory about how to proceed from here
may not be appreciated by the customer. Only time can show the correcteness of such
theory. And I fucking hate the discussion about what to do and what will happen if
we do this or that.
To put gently here, "Any meeting that into such reasoning is not worth attending".

It is  because there is something that escaped the model you have in your head about
the present and the past. Something you say "Oh! Fuck!" the moment you hear.
Anythink other than that is speculation and noise.
You get to what to do collaboratively by adding constarints on the environment
and by eliminating options.
The options you have them are not guarenteed to work, so you protect what you
value and you take the options that has the most outcome if it works.

# Why writing "correct" code is hard
?? once said in GEB
"Relying on words to lead you to the truth is like relying on an incomplete
 formal system to lead you to the truth. A formal system will give you some truths,
 but as we shall soon see, a formal system, no matter how powerful—cannot lead to all truths."

A type system is a formal system.
When I write a module. I want to decouple it from the others.
I want it to be as automous as possible.
Isolation, mind you, means simpler isolation for debugging and replacability, easier
testing, and well composability (orthogonality).
I don't think about its relations to every other module
it may be talk to. I assume the worst and adapt. The worst here means bad
input, system down,..
But, also I will make assumptions about the other modules.
Otherwise, my module should run as an operating system, not as a brick of a large
program.

It is those assumptions that testing is meant to challenge. I try to become
aware of the assumptions before adding the simplest trick to my program.
But, I don't want it to take for ever. So, I compromise.
Remember the Windows error dialog saying "Something went wrong".
My assumption is that the programmer working one of the hundrends (thousands?)
modules working to the execute the task detected an unvalid? behavior, maybe tried
to track what may cause it and failed to find something tangible (a rule that
applies to every sequence of events causing the behavior to execute) and
prefered to show the dialog box instead of letting the computer crash.
Or, maybe he just went to end his task and go home early to prepare himself
for a date.

# The problem is now waterfall, the problem is linearity
I am very skeptical of incrimental development when it is all about adding code.
Incrimental means also deleting code. The increment adj? applies, not to the code,
but to the model above the code (the rules by which I think about the code and changing
the code).
The problem is that these rules need not be consistent (a model, but not a mathematical, model).
Otherwise, not making them explicit in the code is the problem.

# Feedback is harmful in large quantities
Feedback is data. And "data is harmful in large quantities".

# No silver bullet, yet

# Me
I want to "have the courage to live in a world I don't understand".