package  Datatype;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Carp;

use Hessian::Serializer;
use Hessian::Deserializer;
use Hessian::Translator::V2;
use Hessian::Translator;

sub prep001_compose_hessian : Test(setup) {    #{{{
    my $self   = shift;
    my $simple = Hessian::Translator->new(version => 2);
    Hessian::Translator::V2->meta()->apply($simple);
    Hessian::Serializer->meta()->apply($simple);
    Hessian::Deserializer->meta()->apply($simple);
    $self->set_hessian_obj($simple);
}    #}}}

sub get_string_file_input_handle {    #{{{
    my ( $self, $hessian_string ) = @_;
    my $hessian = $self->get_hessian_obj($hessian_string);
    open my $ih, "<", \$hessian_string
      or croak "Could not read from string handle";
    return $ih;

}    #}}}

sub set_hessian_obj {    #{{{
    my ( $self, $hessian ) = @_;
    $self->{hessian} = $hessian;
}    #}}}

sub get_hessian_obj {    #{{{
    my $self = shift;
    return $self->{hessian};
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype - Base class for Datatype testing

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


