package  Hessian::Exception;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Exception::Class (
    'Hessian::Exception',
    'ProtocolException' => {
        isa         => 'Hessian::Exception',
        description => 'The Hessian request has some sort of syntactic error'
    },
    'InputOutput::X' => {
        isa         => 'Hessian::Exception',
        description => 'Unable to read/write to a file or string handle.'
    },
    'Parameter::X' => {
        isa         => 'Hessian::Exception',
        description => 'Incorrect or missing parameter to method'
    },
    'NoSuchObjectException' => {
        isa         => 'Hessian::Exception',
        description => 'The requested object does not exist.'
    },
    'NoSuchMethodException' => {
        isa         => 'Hessian::Exception',
        description => 'The requested method does not exists.'
    },
    'RequireHeaderException' => {
        isa         => 'Hessian::Exception',
        description => 'A required header was '
          . 'not understood by the server.'
    },
    'ServiceException' => { 
        isa         => 'Hessian::Exception',
        description => 'The called method threw an exception.'
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


