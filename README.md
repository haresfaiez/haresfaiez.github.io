# Jekyll personal web site

## Starting the application
```
jekyll serve
```

## Roadmap
  * Mark a section from a blog post as "Under construction" when not finished
  but the remaining is ready.
  * Use a better theme for the source code.

## Build procss

The source is compiled to a static website.
Meanwhile, we use a pre-build script to polish the content before building it using jekyll.
The process contains the following steps:
  * Join Scss sources into a single file (The file is then compiled to CSS by jekyll)
