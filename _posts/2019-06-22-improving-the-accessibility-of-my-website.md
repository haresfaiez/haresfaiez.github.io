---
layout: post
comments: true
title:  "Improving the accessibilty of my website"
date:   2019-06-22 12:37:00 +0100
tags: featured
---

People use different technologies than what most of us are familiar with.
They are used to navigate the web in customized settings.
When they cannot read fluently, they use screen readers or they save the page for a next break.
And if they fail to digest the content then, either they ignore it or they ask for help -which is
not easy.
They might not distinguish colors, fail to keep up with videos, you name it.

Not all disabilities are permanent. One might fall-ill, might break a hand,
or might become short-sighted.
These are situations where a web page optimized for a relaxed, middle-aged, eager-for-delight,
"regular" man fails to reach its visitor.

There is a lot we can do as programmers to make our work accessible to the wider audience.
I document the improvements I am making to my blog and the reasons behind each decision here.
I will keep editing this post as I make accessibility improvements and I publish what I do in the newsletter.

## Web fonts and CSS-generated content

Web fonts interpretation and application introduce points of failures.
The browser could fail to fetch a font. A user plugin could override the font.
The text itself could include a character missing from the font file...
And after all, there is Murphy's law:
> "things will go wrong in any given situation, if you give them a chance."

I use four fonts; a serif font for the post body, a sans-serif font
for titles and short notices, **Fira code** for code examples, and [Font Awesome](https://fontawesome.com)
for icons.

To handle failures, I use fallbacks for each of the first three fonts.
When a problem happens to a load of a font, the content will be there and will be accessible to screen readers.

But, icons display fails in many ways.
First, they are invisible when either of the CSS file or the font file is missing.
I use CSS generated content for icons. Font Awesome maps each glyph to a character non-writable
by a regular font and non-readable by a screen reader.
Then, even if the icons show up, the intent behind each could be unclear.

I added a description to each icon to communicate the intent or the destination -for clickable icons.
Even when not familiar with the icon, visitors have more information.
The header containing my social media references takes more space now. I find it less beautiful
-and adding another reference later will require a modification to the whole page design.
But, accessibility is more important in this situation.

## Localizability
It is a common practice to put the name of the website in the top left corner.
I don't follow this. I keep a home icon instead.
The small home icon appears on every page. It is pink and noticeable. It attracts the eye, in the same way that
a name for the site would.

But, with a home icon always in the top left corner,
a visitor might not tell whether he is in the home page or not.
Someone visiting a post might notice that the page he is visiting is a post in a blog.
But, he may find it hard to tell what blog is this, who wrote it,
and how does the page he is visiting relates to the website he is in.

My website has a map. It contains two pages; a home page and a post page.
But, that map is not explicit in the views.

The home page is good. It contains a greeting message.
The post page, though, needs to communicate more, mainly about the context.
A reader needs to have answers to questions like "Who wrote this?", "Is this a personal blog or a company blog?",
"When was it written?", "Was it modified since the last time?", "How can I give feedback?", ...

I will put my name in the top left corner now. Most personal blogs are named after the author.
This removes some ambiguities and communicates the context of a page better.
Also, I will add the label "Published on" to describe the date and to highlight the fact that a blog post
is written and published by me.
Finally, I will move the date closer to the title.
They will appear as a single component; a component describing the page.

## Headings
To simplify the skimming,  memorization, and readability of posts.
I break down each post into many parts, each with a different heading.
I prefer to keep one heading level for a post. But, I use two in extreme situations.

All headings in my posts are in the same size.
I use different colors and margins to distinguish different levels.
The main heading is pink and has a one-line vertical margin. The subheading is blue and has half the margin.

Color blindness turns out to be more common and impeding that I thought.
People with such impairment cannot distinguish colors as I do.
Under many kinds of color blindness, all headings look the same, dark color on white.

A heuristic says that the grayscale view of the page provides similar clues and affordance as the normal view.
In my case, in the two views, heading levels look similar. Even the margin is hardly noticeable.

I will remove the margin variation from headings.
Then, I will use a thick font face for the main headings and a light one for subheadings.
Note that subheadings and a paragraph will have different fonts and sizes.
That will make them distinguishable.
I will keep the color variation. It helps with skimming.

## Validation
[WAVE](wave.webaim.or) is a web accessibility validation tool.
I use it to validate my website.
WAVE identifies accessibility issues in the view and structure of a web page.
In my case, it highlights the icons problem and other structural problems.
But, it didn't mention headings and localizability.
You can learn more about web accessibility on
[WAI - W3C Accessibility Initiative](https://www.w3.org/WAI/fundamentals/accessibility-intro/).
