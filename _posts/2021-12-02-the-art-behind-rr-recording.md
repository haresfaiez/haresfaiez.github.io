---
layout:   post
comments: true
title:    "The art behind RR recording"
date:     2021-12-02 12:00:00 +0100
tags:     featured
---

Record-and-replay debuggers are efficient utilities to communicate live examples of running programs.
Tools like [Replay.io](https://www.replay.io/) and [RR](https://github.com/rr-debugger/rr/)
are used by teams maintaining famous products.

The product of recording is a debuggable execution,
which offers a medium richer than videos and written steps to inspect intermittent bugs.
We can re-execute sophisticated scenarios accurately,
play a unique path through a given program over and over without incurring side-effects,
and step back through the code.

[RR](https://github.com/rr-debugger/rr/) is an open-source record-and-replay debugger
developed at Mozilla.
It uses [ptrace](https://linux.die.net/man/2/ptrace) to control a tracee program,
then [GDB](https://sourceware.org/gdb/) to replay the program within the recorded environment.


Globally,
 
> Most low-overhead record-and-replay systems depend
> on the observation that CPUs are mostly deterministic.
> We identify a boundary around state and computation,
> record all sources of nondeterminism within the bound-
> ary and all inputs crossing into the boundary, and reex-
> ecute the computation within the boundary by replaying
> the nondeterminism and inputs.
>
> [RR technical paper](link)


`ptarce` pauses the tracee when the latter receives a signal and before/after the
execution of a system call. It gives control to RR, which records the memory state,
the registers, and the instruction address inside a trace.

During replay, RR uses GDB to put breakpoints on the instruction address of each pause.
Then on pausing, it updates the memory and the registers to the values in the recorded trace.

For the replayed program, it appears as if it executed a system call and got the result.
But under the hood, RR pauses it just before the system call, sets up the memory and the registers
to appear as if the system call succeeded, then resumes the replay.

Each step (or event as called in the code)
has a type and a set of arguments that allow the replay command
to prepare or verify the context needed to execute the task.
Normal system calls record two events: `ENTERING_SYSCALL` and `EXITING_SYSCALL`.

If we add to a program a `printf` statement

```c
printf("Hello RR!");
```

The trace will have two new entries, one for entering the `write` system call and one for leaving it.

For the system call-entering event, RR records the event type and the called function.
For the leaving event, it records also the state of registers after the system call.
It overrides only the registers of the system call outcome.
The registers containing the arguments passed to the system call are
[set automatically by previous instructions](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html#calling).

During replay, it plays the program to just before executing the `call write` instruction,
updates the register to the ones saved in the second event, then resumes the execution.

The tracee might have multiple threads and processes.
For RR, the unit of execution is a `Task`. It can be a process or a thread.
The debugger does not make a difference because it controls all the processes' memories
and it can override the memory and the registers before each step.

The recording is managed by a `Scheduler`, which decides which task to run, and for how long.
Some steps in the trace end not because there is a signal or a system call, but because
the scheduler decides to interrupt a running thread and resume another one.

To replay multi-threaded programs, the scheduler interrupts all threads and allows only
one thread and one process to run at a time.
It produces one sequence of steps that can be replayed on one thread.

I am just beginning to explore RR. I will probably write other posts about the internals.
I would like to hear what you think about this tool and whether you used a similar tool.
I would like to hear also about other tools you used to effectively explore new codebases.
