package  Communication::TestServlet2;

use strict;
use warnings;

use base 'Communication';


use Test::More;
use Test::Deep;
use Test::Exception;

use Hessian::Client;

my $test_service = 'http://hessian.caucho.com/test/test2'; 

sub prep01_check_webservice : Test(startup)  { #{{{
    my $self = shift;
    my $client = Hessian::Client->new(  { 
        version => 2, service => $test_service
        });
       eval {
           
       my $result = $client->methodNull(); 
       };
       if (my $e = $@) {
        $self->SKIP_ALL("Problem connecting to test service.");
       }

} #}}}


sub t030_reply_object_16 : Test(1) { #{{{
    my $self = shift;
        my $hessian_client = Hessian::Client->new(
            {
                version => 2,
                service => $test_service
            }
        );
        my $result = $hessian_client->replyObject_16();
    cmp_deeply(
        $result,
        { hessian_version => '2.0',reply_data => array_each(ignore())},
        "Received expected header from service."
    );
} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication::TestServlet2 - Test communication with a test service that runs
version 2

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


