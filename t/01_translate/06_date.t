#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More tests => 2;
use DateTime;
use DateTime::Format::Epoch;
use DateTime::Format::Strptime;
use Hessian::Translator::Date qw/:to_hessian :from_hessian/;
my $strptime_formatter = DateTime::Format::Strptime->new(
    pattern   => '%F %T',
    time_zone => 'GMT'
);
my $date = DateTime->new(
    year      => 1998,
    month     => 5,
    day       => 8,
    hour      => 9,
    minute    => 51,
    second    => 31,
    time_zone => 'UTC'
);
print "Original date: " .( $strptime_formatter->format_datetime($date)) . "\n";
my $formatter = DateTime::Format::Epoch->new(
    unit  => 'milliseconds',
    type  => 'bigint',
    epoch => DateTime->new(
        year      => 1970,
        month     => 1,
        day       => 1,
        time_zone => 'UTC'
    )
);
my $formatted = $formatter->format_datetime($date);
print "formatted epoch time: $formatted\n";
my $hessian_date = write_date($formatted);
my $byte_string  = "\x{4a}\x{00}\x{00}\x{00}\x{d0}\x{4b}\x{92}\x{84}\x{b8}";


like(
    $hessian_date,
    qr/  $byte_string /xms,
    "Simple translation of date."
);

my $processed_time    = read_date(  $byte_string );
my $from_hessian_date = $formatter->parse_datetime($processed_time);
my $readable_date =
$strptime_formatter->format_datetime($from_hessian_date);
print "Interpreted datetime: $readable_date\n";
$from_hessian_date->set_time_zone('UTC');

my $cmp = DateTime->compare( $date, $from_hessian_date );
is( $cmp, 0, "Hessian date as expected." );


