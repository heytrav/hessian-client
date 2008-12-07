package  Hessian::Translator::Binary;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Switch;

sub read_binary_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $binary, $data, $length );
    switch ($first_bit) {
        case /[\x42\x62]/ {
            read $input_handle, $data, 2;
            $length = unpack "n", $data;
        }
        case /[\x20-\x2f]/ {
            my $raw_octet = "\x00" . $first_bit;
            $length = unpack 'n', $raw_octet;
            $length -= 0x20;
        }
    }
    read $input_handle, $binary, $length;
    return $binary;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Binary - Translate Hessian to and from binary data

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


