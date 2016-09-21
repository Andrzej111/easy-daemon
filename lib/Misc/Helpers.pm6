#!/usr/bin/env perl6

unit module MiscHelpers;

sub fill-right($str, Int $total, $empty = ' ') is export {
    with $str ~ $empty x ($total - $str.chars) {
        return $str[^$total-1] if $_.chars > $total;
        return $_;
    }
}


