package Datatype::Composite;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Hessian::Client;

__PACKAGE__->SKIP_CLASS(1);

sub t001_initialize_hessian : Test(4) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $hessian_obj  = Hessian::Client->new( input_string => $hessian_data);

    ok(
        $hessian_obj->does('Hessian::Deserializer'),
        "We can handle deserialization requests."
    );
    ok(
        $hessian_obj->can('deserialize_data'),
        "Deserialize role has been composed."
    );
    my $input_handle = $hessian_obj->input_handle();
    isa_ok( $input_handle, 'GLOB', "Input handle" );
    $hessian_obj->input_string("V\x04[int\x93\x90\x92\x93");
    $input_handle = $hessian_obj->input_handle();
    isa_ok( $input_handle, 'GLOB', "Input handle" );

}    #}}}

sub t002_initialize_hessian : Test(4) {    #{{{
    my $self        = shift;
    my $hessian_obj = Hessian::Client->new();
    ok(
        !$hessian_obj->does('Hessian::Deserializer'),
        "We can not yet handle deserialization requests."
    );
    ok(!$hessian_obj->does('Hessian::Translator::V1'),
    "We are not yet specialized for Hessian version 1.");
    ok(!$hessian_obj->does('Hessian::Translator::V2'),
    "We are not yet specialized for Hessian version 2.");
    ok(
        !$hessian_obj->can('deserialize_data'),
        "Deserialize role has not been composed."
    );
}    #}}}


"one, but we're not the same";

__END__


=head1 NAME

Datataype::Composite - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


