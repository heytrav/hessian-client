package Hessian::Translator::V2;

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
        case /[\x56\x76]/ {    # lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list( $first_bit, );
        }
        case /\x4d/ {          # typed map
            push @{ $self->reference_list() }, {
            };

            # Get the type for this map. This seems to be more like a
            # perl style object or "blessed hash".

            my $map = $self->read_map_handle();
            $datastructure = $map;

        }
        case /[\x4f\x6f]/ {
            push @{ $self->reference_list() }, {
            }
            if $first_bit =~ /\x6f/;
            $datastructure = $self->read_class_handle( $first_bit, );

        }
    }

    return $datastructure;

}    #}}}

sub read_class_handle {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $save_reference, $datastructure );
    switch ($first_bit) {
        case /\x4f/ {      # Read class definition
            my $v1_type = $self->read_v1_type($first_bit);
            my ( $class_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            $datastructure = $self->store_class_definition($class_type);
        }
        case /\x6f/ {    # Read hessian data and create instance of class
            $save_reference = 1;
            $datastructure  = $self->fetch_class_for_data();
        }
    }
    push @{ $self->reference_list() }, $datastructure
      if $save_reference;
    return $datastructure;
}    #}}}

sub read_simple_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $element;
    switch ($first_bit) {
        case /\x4e/ {              # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {        # 'T'rue or 'F'alse
            $element = $self->read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ {
            $element = $self->read_integer_handle_chunk($first_bit);
        }
        case /[\x4c\x77\xd8-\xef\xf0-\xff\x38-\x3f]/ {
            $element = $self->read_long_handle_chunk($first_bit);
        }
        case /[\x44\x5b-\x5f]/ {
            $element = $self->read_double_handle_chunk($first_bit);
        }
        case /\x64/ {
            $element = $self->read_date_handle_chunk($first_bit);
        }
        case /[\x53\x00-\x1f\x73]/ {    #   for version 2: \x73
            $element = $self->read_string_handle_chunk($first_bit);
        }
        case /[\x42\x62\x20-\x2f]/ {
            $element = $self->read_binary_handle_chunk($first_bit);
        }
        case /[\x48\x6d]/ {             # a header or method name
            $element = $self->read_string_handle_chunk('S');
        }
        case /[\x43\x4d\x4f\x48\x55-\x58\x60-\x6f\x70-\x7f]/
        {                               # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        case /\x52/ {
            my $reference_id = $self->read_integer_handle_chunk('I');
            $element = $self->reference_list()->[$reference_id];

        }
        case /[\x4a\x4b]/ {
            my $hex_reference;
            read $input_handle, $hex_reference, 1;
            my $reference_id = unpack 'C*', $hex_reference;
            $element = $self->reference_list()->[$reference_id];

        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

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

sub write_hessian_string {    #{{{
    my ( $self, $chunks ) = @_;
    return $self->write_string( { chunks => $chunks } );

}    #}}}

sub write_hessian_date {    #{{{
    my ( $self, $datetime ) = @_;
    return $self->write_date($datetime);
}    #}}}

sub write_object {    #{{{
    my ( $self, $datastructure ) = @_;
    my $type              = ref $datastructure;
    my @class_definitions = @{ $self->class_definitions() };
    my ( $hessian_string, $class_already_stored );
    my $index = 0;
    foreach my $class_def (@class_definitions) {
        my $defined_type = $class_def->{type};
        if ( $defined_type eq $type ) {
            $class_already_stored = 1;
            last;
        }
        $index++;
    }
    my @fields = keys %{$datastructure};
    if ( not $class_already_stored ) {
        my $hessian_type = $self->write_scalar_element($type);
        $hessian_type =~ s/\x53/t/;
        $hessian_string = "\x4f" . $hessian_type;
        my $num_of_fields = scalar @fields;
        $hessian_string .= ( $self->write_scalar_element($num_of_fields) );
        foreach my $field (@fields) {
            my $hessian_field = $self->write_scalar_element($field);
            $hessian_string .= $hessian_field;
        }
        my $store_definition = { type => $type, fields => \@fields };
        push @{ $self->class_definitions() }, $store_definition;
        $index = ( scalar @{ $self->class_definitions } ) - 1;
    }
    $hessian_string .= "\x6f";
    $hessian_string .= ( $self->write_scalar_element($index) );
    foreach my $field (@fields) {
        my $value;
        eval { $value = $datastructure->$field(); };
        if ( my $e = $@ ) {
            $value = $datastructure->{$field} if $e =~ /locate\sobject\smethod/;
        }

        $hessian_string .= ( $self->write_scalar_element($value) );
    }
    return $hessian_string;
}    #}}}

sub write_referenced_data {    #{{{
    my ( $self, $index ) = @_;
    my $hessian_string = "\x51";
    my $hessian_index  = $self->write_scalar_element($index);
    $hessian_string .= $hessian_index;
    return $hessian_string;
}    #}}}

sub write_hessian_call {    #{{{
    my ( $self, $datastructure ) = @_;
    my $hessian_call   = "c\x02\x00";
    my $method         = $datastructure->{method};
    my $hessian_method = $self->write_scalar_element($method);
    $hessian_method =~ s/S/m/;
    $hessian_call .= $hessian_method;
    my $arguments = $datastructure->{arguments};
    foreach my $argument ( @{$arguments} ) {
        my $hessian_arg = $self->write_hessian_chunk($argument);
        $hessian_call .= $hessian_arg;
    }
    $hessian_call .= "z";
    return $hessian_call;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::V2 - Translate datastructures to and from Hessian 2.0.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


=head2 read_class_handle

Read a class definition from the Hessian stream and possibly create an object
from the definition and given parameters.

=head2 read_composite_data

Read Hessian 2.0 specific datastructures from the stream.

=head2 read_map_handle

Read a map (perl HASH) from the stream.

=head2 read_message_chunk_data

Read Hessian 2.0 envelope.  For version 2.0 of the protocol this applies to
I<envelope>, I<packet>, I<reply>, I<call> and I<fault> objects.


=head2 read_rpc

Read a remote procedure call from the input stream.

=head2 read_simple_datastructure

Read a scalar of one of the basic Hessian datatypes from the stream.  This can
be one of: 

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


=head2 read_typed_list

Read a Hessian 2.0 typed list.  Note that this is mainly for compatability
with other servers that are implemented in languages like Java where I<type>
is actually relevant.  

=head2 read_untyped_list

Read a list of arbitrarily typed entities.

=head2 write_hessian_array

Writes an array datastructure into the outgoing Hessian message. 

Note: This object only writes B<untyped variable length> arrays.

=head2 write_hessian_date

Writes a L<DateTime|DateTime> object into the outgoing Hessian message. 

=head2 write_hessian_hash

Writes a HASH reference into the outgoing Hessian message.

=head2 write_hessian_string

Writes a string scalar into the outgoing Hessian message.

=head2 write_hessian_call

Writes out a Hessian 2 specific remote procedure call

=head2 write_object

Serialize an object into a Hessian 1.0 string.

=head2 write_referenced_data

Write a referenced datastructure into a Hessian 1.0 string.
