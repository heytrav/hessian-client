package Communication;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Hessian::Client;

__PACKAGE__->SKIP_CLASS(1);

sub t005_initialize_client : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Client->new( version => 1 );
    ok(
        !$client->does('Hessian::Serializer'),
        "Serializer role has not been composed."
    );
}    #}}}
"one, but we're not the same";

__END__


=head1 NAME

Communication - Test communication in Hessian

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


