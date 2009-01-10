package Datatype::v2Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype::Message';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Client;
use Hessian::Deserializer;


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
    cmp_deeply( $tokens->[0],
    {hessian_version => "2.0"},
    "Parsed hessian version 2." );
    my $reply_data =$tokens->[1]->[0]->{packets}->[0] ;
    my $text ="$reply_data->{reply_data}"; 
    cmp_deeply(
        $reply_data,
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
      my $second_packet =$tokens->[1]->[1]->{packets}->[0] ;
    my $text ="$second_packet";
    cmp_deeply( $second_packet,
        "hello, world", 
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

Datatype::v2Message - Test processing of Hessian version 2

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


