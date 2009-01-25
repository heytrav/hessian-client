package  Hessian::Deserializer::Numeric;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

use integer;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;
use POSIX qw/floor ceil/;
use Switch;

sub read_boolean {  #{{{
    my ($self, $hessian_value) = @_;
    return
        $hessian_value =~ /T/ ? 1
      : $hessian_value =~ /F/ ? 0
      :                         die "Not an acceptable boolean value";
}    #}}}

sub read_integer{   #{{{
    my ($self,$hessian_data) = @_;
    ( my $raw_octets = $hessian_data ) =~ s/^I(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? _read_single_octet( $chars[0], 0x90 )
      : $octet_count == 2 ? _read_double_octet( \@chars, 0xc8 )
      : $octet_count == 3 ? _read_triple_octet( \@chars, 0xd4 )
      :                     _read_quadruple_octet( \@chars );
    return $result;
}    #}}}

sub read_long {  #{{{
    my ($self, $hessian_data) = @_;
    ( my $raw_octets = $hessian_data ) =~ s/^L(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? _read_single_octet( $chars[0], 0xe0 )
      : $octet_count == 2 ? _read_double_octet( \@chars, 0xf8 )
      : $octet_count == 3 ? _read_triple_octet( \@chars, 0x3c )
      : $octet_count == 4 ? _read_quadruple_octet( \@chars )
      :                     _read_full_long( \@chars );
    return $result;
}    #}}}

sub _read_single_octet {    #{{{
    my ( $self, $octet, $octet_shift ) = @_;
    my $integer = $octet - $octet_shift;
    return $integer;
}    #}}}

sub _read_double_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    my $integer = ( ( $bytes->[0] - $octet_shift ) << 8 ) + $bytes->[1];
    return $integer;
}    #}}}

sub _read_triple_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    my $integer =
      ( ( $bytes->[0] - $octet_shift ) << 16 ) +
      ( $bytes->[1] << 8 ) +
      $bytes->[2];
    return $integer;
}    #}}}

sub _read_quadruple_octet {    #{{{
    my $bytes     = shift;
    my $shift_val = 0;
    my $sum;
    foreach my $byte ( reverse @{$bytes} ) {
        $sum += $byte << $shift_val;
        $shift_val += 8;
    }
    return $sum;
}    #}}}

sub _read_full_long{    #{{{
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

sub read_integer_handle_chunk {    #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my ( $number, $data );
    switch ($first_bit) {
        case /\x49/ {
            read $input_handle, $data, 4;
            $number = $self->read_integer($data);
        }
        case /[\x80-\xbf]/ {
            $number = $self->read_integer($first_bit);
        }
        case /[\xc0-\xcf]/ {
            read $input_handle, $data, 1;
            $number = $self->read_integer( $first_bit . $data );
        }
        case /[\xd0-\xd7]/ {
            read $input_handle, $data, 2;
            $number = $self->read_integer( $first_bit . $data );
        }

    }
    return $number;

}    #}}}

sub read_long_handle_chunk  {    #{{{
    my ( $self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my ( $number, $data );
    switch ($first_bit) {
        case /[\xd8-\xef]/ { 
            $number = $self->read_long($first_bit); }
        case /[\xf0-\xff]/ {
            read $input_handle, $data, 1;
            $number = $self->read_long( $first_bit . $data );
        }
        case /[\x38-\x3f]/ {
            read $input_handle, $data, 2;
            $number = $self->read_long( $first_bit . $data );
        }
        case /\x4c/ {
            read $input_handle, $data, 8;
            $number = $self->read_long($data);
        }

    }
    return $number;
}    #}}}

sub read_double_handle_chunk  {    #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
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
    $number = $self->read_double( $first_bit . $data );
    return $number;
}    #}}}

sub read_boolean_handle_chunk  {    #{{{
    my ($self, $first_bit) = @_;
    return $self->read_boolean($first_bit);

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Numeric - Deserializer methods for booleans, integers and
floating point numbers.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


