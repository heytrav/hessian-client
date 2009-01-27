package Hessian::Client;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use LWP::UserAgent;
use HTTP::Request;
use Hessian::Exception;
use Hessian::Translator;
use Class::Std;
use YAML;
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
            return $self->call_remote($datastructure);
          }

    }    #}}}

    sub call_remote {    #{{{
        my ( $self, $datastructure ) = @_;
        my $service = $self->get_service();
        my $request = HTTP::Request->new( 'POST', $service );
        my $hessian = $self->get_translator();
        $hessian->serializer();
        my $hessian_string = $hessian->serialize_message($datastructure);
        $request->content($hessian_string);
        my $agent    = LWP::UserAgent->new();
        my $response = $agent->request($request);

        if ( $response->is_success() ) {
            my $content   = $response->content();
            my $processed = $hessian->input_string($content);
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

Hessian::Client - Communicate with a remote Hessian server

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


