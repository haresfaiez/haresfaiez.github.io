---
layout: post
title:  "UNIX, design for the future"
date:   2016-07-22 11:55:43 +0100
categories: Software
tags: featured
---

What is a good software?
A software that does everything you expect from? A one with an attractive user interface? well documented one ?
The definition of a good software is context-specific, and a good software for a person may not be the same for an other.
Everyone has its metrics and its view of a good software.

But, what about a useful software?
We can get the definition of a useful software:

“A useful software is the software that is able to be used for a practical purpose.”

It may not be the best solution, it may not be optimized, it may not look good, but it solves the problem facing us now. It accomplishes the practical purpose it is built for.
For a software engineer, it is generally complex to build a useful software.
We cannot predict many aspects of a software up-front, but, we can design our software to be adaptable and easy to change and to enhance. So, we can make further changes and improvements easily in the future to meet more specifications.
And we have many principles, patterns and values to guide us.

Unix and Unix-like systems have been built with some great design philosophies in mind, they are still useful nowadays, you see, and they are not that good tools — like any other software.

Through this collection of posts, I tried to help you and myself to explore some of the most known UNIX design decisions and to learn from them in order to create better software — a good-enough software.
Small is beautiful

“Composing programs from smaller programs to accomplish a desired task”.
That is the heart of the UNIX philosophy.
In a UNIX system; commands are simple, small, and easy to remember, so always tend to make your tool simple, small and easy to understand and to remember.

How much small a tool have to be is complex to define. It is relative to the domain and the problem the tool deals with.
Start always with just one tool that solves the problem and profits from available tools, the tool should be good-enough to do the job you need — don’t focus neither on perfection nor on optimization (may be five-lines shell script is enough, do it the right way, clean, documented, easy to understand…, don’t let it does more than what you need at that moment).
Then improve it as you use it from day to day — may be your colleague helps and the tool grows collaboratively.
The time you find some difficulties or you take more than then a reasonable time editing the software, split it to two or three tools easy to deal with. Try to not split to more and be careful to not re-engineer what the system and other tools offer to you.

The moral is to not over engineer, work iteratively and with small changes and keep your software maintainable.
Keep in mind that there are a plenty of available tools that help to achieve great performances; tools to format input, to configure hardware and to do some plumbing work at lower levels of abstraction.
So, focus on the purpose; it is up to the user to use it correctly.

UNIX adopt this principle through the pipes-and-filter architectural style.
The idea of pipes was inspired from Douglas McIlroy, who wrote a memo in 1964 suggesting the metaphor of data passing through a segmented garden hose.
This style is well known in the software community and it is as well adopted by many software architectures — I have explained how the Apache request processing cycle works in a previous post.
The idea in a nutshell is to pass the input to a cluster of small tools — together called a job, each tool manipulates the data in its way (filters it), and passes it next.
Design for the future

“Always design a thing by considering it in its next larger
context — a chair in a room, a room in a house, a house in an
environment, an environment in a city plan.”
— Eliel Saarinen

Choosing the right level of abstraction is task-specific, but a tool should be designed from the ground for reuse, it should offer a clear interface that communicates the provided functionalities and not the implementation details.
We cannot imagine what purposes users will use our piece of software for; a well designed software always satisfies needs the designer never predicted.

Make your software extensible and open to change so users can extend it and improve it easily, follow common practices from naming conventions to coding standards and documentation. That helps to understand the tool easily.
Avoid captive user interfaces (CUI), a captive user interface is an interface that prevents the user from using other global command for the duration of captures; CUI are hard to fit-in, complex to learn and to automate. The user is asked to learn new tools and a different syntax than that those he is actually using . These kind of software are also hard to build, to test and to maintain.
Meanwhile, GUI are sometimes useful. Use them when they fit well.

A good tool’s interface is easy to plug into multiple presentations, possibly simultaneously.

Building for the future also means accepting that changes in software is unavoidable, the software will not be the same the next year, nor even few months ahead; requirements change, technologies change and our perspective toward problems changes. The tool should be adaptable.

There are plenty of design decisions in a UNIX system that reflect long-lived design, “Everything is a file” is useful model (reading/writing in device files, accounts management, system configuration …) although it is a wrong model of reality, but it give us a useful abstraction to do the job well.
Regular expressions, file systems, and hardware improvements are making that model more useful.
