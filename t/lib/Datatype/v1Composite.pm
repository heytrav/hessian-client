package  Datatype::v1Composite;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype::Composite';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Client;


sub  t004_initialize_hessian_obj : Test(4){ #{{{
    my $self = shift;
    my $hessian_obj = Hessian::Client->new(version => 1);
    ok(!$hessian_obj->does('Hessian::Deserializer'), 
    "Have not yet composed the Deserialization logic.");
    my $hessian_data = "V\x04[int\x92\x90\x91";
    $hessian_obj->input_string($hessian_data);

    ok($hessian_obj->does('Hessian::Deserializer'), 
    "Have composed the Deserialization logic.");
    ok($hessian_obj->does('Hessian::Translator::V1'),
    "Composed version 1 methods."
    );
    ok(!$hessian_obj->does('Hessian::Translator::V2'),
    "Do not have methods for hessian version 2");

    
} #}}}


sub  t008_initialize_hessian_obj : Test(2) { #{{{
    
    my $self = shift;
    my $hessian_obj = Hessian::Client->new( 
    input_string => "Vt\x00\x04[int\x92\x90\x91", version => 1);
    ok( $hessian_obj->does('Hessian::Deserializer'),
    "Deserializer has been composed.");
    ok($hessian_obj->does('Hessian::Translator::V1'),
    "Hessian version 1 methods have been composed.");

    $self->{deserializer}  = $hessian_obj;
} #}}}


sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vt\x00\x04[intl\x00\x00\x00\x02\x90\x91";
    my $hessian_obj  = $self->{deserializer};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    print "got datastructure:\n".Dump($datastructure)."\n";
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::v1Composite - Test composite parsing methods for Hessian version 1

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


