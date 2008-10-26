package  Hessian::Translator::Numeric;

use strict;
#use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;

sub write_integer : Export(:to_hessian) {    #{{{
    my $integer            = shift;
    my $result =
        -16 <= $integer     && $integer <= 47     ? write_single_octet($integer)
      : -2048 <= $integer   && $integer <= 2047   ? write_double_octet($integer)
      : -262144 <= $integer && $integer <= 262143 ? write_triple_octet($integer)
      :     write_quadruple_octet($integer);
    return 'I' . $result;
}    #}}}

sub write_quadruple_octet {    #{{{
    my $integer = shift;
    my $new_int = pack 'N', $integer;
    return $new_int;
}    #}}}

sub write_single_octet {    #{{{
    my $number = shift;
    # {-16 >= x >= 31: x + x90 = b0}
    my $new_int = pack "C*", ( $number + 0x90 );
    return $new_int;
}    #}}}

sub write_double_octet {    #{{{
    my $integer = shift;
    # {-2048 >= x >= 2047: x = 256 * (b0 - xd8) + b1 }
    my $big_short = pack "n", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit = ( ( $integer - $bytes[0] ) >> 8 ) + 0xc8;
    my $new_int = pack 'C*', $high_bit, $bytes[0];
    return $new_int;
}    #}}}

sub write_triple_octet {    #{{{
    my $integer = shift;
    # { -262144 >= x >= 262143: x = 65536 * (b0 - x5c) + 256 * b1 + b0}
    my $big_short = pack "N", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit =
      ( ( $integer - $bytes[0] - ( $bytes[1] >> 8 ) ) >> 16 ) + 0xd4;
    my $new_int = pack 'C*', $high_bit, $bytes[1], $bytes[0];
    return $new_int;
}    #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Numeric - Translation of numerical data to and from
hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


