package  Datatype::v1Message;

use strict;
use warnings;
use base 'Datatype::Message';

use version; our $VERSION = qv('0.0.1');

use YAML;
use Test::More;
use Test::Deep;

sub t005_hessian_v1_parse : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "r\x01\x00I\x00\x00\x00\x05z";
    my $hessian_obj  = Hessian::Translator->new( version => 1 );
    $hessian_obj->input_string($hessian_data);
    my $result = $hessian_obj->process_message();

    #    is($hessian_obj->is_version_1(), 1, "Processing version 1.");
    is( $result->[1], 5, "Correct integer parsed from hessian." );

}    #}}}

sub t015_hessian_call : Test(2) {    #{{{
    my $self = shift;
    my $hessian_data =
      "c\x01\x00m\x00\x04add2I" . "\x00\x00\x00\x02I\x00\x00\x00\x03z";
    my $hessian_obj = Hessian::Translator->new( version => 1 );
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_message();
    my $version = $datastructure->{hessian_version};
    is( $version, "1.0", "Processing version 1 of hessian." );
    cmp_deeply(
        $datastructure,
        {
            call =>
              superhashof( 
                { 
                    arguments => array_each(ignore()), 
                    method => ignore() 
                } 
              ),
              hessian_version => '1.0'
        },
        "Processed a hessian call."
    );

}    #}}}

sub  t017_hessian_call : Test(1) { #{{{
    my $self = shift;
    my $hessian_data = "c\x01\x00m\x00\x02eqMt\x00\x07"
    ."qa.BeanS\x00\x03fooI\x00\x00\x00\x0dzR\x00\x00\x00\x00z";
    my $hessian_obj = Hessian::Translator->new(version => 1);
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_message();
    cmp_deeply(
        $datastructure,
        {
            call =>
              superhashof( 
                { 
                    arguments => array_each(ignore()), 
                    method => ignore() 
                } 
              ),
              hessian_version => '1.0'
        },
        "Processed a hessian call."
    );
} #}}}

sub t019_hessian_call : Test(1) { #{{{
    my $self = shift;
    my $hessian_data = "c\x01\x00H\x00\x0btransactionrt"
    ."\x00\x28com.caucho.hessian.xa."
    ."TransactionManagerS\x00\x23http"
    ."://hostname/xa?ejbid=01b8e19a77m\x00\x05debugI\x00\x03\x01\xcbz";
    my $hessian_obj = Hessian::Translator->new(version => 1);
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_message();
    cmp_deeply(
        $datastructure,
        {
            call =>
              superhashof( 
                { 
                    arguments => array_each(ignore()), 
                    method => ignore() 
                } 
              ),
              hessian_version => '1.0'
        },
        "Processed a hessian call."
    );
} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Datatype::v1Message - Parse Hessian version 1 messages.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


