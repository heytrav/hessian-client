package Hessian::Translator::Composite;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

with 'Hessian::Translator::Envelope';

use Switch;
use YAML;
use Hessian::Exception;
use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Hessian::Translator::Date qw/:input_handle/;
use Hessian::Translator::Binary qw/:input_handle/;
use Simple;

sub read_list {    #{{{
    my $hessian_list = shift;
    my $array        = [];
    if ( $hessian_list =~ /^  \x57  (.*)  Z/xms ) {
        $array = read_variable_untyped_list($1);
    }

    return $array;
}    #}}}

sub write_list {    #: Export(:to_hessian) {    #{{{
    my $list = shift;
}    #}}}

sub read_typed_list_element {    #{{{
    my ( $self, $type, $args ) = @_;
    my $input_handle = $self->input_handle();
    my ( $element, $first_bit );
    binmode( $input_handle, 'bytes' );
    if ( $args->{first_bit} ) {
        $first_bit = $args->{first_bit};
    }
    else {
        read $input_handle, $first_bit, 1;
    }
    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit =~ /z/i;
    my $map_type = 'map';
    switch ($type) {
        case /boolean/ {
            $element = read_boolean_handle_chunk($first_bit);
        }
        case /int/ {
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }
        case /long/ {
            $element = read_long_handle_chunk( $first_bit, $input_handle );
        }
        case /double/ {
            $element = read_double_handle_chunk( $first_bit, $input_handle );
        }
        case /date/ {
            $element = read_date_handle_chunk( $first_bit, $input_handle );
        }
        case /string/ {
            $element = read_string_handle_chunk( $first_bit, $input_handle );
        }
        case /binary/ {
            $element = read_binary_handle_chunk( $first_bit, $input_handle );
        }
        case /list/ {
            $element = $self->read_composite_datastructure($first_bit);
        }
    }
    return $element;
}    #}}}

sub read_list_type {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $type_length;
    read $input_handle, $type_length, 1;
    my $type = read_string_handle_chunk( $type_length, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $type;
}    #}}}

sub store_fetch_type {    #{{{
    my ( $self, $entity_type ) = @_;
    my $type;
    if ( $entity_type =~ /^([^\x00-\x0f].*)/ ) {
        $type = $1;
        push @{ $self->type_list() }, $type;
    }
    else {
        my $integer = unpack 'C*', $entity_type;
        $type = $self->type_list()->[$integer];

    }
    return $type;
}    #}}}

sub store_class_definition {    #{{{
    my ( $self, $class_type ) = @_;
    my $input_handle = $self->input_handle();
    my $length;
    read $input_handle, $length, 1;
    my $number_of_fields = read_integer_handle_chunk( $length, $input_handle );
    my @field_list;

    foreach my $field_index ( 1 .. $number_of_fields ) {

        # using the wrong function here, but who cares?
        my $field = $self->read_hessian_chunk();
        push @field_list, $field;

    }

    my $class_definition = { type => $class_type, fields => \@field_list };
    push @{ $self->class_definitions() }, $class_definition;
    return $class_definition;
}    #}}}

sub fetch_class_for_data {    #{{{
    my $self = shift;
    my $input_handle = $self->input_handle();
    my $length;
    read $input_handle, $length, 1;
    my $class_definition_number =
      read_integer_handle_chunk( $length, $input_handle );
    return $self->instantiate_class($class_definition_number);

}    #}}}

sub instantiate_class {    #{{{
    my ( $self, $index ) = @_;
    my $class_definitions = $self->class_definitions;
    my $class_definition  = $self->class_definitions()->[$index];
    my $datastructure     = $self->reference_list()->[-1];
    my $class_type        = $class_definition->{type};
    return $self->assemble_class(
        {
            class_def => $class_definition,
            data      => $datastructure,
            type      => $class_type
        }
    );
}    #}}}

sub assemble_class {    #{{{
    my ( $self, $args ) = @_;
    my ( $class_definition, $datastructure, $class_type ) =
      @{$args}{qw/class_def data type/};
    my $simple_obj = bless $datastructure, $class_type;
    {
        ## no critic
        no strict 'refs';
        push @{ $class_type . '::ISA' }, 'Simple';
        ## use critic
    }
    foreach my $field ( @{ $class_definition->{fields} } ) {
        $simple_obj->meta()->add_attribute( $field, is => 'rw' );
        my $value = $self->deserialize_data();
        $simple_obj->$field($value);
    }
    return $simple_obj;

}    #}}}

sub read_list_length {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();

    my $array_length;
    if ( $first_bit =~ /[\x56\x58]/ ) {    # read array length
        my $length;
        read $input_handle, $length, 1;
        $array_length = read_integer_handle_chunk( $length, $input_handle );
    }
    elsif ( $first_bit =~ /[\x70-\x77]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x70;
    }
    elsif ( $first_bit =~ /[\x78-\x7f]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x78;
    }
    elsif ( $first_bit =~ /\x6c/ ) {
        $array_length = read_integer_handle_chunk( 'I', $input_handle );
        print "received array length of $array_length\n";
    }
    return $array_length;
}    #}}}

sub read_hessian_chunk {    #{{{
    my ( $self, $args ) = @_;
    my $input_handle = $self->input_handle();
    binmode( $input_handle, 'bytes' );
    my ( $first_bit, $element );
    if ( 'HASH' eq ( ref $args ) and $args->{first_bit} ) {
        $first_bit = $args->{first_bit};
    }
    else {
        read $input_handle, $first_bit, 1;
    }

    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit =~ /z/i;

    return $self->read_simple_datastructure($first_bit);
}    #}}}

sub read_composite_datastructure { #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    binmode( $input_handle, 'bytes' );
   return $self->read_composite_data($first_bit); 
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




