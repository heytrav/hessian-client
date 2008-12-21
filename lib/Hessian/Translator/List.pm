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
    print "Read list length = $array_length\n";
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
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';
    switch ($type) {
        case /int/ {
            binmode( $input_handle, 'bytes' );
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }

    }
    return $element;
}    #}}}

sub read_untyped_list_element {    #{{{
    my $input_handle = shift;
    my $element;
    my $first_bit;
    read $input_handle, $first_bit, 1;
    return $first_bit if $first_bit eq 'Z';
    switch ($first_bit) {
        case /[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ {
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4c\xd8-\xef\xf0-\xff\x38-\x3f\x59]/ {
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

=head1 DESCRIPTION

=head1 INTERFACE


