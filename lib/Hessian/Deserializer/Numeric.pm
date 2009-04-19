package  Hessian::Deserializer::Numeric;

use Moose::Role;

use Math::Int64 qw/int64_to_number int64_to_net int64 net_to_int64/;
use Math::BigInt lib   => 'GMP';
use Math::BigFloat lib => 'GMP';
use Hessian::Exception;
use POSIX qw/floor ceil/;
use Switch;

sub read_boolean {    #{{{
    my ( $self, $hessian_value ) = @_;
    return
        $hessian_value =~ /T/ ? 1
      : $hessian_value =~ /F/ ? 0
      :                         die "Not an acceptable boolean value";
}    #}}}

sub read_integer {    #{{{
    my ( $self, $hessian_data ) = @_;
    ( my $raw_octets = $hessian_data ) =~ s/^I(.*)/$1/;
    my @chars = unpack 'C*', $raw_octets;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? _read_single_octet( $chars[0], 0x90 )
      : $octet_count == 2 ? _read_double_octet( \@chars, 0xc8 )
      : $octet_count == 3 ? _read_triple_octet( \@chars, 0xd4 )
      :                    _read_quadruple_octet( \@chars );
    return $result;
}    #}}}

sub read_long {    #{{{
    my ( $self, $hessian_data ) = @_;
    ( my $raw_octets = $hessian_data ) =~ s/^(?:L|\x77)(.*)/$1/;
    my @chars       = unpack 'C*', $raw_octets;
    my $array_size  = scalar @chars;
    my $octet_count = scalar @chars;
    my $result =
        $octet_count == 1 ? _read_single_octet( $chars[0], 0xe0 )
      : $octet_count == 2 ? _read_double_octet( \@chars, 0xf8 )
      : $octet_count == 3 ? _read_triple_octet( \@chars, 0x3c )
      : $octet_count == 4 ? Implementation::X->throw(
        error => "32 bit longs
      not currently supported."
      )
      : _read_full_long($raw_octets);    #\@chars );
                                         #_read_quadruple_octet( \@chars,
    return $result;
}    #}}}

sub read_double {    #{{{
    my ( $self, $octet ) = @_;
    my $double_value =
        $octet =~ /\x{5b}/                    ? 0.0
      : $octet =~ /\x{5c}/                    ? 1.0
      : $octet =~ /(?: \x{5d} | \x{5e} ) .*/x ? _read_compact_double($octet)
      : $octet =~ /\x5f/                      ? Implementation::X->throw(
        error => "32 bit doubles not currently supported." )
      : _read_full_double($octet);

    #_read_quadruple_octet_double($octet)
    return $double_value;
}    #}}}

sub _read_single_octet {    #{{{
    my ( $octet, $octet_shift ) = @_;
    my $integer = $octet - $octet_shift;
    return $integer;
}    #}}}

sub _read_double_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    {
        use integer;
        my $integer = ( ( $bytes->[0] - $octet_shift ) << 8 ) + $bytes->[1];
        return $integer;
    }
}    #}}}

sub _read_triple_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    {
        use integer;
        my $integer =
          ( ( $bytes->[0] - $octet_shift ) << 16 ) +
          ( $bytes->[1] << 8 ) +
          $bytes->[2];
        return $integer;
    }
}    #}}}

sub _read_quadruple_long_octet {    #{{{
    my ( $bytes, $octet_shift ) = @_;
    my $big_int   = Math::BigInt->new();
    my $shift_val = 0;
    my $index     = 0;
    foreach my $byte ( reverse @{$bytes} ) {

        #        $index++;
        my $shift_byte = Math::BigInt->new($byte);

        #        $shift_byte->bsub($octet_shift) if $index == 4;
        $shift_byte->blsft($shift_val);
        $big_int->badd($shift_byte);
        $shift_val += 8;
    }
    return $big_int->bstr();
}    #}}}

sub _read_quadruple_octet {    #{{{
    my $bytes = shift;
    {
        use integer;

        my $shift_val = 0;
        my $sum;
        foreach my $byte ( reverse @{$bytes} ) {
            $sum += $byte << $shift_val;
            $shift_val += 8;
        }
        return $sum;
    }
}    #}}}

sub _read_full_long {    #{{{
    my $string    = shift;
    my $net_int64 = net_to_int64($string);
    return "$net_int64";
}    #}}}

sub _read_compact_double {    #{{{
    my $compact_octet = shift;
    my @chars = unpack 'c*', $compact_octet;
    shift @chars;
    my $chars_size = scalar @chars;
    my $float      = _read_quadruple_octet( \@chars );
    return $float;
}    #}}}

