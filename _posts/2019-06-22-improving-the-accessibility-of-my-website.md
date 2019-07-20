---
layout: post
comments: true
title:  "Improving the accessibilty of my website"
date:   2019-06-22 12:37:00 +0100
tags: featured
---

People use customized tools and unfamiliar applications to navigate the web.
They have no use for a screen, a keyboard, or a regular browser.
They need assistance (we all do).
When they can't read, they use screen readers.
When they fail to distinguish colors, they spend their time guessing, then they misinterpret the content.
Some fail to keep up with videos, to see small text, to drag-and-drop small objects,...

Not all disabilities are permanent. One falls-ill, breaks a hand, and becomes short-sighted.
For such person, a page optimized for a relaxed, middle-aged, eager-for-delight,
"regular" man will be hard to get along with.
There is a lot we can do as programmers to make our work accessible to a wider audience.
I am learning about the subject.
I document in this post the improvements I am making to my blog and the reason behind each.
I edit it with each improvement, then I will publish what I do in the newsletter.

## Web fonts and CSS-generated content

Web fonts interpretation and application introduce points of failures.
The browser could fail to fetch a font. A user plugin could override the font.
The text itself could include a character that is missing from the font file...

After all, there is Murphy's law:
> "things will go wrong in any given situation, if you give them a chance."

I use four fonts; a serif font for the post body, a sans-serif font
for titles and short notices, **Fira code** for source code, and [Font Awesome](https://fontawesome.com)
for icons.

To handle failures, I use fallbacks for each of the three first fonts.
When loading a font fails, the content will stay visible and will stay accessible to screen readers.

But, the display of the icons could fail.
They are invisible when either the CSS file or the font file is missing.
I use CSS-generated content for icons. Font Awesome maps each glyph to a character non-writable
by a regular font and non-readable by a screen reader.

Even when an icon shows up, the intent behind it could be unclear.

I added a description to each icon to communicate the intent or the destination -for clickable icons.
The intent is there, even without styles.
And even when not familiar with the icon, visitors have more information.
The header containing my social media references takes more space now. I find it less beautiful
-adding another reference later will require a modification to the whole page design.
But, accessibility is more important.

## Localizability
It is a common practice to put the name of a website in its top-left corner.
I don't follow this. I put a home icon instead.
The small home icon appears on every page. It is pink and noticeable.
It attracts the eye, in the way that a name would.

But, with a home icon always in the top left corner,
a visitor might not tell whether he is in the home page or not.
Someone visiting a post might notice that the page he is visiting is a post in a blog.
But, he may find it hard to tell whose blog is this, who wrote the post,
and how does the page he is visiting relates to the website he is in.

My website has a map. It has two pages; a home page and a post page.
But, that map is not explicit in the views.

The home page is good. It includes a greeting message.
The post page, though, needs to tell more about itself -mainly about the context.
A reader needs to answer questions like "Who wrote this?", "Is this a personal blog or a company blog?",
"When was it written?", "Was it modified since the last time?", "How can I give feedback?", ...

I put my name in the top left corner. Most personal blogs are named after the author.
This removes ambiguities and communicates the context better.
Also, I added the label "Published on" to describe the date of a post, and to highlight the fact that a blog post
is written and published by me.
Finally, I will move the date closer to the title so that meta-informations stay close together
and distinct from the body.

## Headings
I break down posts into parts. I put a heading to each part to simplify skimming and memorization.
I like to use one heading level, and I use two at most.

All headings in my posts are in the same size.
I use colors and margins to highlight the difference in levels.
The main heading is pink and has a one-line vertical margin.
The subheading is blue and has half the margin.

But, people with color blindness cannot distinguish the colors of the subheading and the post.
And under many kinds of color blindness, all headings look the same; dark on white.

A heuristic says that a grayscale view of the page provides similar clues and affordance as a normal view.
In my situation heading levels look similar in the grayscale view. Even the margin is hardly noticeable.

I removed the variation in the margin between headings
and used a thick font face for the main headings and a light one for subheadings.
Subheadings and a paragraph have different fonts and sizes. So, they are distinguishable.
I kept the color variation as it helps with the skimming.

## Validation
[WAVE](https://wave.webaim.org/) is a web accessibility validation tool.
I use it to validate my website.
WAVE identifies accessibility issues in the view and the structure of a page.
In my case, it highlights the icons problem and other structural problems.
But, it didn't mention headings and localizability.
You can learn more about web accessibility on
[WAI - W3C Accessibility Initiative](https://www.w3.org/WAI/fundamentals/accessibility-intro/).
