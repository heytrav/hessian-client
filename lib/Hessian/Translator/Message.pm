package  Hessian::Translator::Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

my $deserializer_object;

sub get_deserializer {    #{{{
    return $deserializer_object;
}    #}}}

sub set_deserializer {    #{{{
    my $package = shift;
    $deserializer_object = shift;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Message - Base class for translation of Hessian content
and data.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


