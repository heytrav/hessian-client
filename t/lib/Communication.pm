package Communication;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use URI;
use Hessian::Client;

sub t005_initialize_client : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Client->new( version => 1 );
    ok(
        !$client->does('Hessian::Serializer'),
        "Serializer role has not been composed."
    );
}    #}}}

sub  t007_compose_serializer : Test(1) { #{{{
    my $self = shift;
    my $client = Hessian::Client->new( version => 1);
    $client->service(URI->new('http://localhost:8080'));
    ok( $client->does('Hessian::Serializer'),
    "Serializer role has been composed."
    );
} #}}}

sub  t020_serialize_hash_map { #{{{
    my $self = shift;
    my $client = Hessian::Client->new( version => 1);
    $client->service(URI->new('http://localhost:8080'));
    my $datastructure =  { 1 => 'fee', 16 => 'fie', 256 => 'foe' };

} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication - Test communication in Hessian

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


