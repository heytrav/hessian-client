package Datatype::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Test::Deep;

use Hessian::Translator::List qw/:input_handle/;

sub t010_read_fixed_length_untyped : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply($datastructure, [0,1], "Received expected datastructure.");
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datataype::List - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


