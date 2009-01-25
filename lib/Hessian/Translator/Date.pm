package Hessian::Translator::Date;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;
use Switch;
use Hessian::Translator::Numeric qw/
  :from_hessian
  :to_hessian :utility
  :input_handle
  /;

sub write_date : Export(:to_hessian ) {    #{{{
    my ( $epoch_time, $prefix ) = @_;
    my $time =
      $epoch_time <= 4_294_967_295
      ? write_integer($epoch_time)
      : write_long($epoch_time);
    if ($prefix) {
        $time =~ s/^(?:I|L )/$prefix/;
    }
    else {
        $time =~ s/^L/\x{4a}/;
        $time =~ s/^I/\x{4b}/;

    }
    return $time;
}    #}}}

sub read_date : Export(:from_hessian) {    #{{{
    my ( $hessian_date, $prefix ) = @_;
    my ($date_string) = $hessian_date =~ / (?:^d)?  (.*) /x;
    my $int;
    if ( $date_string =~ /^\x4a (.*)/x ) {
        $int = read_long($1);
    }
    elsif ( $date_string =~ /^(?: \x4b | \x64) (.*)/x ) {
        $int = read_integer($1);
        my $left_over = $1;
        my @chars = unpack 'C*', $left_over;
        print "Date hex thingy = ";
        print join " " => map { sprintf "%#02x" => $_ } @chars;
        print "\n";
    }

    return $int;
}    #}}}

sub read_date_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $date, $data );
    switch ($first_bit) {
        case /\x4a/ {
            $data = read_long_handle_chunk( 'L', $input_handle );
        }
        case /[\x4b\x64]/ {
            $data = read_integer_handle_chunk( 'I', $input_handle );

        }
    }
    return $data;

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Date - Translates time into and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


