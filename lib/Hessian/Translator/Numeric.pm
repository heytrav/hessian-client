package  Hessian::Translator::Numeric;

use strict;

use version; our $VERSION = qv('0.0.1');

use integer;
use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;
use POSIX qw/floor ceil/;
use Switch;

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
        $bool_val =~ /(?:1|t(?:rue)?)/i  ? 'T'
      : $bool_val =~ /(?:0|f(?:alse)?)/i ? 'F'
      :                                    'N';

    # throw a fault
}    #}}}

sub read_boolean : Export(:from_hessian) {    #{{{
    my $hessian_value = shift;
    return
        $hessian_value =~ /T/ ? 1 
      : $hessian_value =~ /F/ ? 0
      :                         die "Not an acceptable boolean value";
}    #}}}

sub read_integer : Export(:from_hessian) {    #{{{
    my $hessian_data = shift;
    ( my $raw_octets = $hessian_data ) =~ s/^I(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? read_single_octet( $chars[0], 0x90 )
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

sub read_quadruple_octet {    #{{{
    my $bytes     = shift;
    my $shift_val = 0;
    my $sum;
    foreach my $byte ( reverse @{$bytes} ) {
        $sum += $byte << $shift_val;
        $shift_val += 8;
    }
    return $sum;
}    #}}}

sub read_long : Export(:from_hessian) {    #{{{
    my $hessian_data = shift;
    ( my $raw_octets = $hessian_data ) =~ s/^L(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? read_single_octet( $chars[0], 0xe0 )
      : $octet_count == 2 ? read_double_octet( \@chars, 0xf8 )
      : $octet_count == 3 ? read_triple_octet( \@chars, 0x3c )
      : $octet_count == 4 ? read_quadruple_octet( \@chars )
      :                     read_full_long( \@chars );
    return $result;
}    #}}}

sub read_full_long : Export(:utility) {    #{{{
    my $bytes     = shift;
    my $big_int   = Math::BigInt->new();
    my $shift_val = 0;
    foreach my $byte ( reverse @{$bytes} ) {
        my $shift_byte = Math::BigInt->new($byte);
        $shift_byte->blsft($shift_val);
        $big_int->badd($shift_byte);
        $shift_val += 8;
    }
    return $big_int;
}    #}}}

sub write_long : Export(:to_hessian) {    #{{{
    my $long = shift;
    my $result =
        -8 <= $long && $long <= 15 ? write_single_octet( $long, 0xe0 )
      : -2048 <= $long && $long <= 2047 ? write_double_octet( $long, 0xf8 )
      : -262144 <= $long && $long <= 262143 ? write_triple_octet( $long, 0x3c )
      :                                       write_full_long($long);
    return 'L' . $result;
}    #}}}

sub write_full_long {    #{{{
        # This will probably only work with Math::BigInt or similar
    my $long       = shift;
    my $int64      = int64($long);
    my $net_string = int64_to_net($int64);
    return $net_string;
}    #}}}

sub read_double : Export(:from_hessian) {    #{{{
    my $octet = shift;
    my $double_value =
        $octet =~ /\x{5b}/                    ? 0.0
      : $octet =~ /\x{5c}/                    ? 1.0
      : $octet =~ /(?: \x{5d} | \x{5e} ) .*/x ? read_compact_double($octet)
      :                                         read_full_double($octet);
}    #}}}

sub read_compact_double {    #{{{
    my $compact_octet = shift;
    my @chars = unpack 'c*', $compact_octet;
    shift @chars;
    my $chars_size = scalar @chars;
    my $float      = read_quadruple_octet( \@chars );
    return $float;
}    #}}}

sub read_full_double {    #{{{
    my $double = shift;
    ( my $octets = $double ) =~ s/D (.*) /$1/x;
    my @chars = unpack 'C*', $octets;
    my $double = unpack 'F', pack 'C*', reverse @chars;
    return $double;
}    #}}}

sub write_double : Export(:to_hessian) {    #{{{
    my $double = shift;
    my $hessian_string;
    my $compare_with = $double < 0 ? ceil($double) : floor($double);
    if ( $double eq $compare_with ) {
        $hessian_string =
             $double > -129
          && $double < 128 ? "\x5d" . write_single_octet_float($double)
          : $double > -32769
          && $double < 32768 ? "\x5e" . write_double_octet_float($double)
          :                    "D" . write_full_double($double);

    }
    else {
        $hessian_string = "D" . write_full_double($double);
    }

    return $hessian_string;

}    #}}}

sub write_single_octet_float {    #{{{
    my $double = shift;
    my $hessian_string = pack 'c*', $double;
    return $hessian_string;
}    #}}}

sub write_double_octet_float {    #{{{
    my $double = shift;
    my $hessian_string = pack 'n', unpack 'S', pack "s", $double;
    return $hessian_string;

}    #}}}

sub write_full_double {    #{{{
    my $double         = shift;
    my $native_float   = pack 'F', $double;
    my @chars          = unpack 'C*', $native_float;
    my $hessian_string = pack 'C*', reverse @chars;
    return $hessian_string;
}    #}}}

sub read_integer_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $number, $data );
    switch ($first_bit) {
        case /\x49/ {
            read $input_handle, $data, 4;
            $number = read_integer($data);
        }
        case /[\x80-\xbf]/ {
            $number = read_integer($first_bit);
        }
        case /[\xc0-\xcf]/ {
            read $input_handle, $data, 1;
            $number = read_integer( $first_bit . $data );
        }
        case /[\xd0-\xd7]/ {
            read $input_handle, $data, 2;
            $number = read_integer( $first_bit . $data );
        }

    }
    return $number;

}    #}}}

sub read_long_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $number, $data );
    switch ($first_bit) {
        case /[\xd8-\xef]/ { $number = read_long($first_bit); }
        case /[\xf0-\xff]/ {
            read $input_handle, $data, 1;
            return read_long( $first_bit . $data );
        }
        case /[\x38-\x3f]/ {
            read $input_handle, $data, 2;
            return read_long( $first_bit . $data );
        }
        case /\x4c/ {
            read $input_handle, $data, 8;
            $number = read_long($data);
        }

    }
    return $number;
}    #}}}

sub read_double_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $number, $data );
    switch ($first_bit) {
        case /[\x5b-\x5c]/ { $data = $first_bit; }
        case /\x5d/ { read $input_handle, $data, 1; }
        case /\x5e/ { read $input_handle, $data, 2; }
        case /\x5f/ {
            read $input_handle, $data, 4;
        }
        case /\x44/ {
            $first_bit = "";
            read $input_handle, $data, 8;
        }

    }
    $number = read_double( $first_bit . $data );
    return $number;
}    #}}}

sub  read_boolean_handle_chunk : Export(:input_handle) { #{{{
    my $first_bit = shift;
return read_boolean($first_bit);

} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Numeric - Translation of numerical data to and from
hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


