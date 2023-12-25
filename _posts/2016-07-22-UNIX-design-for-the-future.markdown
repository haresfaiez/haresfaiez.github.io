---
layout: post
comments: true
title:  "UNIX, design for the future"
date:   2016-07-22 11:55:43 +0100
categories: Software, unix
tags: featured
---

> “Always design a thing by considering it in its next larger
> context — a chair in a room, a room in a house, a house in an
> environment, an environment in a city plan.”
> 
> — Eliel Saarinen

Choosing the right level of abstraction is task-specific, but each tool should be designed for reuse, it should offer a clear interface that communicates the provided functionalities.
We cannot imagine which purposes the users will use our software for; a well designed software always satisfies needs the designer have never predicted.

A good tool’s interface is easy to plug into multiple presentations, possibly simultaneously.

Make your software extensible and open to change so users can extend it and improve it easily.
Follow common practices from naming conventions to coding standards and documentation that help to understand the tool easily.
Avoid captive user interfaces (CUI), a captive user interface is an interface that prevents the user from using other global command for the duration of captures; CUI are hard to fit-in, complex to learn and to automate. The user is asked to learn new tools and a different syntax than those he is actually using . These kinds of software are also hard to build, to test and to maintain.

But, GUI are sometimes useful. Use them when they fit well.

Building for the future also means accepting that changes in software is inevitable, the software will not be the same the next year, nor even few months later; requirements change, technologies change and our perspective toward problems changes. The tool should adapt.

There are plenty of design decisions in a UNIX system that reflect long-lived design, “Everything is a file” is a useful model (reading/writing in device files, accounts management, system configuration …) although it's a wrong model of reality. It gives us useful abstractions to do the job well.
Regular expressions, file systems, and hardware improvements are making that model more and more useful.
