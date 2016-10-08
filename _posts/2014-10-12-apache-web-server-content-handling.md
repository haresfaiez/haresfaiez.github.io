---
layout: post
title:  "Apache web server: Content handling"
date:   2016-02-09 22:47:43 +0100
categories: Software
tags: featured
---
> As we said in the previous post, web servers have common phases that we called ‘the request processing axis’. Here in this post we will introduce how Apache web server handles its requests, and how it uses the content generator to maintain http requests through theses stages.

Apache web server is modular, it’s constructed from a core — the content generator — and some modules around it; the accepted request will be handled by a content generator and the modules contribute at well-specified steps.We can think of request processing as a combination of pipes, where modules are aware of attaching their handlers; so when the request process reach a step (named: hook) all module’s registered listeners (hook handlers) are going to be called in their order.

This is the main design of Apache, but in recent Apache versions 2.x, a new vertical axis appears : the data axis, called also the filter chain.

> The major innovation in Apache 2 that transforms it from a ‘mere’ web server (like Apache 1.3 and others) into a powerful applications platform is the filter chain. … The request data may be processed by input filters before reaching the content generator, and the response may be processed by output filters before being sent to the client. Filters enable a far cleaner and more efficient implementation of data processing than was possible in the past, as well as separating it from content generation. Examples of filters include Server side includes (SSI), XML and XSLT processing, gzip compression, and Encryption (SSL).

We have here two axis that intersect on the content generator.
While request processing axis phases are ordered, the data axis phase (input filters, content generator and output filters) aren’t.
So needed updates on the request must be done before passing any data down the chain (generator and output filters), or before returning data to the caller (input filters).

The content generator is unique for each request (we are not allowed to use two content handlers in a same request processing unless we modify the core source), it is responsible for invoking input filter chain at the moment of reading the request and the output filter chain when it sends the response back.

*Apache modules*

Modules are pluggables, the administrator can load/unload them via the httpd.conf file. Modules can be compiled as dynamic shared objects (DSO) that exist separately from the main httpd binary file, inside the lib directory— and this is required—, or compiled into the httpd binary when the server is built.
To be reconized by Apache they must be registered inside httpd.conf file, excet mod\_so modules, others can be either compiled when the server is built or added out of the httpd source tree as an extension thanks to the Apache extension tool. mod_so is the loader module.

From a technical point of view; while installing a http server into modern UNIX derivatives OS, 
make install procedure of the configurer’s script — a script that configures the source tree and the destination for Apache’s compilation and installation on a specific platform, it’s located within the root directory of the distribution : ./configure — installs Apache C header files, and puts platform-dependent compiler and linker flags for building dynamic shared objects, so other module’s sources will be compiled without Apache httpd source tree and without having to carry about the platform-dependent compiler and linker flags for DSO support.

At run-time, Apache modules can be loaded statically (when they are compiled with the core) or dynamically through a loader, so they can call module’sfunctions and module will become able to use Apache API and modify some records and data sets.

*Hooks*

Hooks are everywhere in Apache web server, they have the same mission as events in some programming languages (i.e JAVA); some handlers are attached to them and when they are trigged, handlers are called.
Apache core offers some predefined hooks.
Each Apache module can register his handlers to any offered hook and can create new hooks so that other modules can register their handlers.
Apache API offers the possibility to specify a position in the handlers chain for a module handler at registering time, and that’s so important for the chain organization.

There are two alternatives for calling hook handlers :

* RUN ALL / VOID : all handlers will be called consecutively in their order — whatever a handler complete or refuse to complete the task— unless the apparition of an execution error.
* RUN FIRST : all handlers will be called consecutively unless there is an execution error occurs or a handler completes the task.

*Apache Filters*

A filter is a set of data manipulations applied on an input (consecutively output) data while reading the request and before content handling (consecutively after content handling while sending response back to the client).

A chain is a set of filters; each filter has as an input the output of the previous one in the chain.
filters generally implement protocol’s behaviour, encrypt/decrypt data, establish and release a connection…, and they often communicate with the operating system;

While it is all about hooks, to support new protocols other than TCP/IP, or to insert new filters in the chain, just a module implementing the input or the output filter and a simple hook’s handler registration are required.
