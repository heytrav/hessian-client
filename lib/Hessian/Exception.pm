package  Hessian::Exception;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Exception::Class (
    'Hessian::Exception',
    'Protocol::X' => {
        isa         => 'Hessian::Exception',
        description => 'Error in the hessian protocol.'
    },
    'InputOutput::X' => {
        isa         => 'Protocol::X',
        description => 'Unable to read/write to a file or string handle.'
    },
    'Parameter::X' => {
        isa         => 'Hessian::Exception',
        description => 'Incorrect or missing parameter to method'
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


