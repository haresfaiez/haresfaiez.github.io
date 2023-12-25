---
layout: post
comments: true
title:  "UNIX, Small is beautiful"
date:   2016-07-22 11:55:43 +0100
categories: Software
tags: featured
---

>“Composing programs from smaller programs to accomplish a desired task”.

That is the heart of the UNIX philosophy.

In a UNIX system; commands are simple, small, and easy to remember, so always tend to make your tool simple, small and easy to understand and to remember.

How much small a tool have to be is complex to define. It is relative to the domain and the problem the tool deals with.
Start with just one tool that solves the problem and leverage available tools, the tool should be good-enough to do the job you need — don’t focus neither on perfection nor on optimization (may be five-lines shell script is enough, do it the right way, clean, documented, easy to understand…, don’t let it be more than what you need at that moment).

Then improve it as you use it from day to day.
The time you find some difficulties or you take more than a reasonable time to change the software, split it into two or three tools that are easy to deal with.
Try to not split it into more, and be careful to not re-engineer what the system and other tools offer.

The moral is to not over engineer, work iteratively and with small changes and to keep your software maintainable.
Keep in mind that there are plenty of tools that help; to format input, to configure hardware and to do some plumbing work at lower levels of abstraction.
So, focus on the purpose; it is up to the user to use it correctly.

UNIX adopt this principle through the pipes-and-filter architectural style.
The idea of pipes was inspired from Douglas McIlroy, who wrote a memo in 1964 suggesting the metaphor of data passing through a segmented garden hose.

This style is well known in the software community and it is as well adopted by many software architectures.
The idea, in a nutshell, is to pass the input to a cluster of small tools.
Each one manipulates the data in its way (or filters it), and passes it next.
