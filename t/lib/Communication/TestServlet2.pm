package  Communication::TestServlet2;

use strict;
use warnings;

use base 'Communication';

use Test::More;
use Test::Deep;
use Test::Exception;

use Hessian::Client;
use YAML;

my $test_service = 'http://hessian.caucho.com/test/test2';

sub prep01_check_webservice : Test(startup) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    eval {

        my $result = $client->methodNull();
    };
    if ( my $e = $@ ) {
        $self->SKIP_ALL("Problem connecting to test service.");
    }

}    #}}}

sub test_reply_int_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_0();
    is( $result->{reply_data}, 0 );
}    #}}}

sub test_reply_int_47 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_47();
    is( $result->{reply_data}, 47 );
}    #}}}

sub test_reply_int_mx800 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyInt_m0x800";
    my $result = $client->$function();
    is( $result->{reply_data}, -0x800 );
}    #}}}

sub test_reply_long_mOx80000000 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_m0x80000000";
    my $result = $client->$function();
    is( $result->{reply_data}, -0x80000000);
}    #}}}

sub test_reply_long_mOx80000001 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_m0x80000001";
    my $result = $client->$function();
    is( $result->{reply_data}, -0x80000001 );
}    #}}}


sub test_reply_long_Ox10 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_0x10";
    my $result = $client->$function();
    is( $result->{reply_data}, 0x10 );
}    #}}}

sub test_reply_double_0_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_0_0";
    my $result = $client->$function();
    is( $result->{reply_data}, 0.0);
}    #}}}

sub test_reply_double_m0_001 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_m0_001";
    my $result = $client->$function();
    is( $result->{reply_data},-0.001 );
}    #}}}

sub test_reply_double_127_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_127_0";
    my $result = $client->$function();
    is( $result->{reply_data}, 127);
}    #}}}

sub test_reply_double_3_14159 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_3_14159";
    my $result = $client->$function();
    is( $result->{reply_data}, 3.14159  );
}    #}}}

sub test_reply_int_m17 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_m17();
    is( $result->{reply_data}, -17 );
}    #}}}

sub t030_reply_object_16 : Test(1) {    #{{{
    my $self           = shift;
    my $hessian_client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $hessian_client->replyObject_16();
    cmp_deeply(
        $result,
        { hessian_version => '2.0', reply_data => array_each( ignore() ) },
        "Received expected header from service."
    );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication::TestServlet2 - Test communication with a test service that runs
version 2

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


