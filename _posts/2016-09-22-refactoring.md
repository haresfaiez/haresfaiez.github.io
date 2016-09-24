-
-
layout: post
title:  "Refactoring"
date:   2016-09-22 22:47:43 +0100
categories: Software, Refactoring
tags: featured
---

- 0 -
Score value;
Roll  last;

public Yatzy() {
    this.value = new Score(50);
}
    public void roll(Roll aRoll) {
        if (last != null && last.side != aRoll.side)
            value = new Score(0);

        last = aRoll;
    }

- 1 -

public Yatzy() {
    this.value = new Score(50);
}
public void roll(Roll aRoll) {
        if (last != null && last.side != aRoll.side)
            value = new Score(0);

        if (!(last != null && last.side != aRoll.side))
            value = new Score(50);

        last = aRoll;
    }

-2-
public Yatzy() {
    this.value = new Score(50);
}
public void roll(Roll aRoll) {
        if (last != null && last.side != aRoll.side)
            value = new Score(0);

        if (!(last != null) || !(last.side != aRoll.side))
            value = new Score(50);

        last = aRoll;
    }

    -3-
public Yatzy() {
    this.value = new Score(50);
}
    public void roll(Roll aRoll) {
        if (last != null && last.side != aRoll.side)
            value = new Score(0);

        if (last == null || last.side == aRoll.side)
            value = new Score(50);

        last = aRoll;
    }

    -4-


    public Yatzy() {
        roll(null);
    }

    @Override
    public void roll(Roll aRoll) {
        if (last != null && last.side != aRoll.side)
            value = new Score(0);

        if (last == null || last.side == aRoll.side)
            value = new Score(50);

        last = aRoll;
    }

    -5-
