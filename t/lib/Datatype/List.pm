package Datatype::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Translator::List qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Simple;

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}    #}}}

sub t011_read_variable_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x55\x04[int\x90\x91\xd7\xff\xffZ";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t012_read_fixed_length_type : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x73\x04[int\x90\x91\xd7\xff\xff";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
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
    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;

    my $datastructure = read_complex_datastructure( $first_bit, $ih );
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
    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );

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

    my $ih = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );
    cmp_deeply(
        $datastructure,
        { 1 => 'hello', word => 'Beetle' },
        "Correctly interpreted datastructure."
    );
}    #}}}

sub t030_read_class_definition : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "C\x0bexample.Car\x92\x05color\x05model";
    my $ih           = $self->get_string_file_input_handle($hessian_data);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $datastructure = read_complex_datastructure( $first_bit, $ih );

    # This will need to be linked to the class definition reference list
    # somehow
    push @{ $self->{class_ref} }, $datastructure;

    $hessian_data = "C\x0bexample.Cap\x93\x03row\x04your\x04boat";
    my $ih2 = $self->get_string_file_input_handle($hessian_data);
    read $ih2, $first_bit, 1;
    $datastructure = read_complex_datastructure( $first_bit, $ih2 );

    #    close $ih;
    #    close $ih2;

    push @{ $self->{class_ref} }, $datastructure;
    pass("Token test that only passes.");
    pass("Token test that only passes.");
}    #}}}

sub t031_basic_object : Test(7) {    #{{{
    my $self         = shift;
    my $hessian_data1 = "\x60\x03RED\x06ferari";
    my $example_car = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'ferari', "Correct car from referenced class." );
    is( $example_car->color(), 'RED',    "Car has the correct color." );

    my $hessian_data2 = "\x61\x05dingy\x06thingy\x05wingy";
    my $example_cap = $self->class_instance_generator($hessian_data2);

    is($example_cap->boat(), 'wingy', "Boat is correct.");

}    #}}}

sub  class_instance_generator { #{{{
    my ($self, $object_definition) = @_;
    my $ih           = $self->get_string_file_input_handle($object_definition);
    my $first_bit;
    read $ih, $first_bit, 1;
    my $class_definition_index = read_complex_datastructure( $first_bit, $ih );
    my $class_definition = $self->{class_ref}->[$class_definition_index];

    # This here will be part of the "class construction" code.
    my $class_type = $class_definition->{type};
    my $simple_obj = bless {}, $class_type;
    {
        # This is so we can take advantage of Class::MOP/Moose's meta object
        # capabilities and add arbitrary fields to the new object.
        no strict 'refs';
        push @{ $class_type . '::ISA' }, 'Simple';
    }
    foreach my $field ( @{ $class_definition->{fields} } ) {
        $simple_obj->meta()->add_attribute( $field, is => 'rw' );
    }
    can_ok( $simple_obj, @{ $class_definition->{fields} } );
    isa_ok($simple_obj, $class_type, "New object type");

    my $field_index;
    while ( read $ih, $first_bit, 1 ) {
        my $field_value = read_string_handle_chunk( $first_bit, $ih );
        my $field = $class_definition->{fields}->[ $field_index++ ];
        $simple_obj->$field($field_value);
    }
    return $simple_obj;
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Datataype::List - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


