package  Datatype::Binary;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;

use Hessian::Translator::Binary qw/:input_handle/;

sub t040_read_binary_input_handle : Test(1) {    #{{{
    my $self = shift;

    my $ih = $self->get_string_file_input_handle("\x23\x01\x02\x03");
    my $first_bit;
    read $ih, $first_bit, 1;
    my $octets = read_binary_handle_chunk( $first_bit, $ih );
    my @octet_array = unpack 'C*', $octets;
    my $array_count = scalar @octet_array;
    is( $array_count, 3,
        "Collected correct number of binary octets from handle." );

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Binary - Base class for testing binary data serialization in
Hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


