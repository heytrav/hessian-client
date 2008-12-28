package  Datatype;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Carp;

sub  get_string_file_input_handle { #{{{
    my ($self, $hessian_string) = @_;
    open my $ih, "<", \$hessian_string
      or croak "Could not read from string handle";
      return $ih;

} #}}}



"one, but we're not the same";

__END__


=head1 NAME

Datatype - Base class for Datatype testing

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


