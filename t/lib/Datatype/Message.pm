package Datatype::Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use Hessian::Client;

__PACKAGE__->SKIP_CLASS(1);

sub t001_initialize_hessian : Test(3) {    #{{{
    my $self        = shift;
    my $hessian_obj = Hessian::Client->new();

    ok(
        !$hessian_obj->can('deserialize_message'),
        "Deserialize role has not been composed."
    );

    ok(
        !$hessian_obj->does('Hessian::Translator::V1'),
        "Not ready for processing of Hessian version 1"
    );
    ok(
        !$hessian_obj->does('Hessian::Translator::V2'),
        "Not ready for processing of Hessian version 2"
    );

    #$self->{deserializer} = $hessian_obj;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Message - Test message processing

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


