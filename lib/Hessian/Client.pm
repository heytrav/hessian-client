package Hessian::Client;

use strict;
use warnings;

use version; our $VERSION = qv('0.1.3');

use LWP::UserAgent;
use HTTP::Request;
use Hessian::Exception;
use Hessian::Translator;
use Class::Std;
{
    my %service : ATTR(:name<service>);
    my %version : ATTR(:get<version> :init_arg<version>);
    my %hessian_translator : ATTR(:get<translator> :set<translator>);

    sub BUILD {    #{{{
        my ( $self, $id, $args ) = @_;
        my $hessian = Hessian::Translator->new( version => $args->{version} );
        $self->set_translator($hessian);
    }    #}}}

    sub AUTOMETHOD {    #{{{
        my ( $self, $id, @args ) = @_;
        my $method_name = $_;

        return sub {
            my $datastructure = {
                call => {
                    method    => $method_name,
                    arguments => \@args

                },
            };
            return $self->_call_remote($datastructure);
          }

    }    #}}}

    sub _call_remote {    #{{{
        my ( $self, $datastructure ) = @_;
        my $service = $self->get_service();
        my $request = HTTP::Request->new( 'POST', $service );
        my $hessian = $self->get_translator();
        $hessian->serializer();
        my $hessian_string = $hessian->serialize_message($datastructure);
        $request->content($hessian_string);
        my $agent    = LWP::UserAgent->new();
        my $response = $agent->request($request ); 
        if ( $response->is_success() ) {
            my $content   = $response->content();
            $hessian->input_string($content);
            my $processed = $hessian->process_message();
            return $processed;
        }
        else {

            print "NO response!\n";
        }

    }    #}}}

}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Client - RPC via Hessian with a remote server.


=head1 SYNOPSIS

 use Hessian::Client;

 my $client = Hessian::Client->new(
    version => 1,
    service => 'http://some.hessian.service/.....'
 );

 
 # RPC 
 my $response = $hessian->remoteCall($arg1, $arg2, $arg3, ...);

=head1 DESCRIPTION

The goal of Hessian::Client and all associated classes in this namespace is to
provide support for communication via the Hessian protocol in Perl.  For a
more detailed introduction into the Hessian protocol, see the main project
documentation for L<Hessian 1.0|http://hessian.caucho.com/doc/hessian-ws.html>
and L<Hessian
2.0|http://www.caucho.com/resin-3.0/protocols/hessian-2.0-spec.xtp>.  

Hessian::Client implements basic RPC for Hessian. Although currently only
tested with version 1, communication with version 2.0 servers should also work.


=head1 INTERFACE

=head2 BUILD

Not part of the public interface. See L<Class::Std|Class::Std/"BUILD"> documentation.

=head2 AUTOMETHOD


Not part of the public interface. See L<Class::Std|Class::Std/"AUTOMETHOD"> documentation.



=head1 TODO

=over 2

=item *
Testing with a Hessian 2.0 service. If anyone out there would be interested in
helping with this I would be very grateful.


=item *
Work on messaging. RPC is only part of the Hessian protocol.

=item *
Make a POE filter for this perhaps.



=back
