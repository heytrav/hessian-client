package Datatype::v2Composite;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype::Composite';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Translator;
use Hessian::Serializer;

sub  t004_initialize_hessian_obj : Test(4){ #{{{
    my $self = shift;
    my $hessian_obj = Hessian::Translator->new(version => 2);
    ok(!$hessian_obj->does('Hessian::Deserializer'), 
    "Have not yet composed the Deserialization logic.");
    my $hessian_data = "V\x04[int\x92\x90\x91";
    $hessian_obj->input_string($hessian_data);

    ok($hessian_obj->does('Hessian::Deserializer'), 
    "Have composed the Deserialization logic.");
    ok($hessian_obj->does('Hessian::Translator::V2'),
    "Composed version 2 methods."
    );
    ok(!$hessian_obj->does('Hessian::Translator::V1'),
    "Do not have methods for hessian version 1");

    
} #}}}

sub  t008_initialize_hession_obj : Test(2) { #{{{
    my $self = shift;
    my $hessian_obj = Hessian::Translator->new( 
    input_string => "V\x04[int\x92\x90\x91", version => 2);
    ok( $hessian_obj->does('Hessian::Deserializer'),
    "Deserializer has been composed.");
    ok($hessian_obj->does('Hessian::Translator::V2'),
    "Hessian version 2 methods have been composed.");

    $self->{deserializer}  = $hessian_obj;
} #}}}

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vt\x00\x04[int\x6e\x02\x90\x91z";
    my $hessian_obj  = $self->{deserializer};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}    #}}}

sub t011_read_variable_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vt\x00\x04[int\x90\x91\xd7\xff\xffz";
    my $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );
      
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}    #}}}

sub t012_read_fixed_length_type : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vt\x00\x04[int\x90\x91\xd7\xff\xffz";
    my $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure. ".Dump($datastructure)
    );
}    #}}}

#sub t013_read_fixed_length_untyped  { #: Test(1) {    #{{{
#    my $self         = shift;
#    my $hessian_data = "V\x6e\x07\x90\x91"
#    ."D\x40\x28\x80\x00\x00\x00\x00\x00\xd7"
#      . "\xff\xff\x52\x00\x07hello, T\x05worldZ";
#    my $datastructure =
#      $self->{deserializer}
#      ->deserialize_data( { input_string => $hessian_data } );
#    cmp_deeply(
#        $datastructure,
#        [ 0, 1, 12.25, 262143, 'hello, ', 1, 'world' ],
#        "Received expected datastructure."
#    );
#}    #}}}

sub t020_read_typed_map : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "Mt\x00\x08SomeType"
    ."\x05color\x0aaquamarine"
      . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00z";
    my $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );

    isa_ok( $datastructure, 'SomeType',
        'Data structure returned by deserializer' );
    is( $datastructure->{model},
        'Beetle', 'Model attribute has correct value.' );
    like( $datastructure->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );
}    #}}}

sub t023_read_untyped_map : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "M\x91\x05hello\x04word\x06Beetlez";

    my $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );
    cmp_deeply(
        $datastructure,
        { 1 => 'hello', word => 'Beetle' },
        "Correctly interpreted datastructure."
    );
}    #}}}

sub t030_read_class_definition : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Ot\x00\x0bexample.Car\x92\x05color\x05model";
    my $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );

    # This will need to be linked to the class definition reference list
    # somehow
    push @{ $self->{class_ref} }, $datastructure;

    $hessian_data = "Ot\x00\x0bexample.Cap\x93\x03row\x04your\x04boat";
    $datastructure =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );
    push @{ $self->{class_ref} }, $datastructure;
    pass("Token test that only passes.");
}    #}}}

sub t031_basic_object : Test(3) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "o\x90\x03RED\x06ferari";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'ferari', "Correct car from referenced class." );
    is( $example_car->color(), 'RED',    "Car has the correct color." );

    my $hessian_data2 = "o\x91\x05dingy\x06thingy\x05wingy";
    my $example_cap   = $self->class_instance_generator($hessian_data2);

    is( $example_cap->boat(), 'wingy', "Boat is correct." );

}    #}}}

sub t032_object_long_form : Test(2) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "o\x90\x05green\x05civic";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'civic', "Correct car from referenced class." );
    is( $example_car->color(), 'green', "Correct color from class." );
}    #}}}

sub t033_retrieve_object_from_reference : Test(2) {    #{{{
    my $self       = shift;
    my $last_index = scalar @{ $self->{deserializer}->reference_list() } - 1;
    Hessian::Serializer->meta()->apply($self->{deserializer});
    my $hessian_integer = $self->{deserializer}->serialize_chunk($last_index);
    my $hessian_data = "\x4a\x0a";
    my $example_car =
      $self->{deserializer}
      ->deserialize_data( { input_string => $hessian_data } );
    is( $example_car->model(), 'civic', "Correct car from referenced object." );
    is( $example_car->color(), 'green', "Correct color from class." );

}    #}}}

sub class_instance_generator {    #{{{
    my ( $self, $object_definition ) = @_;
    $self->{deserializer}->input_string($object_definition);
    return $self->{deserializer}->deserialize_data();
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datataype::Composite - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


