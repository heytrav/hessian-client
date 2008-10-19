#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More qw( no_plan );
use DateTime;
use DateTime::Format::Epoch::Unix;
use Hessian::Translator qw/:to_hessian :from_hessian/;

my $date = DateTime->new(
    year      => 1998,
    month     => 5,
    day       => 8,
    hour      => 2,
    minute    => 51,
    second    => 31,
    time_zone => 'UTC'
);
print "Original date: " . $date . "\n";
my $formatter    = DateTime::Format::Epoch::Unix->new();
my $formatted    = $formatter->format_datetime($date);
my $hessian_date = write_date($formatted);
my $byte_string  = "\x{00}\x{00}\x{00}\x{d0}\x{4b}\x{92}\x{84}\x{b8}";
TODO: {
    local $TODO = "Problems with 64 bit numbers.";
    like(
        $hessian_date,
        qr/ 
      d $byte_string
    /xms,
        "Simple translation of date."
    );

    my $processed_time    = read_date($byte_string);
    my $from_hessian_date = $formatter->parse_datetime($processed_time);
    $from_hessian_date->set_time_zone('UTC');

    my $cmp = DateTime->compare( $date, $from_hessian_date );
    is($cmp, 
    0, 
    "Hessian date as expected."
    );

}

