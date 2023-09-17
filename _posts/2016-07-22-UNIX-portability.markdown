---
layout: post
comments: true
title:  "UNIX portability"
date:   2016-07-22 11:50:43 +0100
categories: Software, unix
tags: featured
---

We are lazy.
If some tasks can be automated, we'll do that immediately.
But, sometimes, we will be doing that all the time.
Each platform gets its specific variant of the task,
which will be upgraded with each platform update, maybe just to adhere
to the new interface or the new infrastructure.

Keeping them synchronized may have a significant cost.
We may not offer the same features in different environments at the same time.
The user may not have the same experience across different contexts.
And he will not be satisfied.

Duplication is evil.

Our solutions should be easy to maintain.
Repeating the same solution over and over is error-prone and boring.

The solution, then, is to work on abstractions.
UNIX offers that.

UNIX gives us the abstraction we need through clean and easy-to-use text-based interfaces.

We benefit from our solution in more than the current distribution.
And, we can plug in more and more solutions without effort.

Software interoperability is the ability of a component to be used by other pieces of software easily.
That enables other tools to benefit from the component’s improvements, which enables us to write more focused software.
Software interoperability manifests itself all around us, HTML, TCP/IP, CORBA, …

There should be an interface to be implemented, a protocol, or an adapter to use to expose the available functionality.
UNIX offers through the pipe-and-filter style a great context to grow our tools with such a principle.

An interoperable software component can be plugged in with other components without a ceremony.

Suppose we have to send emails to our team.
All we need is to combine three tasks: grab the list from a file, then, for each line, extract the user's email address and send him the message.
Using a shell script, that fits on a single line.

Pretty easy! Isn’t it?

Doing such actions in a graphic-based environment is harder. We need to find the folder where our team data are stored, open the file, copy the addresses (filter the lines manually), and open the e-mail client and paste them with the message, then send it. That will take a reasonable amount of time and mental energy.
Imagine doing that every day.

The latter tools were not built with interoperability in mind. They may be small, simple, and focused. But they don’t work well together. That makes our mission harder. It makes combining more and more tools in the same process nonpleasurable.
That kind of software ends up trying to predict all users’ actions and integrating them into a single tool. What makes it complex, huge, and sometimes insufficient; it cannot predict all that users want.

What about performance?

It's not unusual to spend many hours optimizing the software;
making some shortcuts here and putting some hacks there,
or having a week of bench-marking before opting for a sort algorithm.

Often, we spend a lot of our time thinking about performance.
Without doing that, we may not feel clever enough.

But, often the end user won’t notice those milliseconds wasted during application startup.

Nine times out of ten, the amount of performance improvement won’t matter.
So don’t consider performance upstream.
When it does matter, it is easier to just optimize the modules that need to be enhanced. We have then some vision about how much to improve when to do that, and where.
Sometimes it's just a matter of some flags that need to be enabled at startup.

When you design your software to operate in several environments. It is going to be easier to optimize. You need only to enhance it at one place.
