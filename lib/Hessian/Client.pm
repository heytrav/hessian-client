package Hessian::Client;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use LWP::UserAgent;
use Hessian::Exception;
use Hessian::Translator;
use Class::Std;
{
    my %service : ATTR(:name<service>);
    my %version : ATTR(:get<version> :init_arg<version>);
    my %hessian_client : ATTR(:get<client> :set<client>);

    sub  BUILD { #{{{
        my ($self, $id, $args) = @_;
        my $version = $self->get_version();
        my $hessian= Hessian::Translator->new( version => $version);  
       $hessian_client{$id} = $hessian; 
    } #}}}


}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Client - Communicate with a remote Hessian server

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


