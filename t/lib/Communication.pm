package Communication;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use DateTime;
use DateTime::Format::Strptime;
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

sub compare_date {    #{{{
    my ( $self, $original_date, $processed_time ) = @_;
    my $from_hessian_date = DateTime->from_epoch( epoch => $processed_time );
    my $formatter = DateTime::Format::Strptime->new(
        pattern   => '%F %T',
        time_zone => 'GMT'
    );
    my $readable_date = $formatter->format_datetime($from_hessian_date);
    $from_hessian_date->set_time_zone('UTC');

    my $cmp = DateTime->compare( $original_date, $from_hessian_date );
    is( $cmp, 0, "Hessian date as expected." );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication - Test communication in Hessian

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


