#!/usr/bin/env perl6
use v6;
use Config::Simple;
use JSON::Pretty;
use Data::Dump;
unit class UNIX::Daemonize::EasyDaemon;

sub generate-template($file-name) is export {
    my $conf = Config::Simple.new(:f<JSON>);
    $conf.filename = $file-name;
    my $programs := $conf<PROGRAMS-DEFINITIONS>;
    $programs<troll-cow><command> = "xcowsay 'hey there, stop me with: easy-daemon stop troll-cow'; sleep 5";
    $programs<troll-cow><shell> = True;
    $programs<troll-cow><repeat> = True;
    $conf<PID-LOCK-DIR> = "/var/run/lock/easy-daemon";
    $conf<PID-LOCK-DIR>.IO.mkdir;
    if $file-name.defined {
        try {$conf.filename.IO.dirname.IO.mkdir;} # create dir if doesnt exist
        try {
            $conf.write; # write the conf to a file
            CATCH {default {die("Can't config write to $file-name");}}
            say "Written example config file to $file-name";
        }
    } else { 
        say to-json($conf.hash);
    }
}

sub dump(Str $file-name) is export {
    my $conf = Config::Simple.read($file-name, :f<JSON>);
    my %programs = $conf<PROGRAMS-DEFINITIONS>;
    say to-json($conf.hash);
}
multi load-config(@paths) is export {
    my $conf-file = @paths.first: *.IO.e;

    unless $conf-file.defined {
        my $msg = "Can't find config file in any of these:\n" ~ @paths.join("\n") ~ 
            "\n\nTo quickly generate one enter:\neasy-daemon config generate " ~ @paths[0]  ~"\n";
        die($msg);
    }

    return load-config $conf-file;
}
multi load-config(Str $file-name) is export {
    my $conf = Config::Simple.read($file-name, :f<JSON>);
    my %PROGRAMS-DEFINITIONS = $conf<PROGRAMS-DEFINITIONS>;
    my $PID-LOCK-DIR = $conf<PID-LOCK-DIR>;
    # pid-lock-dir might be erased after reboot
    try {$PID-LOCK-DIR.IO.mkdir;}
    return ($file-name, $PID-LOCK-DIR, %PROGRAMS-DEFINITIONS);
}

sub parse-to-arguments($name, @paths) is export {
    my ($file-name, $PID-LOCK-DIR, %PROGRAMS-DEFINITIONS) = load-config @paths;  

    my (@args, %kwargs);
    with %PROGRAMS-DEFINITIONS{$name} {
        @args = .<command>.words;
        %kwargs.push: (repeat => $_) with .<repeat>;
        %kwargs.push: (shell => $_) with .<shell>;
        %kwargs.push: (stderr => $_) with .<stderr>;
        #%kwargs.push: (stderr => $_) with .<stderr>;
        %kwargs.push: (pid-file => "$PID-LOCK-DIR/$name");
    } else { fail "Did not found $name daemon in $file-name file"; };
    return (@args, %kwargs);
}

=begin pod

=head1 NAME

UNIX::Daemonize::EasyDaemon - Quick & easy daemon manager for UNIX written in Perl6. 

Lets you run custom commands as daemon, exactly one instance at a time. Meant as front-end to UNIX::Daemonize.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Desc…

=head1 BUGS / CONTRIBUTIONS

Repo at L<https://github.com/hipek8/easy-daemon>.

Bugs included, open issue if you find one.

TODO:
=item edit daemon parameters from command-line
=item any

=head1 AUTHOR

Paweł Szulc <pawel_szulc@onet.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

