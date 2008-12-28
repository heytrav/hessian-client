package Hessian::Translator::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Switch;

use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Hessian::Translator::Date qw/:input_handle/;
use Hessian::Translator::Binary qw/:input_handle/;
#use Template;

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

sub read_variable_untyped_list {    #{{{
    my $hessian_list = shift;

}    #}}}

sub read_complex_datastructure : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ($datastructure);
    switch ($first_bit) {
        case /[\x55\x56\x70-\x77]/ {                        # typed lists
            $datastructure = read_typed_list( $first_bit, $input_handle );
        }
        case /[\x57\x58\x78-\x7f]/ {                        # untyped lists
            $datastructure = read_untyped_list( $first_bit, $input_handle );
        }
        case /\x48/ {
            $datastructure = read_map_handle($input_handle);
        }
        case /\x4d/ {

            # Get the type for this map. This seems to be more like a
            # perl style object or "blessed hash".
            my $map_type = read_list_type($input_handle);
            my $map      = read_map_handle($input_handle);
            $datastructure = bless $map, $map_type;

        }
        case /[\x43\x4f\x60-\x6f]/ {
            $datastructure = read_class_handle( $first_bit, $input_handle );
        }
    }
    return $datastructure;

}    #}}}

sub read_typed_list {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my $type = read_list_type($input_handle);
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
    switch ($first_bit) {
        case /\x43/ {      # Read Class definition
            my $class_type = read_list_type($input_handle);
            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            my $length;
            read $input_handle, $length, 1;
            my $number_of_fields =
              read_integer_handle_chunk( $length, $input_handle );
            my @field_list;
            foreach my $field_index ( 1 .. $number_of_fields ) {

                # using the wrong function here, but who cares?
                my $field = read_list_type($input_handle);
                push @field_list, $field;

            }
            return { type => $class_type, fields => \@field_list};
        }
        case /\x4f/ {    # Read hessian data and create instance of class

        }
        case /[\x60-\x6f]/ {    # The class definition is in the ref list
            my $hex_bit = unpack 'C*', $first_bit;
            my $class_definition_number = $hex_bit - 0x60;
            return $class_definition_number;
        }
    }
}    #}}}

sub read_map_handle {    #{{{
    my $input_handle = shift;

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        my $key = read_untyped_list_element($input_handle);
        last MAPLOOP if $key eq 'Z';
        my $value = read_untyped_list_element($input_handle);
        push @key_value_pairs, $key => $value;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements
    my $datastructure = {@key_value_pairs};
    return $datastructure;

}    #}}}

sub read_untyped_map {    #{{{
    my ( $first_bit, $input_handle ) = @_;
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
        my $element = read_untyped_list_element($input_handle);
        last LISTLOOP if $first_bit =~ /\x57/ && $element eq 'Z';

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_typed_list_element {    #{{{
    my ( $type, $input_handle ) = @_;
    my $element;
    my $first_bit;
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';
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
        case /object/ { }
        case /list/ {
            $element = read_complex_datastructure( $first_bit, $input_handle );
        }
        case /$map_type/ {

        }
    }
    return $element;
}    #}}}

sub read_untyped_list_element :Export(:input_handle) {    #{{{
    my $input_handle = shift;
    my $element;
    my $first_bit;
    binmode( $input_handle, 'bytes' );
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';

    switch ($first_bit) {
        case /\x4e/ {  # 'N' for NULL
            $element = undef; 
            }
        case /[\x46\x54]/ {
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
        case /[\x55-\x58\x70-\x7f]/ {
            $element = read_complex_datastructure( $first_bit, $input_handle );
        }
    }
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

sub read_list_file_handle : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




