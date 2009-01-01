package Hessian::Translator::Envelope;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Hessian::Translator::Message';

use Perl6::Export::Attrs;
use Switch;
use YAML;

use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;


sub read_message_chunk :Export(:deserialize) {    #{{{
    my ( $input_handle, $deserializer_obj ) = @_;
    my $deserializer = $deserializer_obj;
    $deserializer =
      $deserializer
      ? __PACKAGE__->set_deserializer($deserializer)
      : __PACKAGE__->get_deserializer();
    my ( $first_bit, $element );
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';
    my $datastructure;
    switch ($first_bit) {
        case /\x48/ {    # TOP with version
            my $version;
            read $input_handle, $version, 2;
            my @values = unpack 'C*', $version;
            $datastructure = $values[0];
        }
        case /\x43/ {    # Hessian Remote Procedure Call

        }
        case /\x45/ {    # Envelope

        }
        case /\x46/ {    # Fault

        }
        case /\x52/ {    # Reply

        }
    }
    return $datastructure;
}    #}}}

sub read_envelope {    #{{{

}    #}}}

sub read_envelope_chunk {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $deserializer = __PACKAGE__->get_deserializer();
    switch ($first_bit) {
        case /[\x4f\x50\x70-\x7f\x80-\x8f]/ {

        }
    }
}    #}}}

sub read_packet {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $deserializer = __PACKAGE__->get_deserializer();

    switch ($first_bit) {
        case /\x4f/ {
        }
        case /\x50/ {
        }
        case /[\x70-\x7f]/ {
        }
        case /[\x80-\x8f]/ {
        }
    }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Envelope - Translate envelope level Hessian syntax

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


