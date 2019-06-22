---
layout: post
comments: true
title:  "Improving the accessibilty of my website"
date:   2019-06-22 12:37:00 +0100
tags: featured
---

Murphy's law states that
> "things will go wrong in any given situation, if you give them a chance."

The number of components involved in displaying this page is huge.
Things may work well, now.
But, due to the flexibility and interdependence of these building blocks, devices fail to paint this page
in different settings.
Not everyone uses the same tool to navigate the web.
People face impediments with technologies you are familiar with.
They cannot read, distinguish colors, or access some resources,...
The context of navigation itself varies, even for the same person.
A web page, however, should strive to embrace the widest possible audience,
allowing every visitor to meet his needs.

Following this rule, I am improving the accessibility of my blog.
Better accessibility allows a wider audience to learn about my ideas.
I list here the first improvements.
I would like you to hear about your experience -how design decisions made, here or elsewhere,
impede your interaction with a page.

## Web fonts and CSS-generated content
Although the support of web fonts is improving, a page needs to work well without them.
Web fonts interpretation and application introduce points of failures.
The browser might fail to fetch a font, the font might be overridden by a user plugin,
or the content might contain a character the font does not support well.

I use four font families; a serif font for the post body, a sans-serif font
for titles and short notices, a font for code examples, and [Font Awesome](https://fontawesome.com)
for icons. I have fallback alternatives for the serif and the sans-serif fonts.
Icons, though, fail to show up when Font Awesome is not loaded.

CSS allows for the selection of fallback fonts to handle font loading failures.
Browsers, too, use a fallback font in such situations.
But, neither of these is of much help in my situation.

I use CSS generated content for icons. Without CSS, all icons are invisible.
For
[decorative icons](https://fontawesome.com/how-to-use/on-the-web/other-topics/accessibility),
that does not matter. The text already communicates the intent.
But, semantic icons are essential. I use them for social media references. They help people get in touch with me.
Even if CSS works well and the icons are all visible, the meaning behind some of them might not be clear.

I will add the description next to each icon.
That communicates the meaning of the link destination to the visitors,
even when they are not familiar with the icon.
The header will take more space, which I find less beautiful.
Adding a new reference, later, will require a change to the design of the home page.
But, as I prioritize accessibility, such change is crucial.

## Localizability
It is a common practice to put the name of the website in the top left corner.
I am not following that. I keep a home icon instead.
The small home icon appears on every page. It was pink and noticeable. It attracts the eye, in the same way that
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
