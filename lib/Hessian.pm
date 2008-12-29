package Hessian;

use Moose;
use version; our $VERSION = qv('0.0.1');

use Module::Load;
use Simple;

has 'class_definitions' => (is => 'rw',default => sub   { [] });
has 'object_list'       => ( is => 'rw',default => sub   { [] });
has 'reference_list'    => ( is => 'rw',default => sub   { [] });

sub  BUILD { #{{{
    my ($self, $params) = @_;
    foreach my $role (qw/serializer deserializer/) {
        next unless $params->{$role};
        my $name = ucfirst $role;
        my $role = 'Hessian::'.$name;
        load $role;
        $role->meta()->apply($self);
    }
} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian - Base class for Hessian serialization/deserialization.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


