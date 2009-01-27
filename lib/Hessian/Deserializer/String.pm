package  Hessian::Deserializer::String;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

use Switch;

sub read_string_handle_chunk  {    #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my ( $string, $data, $length );
    switch ($first_bit) {
        case /[\x00-\x1f]/ {
            $length = unpack "n", "\x00" . $first_bit;
        }
        case /[\x30-\x33]/ {
            read $input_handle, $data, 1;
            $length = unpack "n", $first_bit . $data;
        }
        case /[\x52-\x53\x73]/ {
            read $input_handle, $data, 2;
            $length = unpack "n", $data;
        }
    }
 
    binmode( $input_handle, 'utf8' );
    read $input_handle, $string, $length;
    return $string;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::String - Methods for serialization of strings

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 read_string_handle_chunk
