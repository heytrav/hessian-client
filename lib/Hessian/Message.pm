package Hessian::Message;

use Moose;
use version; our $VERSION = qv('0.0.1');

has 'content' => ( is => 'rw', isa => 'Any' );
has 'meta' => ( is => 'rw' => isa => 'Ref' );

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Message - Encapsulate a Hessian message.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


