---
layout: post
comments: true
title:  "How to grow an octopus: how Vite source code grows"
date:   2024-08-25 10:00:00 +0100
tags: featured
---

> "The purpose of computing is insight, not numbers."
> -- Richard Hamming

** talk about this a bit
** Software as simulation

Source code: https://github.com/vitejs/vite

Questions to answer:
  - boundaries:
    - when a new boundary is created (and where), how often
    - ... a boundary is removed (and where), how often
    - when a boundary changes, what functions/modules change (and where)
  - conditionsals:
    - where, how often
    - how often an if is nested vs. many ifs added
  - entropies:
    - for boundaries
  - authors:
    - how often different authors change the same boundary

Focus:
  ---> how edge cases are handled
  - edge cases vs. more functionality
  - how edge cases are handled
  - frequence of renaming/move-fn-class-... = f(people)
  - similarity between how same person/many changes vs. many persons one/many changes

## the cathedral and the bazaar

## Why / Emacs and recursivity