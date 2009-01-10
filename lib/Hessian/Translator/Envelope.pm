package Hessian::Translator::Envelope;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

requires qw/deserialize_data/;

use Switch;
use YAML;
use Contextual::Return;

use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Hessian::Exception;

# Version 2 specific
sub read_message_chunk {   #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my ( $first_bit, $element );
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1
      or EndOfInput->throw( error => "Reached end of input" );
    EndOfInput->throw( error => "Encountered end of datastructure." )
      if $first_bit =~ /z/i;
    my $datastructure;
    switch ($first_bit) {
        case /\x48/ {       # TOP with version
            my $hessian_version = $self->read_version();
            $datastructure = { hessian_version => $hessian_version };
        }
#        case /\x43/ {       # Hessian Remote Procedure Call
#             # call will need to be dispatched to object designated in some kind of
#             # service descriptor
#            $datastructure =
#              "Server side remote procedure " . "calls not implemented.";
#        }
        case /\x45/ {    # Envelope
            $datastructure = $self->read_envelope();

        }
        case /\x46/ {    # Fault
            my $result                = $self->deserialize_data();
            my $exception_name        = $result->{code};
            my $exception_description = $result->{message};
            $datastructure =
              $exception_name->new( error => $exception_description );
        }
#        case /\x66/ {    # version 1 fault
#            $self->is_version_1(1);
#            my @tokens;
#            while ( my $token = $self->deserialize_data() ) {
#                push @tokens, $token;
#            }
#            my $exception_name        = $tokens[1];
#            my $exception_description = $tokens[3];

#        }
#        case /\x72/ {    # version 1 reply
#            $self->is_version_1(1);
#            my $hessian_version = $self->read_version();
#            $datastructure =
#              { hessian_version => $hessian_version, state => 'reply' };
#        }
        case /\x52/ {    # Reply
            my $reply_data = $self->deserialize_data();
            $datastructure = { reply_data => $reply_data };
        }
        else {
            $datastructure =
              $self->deserialize_data( { first_bit => $first_bit } );
        }
    }
    return $datastructure;
}    #}}}

sub read_version {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $version;
    read $input_handle, $version, 2;
    my @values = unpack 'C*', $version;
    my $hessian_version = join "." => @values;
    return $hessian_version;

}    #}}}

# Version 2 specific
sub read_envelope {    #{{{
    my $self = shift;
    my ( $first_bit, @chunks );
    my $input_handle = $self->input_handle();
    read $input_handle, $first_bit, 1;
    EndOfInput::X->throw( error => 'End of datastructure.' )
      if $first_bit =~ /z/i;

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
            push @headers, $self->read_header_or_footer();
        }

      PACKETCHUNKS: {
            read $input_handle, $first_bit, 1;
            my $length = unpack "C*", $first_bit;
            $packet_size =
                $first_bit =~ /[\x70-\x7f]/
              ? $length - 0x70
              : $length - 0x80;
            my $packet = $self->read_packet($packet_size);
            push @packets, $packet;

            last PACKETCHUNKS if $first_bit =~ /[\x80-\x8f]/;
            redo PACKETCHUNKS;
        }

        read $input_handle, $first_bit, 1;
        $footer_count = read_integer_handle_chunk( $first_bit, $input_handle );
        foreach ( 1 .. $footer_count ) {
            push @footers, $self->read_header_or_footer();
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

# Version 2 specific
sub read_header_or_footer {    #{{{
    my $self = shift;

    my $input_handle = $self->input_handle();
    my $first_bit;
    read $input_handle, $first_bit, 1;
    my $header = read_string_handle_chunk( $first_bit, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $header;
}    #}}}

# Version 2 specific
sub read_envelope_chunk {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    switch ($first_bit) {
        case /[\x4f\x50\x70-\x7f\x80-\x8f]/ {    # packet

        }
    }
}    #}}}

# Version 2 specific
sub read_packet {    #{{{
    my ( $self, $packet_size ) = @_;
    my $input_handle = $self->input_handle();
    my $packet_string;
    read $input_handle, $packet_string, $packet_size;
    return FIXED NONVOID {
        $self->deserialize_message({ input_string => $packet_string });
    };
}    #}}}

sub deserialize_message {    #{{{
    my ( $self, $args ) = @_;
    my $result;
    eval { $result = $self->read_message_chunk(); };
    return if Exception::Class->caught('EndOfInput::X');
    return $result;
}    #}}}

sub next_token {    #{{{
    my $self = shift;
    return $self->deserialize_message();
}    #}}}

sub process_message {    #{{{
    my $self = shift;
    my @tokens;
    while ( my $token = $self->next_token() ) {
        push @tokens, $token;
    }
    return \@tokens;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Envelope - Translate envelope level Hessian syntax

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


