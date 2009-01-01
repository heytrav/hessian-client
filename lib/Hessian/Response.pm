package Hessian::Response;

use Moose;
use version; our $VERSION = qv('0.0.1');
use Hessian::Message;

has 'content' => (
    is      => 'rw',
    isa     => 'Hessian::Message',
    default => sub {
        Hessian::Message->new();
    }
);
has 'is_success' => ( is => 'rw', isa => 'Bool' );

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Response - Object representing a response from a hessian service.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 content

Contains the L<message|Hessian::Message> or I<fault> object that was sent by
the remote service.


=head2 is_success

Boolean attribute for response object.


