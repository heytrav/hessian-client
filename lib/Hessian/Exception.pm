package  Hessian::Exception;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Exception::Class (
    'Hessian::Exception',
    'Protocol::Exception' => {
        isa         => 'Hessian::Exception',
        description => 'Error in the hessian protocol.'
    }
);

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Exception - Basic exceptions for the Hessian protocol.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


