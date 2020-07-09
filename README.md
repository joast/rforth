russ forth
==========

A simple Forth interpreter in Ruby. Originally written for ruby 1.9. This
verison is being developed with ruby 2.7.1. A few older versions of ruby will
be tried as time permits.

This is still a toy (i.e. not anywhere near being a "complete" implementation
of forth).

A few minor examples:

    1 2 dup + +
    .
    5

    3 2 1 + *
    .
    9

    : sq dup * ;

    2 sq
    .
    4

This version is a fork of russ forth by [ananthrk](https://github.com/ananthrk)/[fogus](http://fogus.me/) which was based on a sweet hack by [Russ Olsen](http://russolsen.com/) presented to fogus in a [GoodReads comment](http://www.goodreads.com/review/show/120660311).
