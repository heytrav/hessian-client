package  Hessian::Translator::Numeric;

use strict;

#use warnings;

use version; our $VERSION = qv('0.0.1');

use integer;
use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;

sub write_integer : Export(:to_hessian) {    #{{{
    my $integer = shift;
    my $result =
        -16 <= $integer && $integer <= 47 ? write_single_octet( $integer, 0x90 )
      : -2048 <= $integer
      && $integer <= 2047 ? write_double_octet( $integer, 0xc8 )
      : -262144 <= $integer
      && $integer <= 262143 ? write_triple_octet( $integer, 0xd4 )
      :                       write_quadruple_octet($integer);
    return 'I' . $result;
}    #}}}

sub write_quadruple_octet {    #{{{
    my $integer = shift;
    my $new_int = pack 'N', $integer;
    return $new_int;
}    #}}}

sub write_single_octet {    #{{{
    my ( $number, $octet_shift ) = @_;
    my $new_int = pack "C*", ( $number + $octet_shift );
    return $new_int;
}    #}}}

sub write_double_octet {    #{{{
    my ( $integer, $octet_shift ) = @_;

    # {-2048 >= x >= 2047: x = 256 * (b0 - xd8) + b1 }
    my $big_short = pack "n", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit = ( ( $integer - $bytes[0] ) >> 8 ) + $octet_shift;
    my $new_int = pack 'C*', $high_bit, $bytes[0];
    return $new_int;
}    #}}}

sub write_triple_octet {    #{{{
    my ( $integer, $octet_shift ) = @_;

    # { -262144 >= x >= 262143: x = 65536 * (b0 - x5c) + 256 * b1 + b0}
    my $big_short = pack "N", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit =
      ( ( $integer - $bytes[0] - ( $bytes[1] >> 8 ) ) >> 16 ) + $octet_shift;
    my $new_int = pack 'C*', $high_bit, $bytes[1], $bytes[0];
    return $new_int;
}    #}}}

sub write_boolean : Export(:to_hessian) {    #{{{
    my $bool_val = shift;
    return
        $bool_val =~ /t(?:rue)?/i  ? 'T'
      : $bool_val =~ /f(?:alse)?/i ? 'F'
      :                              'N';

    # throw a fault
}    #}}}

sub read_integer : Export(:from_hessian) {    #{{{
    my $hessian_data = shift;
    ( my $raw_octets = $hessian_data ) =~ s/^I(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? read_single_octet($chars[0], 0x90)
      : $octet_count == 2 ? read_double_octet( \@chars, 0xc8 )
      : $octet_count == 3 ? read_triple_octet( \@chars, 0xd4 )
      :                     read_quadruple_octet( \@chars );
    return $result;
}    #}}}

sub read_single_octet {    #{{{
    my ( $octet, $octet_shift ) = @_;
    my $integer = $octet - $octet_shift;
    return $integer;
}    #}}}

sub read_double_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    my $integer = ( ( $bytes->[0] - $octet_shift ) << 8 ) + $bytes->[1];
    return $integer;
}    #}}}

sub read_triple_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    my $integer =
      ( ( $bytes->[0] - $octet_shift ) << 16 ) +
      ( $bytes->[1] << 8 ) +
      $bytes->[2];
    return $integer;
}    #}}}

sub  read_long :Export(:from_hessian) { #{{{
    my $hessian_data = shift;
    ( my $raw_octets = $hessian_data ) =~ s/^L(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? read_single_octet($chars[0], 0xe0)
      : $octet_count == 2 ? read_double_octet( \@chars, 0xf8 )
      : $octet_count == 3 ? read_triple_octet( \@chars, 0x3c )
      :                     read_quadruple_octet( \@chars );
    return $result;
} #}}}

sub  write_long :Export(:to_hessian) { #{{{
    my $long = shift; 
    my $result =
        -8 <= $long && $long <= 15 ? write_single_octet( $long, 0xe0 )
      : -2048 <= $long
      && $long <= 2047 ? write_double_octet( $long, 0xf8 )
      : -262144 <= $long
      && $long <= 262143 ? write_triple_octet( $long, 0x3c )
      :                       write_quadruple_octet($long);
    return 'L' . $result;
} #}}}



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


