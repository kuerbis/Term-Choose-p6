NAME
====

Term::Choose - Choose items from a list interactively.

SYNOPSIS
========

    use Term::Choose :choose;

    my @list = <one two three four five>;


    # Functional interface:
     
    my $chosen = choose( @list, :2layout );


    # OO interface:
     
    my $tc = Term::Choose.new( :1mouse, :0order );

    $chosen = $tc.choose( @list, :1layout, :2default );

DESCRIPTION
===========

Choose interactively from a list of items.

For `choose`, `choose-multi` and `pause` the first argument holds the list of the available choices.

The different options can be passed as key-values pairs. See [OPTIONS](#OPTIONS) to find the available options.

The return values are described in [Routines](#Routines)

USAGE
=====

To browse through the available list-elements use the keys described below.

If the items of the list don't fit on the screen, the user can scroll to the next (previous) page(s).

If the window size is changed, the screen is rewritten as soon as a key is pressed.

How to choose the items is described in [ROUTINES](#ROUTINES).

Keys
----

  * the Arrow keys (or h,j,k,l) to move up and down or to move to the right and to the left,

  * the Tab key (or Ctrl-I) to move forward, the BackSpace key (or Ctrl-H) to move backward,

  * the PageUp key (or Ctrl-P) to go to the previous page, the PageDown key (or Ctrl-N) to go to the next page,

  * the Insert key to go back 10 pages, the Delete key to go forward 10 pages,

  * the Home key (or Ctrl-A) to jump to the beginning of the list, the End key (or Ctrl-E) to jump to the end of the list.

For the usage of SpaceBar, Ctrl-SpaceBar, Return and the q-key see [choose](#choose), [choose-multi](#choose-multi) and [pause](#pause).

With *mouse* enabled use the the left mouse key instead the Return key and the right mouse key instead of the SpaceBar key. Instead of PageUp and PageDown it can be used the mouse wheel. See [mouse](#mouse)

Pressing the Ctrl-F allows one to enter a regular expression so that only the items that match the regular expression are displayed. When going back to the unfiltered menu (Return) the item highlighted in the filtered menu keeps the highlighting. Also (in *list context*) marked items retain there markings. The Raku function `prompt` is used to read the regular expression if [Readline](Readline) is not available. See option [search](#search).

CONSTRUCTOR
===========

The constructor method `new` can be called with named arguments. For the valid options see [OPTIONS](#OPTIONS). Setting the options in `new` overwrites the default values for the instance.

ROUTINES
========

choose
------

`choose` allows the user to choose one item from a list: the highlighted item is returned when Return is pressed.

`choose` returns nothing if the q or Ctrl-Q is pressed.

choose-multi
------------

The user can choose many items.

To choose an item mark the item with the SpaceBar. When Return is pressed `choose-multi` then returns the marked items as an Array. If the option *include-highlighted* is set to `1`, the highlighted item is also returned.

If Return is pressed with no marked items and [include-highlighted](#include-highlighted) is set to `2`, the highlighted item is returned.

Ctrl-SpaceBar (or Ctrl-@) inverts the choices: marked items are unmarked and unmarked items are marked.

`choose-multi` returns nothing if the q or Ctrl-Q is pressed.

pause
-----

Nothing can be chosen, nothing is returned but the user can move around and read the output until closed with Return, q or Ctrl-Q.

OUTPUT
======

For the output on the screen the elements of the list are copied and then modified. Chosen elements are returned as they were passed without modifications.

Modifications:

  * If an element is not defined the value from the option *undef* is assigned to the element.

  * If an element holds an empty string the value from the option *empty* is assigned to the element.

  * Tab characters in elements are replaces with a space.

    $element =~ s/\t/ /g;

  * Vertical spaces in elements are squashed to two spaces.

    $element =~ s/\v+/\ \ /g;

  * Code points from the ranges of control, surrogate and noncharacter are removed.

    $element =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;

  * If the length (print columns) of an element is greater than the width of the screen the element is cut and three dots are attached.

OPTIONS
=======

Options which expect a number as their value expect integers.

### alignment

0 - elements ordered in columns are aligned to the left (default)

1 - elements ordered in columns are aligned to the right

2 - elements ordered in columns are centered

### beep

0 - off (default)

1 - on

### bottom-text

Expects as its value a string. If set, the text is printed below the menu.

### clear-screen

0 - off

1 - clears the screen before printing the choices (default)

### color

If enabled, SRG ANSI escape sequences can be used to color the screen output.

0 - off (default)

1 - on (current selected element not colored)

2 - on (current selected element colored)

### default

With the option *default* it can be selected an element, which will be highlighted as the default instead of the first element.

*default* expects a zero indexed value, so e.g. to highlight the third element the value would be *2*.

If the passed value is greater than the index of the last array element, the first element is highlighted.

Allowed values: 0 or greater

(default: 0)

### empty

Sets the string displayed on the screen instead of an empty string.

(default: "<empty>")

### footer

Add a string in the bottom line.

If a footer string is passed with this option, the option page is automatically set to `2`.

(default: undefined)

### hide-cursor

0 - keep the terminals highlighting of the cursor position

1 - hide the terminals highlighting of the cursor position (default)

### index

0 - off (default)

1 - return the indices of the chosen elements instead of the chosen elements.

This option has no meaning for `pause`.

### info

Expects as its value a string. The string is printed above the prompt string.

### keep

*keep* prevents that all the terminal rows are used by the prompt lines.

Setting *keep* ensures that at least *keep* terminal rows are available for printing "list"-rows.

If the terminal height is less than *keep*, *keep* is set to the terminal height.

Allowed values: 1 or greater

(default: 5)

### layout

From broad to narrow: 0 > 1 > 2

  * 0 - layout off

        .-------------------.   .-------------------.   .-------------------.   .-------------------.
        | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |
        |                   |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |
        |                   |   |                   |   | .. .. .. ..       |   | .. .. .. .. .. .. |
        |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
        |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
        |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
        '-------------------'   '--- ---------------'   '-------------------'   '-------------------'

  * 1 - (default)

        .-------------------.   .-------------------.   .-------------------.   .-------------------.
        | .. .. .. .. .. .. |   | .. .. .. ..       |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
        |                   |   | .. .. .. ..       |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
        |                   |   | .. ..             |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
        |                   |   |                   |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
        |                   |   |                   |   | .. .. ..          |   | .. .. .. .. .. .. |
        |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
        '-------------------'   '-------------------'   '-------------------'   '-------------------'

  * 2 - all in a single column

        .-------------------.   .-------------------.   .-------------------.   .-------------------.
        | ..                |   | ..                |   | ..                |   | ..                |
        | ..                |   | ..                |   | ..                |   | ..                |
        | ..                |   | ..                |   | ..                |   | ..                |
        |                   |   | ..                |   | ..                |   | ..                |
        |                   |   |                   |   | ..                |   | ..                |
        |                   |   |                   |   |                   |   | ..                |
        '-------------------'   '-------------------'   '-------------------'   '-------------------'

### margin

The option *margin* allows one to set a margin on all four sides.

*margin* expects a list of four elements in the following order:

- top margin (number of terminal lines)

- right margin (number of terminal columns)

- botton margin (number of terminal lines)

- left margin (number of terminal columns)

See also [tabs-info](#tabs-info) and [tabs-prompt](#tabs-prompt).

Allowed values: 0 or greater. Elements beyond the fourth are ignored.

(default: undefined)

### max-cols

Limit the number of item columns to *max-cols*.

Allowed values: 1 or greater

(default: undefined)

### max-height

If defined sets the maximal number of rows used for printing list items.

If the available height is less than *max-height*, *max-height* is set to the available height.

Height in this context means number of print rows.

*max-height* overwrites *keep* if *max-height* is set to a value less than *keep*.

Allowed values: 1 or greater

(default: undefined)

### max-width

If defined, sets the maximal output width to *max-width* if the terminal width is greater than *max-width*.

To prevent the "auto-format" to use a width less than *max-width* set *layout* to `0`.

Width refers here to the number of print columns.

Allowed values: 2 or greater

(default: undefined)

### mouse

0 - no mouse (default)

1 - mouse enabled

### order

If the output has more than one row and more than one column:

0 - elements are ordered horizontally

1 - elements are ordered vertically (default)

### pad

Sets the number of whitespaces between columns. (default: 2)

Allowed values: 0 or greater

### page

0 - off

1 - print the page number on the bottom of the screen. If all the choices fit into one page, the page number is not displayed. (default)

2 - the page number is always displayed even with only one page. Setting page to 2 automatically enables the option clear-screen.

### prompt

If *prompt* is undefined, a default prompt-string will be shown.

If the *prompt* value is an empty string (""), no prompt-line will be shown.

(default: undefined)

### save-screen

0 - off (default)

1 - use the alternate screen

### search

Set the behavior of Ctrl-F.

0 - off

1 - case-insensitive search (default)

2 - case-sensitive search

### tabs-bottom-text

The option *tabs-bottom-text* allows one to insert spaces at beginning and the end of *info* lines.

*tabs-bottom-text* expects a list with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If *margin* is set, the initial-tab and the subsequent-tab are set to left-*margin* and the right margin is set to right-*margin*. If *margin* is not defined, the default is undefined.

### tabs-info

The option *tabs-info* allows one to insert spaces at beginning and the end of *info* lines.

*tabs-info* expects a list with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If *margin* is set, the initial-tab and the subsequent-tab are set to left-*margin* and the right margin is set to right-*margin*. If *margin* is not defined, the default is undefined.

### tabs-prompt

The option *tabs-prompt* allows one to insert spaces at beginning and the end of *prompt* lines.

*tabs-prompt* expects a list with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If *margin* is set, the initial-tab and the subsequent-tab are set to left-*margin* and the right margin is set to right-*margin*. If *margin* is not defined, the default is undefined.

### undef

Sets the string displayed on the screen instead of an undefined element.

(default: "<undef>")

options choose-multi
--------------------

### include-highlighted

0 - `choose-multi` returns the items marked with the SpaceBar. (default)

1 - `choose-multi` returns the items marked with the SpaceBar plus the highlighted item.

2 - `choose-multi` returns the items marked with the SpaceBar. If no items are marked with the SpaceBar, the highlighted item is returned.

### mark

*mark* expects as its value a list of indexes (integers). `choose-multi` preselects the list-elements correlating to these indexes.

(default: undefined)

### meta-items

*meta-items* expects as its value a list of indexes (integers). List-elements correlating to these indexes can not be marked with the SpaceBar or with the right mouse key but if one of these elements is the highlighted item it is added to the chosen items when Return is pressed.

Elements greater than the last index of the list are ignored.

(default: undefined)

### no-spacebar

*no-spacebar* expects as its value an list. The elements of the list are indexes of choices which should not be markable with the SpaceBar or with the right mouse key. If an element is preselected with the option *mark* and also marked as not selectable with the option *no-spacebar*, the user can not remove the preselection of this element.

(default: undefined)

MULTITHREADING
==============

`Term::Choose` uses multithreading when preparing the list for the output; the number of threads to use can be set with the environment variable `TC_NUM_THREADS`.

REQUIREMENTS
============

Escape sequences
----------------

The control of the cursor location, the highlighting of the cursor position and the marked elements and other options on the terminal is done via escape sequences.

By default `Term::Choose` uses `tput` to get the appropriate escape sequences. If the environment variable `TC_ANSI_ESCAPES` is set to a true value, hardcoded ANSI escape sequences are used directly without calling `tput`.

The escape sequences to enable the *mouse* mode and the escape sequence to get the cursor position are always hardcoded.

If the environment variable `TERM` is not set to a true value, `vt100` is used instead as the terminal type for `tput`.

Monospaced font
---------------

It is required a terminal that uses a monospaced font which supports the printed characters.

Ambiguous width characters
--------------------------

By default ambiguous width characters are treated as half width. If the environment variable `TC_AMBIGUOUS_WIDTH_IS_WIDE` is set to a true value, ambiguous width characters are treated as full width.

The support for the old variable name `TC_AMBIGUOUS_WIDE` will be removed.

Restrictions
------------

Term::Choose is not installable on Windows.

AUTHOR
======

Matthäus Kiem <cuer2s@gmail.com>

CREDITS
=======

Based on the `choose` function from the [Term::Clui](https://metacpan.org/pod/Term::Clui) module.

Thanks to the people from [Perl-Community.de](http://www.perl-community.de), from [stackoverflow](http://stackoverflow.com) and from [#perl6 on irc.freenode.net](irc://irc.freenode.net/#perl6) for the help.

LICENSE AND COPYRIGHT
=====================

Copyright (C) 2016-2026 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

