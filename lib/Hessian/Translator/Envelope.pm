package Hessian::Translator::Envelope;

use Moose::Role;

use Switch;
use YAML;
use Contextual::Return;
use List::MoreUtils qw/any/;
use Hessian::Exception;

# Experimental. Regulates the size of an average packet.
has 'max_packet_size' => ( is => 'ro', isa => 'Int', default => 15 );

sub read_message_chunk_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $datastructure;
    switch ($first_bit) {
        case /\x45/ {            # Envelope
            $self->set_current_position(-1);
            my $file_handle_pos = tell $input_handle;
            my $hessian_version = $self->read_version();
            $datastructure = {
                hessian_version => $hessian_version,
                envelope        => $self->read_envelope()
            };
        }
        case /\x63/ {
            my $hessian_version = $self->read_version();
            my $rpc_data        = $self->read_rpc();
            $datastructure = {
                hessian_version => $hessian_version,
                call            => $rpc_data
            };
        }
        case /\x66/ {
            my @tokens;
            eval {
                while ( my $token = $self->deserialize_data() )
                {
                    push @tokens, $token;
                }
            };
            if ( Exception::Class->caught('EndOfInput::X') ) {
                my $exception_name        = $tokens[1];
                my $exception_description = $tokens[3];
                $exception_name->throw( error => $exception_description );
            }
        }
        case /\x70/ {    # read packet
            my $hessian_version = $self->read_version();
            $datastructure = $self->read_packet();
        }
        case /\x72/ {
            my $hessian_version = $self->read_version();
            $datastructure =
              { hessian_version => $hessian_version, state => 'reply' };
        }
        else {
            my $param = { first_bit => $first_bit };
            $datastructure = $self->deserialize_data($param);
        }
    }
    return $datastructure;

}    #}}}

sub read_message_chunk {    #{{{
    my $self = shift;
    my ($element);
    my $first_bit = $self->read_from_inputhandle(1)
      or EndOfInput->throw( error => "Reached end of input" );
    EndOfInput->throw( error => "Encountered end of datastructure." )
      if $first_bit =~ /z/i;
    my $datastructure = $self->read_message_chunk_data($first_bit);
    return $datastructure;
}    #}}}

sub read_version {    #{{{
    my $self = shift;

    #    my $input_handle = $self->input_handle();
    my $version = $self->read_from_inputhandle(2);

    #    read $input_handle, $version, 2;

    my @values = unpack 'C*', $version;
    my $hessian_version = join "." => @values;
    return $hessian_version;

}    #}}}

sub read_envelope {    #{{{
    my $self = shift;
    my ( $packet_body, @chunks );
    my $input_handle = $self->input_handle();
    my $first_bit    = $self->read_from_inputhandle(1);
    EndOfInput::X->throw( error => 'End of datastructure.' )
      if $first_bit =~ /z/i;

    my $method_string;
    $method_string = $self->read_string_handle_chunk('S')
      if $first_bit eq 'm';

    binmode( $input_handle, 'bytes' );
  ENVELOPECHUNKS: {
        my ( $header_count, $footer_count, $packet_size );
        my ( @headers,      @footers,      @packets );
        $first_bit = $self->read_from_inputhandle(1);
        last ENVELOPECHUNKS if $first_bit =~ /z/i;
        $header_count = $self->read_integer_handle_chunk( $first_bit, );

      PROCESSHEADERS: {
            last PROCESSHEADERS unless $header_count;
            foreach ( 1 .. $header_count ) {
                push @headers, $self->read_header_or_footer();
            }
        }

        my $body                 = $self->deserialize_message();
        my $file_handle_location = tell $input_handle;
        $body =~ s/^p\x02\x00(.*)z$/$1/;
        $packet_body .= $body;

        $first_bit    = $self->read_from_inputhandle(1);
        $footer_count = $self->read_integer_handle_chunk( $first_bit, );
      PROCESSFOOTERS: {
            last PROCESSFOOTERS unless $footer_count;
            foreach ( 1 .. $footer_count ) {
                push @footers, $self->read_header_or_footer();
            }
        }
        push @chunks,
          {
            headers => \@headers,
            footers => \@footers
          };
        redo ENVELOPECHUNKS;
    }
    my $message_body = $self->read_body($packet_body);
    return { packet => $message_body, meta => \@chunks };
}    #}}}

sub read_rpc {    #{{{
    my $self = shift;

    #    my $input_handle = $self->input_handle();
    my $call_data = {};
    my $call_args;
    my $in_header;
  RPCSTRUCTURE: {

        #        my $first_bit;
        my $first_bit = $self->read_from_inputhandle(1);

        #        read $input_handle, $first_bit, 1;
        last RPCSTRUCTURE unless $first_bit;
        last RPCSTRUCTURE if $first_bit eq 'z';
        my $element;
        eval {
            $element = $self->read_hessian_chunk( { first_bit => $first_bit } );
        };
        last RPCSTRUCTURE if Exception::Class->caught('EndOfInput::X');
        switch ($first_bit) {
            case /\x6d/ {
                $in_header = 0;
                $call_data->{method} = $element;
            }
            case /\x48/ {
                $in_header = 1;
                push @{ $call_data->{headers} }, { header => $element };
            }

            else {
                if ($in_header) {
                    push @{ $call_data->{headers}->[-1]->{elements} }, $element;
                }
                else {
                    push @{$call_args}, $element;
                }
            }
        }
        redo RPCSTRUCTURE;
    }
    $call_data->{arguments} = $call_args;
    return $call_data;
}    #}}}

