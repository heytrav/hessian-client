#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Test::More tests => 2;
use DateTime;
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
    time_zone => 'UTC'
);
my $date_epoch = $date->epoch();
my $hessian_date = write_date($date_epoch);
my $byte_string  = "\x{4b}\x{35}\x{52}\x{d5}\x{84}";


like(
    $hessian_date,
    qr/  $byte_string /xms,
    "Simple translation of date."
);

my $processed_time    = read_date(  $byte_string );
my $from_hessian_date = DateTime->from_epoch(epoch => $processed_time);
my $readable_date =
$strptime_formatter->format_datetime($from_hessian_date);
$from_hessian_date->set_time_zone('UTC');

my $cmp = DateTime->compare( $date, $from_hessian_date );
is( $cmp, 0, "Hessian date as expected." );







