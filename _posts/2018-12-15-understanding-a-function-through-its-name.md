---
layout: post
comments: true
title:  "Understanding a function through its name"
date:   2018-12-15 16:31:00 +0100
tags: featured
---
> There are only two hard things in Computer Science: cache invalidation and naming things.
>
> -- Phil Karlton

Naming things is intricate.
As I write a new function, I know exactly how and where to use it.
Its name, at that time, does not convey a significant meaning.
I can call it `x` or `f` and still be able understand it and use it well.

I spend time choosing a good name for a function to prevent future miscomprehensions.
I may rename a couple of adjacent functions as a side-effect
of thinking about the name of my new function. Or I may give it the name of an old function
and rename the old one.
Here, I am optimizing my future programming time, eliminating the burden of
reading the function body and figuring out how to call it when I decide to use it again.

## A good function name
Spending effort choosing the name of a function has a significant payoff which increases
as the function is used more and more.

A good name prevents duplicating the logic by a future programmer, as an obscure name
makes him blind to the existence of the function.

A good name helps me understand the code using the function, especially when it is used more than once.
The cost of keeping an obscure name for such function increases
exponentially with each use, because the function using it is used by other functions as well.

I find it fine to call a function `execute` when it is used once locally
in some recursive functions, but not in a publicly exposed API (unless it is the only
exposed function).

```javascript
function bounds(numbers) {
  function execute(subject, max, min)  {
    if (!subject.length) return { min, max };

    const head = subject[0];
    return execute(subject.slice(1)
                 , head > max ? head : max
                 , head < min ? head : min);
  }

  return execute(numbers.slice(1), numbers[0], numbers[0]);
}
```

A function name should not have a unique universal meaning, unless it has such a unique
meaning in the real world.
More often than not, a function is used by clients that share a need, the need which
the function fulfills.
I try to focus on these clients when naming a function.
I can rename it later if more clients with different needs emerge.

Suppose I have three functions `A`, `B`, and `C`, where `A --calls-> B --calls-> C`
I cannot understand how `B` works without understanding `C` to some degree.
Finding a good name for `C` will be a good investment when `B` is revisited frequently.
But, the name of `C` does not directly affect my understanding of `A`
if I understand `B` well (or if I know how to use it for the specific needs of `A`).

## Context matters more than the name
The location of a function (To what module it belongs? Who are its neighbors?)
helps me understand why the function exists, how to use it, and more importantly,
how to find it in the code.

Let's see. There is a red button on the home screen. I want it green.
I start looking for what to modify in the code. Or precisely, where.
If I have an AI programming assistant, it will rename the function to be modified to `changeThis`.
Such a name costs me the least amount effort, and gives me the highest level of confidence.
Anything different than that means that I need to spend some time looking for the function.
As in the real world, the function will be buried somewhere within million-line codebase,
and the formula for generating the color itself will be computed using a couple of other functions.
It is challenging to choose a unique name for each function and understand them all in such codebase.

> Although software has no mass, it does have weight, weight that can ossify any 
> system by creating inertia to change and introducing crushing complexity.
>
> -- Grady Booch

I change the color of a button inside the browser with a couple of seconds;
I inspect the element, and add a `style="color: green;"`.
But when the a button needs hundreds of decisions made about its existence,
and another hundred about its style. Finding what to change is complicated.

I need to rely on the names of modules and submodules to locate the function.
Then, the name kicks in as a reminder if I am familiar with code.
If this is the first time with me on the code, I need some time to assure myself that
the decision to be modified lies within this function, some time to
understand how the function works and some time to understand how it is used.

There are a couple of activities I use to reason about a function and understand its contribution:
  * I look at the body of the function. I find out where and how it is used and see how other functions
  in its module are used. Then, I repeat the same activities for its dependencies,
  down to a level I grasp or I can reason about. (I call this understanding the
  static context of a function.)

  * I execute it, or one of the functions using it, with different arguments and see what happens
  (I call this understanding the runtime/dynamic context of a function.)

  * I ask about how the function came out to be here and what are the constraints
  that made it look like it is now. (This is often conveyed through various forms of documentation,
  or through the source code management tools, but not always.
  A teammate with some time on the code can tell you that.)

If I find it challenging to name a function, I change the name of the container,
I split the container into two other containers where the name of the function
can be a sligh variation from the name of one of them. Or I move the function to another container.
I do not put that much effort into naming a function compared to finding
where to put it.
If I know where to put a function, its name does not matter that much.

A container, itself, is defined by its name and the names of its children.
This is why software development is an iterative endeavour,
I change the names of functions, their containers, and the name of the containers
all the time. Each feature will bring its own knowledge that should be reflected
in the code.

Sometimes, a function gets bigger and there is an urge to split it into other
functions. This can be a reason for bad function names as the decomposition
might be premature, which means more bad names for the extracted functions
and more bad names when these functions change.
I am all for simplifying each function, and for composing programs from small functions.
But, I believe also that living with big functions is not such a bad idea.
Short functions do not necessarily make grasping code easier.
It is about the mental load, wich comes primarily from the context of a function, not size.
