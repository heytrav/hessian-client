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
use Hessian::Translator::Composite qw/:input_handle/;
use Hessian::Exception;

sub read_message_chunk : Export(:deserialize) {    #{{{
    my ( $input_handle, $deserializer_obj ) = @_;
    my $deserializer = $deserializer_obj;
    $deserializer =
      $deserializer
      ? __PACKAGE__->set_deserializer($deserializer)
      : __PACKAGE__->get_deserializer();
    my ( $first_bit, $element );
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1
      or EndOfInput->throw( error => "Reached end of input" );
    EndOfInput->throw( error => "Encountered end of datastructure." )
      if $first_bit =~ /z/i;
    my $datastructure;
    switch ($first_bit) {
        case /\x48/ {    # TOP with version
            my $hessian_version = read_version($input_handle);
            $datastructure = { hessian_version => $hessian_version };
        }
        case /\x43/ {    # Hessian Remote Procedure Call
             # call will need to be dispatched to object designated in some kind of
             # service descriptor
            $datastructure =
              "Server side remote procedure " . "calls not implemented.";
        }
        case /\x45/ {    # Envelope
            $datastructure = read_envelope($input_handle);

        }
        case /\x46/ {    # Fault
            my $result                = $deserializer->deserialize_data();
            my $exception_name        = $result->{code};
            my $exception_description = $result->{message};
            $datastructure =
              $exception_name->new( error => $exception_description );
        }
        case /\x66/ {    # version 1 fault
            $deserializer->is_version_1(1);
            my @tokens;
            while ( my $token = $deserializer->deserialize_data() ) {
                push @tokens, $token;
            }
            my $exception_name        = $tokens[1];
            my $exception_description = $tokens[3];

        }
        case /\x72/ {    # version 1 reply
            $deserializer->is_version_1(1);
            my $hessian_version = read_version($input_handle);
            $datastructure =
              { hessian_version => $hessian_version, state => 'reply' };
        }
        case /\x52/ {    # Reply
            my $reply_data = $deserializer->deserialize_data();
            $datastructure = { reply_data => $reply_data };
        }
        else {
            print "Processing datastructure...\n";
            $datastructure =
              $deserializer->deserialize_data( { first_bit => $first_bit } );
        }
    }
    return $datastructure;
}    #}}}

sub read_version {    #{{{
    my ($input_handle) = @_;
    my $version;
    read $input_handle, $version, 2;
    my @values = unpack 'C*', $version;
    my $hessian_version = join "." => @values;
    return $hessian_version;

}    #}}}

sub read_envelope {    #{{{
    my ($input_handle) = @_;
    my ( $first_bit, @chunks );
    read $input_handle, $first_bit, 1;
    EndOfInput::X->throw(error => 'End of datastructure.') if $first_bit eq 'Z';

    # Just the word "Header" as far as I understand
    my $header_string = read_string_handle_chunk( $first_bit, $input_handle );
    binmode( $input_handle, 'bytes' );
  ENVELOPECHUNKS: {
        my ( $header_count, $footer_count, $packet_size );
        my ( @headers,      @footers,      @packets );
        read $input_handle, $first_bit, 1;
        last ENVELOPECHUNKS if $first_bit =~ /z/i;
        $header_count = read_integer_handle_chunk( $first_bit, $input_handle );
        foreach ( 1 .. $header_count ) {
            push @headers, read_header_or_footer($input_handle);
        }

      PACKETCHUNKS: {
            read $input_handle, $first_bit, 1;
            my $length = unpack "C*", $first_bit;
            $packet_size =
                $first_bit =~ /[\x70-\x7f]/
              ? $length - 0x70
              : $length - 0x80;
            my $packet = read_packet( $packet_size, $input_handle );
            push @packets, $packet;

            last PACKETCHUNKS if $first_bit =~ /[\x80-\x8f]/;
            redo PACKETCHUNKS;
        }

        read $input_handle, $first_bit, 1;
        $footer_count = read_integer_handle_chunk( $first_bit, $input_handle );
        foreach ( 1 .. $footer_count ) {
            push @footers, read_header_or_footer($input_handle);
        }
        push @chunks,
          {
            headers => \@headers,
            packets => \@packets,
            footers => \@footers
          };
        redo ENVELOPECHUNKS;
    }
    return \@chunks;

}    #}}}

sub read_header_or_footer {    #{{{
    my $input_handle = shift;
    my $first_bit;
    read $input_handle, $first_bit, 1;
    my $header = read_string_handle_chunk( $first_bit, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $header;
}    #}}}

sub read_envelope_chunk {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $deserializer = __PACKAGE__->get_deserializer();
    switch ($first_bit) {
        case /[\x4f\x50\x70-\x7f\x80-\x8f]/ {    # packet

        }
    }
}    #}}}

sub read_packet {    #{{{
    my ( $packet_size, $input_handle ) = @_;
    my $packet_string;
    read $input_handle, $packet_string, $packet_size;
    my $deserializer = __PACKAGE__->get_deserializer();
    my $deserialized =
        $packet_string =~ /^[\x00-\x3f\x44\x46\x48-\x4f\x53-\x59]/
      ? $deserializer->deserialize_data( { input_string => $packet_string } )
      : $deserializer->deserialize_message(
        { input_string => $packet_string } );
    return $deserialized;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Envelope - Translate envelope level Hessian syntax

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


