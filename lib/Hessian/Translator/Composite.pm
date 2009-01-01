package Hessian::Translator::Composite;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Hessian::Translator::Message';

use Perl6::Export::Attrs;
use Switch;
use YAML;
use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Hessian::Translator::Date qw/:input_handle/;
use Hessian::Translator::Binary qw/:input_handle/;

sub read_list : Export(:from_hessian) {    #{{{
    my $hessian_list = shift;
    my $array        = [];
    if ( $hessian_list =~ /^  \x57  (.*)  Z/xms ) {
        $array = read_variable_untyped_list($1);
    }

    return $array;
}    #}}}

sub write_list : Export(:to_hessian) {    #{{{
    my $list = shift;
}    #}}}

sub read_composite_datastructure : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $datastructure, $save_reference );
    my $deserializer = __PACKAGE__->get_deserializer();
    switch ($first_bit) {
        case /[\x55\x56\x70-\x77]/ {                          # typed lists
            $save_reference = 1;
            $datastructure = read_typed_list( $first_bit, $input_handle );
        }

        case /[\x57\x58\x78-\x7f]/ {                          # untyped lists
            $save_reference = 1;
            $datastructure = read_untyped_list( $first_bit, $input_handle );
        }
        case /\x48/ {
            $save_reference = 1;
            $datastructure  = read_map_handle($input_handle);
        }
        case /\x4d/ {                                         # typed map

            $save_reference = 1;

            # Get the type for this map. This seems to be more like a
            # perl style object or "blessed hash".
            my $map_type = read_hessian_chunk($input_handle);
            if ( $map_type !~ /^\d+$/ ) {
                push @{ $deserializer->type_list() }, $map_type;
            }
            else {
                $map_type = $deserializer->type_list()->[$map_type];
            }
            my $map = read_map_handle($input_handle);
            $datastructure = bless $map, $map_type;

        }
        case /[\x43\x4f\x60-\x6f]/ {
            $datastructure = read_class_handle( $first_bit, $input_handle );

        }
    }
    push @{ $deserializer->reference_list() }, $datastructure
      if $save_reference;
    return $datastructure;

}    #}}}

sub read_typed_list {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $type = read_hessian_chunk($input_handle);
    my $array_length = read_list_length( $first_bit, $input_handle );

    my $datastructure = [];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element = read_typed_list_element( $type, $input_handle );
        last LISTLOOP if $first_bit =~ /\x55/ && $element eq 'Z';

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_class_handle {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $save_reference, $datastructure );
    my $deserializer = __PACKAGE__->get_deserializer();
    switch ($first_bit) {
        case /\x43/ {      # Read class definition
            my $class_type = read_hessian_chunk($input_handle);
            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            my $length;
            read $input_handle, $length, 1;
            my $number_of_fields =
              read_integer_handle_chunk( $length, $input_handle );
            my @field_list;
            foreach my $field_index ( 1 .. $number_of_fields ) {

                # using the wrong function here, but who cares?
                my $field = read_hessian_chunk($input_handle);
                push @field_list, $field;

            }

            my $class_definition =
              { type => $class_type, fields => \@field_list };
            push @{ $deserializer->class_definitions() }, $class_definition;
            $datastructure = $class_definition;
        }
        case /\x4f/ {    # Read hessian data and create instance of class
            my $length;
            $save_reference = 1;
            read $input_handle, $length, 1;
            my $class_definition_number =
              read_integer_handle_chunk( $length, $input_handle );
            $datastructure =
              $deserializer->instantiate_class($class_definition_number);

        }
        case /[\x60-\x6f]/ {    # The class definition is in the ref list
            $save_reference = 1;
            my $hex_bit = unpack 'C*', $first_bit;
            my $class_definition_number = $hex_bit - 0x60;
            $datastructure =
              $deserializer->instantiate_class($class_definition_number);
        }
    }
    push @{ $deserializer->reference_list() }, $datastructure
      if $save_reference;
    return $datastructure;
}    #}}}

sub read_map_handle {    #{{{
    my $input_handle = shift;

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        my $key = read_hessian_chunk($input_handle);
        last MAPLOOP if $key eq 'Z';
        my $value = read_hessian_chunk($input_handle);
        push @key_value_pairs, $key => $value;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements
    my $datastructure = {@key_value_pairs};
    return $datastructure;

}    #}}}

sub read_list_length {    #{{{
    my ( $first_bit, $input_handle ) = @_;

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
    return $array_length;
}    #}}}

sub read_untyped_list {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $array_length = read_list_length( $first_bit, $input_handle );

    my $datastructure = [];
    my $index         = 0;
  LISTLOOP:
    {
        last if $index == 10;
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element = read_hessian_chunk($input_handle);
        last LISTLOOP if $first_bit =~ /\x57/ && $element eq 'Z';

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_typed_list_element {    #{{{
    my ( $entity_type, $input_handle ) = @_;
    my ( $type, $element, $first_bit );
    my $deserializer = __PACKAGE__->get_deserializer();
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';
    my $map_type = 'map';

    if ( $entity_type !~ /^\d+$/ ) {
        $type = $entity_type;
        push @{ $deserializer->type_list() }, $type;

    }
    else {
        $type = $deserializer->type_list()->[$entity_type];
    }

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
            $element =
              read_composite_datastructure( $first_bit, $input_handle );
        }

        #        case /$map_type/ {

        #        }
    }
    return $element;
}    #}}}

sub read_hessian_chunk : Export(:deserialize) {    #{{{
    my ( $input_handle, $deserializer_obj ) = @_;
    my $deserializer = $deserializer_obj;
    $deserializer =
      $deserializer ? __PACKAGE__->set_deserializer($deserializer) :
      __PACKAGE__->get_deserializer();
    my ( $first_bit, $element );
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';

    switch ($first_bit) {
        case /\x4e/ {                              # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {                        # 'T'rue or 'F'alse
            $element = read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ {
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4c\x59\xd8-\xef\xf0-\xff\x38-\x3f]/ {
            $element = read_long_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x44\x5b-\x5f]/ {
            $element = read_double_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4a\x4b]/ {
            $element = read_date_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x52\x53\x00-\x1f\x30-\x33]/ {
            $element = read_string_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x41\x42\x20-\x2f\x34-\x37]/ {
            $element = read_binary_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x43\x4d\x4f\x48\x55-\x58\x60-\x6f\x70-\x7f]/
        {    # recursive datastructure
            $element =
              read_composite_datastructure( $first_bit, $input_handle );
        }
        case /\x51/ {
            my $reference_id = read_hessian_chunk($input_handle);
            $element = $deserializer->reference_list()->[$reference_id];

        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

}    #}}}

sub read_list_type {    #{{{
    my $input_handle = shift;
    my $type_length;
    read $input_handle, $type_length, 1;
    my $type = read_string_handle_chunk( $type_length, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $type;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