sub _read_quadruple_octet_double {    #{{{
    my $octets = shift;
    $octets =~ s/\x5f//;

    #     my @chars = unpack 'C*', $octets;
    #     my @hex_octets =
    #       map { sprintf "%#02x", $_ } @chars;
    #     my $hex_string = join "" => @hex_octets;

    my $double;

    #     $double = str2float($hex_string);
    return $double;
}    #}}}

sub _read_full_double {    #{{{
    my $double = shift;
    ( my $octets = $double ) =~ s/(?:D ) (.*) /$1/x;
    my @chars = unpack 'C*', $octets;
    my $double_value = unpack 'F', pack 'C*', reverse @chars;
    return $double_value;
}    #}}}

sub read_integer_handle_chunk {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $number, $data );
    switch ($first_bit) {
        case /\x49/ {

            #            read $input_handle, $data, 4;
            $data   = $self->read_from_inputhandle(4);
            $number = $self->read_integer($data);
        }
        case /[\x80-\xbf]/ {
            $number = $self->read_integer($first_bit);
        }
        case /[\xc0-\xcf]/ {

            #            read $input_handle, $data, 1;
            $data   = $self->read_from_inputhandle(1);
            $number = $self->read_integer( $first_bit . $data );
        }
        case /[\xd0-\xd7]/ {

            #            read $input_handle, $data, 2;
            $data   = $self->read_from_inputhandle(2);
            $number = $self->read_integer( $first_bit . $data );
        }

    }
    return $number;

}    #}}}

sub read_long_handle_chunk {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $number, $data );
    switch ($first_bit) {
        case /[\xd8-\xef]/ {
            $number = $self->read_long($first_bit);
        }
        case /[\xf0-\xff]/ {

            #            read $input_handle, $data, 1;
            $data   = $self->read_from_inputhandle(1);
            $number = $self->read_long( $first_bit . $data );
        }
        case /[\x38-\x3f]/ {

            #            read $input_handle, $data, 2;
            $data   = $self->read_from_inputhandle(2);
            $number = $self->read_long( $first_bit . $data );
        }
        case /\x59/ {
            $data   = $self->read_from_inputhandle(4);
            $number = $self->read_long($data);

        }
        case /\x4c/ {

            #            read $input_handle, $data, 8;
            $data   = $self->read_from_inputhandle(8);
            $number = $self->read_long($data);
        }

    }
    return $number;
}    #}}}

sub read_double_handle_chunk {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $number, $data );
    switch ($first_bit) {

        #        case /[\x5b-\x5c]/ { $data = $first_bit; }
        #        case /\x5d/ { read $input_handle, $data, 1; }
        #        case /\x5e/ { read $input_handle, $data, 2; }
        #        case /\x5f/ {
        #            read $input_handle, $data, 4;
        case /[\x5b-\x5c]/ { $data = $first_bit; }
        case /\x5d/ {
            $data = $first_bit . $self->read_from_inputhandle(1);

            #            read $input_handle, $data, 1;
        }
        case /\x5e/ {

            $data = $first_bit . $self->read_from_inputhandle(2);

            #            read $input_handle, $data, 2;
        }
        case /\x5f/ {

            #            read $input_handle, $data, 4;
            $data = $first_bit . $self->read_from_inputhandle(4);
        }
        case /\x44/ {
            $first_bit = "";

            #            read $input_handle, $data, 8;
            $data = $first_bit . $self->read_from_inputhandle(8);
        }

    }
    $number = $self->read_double($data);
    return $number;
}    #}}}

sub read_boolean_handle_chunk {    #{{{
    my ( $self, $first_bit ) = @_;
    return $self->read_boolean($first_bit);

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Numeric - Deserializer methods for booleans, integers and
floating point numbers.

=head1 VERSION

=head1 SYNOPSIS

These methods are meant for internal use.

=head1 DESCRIPTION

This module provides methods for reading numerical values from the input file
handle.

=head1 INTERFACE

=head2   read_boolean

Read a boolean value.

=head2   read_boolean_handle_chunk

Reads a boolean value from the file handle.


=head2   read_double_handle_chunk

Read a floating point number from the file handle.


=head2   read_integer

Reads an integer.


=head2   read_integer_handle_chunk

Reads an integer.

=head2   read_long

Reads a long numerical value

=head2 read_double

Reads a floating point number.


=head2   read_long_handle_chunk


Reads a long numerical value from the file handle.
