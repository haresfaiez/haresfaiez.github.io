---
layout: post
title:  "UNIX, Small is beautiful"
date:   2016-07-22 11:55:43 +0100
categories: Software
tags: featured
---

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
