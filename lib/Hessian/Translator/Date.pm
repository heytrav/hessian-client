package  Hessian::Translator::Date;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;


sub write_date : Export(:to_hessian ) {    #{{{
    my $epoch_time    = shift;
    my $epoch_big_int = Math::BigInt->new($epoch_time);

    # Note: Hessian expects 64 bit dates.  Since some systems, including my
    # are 32 bit, I need to some hacking to get around this.
    $epoch_big_int->bmul(1000);            # to add milliseconds

    my $time64          = int64($epoch_big_int);
    my $time_in_network = int64_to_net($epoch_big_int);
    return 'd' . $time_in_network;
}    #}}}

sub read_date : Export(:from_hessian) {    #{{{
    my $hessian_date = shift;
    $hessian_date =~ s/^d(.*)/$1/;

    # Assume caller has already filtered out the leading 'd'
    my @unpacked_input = unpack 'CCCCCCCC', $hessian_date;
    my $int            = Math::BigInt->new(0);
    my $shift_val      = 0;
    foreach my $bit_pos ( reverse @unpacked_input ) {
        my $to_shift = Math::BigInt->new($bit_pos);
        $to_shift->blsft($shift_val);
        $int->bxor($to_shift);
        $shift_val += 8;
    }
    $int->bdiv(1000);    # drop milliseconds
    return $int;
}    #}}}

sub write_boolean {    #{{{
    my $bool_val = shift;
    return
        $bool_val =~ /t(?:rue)?/i  ? 'T'
      : $bool_val =~ /f(?:alse)?/i ? 'F'
      :                              'N';

    # throw a fault
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


