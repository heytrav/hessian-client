package  Hessian::Deserializer::Numeric;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

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

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Numeric - Deserializer methods for integers and
floating point numbers.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


