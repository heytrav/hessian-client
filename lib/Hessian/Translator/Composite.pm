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

    #    if ( $entity_type !~ /^\d+$/ ) {
    #        $type = $entity_type;
    #        push @{ $self->type_list() }, $type;
    #    }
    #    else {
    #        $type = $self->type_list()->[$entity_type];
    #    }

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
        my $integer = unpack 'C', $entity_type;
        $type = $self->type_list()->[$integer];

    }
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




