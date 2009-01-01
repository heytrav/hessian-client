package Datatype::Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use Test::Deep;
use YAML;
use Hessian;

sub t001_initialize_hessian : Test(1) {    #{{{
    my $self = shift;
    my $hessian_obj = Hessian->new( { deserializer => 1 } );

    ok(
        $hessian_obj->can('deserialize_message'),
        "deserialize role has been composed."
    );
    $self->{deserializer} = $hessian_obj;
}    #}}}

sub t010_read_hessian_version : Test(1){    #{{{
    my $self         = shift;
    my $deserializer = $self->{deserializer};
    my $hessian_data = "H\x02\x00";
    my $result =
      $deserializer->deserialize_message( { input_string => $hessian_data } );
    is($result, 2, "Parsed hessian version 2.");
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Message - Test message processing

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


