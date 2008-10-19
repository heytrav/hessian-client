#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');



use Test::More qw( no_plan );
use DateTime;
use DateTime::Format::Epoch::Unix;




my $date = DateTime->new(
    year      => 1998,
    month     => 5,
    day       => 8,
    hour      => 2,
    minute    => 51,
    second    => 31,
    time_zone => 'UTC'
);
my $formatter = DateTime::Format::Epoch::Unix->new();
my $formatted = $formatter->format_datetime($date);
my $hessian_date = write_date($formatted);

like(
    $hessian_date,
    qr/ 
      d \x{00} \x{00} \x{00} \x{d0} \x{4b} \x{92} \x{84} \x{b8}
    /xms,
    "Simple translation of date."
);
