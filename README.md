NAME
====

UNIX::Daemonize::EasyDaemon - Quick & easy daemon manager for UNIX written in Perl6. 

Lets you run custom commands as daemon, exactly one instance at a time. Meant as front-end to UNIX::Daemonize.

SYNOPSIS
========

Install UNIX::Daemonize (if it's not in ecosystem yet)

    git clone https://github.com/hipek8/p6-UNIX-Daemonize.git
    cd easy-daemon
    panda install .

Install me (assuming you've got perl6)

    git clone https://github.com/hipek8/easy-daemon.git
    cd easy-daemon
    panda install .

Install xcowsay to see example

    sudo aptitude install xcowsay

Generate example config in default place, run and see what happens

    easy-daemon config generate ~/.easy-daemon/config.json
    easy-daemon start troll-cow

Edit newly generated config file, add all you want, remember to keep names unique!

DESCRIPTION
===========

Desc…

BUGS / CONTRIBUTIONS
====================

Repo at [https://github.com/hipek8/easy-daemon](https://github.com/hipek8/easy-daemon).

Bugs included, open issue if you find one.

TODO:

  * edit daemon parameters from command-line

  * any

AUTHOR
======

Paweł Szulc <pawel_szulc@onet.pl>

COPYRIGHT AND LICENSE
=====================

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
