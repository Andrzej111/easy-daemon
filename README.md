NAME
====

Easy::Daemon - Quick & easy daemon manager.  Lets you run custom commands as daemon, exactly one instance at a time.

SYNOPSIS
========

Install liblockfile with your favourite package manager sudo aptitude install liblockfile

Install me git clone https://github.com/Andrzej111/easy-daemon.git cd easy-daemon panda install .

Install xcowsay to see example

    sudo aptitude install xcowsay

Generate example config in default place, run and see what happens

    easy-daemon config generate ~/.easy-daemon/config.json
    easy-daemon start troll-cow

DESCRIPTION
===========

Easy::Daemon allows to define daemon-like programs on Linux and (prolly) OSX. Needs fork, kill, … from standard C library and liblockfile to run More specifig description in progress…

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
