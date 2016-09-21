use v6;
unit class Daemon;
use NativeCall;
use NativeSymbols;

# class containing info how program daemon should be run
class ProgramSpec is export {
    has $.command;
    has $.setup;
    has $.cleanup;
    has $.stdout;
    has $.stderr;
    has Bool $.loop;
    method new(%h) {
        self.bless:
            command => %h<command>,
            setup => %h<setup>//"",
            cleanup => %h<cleanup>//"",
            loop => so %h<loop> ~~ m:i/true/,
            stdout => %h<stdout> // Nil,
            stderr => %h<stderr> // Nil,
        ;
    }
}
#=class which is used to run commands as daemon in a manner specified in ProgramSpec structure
class Daemon is export {
    has ProgramSpec $.prog-spec;
    has $.alias;
    has $.PID-LOCK-DIR;
    has $!stop-flag = False;
    method new($PID-LOCK-DIR,$alias,%h) {
        my ProgramSpec $prog-spec .= new: %h;
        self.bless(:$PID-LOCK-DIR,:$alias, :$prog-spec);
    }
    #=starts daemon if none with same alias is currently run
    #=otherwise exits peacfully with some info
    method start() {
        self.daemonize;
    }
    #=tries to stop
    method stop() {
        my $did = self.daemon-id;
        if $did.defined.not or not self.accepts-signals($did) {
            say "Can't stop service. Already finished or lockfile $.PID-LOCK-DIR/$.alias broken";
            exit;
        } elsif $*PID ne $did {
        # Daemon "candidate" looks for real Daemon PID and sends TERM signal
            self.terminate-real-daemon;
        }
    }
    method kill-yourself() {
        $!stop-flag = True; 
        exit;
    }

    method status() {
        return "STOPPED" if self.daemon-id ~~ Nil or self.process-exists(self.daemon-id).not;
        return "RUNNING" if self.accepts-signals(self.daemon-id) && self.process-exists(self.daemon-id);
        return "ABORTED" unless self.process-exists(self.daemon-id);
        return "RUNNING (CURRENT USER CAN'T SEND SIGNALS)"
            if self.process-exists(self.daemon-id) && not self.accepts-signals(self.daemon-id);
        return "UKNOWN";
    }

    method restart() {
        self.stop;
        self.start;
    }
     method daemonize() {
        # parent quits here
        exit unless fork() == 0;
        setsid();
        umask(0);
        signal(SIGINT,SIGTERM,SIGUSR1,SIGUSR2).tap: {
            self.handle-signal($_);
        }
        self.lock;
        self.setup;
        self.main-loop;
        self.cleanup;
        self.unlock;
    }

    method main-loop() {
        say "\nService $.alias started\n";
        if $.prog-spec.loop {
            while !$!stop-flag { 
                self.main-command; 
                last if $!stop-flag;
            } 
        } else {
            self.main-command;
            sleep(∞);
        }
    }
    method setup() {
        my $comm = $.prog-spec.setup;
        $comm ~= " >"  ~ $.prog-spec.stdout with $.prog-spec.stdout;
        $comm ~= " 2>" ~ $.prog-spec.stdout with $.prog-spec.stderr;
        shell "$comm";
    }
    method main-command() {
        my $comm = $.prog-spec.command;
        $comm ~= " >>"  ~ $.prog-spec.stdout with $.prog-spec.stdout;
        $comm ~= " 2>>" ~ $.prog-spec.stdout with $.prog-spec.stderr;
        shell "$comm";
    }

    method cleanup() {
        my $comm = $.prog-spec.cleanup;
        $comm ~= " >>"  ~ $.prog-spec.stdout with $.prog-spec.stdout;
        $comm ~= " 2>>" ~ $.prog-spec.stdout with $.prog-spec.stderr;
        shell "$comm";
    }
    method lock(){
        my $status = lockfile_create("$.PID-LOCK-DIR/$.alias",0,16);
        if $status != Lockfile-Return::L_SUCCESS {
            if "$.PID-LOCK-DIR/$.alias".IO ~~ :e {
                say "Service already running on PID " ~ slurp("$.PID-LOCK-DIR/$.alias") ~ "Not doing anything…";
            } else {
                say "Can't create lock " ~ "$.PID-LOCK-DIR/$.alias" ~
                    "\nlockfile_create returned $status\nMake sure you have sufficent privileges.\nExitting…";
            }
            exit;
        }
    }
    method unlock(){
        lockfile_remove("$.PID-LOCK-DIR/$.alias");
    }


    method daemon-id() {
        return Int( slurp("$.PID-LOCK-DIR/$.alias") ) 
            if "$.PID-LOCK-DIR/$.alias".IO ~~ :e;
        return Nil;
    }
    #=tries to terminate deamon and subprocesses (same PGID),
    #=first, checks if process accepts signals (signal 0), then send USR1 to prepare for termination
    #=then sends TERM to all with same PGID as daemon's
    #=if not dead after some time – send KILL 'em all
    method terminate-real-daemon() {
        my $did = self.daemon-id;
        my Int $pgid = getpgid($did);
        if not self.accepts-signals($pgid) {
            note "Can't send signals to $.alias";
            return 1;
        }
        kill($did,SignalNumbers::USR1);
        say "PID: $*PID\tDaemonID: $did\t DaemonPGID: $pgid";
        kill(-$pgid,SignalNumbers::TERM);
        my $n;
        while self.process-exists(-$pgid) {
            FIRST {$n = 0; }
            $n++;
            sleep(0.5);
            if $n>=5 {
                if kill(-$did,9) == 0 {
                    # killed with 9, has to clean up after him :/
                    self.cleanup;
                    self.unlock;
                    note "Service $.alias stopped by force";
                    return 0 ;
                } 
            }
        } 
        note "Service $.alias stopped";
    }
    method accepts-signals($pid) {
        return True if kill($pid, 0) == 0;
    }

    method process-exists($pid) {
        if kill($pid, 0) == 0 {
            return True;
        } else {
            my $errno = cglobal('libc.so.6', 'errno', int32);
            return True if $errno == 1;
            return False;
        }
    }
    multi method handle-signal(SIGINT) {
        $!stop-flag = True;
        note "GOT SIGINT";
        "stop-flag is $!stop-flag";
    }
    multi method handle-signal(SIGUSR1) {
        $!stop-flag = True;
        note "HELLO USR1111";
    }
    multi method handle-signal(SIGTERM) {
        $!stop-flag = True;
        say "SIGTERM received, quitting…";
        self.kill-yourself;
    }
    multi method handle-signal(Any) {
        say "Got unknown signal, exitting…";
        $!stop-flag = True;
        self.kill-yourself;
    }
}

=begin pod

=head1 NAME

Easy::Daemon - Quick & easy daemon manager. 
Lets you run custom commands as daemon, exactly one instance at a time.

=head1 SYNOPSIS

Install liblockfile with your favourite package manager
  sudo aptitude install liblockfile

Install me
  git clone https://github.com/Andrzej111/easy-daemon.git
  cd easy-daemon
  panda install .

Install xcowsay to see example

  sudo aptitude install xcowsay

Generate example config in default place, run and see what happens

  easy-daemon config generate ~/.easy-daemon/config.json
  easy-daemon start troll-cow

=head1 DESCRIPTION

Easy::Daemon allows to define daemon-like programs on Linux and (prolly) OSX.
Needs fork, kill, … from standard C library and liblockfile to run
More specifig description in progress…

=head1 BUGS

Included…

=head1 AUTHOR

Paweł Szulc <pawel_szulc@onet.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
