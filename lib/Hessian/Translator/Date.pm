package  Hessian::Translator::Date;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;
use Hessian::Translator::Numeric qw/:from_hessian :to_hessian :utility/;

sub write_date : Export(:to_hessian ) {    #{{{
    my $epoch_time = shift;
    my $time =
      $epoch_time <= 4_294_967_295
      ? write_integer($epoch_time)
      : write_long($epoch_time);

    $time =~ s/^L/\x{4a}/;
    $time =~ s/^I/\x{4b}/;
    return $time;
}    #}}}

sub read_date : Export(:from_hessian) {    #{{{
    my $hessian_date = shift;
    my ($date_string) = $hessian_date =~ / (?:^d)?  (.*) /x;
    my $int;
    if ( $date_string =~ /^\x{4a} (.*)/x ) {
        $int = read_long($1);
    }
    elsif ( $date_string =~ /^\x{4b} (.*)/x ) {
        $int = read_integer($1);
        my $left_over = $1;
        my @chars = unpack 'C*', $left_over;
        print "Date hex thingy = ";
        print join " " => map { sprintf "%#02x" => $_} @chars;
        print "\n";
    }

    return $int;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Date - Translates time into and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


