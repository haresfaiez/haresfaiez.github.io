---
layout: post
comments: true
title:  "Refactoring the small blocks early"
date:   2016-09-29 22:47:43 +0100
categories: Software, Refactoring
tags: featured
---

This week, I am working on 'The Gilded Rose' refactoring Kata proposed by Industrial Logic.
The goal of the Kata is to make a complex piece of code clear and easier to extend.

My first strategies toward this task were holistic.
I started with something like
'Remove all nested conditionals', 'Move accesses to that field to that class'.

I was focusing on code smells instead of the knowledge expressed through the code.
I was trying to take away one code smell at a time.
The trouble was that as soon a smell disappeared, it came back, usually under a new form.
Moreover, the code seemed more and more obscure.

So, four or five successive red bars, and I restarted the kata.

I started the second time with a different strategy:
'Take one block, ignore the holistic view,
refactor that block mercilessly,
then go back and do the same for the next block'.

I did well.
I learned a lot about the solution as I was able to hold less context in my head.
And, yes, I got it, without that red bar.

This experience recalls some of my first steps with TDD.
There was a voice in my mind yelling at me after making a test pass
'Go ahead, write one more test, interesting patterns will appear,
and then, you'll refactor all the mess easily'.

It turns out, the "perfect" moment is an evil job, an illusion.

It'is rare to find good insights that help make the code tidy.
Nevertheless, tidy code leads continuously to good insights.
