package Datatype::Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use Test::Deep;
use YAML;
use Hessian;
use Hessian::Deserializer;

sub t001_initialize_hessian : Test(1) {    #{{{
    my $self = shift;
    my $hessian_obj = Hessian->new( );

    ok(
        ! $hessian_obj->can('deserialize_message'),
        "Deserialize role has not been composed."
    );
    $self->{deserializer} = $hessian_obj;
}    #}}}

sub  t002_compose_role : Test(2) { #{{{
    my $self = shift;
    my $hessian_obj = $self->{deserializer};
    Hessian::Deserializer->meta()->apply($hessian_obj);
    ok(
   $hessian_obj->does('Hessian::Deserializer'),
   "Object can deserialize.");
    ok(
         $hessian_obj->can('deserialize_message'),
        "Deserialize role has been composed."
    );
} #}}}

sub  t005_hessian_v1_parse : Test(2){ #{{{
    my $self = shift;
    my $hessian_data = "r\x01\x00I\x00\x00\x00\x05z";
    my $hessian_obj = Hessian->new();
    Hessian::Deserializer->meta()->apply($hessian_obj);
    $hessian_obj->input_string($hessian_data);
    my $result = $hessian_obj->process_message();
    is($hessian_obj->is_version_1(), 1, "Processing version 1.");
    is($result->[1], 5, "Correct integer parsed from hessian.");

} #}}}


sub t010_read_hessian_version : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00";
    my $result =
      $deserializer->deserialize_message( { input_string => $hessian_data } );
    cmp_deeply( $result, {hessian_version => "2.0"}, "Parsed hessian version 2." );
}    #}}}

sub t015_read_envelope : Test(2) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00E\x06Header\x90\x87R\x05hello\x90Z";
    $deserializer->input_string($hessian_data);
    my $tokens =
      $deserializer->process_message();
    cmp_deeply( $tokens->[0],{hessian_version => "2.0"}, "Parsed hessian version 2." );
    cmp_deeply(
        $tokens->[1]->[0]->{packets}->[0],
        superhashof( { reply_data => 'hello' } ),
        "Parsed expected datastructure."
    );

}    #}}}

sub t016_multi_chunk_envelope : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00E\x06Header\x90\x88C\x05hello"
      . "\x91\x90\x90\x8d\x0chello, world\x90Z";
      $deserializer->input_string($hessian_data);
      my $tokens = $deserializer->process_message();
    cmp_deeply( $tokens->[1]->[1]->{packets},
       [ "hello, world"], 
        "Parsed expected datastructure." );
}    #}}}

sub t017_hessian_fault : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "FH\x04code\x10ServiceException\x07message"
      . "\x0eFile Not Found\x06detailM\x1djava.io.FileNotFoundExceptionZZ";
    my $result =
      $deserializer->deserialize_message( { input_string => $hessian_data } );
    isa_ok( $result, 'ServiceException', "Object received from deserializer" );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Message - Test message processing

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


