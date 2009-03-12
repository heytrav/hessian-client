package Hessian::Translator::V1;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

use Switch;
use YAML;
use Hessian::Exception;
use Hessian::Simple;

has 'string_chunk_prefix'       => ( is => 'ro', isa => 'Str', default => 's' );
has 'string_final_chunk_prefix' => ( is => 'ro', isa => 'Str', default => 'S' );

sub read_composite_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $datastructure, $save_reference );
    switch ($first_bit) {
        case /\x72/ {
            $datastructure = $self->read_remote_object();
        }
        case /[\x56\x76]/ {    # typed lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list($first_bit);
        }
        case /\x4d/ {          # typed map
            push @{ $self->reference_list() }, {
            };
            $datastructure = $self->read_map_handle();
        }
        case /[\x4f\x6f]/ {    # object definition or reference
            push @{ $self->reference_list() }, {
            };
            $datastructure = $self->read_class_handle( $first_bit, );
        }
    }
    return $datastructure;

}    #}}}

sub read_remote_object {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $remote_type  = $self->read_v1_type()->{type};
    $remote_type =~ s/\./::/g;
    my $class_definition = {
        type   => $remote_type,
        fields => ['remote_url']
    };
    return $self->assemble_class(
        {
            type      => $remote_type,
            data      => {},
            class_def => $class_definition
        }
    );
}    #}}}

sub read_class_handle {    #{{{

    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $save_reference, $datastructure );
    switch ($first_bit) {
        case /\x4f/ {      # Read class definition
            my $class_name_length = $self->read_hessian_chunk();
            my $class_type;
            read $input_handle, $class_type, $class_name_length;

            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            $datastructure = $self->store_class_definition($class_type);
        }
        case /\x6f/ {    # The class definition is in the ref list
            $save_reference = 1;
            $datastructure  = $self->fetch_class_for_data();
        }
    }

    return $datastructure;
}    #}}}

sub read_simple_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $element;
    switch ($first_bit) {
        case /\x00/ {
            $element = $self->read_hessian_chunk();
        }
        case /\x4e/ {              # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {        # 'T'rue or 'F'alse
            $element = $self->read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xaf\xc0-\xcf\xd0-\xd7]/ {
            $element = $self->read_integer_handle_chunk($first_bit);
        }
        case /[\x4c\xd8-\xef\xf0-\xff\x38-\x3f]/ {
            $element = $self->read_long_handle_chunk($first_bit);
        }
        case /\x44/ {
            $element = $self->read_double_handle_chunk($first_bit);
        }
        case /\x64/ {
            $element = $self->read_date_handle_chunk($first_bit);
        }
        case /[\x53\x58\x73\x78\x00-\x0f]/ {    #   for version 1: \x73
            $element = $self->read_string_handle_chunk($first_bit);
        }
        case /[\x42\x62]/ {
            $element = $self->read_binary_handle_chunk($first_bit);
        }
        case /[\x4d\x4f\x56\x6f\x72\x76]/ {     # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        case /\x52/ {
            my $reference_id = $self->read_integer_handle_chunk('I');
            $element = $self->reference_list()->[$reference_id];
        }
        case /[\x48\x6d]/ {                     # a header or method name
            $element = $self->read_string_handle_chunk('S');
        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

}    #}}}

sub read_list_type {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $type_length;
    read $input_handle, $type_length, 1;
    my $type = $self->read_string_handle_chunk( $type_length, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $type;
}    #}}}

sub write_hessian_hash {    #{{{
    my ( $self, $datastructure ) = @_;
    my $anonymous_map_string = "M";    # start an anonymous hash
    foreach my $key ( keys %{$datastructure} ) {
        my $hessian_key   = $self->write_scalar_element($key);
        my $value         = $datastructure->{$key};
        my $hessian_value = $self->write_hessian_chunk($value);
        $anonymous_map_string .= $hessian_key . $hessian_value;
    }
    $anonymous_map_string .= "z";
    return $anonymous_map_string;
}    #}}}

#sub write_hessian_array {    #{{{
#    my ( $self, $datastructure ) = @_;
#    my $anonymous_array_string = "V";
#    foreach my $element ( @{$datastructure} ) {
#        my $hessian_element = $self->write_hessian_chunk($element);
#        $anonymous_array_string .= $hessian_element;
#    }
#    $anonymous_array_string .= "z";
#    return $anonymous_array_string;
#}    #}}}

sub write_hessian_string {    #{{{
    my ( $self, $chunks ) = @_;
    return $self->write_string( { chunks => $chunks } );

}    #}}}

sub write_hessian_date {    #{{{
    my ( $self, $datetime ) = @_;
#    my $epoch = $datetime->epoch();
    return $self->write_date( $datetime, );
}    #}}}

sub write_hessian_call {    #{{{
    my ( $self, $datastructure ) = @_;
    my $hessian_call   = "c\x01\x00";
    my $method         = $datastructure->{method};
    my $hessian_method = $self->write_scalar_element($method);
    $hessian_method =~ s/^S/m/;
    $hessian_call .= $hessian_method;
    my $arguments = $datastructure->{arguments};
    foreach my $argument ( @{$arguments} ) {
        my $hessian_arg = $self->write_hessian_chunk($argument);
        $hessian_call .= $hessian_arg;
    }
    $hessian_call .= "z";
    return $hessian_call;
}    #}}}

sub write_object { #{{{
    my ($self , $datastructure) = @_;
    my $type = ref $datastructure;
    my $hessian_string = "\x4d";
    my $hessian_type = $self->write_scalar_element($type);
    $hessian_type =~ s/^S/t/;
    $hessian_string .= $hessian_type;
    my @fields = keys %{$datastructure};
    foreach my $field (@fields) {
        my $hessian_field = $self->write_scalar_element($field);
        my $value = $datastructure->{$field};
        my $hessian_value = $self->write_hessian_chunk($value);
        $hessian_string .= $hessian_field . $hessian_value;
    }
    $hessian_string .= "z";
    return $hessian_string;

} #}}}

sub write_referenced_data  { #{{{
    my ( $self, $index) = @_;
    my $hessian_string = "R";
    # Bypass write integer for now
    my $new_int = pack 'N', $index;
    $hessian_string .= $new_int;
    return $hessian_string;
} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::V1 - Translate datastructures to and from Hessian 1.0.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 read_class_handle

Read a class definition from the Hessian stream and possibly create an object
from the definition and given parameters.

=head2 read_composite_data

Read Hessian 1.0 specific datastructures from the stream.

=head2 read_list_type

Read the I<type> attribute of a Hessian 1.0 typed list

=head2 read_remote_object


=head2 read_simple_datastructure

=over 2

=item
string

=item
integer

=item
long

=item
double

=item
boolean

=item
null


=back

=head2 write_hessian_date

Writes a L<DateTime|DateTime> object into the outgoing Hessian message. 

=head2 write_hessian_hash

Writes a HASH reference into the outgoing Hessian message.

=head2 write_hessian_string


Writes a string scalar into the outgoing Hessian message.

=head2 write_hessian_call

=head2 write_object

Serialize an object into a Hessian 1.0 string.

=head2 write_referenced_data

Write a referenced datastructure into a Hessian 1.0 string.