sub read_header_or_footer {    #{{{
    my $self = shift;

    #    my $input_handle = $self->input_handle();
    #    my $first_bit;
    my $first_bit = $self->read_from_inputhandle(1);

    #    read $input_handle, $first_bit, 1;
    my $header = $self->read_string_handle_chunk($first_bit);

    #    binmode( $input_handle, 'bytes' );
    return $header;
}    #}}}

sub read_body {    #{{{
    my ( $self, $body_string ) = @_;
    return FIXED NONVOID {
        $self->input_string($body_string);
        $self->process_message();
    };
}    #}}}

sub write_hessian_envelope {    #{{{
    my ( $self, $envelope ) = @_;
    my $meta = 'Identity';
    $meta = delete $envelope->{meta} if exists $envelope->{meta};
    my $headers         = delete $envelope->{headers};
    my $footers         = delete $envelope->{footers};
    my $envelope_string = "E\x02\x00";
    my $envelope_meta   = $self->write_hessian_string( [$meta] );
    $envelope_meta =~ s/S/m/;
    $envelope_string .= $envelope_meta;
    my $header_count = $self->write_integer( scalar @{$headers} );
    my $footer_count = $self->write_integer( scalar @{$footers} );

    my $serialized_message = $self->write_hessian_message($envelope);
    my $max_packet_size    = $self->max_packet_size() - 4;
    my @packets = $serialized_message =~ /([\x00-\xff]{1,$max_packet_size})/g;
    my @packaged_packets;
    @packaged_packets = map { "p\x02\x00" . $_ . "z" } @packets
      if scalar @packets > 1;
    my @body_chunks;
    foreach my $packet (@packaged_packets) {
        push @body_chunks, $self->write_binary($packet);
    }

    my @wrapped_body = map { $header_count . $_ . $footer_count } @body_chunks;

    $envelope_string .= join "" => @wrapped_body;
    $envelope_string .= 'z';
    return $envelope_string;
}    #}}}

sub write_hessian_message {    #{{{
    my ( $self, $hessian_data ) = @_;

    my $hessian_message;
    if ( ( ref $hessian_data ) eq 'HASH'
        and any { exists $hessian_data->{$_} } qw/data call envelope packet/ )
    {
        my @keys          = keys %{$hessian_data};
        my $datastructure = $hessian_data->{ $keys[0] };
        switch ( $keys[0] ) {
            case /call/ {
                $hessian_message = $self->write_hessian_call($datastructure);
            }
            case /envelope/ {
                $hessian_message =
                  $self->write_hessian_envelope($datastructure);
            }
            case /reply/ {

            }
            case /data/ {
                $hessian_message = $self->write_hessian_chunk($datastructure);

            }
        }
    }
    else {
        $hessian_message = $self->write_hessian_chunk($hessian_data);
    }
    return $hessian_message;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Envelope - Translate envelope level Hessian syntax


=head1 SYNOPSIS

These methods are meant for internal use only.

=head1 DESCRIPTION

This module implements methods necessary for processing the packaging of
Hessian messages. This includes components of Hessian messages like envelopes
and packets (mainly relevant for Hessian 2.0) as well as I<call> and
I<reply> elements.


=head1 INTERFACE

=head2 read_message_chunk_data

Read Hessian I<wrapper> level message components.  For version 1.0 of the
protocol this mainly applies to I<reply>, I<call> and I<fault> objects. For
version 2.0 this applies to the envelope and any nested I<call>, I<reply> or
I<fault> entities.

=head2 next_token


=head2 read_rpc

Read a remote procedure call from the input stream.


=head2 read_envelope

This method is starting point for processing Hessian version 2.0 messages.
An enveloped message is passed to this subroutine to be broken down in to its
components.

=head2 read_header_or_footer

Read the contents of a header or footer for a message chunk.

=head2 read_message_chunk

=head2 read_version

Reads the version of the message.

=head2 write_hessian_message

Writes a datastructure as a hessian message.

=head2 write_hessian_packet

Write a subset of hessian data out as a packet.

=head2 write_hessian_envelope

Write a datastructure into a Hessian serialized message.

This method is called internally if the datastructure passed to
L<Hessian::Serializer|Hessian::Serializer/"serialize_message"> contains hash
with the key I<envelope> pointing to a nested hash datastructure.  The nested
datastructure may vary.

Here are two examples of datastructures that will be passed to the
I<write_hessian_envelope> method:


In this case, the envelope points to a RPC for the method I<hello> and a
signle argument "hello, world".

    my $datastructure = {
        envelope => {
            call => {
                method    => 'hello',
                arguments => ['hello, world']
            },
            meta    => 'Identity',
            headers => [],
            footers => []
        }
    };


In the second example, the envelope wraps some basic data which could
represent any datastructure.

    my $datastructure2 = {
        envelope => {
            data    => "Lorem ipsum dolor sit amet, consectetur adipisicing",
            meta    => 'Identity',
            headers => [],
            footers => []
        }
    };

=head2 read_body

Read the binary wrapped body of a Hessian envelope.
