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
        case /\x55/ {    # variable length list

        }
        case /\x56/ {    # fixed length list
            my $type_length;
            read $input_handle, $type_length, 1;
            my $type = read_string_handle_chunk($type_length, $input_handle);

        }
        case /\x57/ {    # variable length untyped list

        }
        case /\x58/ {    # fixed length untyped list

        }
        case /[\x70-\x77]/ {    # fixed length typed list

        }
        case /[\x78-\x7f]/ {    # fixed length untyped list

        }

    }

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


