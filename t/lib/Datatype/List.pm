package Datatype::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Test::Deep;
use YAML;
use Hessian;
use Simple;

sub t001_initialize_hessian : Test(2) {    #{{{
    my $self = shift;
    my $hessian_obj = Hessian->new( deserializer => 1 );
    ok(
        $hessian_obj->does('Hessian::Deserializer'),
        "We can handle deserialization requests."
    );
    ok(
        $hessian_obj->can('deserialize'),
        "deserialize role has been composed."
    );
    $self->{deserializer} = $hessian_obj;
}    #}}}

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $hessian_obj  = $self->{deserializer};
    my $datastructure =
      $hessian_obj->deserialize( { input_string => $hessian_data } );
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}    #}}}

sub t011_read_variable_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x55\x04[int\x90\x91\xd7\xff\xffZ";
    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t012_read_fixed_length_type : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x73\x04[int\x90\x91\xd7\xff\xff";
    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t013_read_fixed_length_untyped : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x57\x90\x91D\x40\x28\x80\x00\x00\x00\x00\x00\xd7"
      . "\xff\xff\x52\x00\x07hello, T\x05worldZ";
    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 12.25, 262143, 'hello, ', 1, 'world' ],
        "Received expected datastructure."
    );
}    #}}}

sub t020_read_typed_map : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x4d\x08SomeType\x05color\x0aaquamarine"
      . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00Z";
    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );

    isa_ok( $datastructure, 'SomeType',
        'Data structure returned by deserializer' );
    is( $datastructure->{model},
        'Beetle', 'Model attribute has correct value.' );
    like( $datastructure->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );

}    #}}}

sub t023_read_untyped_map : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x48\x91\x05hello\x04word\x06BeetleZ";

    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        { 1 => 'hello', word => 'Beetle' },
        "Correctly interpreted datastructure."
    );
}    #}}}

sub t030_read_class_definition : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "C\x0bexample.Car\x92\x05color\x05model";
    my $datastructure =
      $self->{deserializer}->deserialize( { input_string => $hessian_data } );

    # This will need to be linked to the class definition reference list
    # somehow
    push @{ $self->{class_ref} }, $datastructure;

    $hessian_data = "C\x0bexample.Cap\x93\x03row\x04your\x04boat";
    $datastructure = $self->{deserializer}->deserialize({input_string =>
    $hessian_data } ); 
    push @{ $self->{class_ref} }, $datastructure;
    pass("Token test that only passes.");
    pass("Token test that only passes.");
}    #}}}

sub t031_basic_object : Test(3) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "\x60\x03RED\x06ferari";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'ferari', "Correct car from referenced class." );
    is( $example_car->color(), 'RED',    "Car has the correct color." );

    my $hessian_data2 = "\x61\x05dingy\x06thingy\x05wingy";
    my $example_cap   = $self->class_instance_generator($hessian_data2);

    is( $example_cap->boat(), 'wingy', "Boat is correct." );

}    #}}}

sub t032_object_long_form : Test(2) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "O\x90\x05green\x05civic";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'civic', "Correct car from referenced class." );
    is( $example_car->color(), 'green', "Correct color from class." );
}    #}}}

sub class_instance_generator {    #{{{
    my ( $self, $object_definition ) = @_;
    my $ih = $self->get_string_file_input_handle($object_definition);
    my $simple_obj =
      $self->{deserializer}->deserialize( { input_handle => $ih } ) ; 

    return $simple_obj;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datataype::List - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


