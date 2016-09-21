#!/usr/bin/env perl6
use v6;
use Config::Simple;
use JSON::Pretty;
use Data::Dump;
unit class ConfigGenerator;

sub generate-template($file-name) is export {
    my $conf = Config::Simple.new(:f<JSON>); #if you want to use a ini file;
    $conf.filename = $file-name;
    my $programs := $conf<PROGRAMS-DEFINITIONS>;
    $programs<troll-cow><command> = "xcowsay 'hey there, stop me with: easy-daemon stop troll-cow'; sleep 5";
    $programs<troll-cow><loop> = "True";
    $programs<troll-cow><stdout> = "/dev/null";
    $programs<troll-cow><stderr> = "/dev/null";
    $conf<PID-LOCK-DIR> = "/var/run/lock/easy-daemon";
    $conf<PID-LOCK-DIR>.IO.dirname.IO.mkdir;
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
        my $msg = "Can't find config file in any of these:\n{@paths.join("\n");}" ~ 
            "\n\nTo quickly generate one enter:\neasy-daemon config generate " ~ @paths[0]  ~"\n";
        die($msg);
    }

    return load-config $conf-file;
}
multi load-config(Str $file-name) is export {
    my $conf = Config::Simple.read($file-name, :f<JSON>);
    my %PROGRAMS-DEFINITIONS = $conf<PROGRAMS-DEFINITIONS>;
    my $PID-LOCK-DIR = $conf<PID-LOCK-DIR>;
    return ($file-name, $PID-LOCK-DIR, %PROGRAMS-DEFINITIONS);
}

