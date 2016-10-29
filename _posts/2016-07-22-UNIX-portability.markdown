---
layout: post
title:  "UNIX portability"
date:   2016-07-22 11:50:43 +0100
categories: Software, unix
tags: featured
---

We are lazy. 
If some tasks can be automated, we will be doing that, immediately.
But, sometimes, we will be doing that all the time.
Each platform will have its specific variant of the task.
And it will be upgraded with each platform update, may be just to adhere to the new interface or the new infrastructure.

Then that will be complicated, and we will need a specialist developer or a team to maintain each one.
Keeping them synchronized may have a significant cost.
So we may not offer the same features on different environments at the same time.
The user may not have the same experience across different contexts.
And he will not be satisfied.

Duplication is evil.

Our solutions should be easy to maintain.
Repeating the same solution over and over is error-prone, and boring.

The solution, then, is to work on abstractions.
UNIX offers that.

UNIX gives us the abstraction we need through clean and easy to use text-based interfaces.

So that we benefit from our solution in more than the current distribution. And we can plug in more and more solutions without an effort.
What about performance?

It is not unusual to spend many hours optimizing the software; making some shortcuts here and putting some hack there, or having a week of bench-marking before opting for a sort algorithm.

Often, we spend a lot of our time thinking about performances.
Without doing that, we may not feel clever enough.

But, often the end user won’t notice those milliseconds wasted during application startup. That will not be seen as a huge performance issue.

Nine times out of ten, the amount of performance improvement won’t matter.
So don’t consider performance upstream.
When it does matter, it is easier to just optimize the modules that need to be enhanced. We have then some vision about how much to improve, when to do that and where.
Some times it is a matter of some architecture-specific flags that need to be enabled at startup.

When you design your software to operate on several environments. It is going to be easier to optimize. You need only to enhance it at one place.

Software interoperability

Software interoperability is the ability of a component to be used by other pieces of software easily.
That enables other tools to benefit from the component’s improvements, which enables us to write more focused software.
Software interoperability manifests itself all around us, HTML, TCP/IP, CORBA, …

There should be an interface to be implemented, a protocol or an adapter to use to exposes the available functionality.
UNIX offers through the pipe-and-filter style a great context to grow our tools with such a principle.

An interoperable software component can be plugged in with other components without a ceremony.

Suppose we have to send emails to our team.
All what we need is to combine three tasks: grab the list from a file, then, for each line, extract the user email address and send him the message.
Using a shell script, that fits on a single line.

Pretty easy! Isn’t it?

Doing such actions in a graphic-based environment is harder. We need to find the folder where our team data are stored, open the file, copy the addresses (filter the lines manually), and open the e-mail client and paste them with the message, then send it. That will take a reasonable amount of time and mental energy.
Imagine doing that everyday.

The latter tools were not built with the interoperability in mind. They may be small, simple and focused. But they don’t work well together. And that makes our mission harder. And makes combining more and more tools in a same process non pleasurable.
That kind of software ends up trying to predict all users’ actions and integrating them in a single tool. What makes it complex, huge and some times insufficient; it cannot predict all what users wants.
