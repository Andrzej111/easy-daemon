[![Build Status](https://travis-ci.org/Andrzej111/easy-daemon.svg?branch=master)](https://travis-ci.org/Andrzej111/easy-daemon)

NAME
====

Easy::Daemon - Quick & easy daemon manager. 

Lets you run custom commands as daemon, exactly one instance at a time.

SYNOPSIS
========

Install liblockfile with your favourite package manager

    sudo aptitude install liblockfile1

Install me (assuming you've got perl6)

    git clone https://github.com/Andrzej111/easy-daemon.git
    cd easy-daemon
    panda install .

Install xcowsay to see example

    sudo aptitude install xcowsay

Generate example config in default place, run and see what happens

    easy-daemon config generate ~/.easy-daemon/config.json
    easy-daemon start troll-cow

Edit newly generated config file, add all you want, remember to keep names unique! Editing daemons from command-line soon(er or later).

DESCRIPTION
===========

Easy::Daemon allows to define daemon-like programs on Linux and (prolly) OSX. Needs fork, kill, … from standard C library and liblockfile to run.

Recipe is:

    - fork, father exits
    - child runs setsid() to dettach
    - file corresponding to name is locked with child pid (exit if fails)
    - setup, command, cleanup are run through shell at times you would expect them to

To see what you can do, run help usage or whatever:

    easy-daemon help

More specifig description in progress…

BUGS
====

Included…

AUTHOR
======

Paweł Szulc <pawel_szulc@onet.pl>

COPYRIGHT AND LICENSE
=====================

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
