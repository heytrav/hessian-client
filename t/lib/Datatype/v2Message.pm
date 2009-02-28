package Datatype::v2Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Datatype::Message';

use Test::More;
use Test::Deep;
use YAML;
use Data::Dumper;
use Hessian::Translator;
use Hessian::Deserializer;
use Hessian::Translator::Composite;

sub t004_initialize_hessian : Test(3) {    #{{{
    my $self = shift;
    my $hessian_obj = Hessian::Translator->new( version => 2 );

    ok(
        !$hessian_obj->can('deserialize_message'),
        "Deserialize role has not been composed."
    );

    ok(
        !$hessian_obj->does('Hessian::Translator::V1'),
        "Not ready for processing of Hessian version 1"
    );
    ok(
        !$hessian_obj->does('Hessian::Translator::V2'),
        "Not ready for processing of Hessian version 2"
    );

    $self->{deserializer} = $hessian_obj;
}    #}}}

sub t010_read_hessian_version : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00";
    $deserializer->input_string($hessian_data);
    my $result = $deserializer->deserialize_message();
    cmp_deeply(
        $result,
        { hessian_version => "2.0" },
        "Parsed hessian version 2."
    );
}    #}}}

sub t015_read_envelope : Test(2) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00E\x06Header\x90\x87R\x05hello\x90Z";
    $deserializer->input_string($hessian_data);
    my $tokens = $deserializer->process_message();
    cmp_deeply(
        $tokens->[0],
        { hessian_version => "2.0" },
        "Parsed hessian version 2."
    );
my $packet = $tokens->[1]->{packet};
my $reply_data = $packet->{reply_data};
is($reply_data, 'hello', 
"Retrieved correct answer from enveloped reply.");
}    #}}}

sub t016_multi_chunk_envelope : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00E\x06Header\x90\x88C\x05hello"
      . "\x91\x90\x90\x8d\x0chello, world\x90Z";
    $deserializer->input_string($hessian_data);
    my $tokens = $deserializer->process_message();
    my $packet = $tokens->[1]->{packet};
    my $call   = $packet->{call};

    cmp_deeply(
        $call,
        { method => 'hello', arguments => ['hello, world'] },
        "Parsed call from envelope."
    );
}    #}}}

sub t040_hessian_fault : Test(1) {    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "FH\x04code\x10ServiceException\x07message"
      . "\x0eFile Not Found\x06detailM\x1djava.io.FileNotFoundExceptionZZ";

    eval {

        my $result = $deserializer->deserialize_message(
            { input_string => $hessian_data } );
    };
    if ( my $e = $@ ) {

        isa_ok( $e, 'ServiceException', "Object received from deserializer" );
    }

}    #}}}

sub t050_hessian_call : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "H\x02\x00C\x02eq\x92M\x07qa.Bean\x03foo\x9dZQ\x90";
    my $hessian_obj  = Hessian::Translator->new( version => 2 );
    $hessian_obj->input_string($hessian_data);

    my $datastructure = $hessian_obj->process_message();
    cmp_deeply(
        $datastructure->[1]->{call},
        {
            arguments => ignore(),
            method    => 'eq'
        }
    );
    my @arguments = @{ $datastructure->[1]->{call}->{arguments} };

    foreach my $argument (@arguments) {
        isa_ok( $argument, 'qa.Bean', "Type parsed from call" );
    }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::v2Message - Test processing of Hessian version 2

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


