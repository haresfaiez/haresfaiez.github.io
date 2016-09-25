---
layout: post
title:  "web servers: overview"
date:   2014-09-27 22:47:43 +0100
categories: web
tags: featured
---
> The term web server, also written as Web server, can refer to either the hardware
> (the computer) or the software (the computer application) that helps to deliver 
> web content that can be accessed through the Internet.
	
Web server so is a simple software,
that can accept http requests on a predefined port and handles them.
In this collection, we are going to sail into web servers internal design and implementation,
we are going to visit so many islands in our trip too;
we will discover web application servers internals for node js,
java ee, and many other web-related technologies and tricks.

## Http request overview
The main mission of a web server is to listen to incoming requests instead to handle them. For each request; the client’s web browser translates the requested domain address into the IP address of his server — directly or through a DNS—, opens a TCP connection to that IP and sends it the request as a well-structured http request.

The web server receives the request through a predefined network port (generally 80 or 8080) and processes it instead to return a response to the client.

## The request processing axis
Received by the web server, the request will be splatted into several phases in order to manipulate headers and to devide the necessary work into several phases.
Each web server implements its own strategy to process incoming http log over requests, but a families of operations known as ‘the request processing axis’ are common for all web servers. The request processing contains three units:
* Themeta-data phase:
where the web server examines, manipulates the request’s headers and determines what to do with the request (e.g : access and authentication to check if the client is authorized to access to the requested point of the file system). It selects then the mapping target : a CGI script, a static file, the file system or whatever…

* Thecontent generator phase:
the response (html, picture, …) is produced and sent back to the client’s browser dynamically basing on the gutted request. The web server has a full control on all operations happened in the middle.

* The logger phase:
it comes after sending reply back, it helps administrators to have a feedback about the activities and the performance of the server as well as any problems that may be occurring.
