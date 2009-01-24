package  Hessian::Serializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

sub serialize_chunk {    #{{{
    my ( $self, $datastructure ) = @_;
    my $result = $self->write_hessian_chunk($datastructure);
    return $result;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer - Serialize data into Hessian messages

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2   serialize_chunk

