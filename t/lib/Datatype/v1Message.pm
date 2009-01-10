package  Datatype::v1Message;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');


sub  t005_hessian_v1_parse : Test(2){ #{{{
    my $self = shift;
    my $hessian_data = "r\x01\x00I\x00\x00\x00\x05z";
    my $hessian_obj = Hessian::Client->new();
    Hessian::Deserializer->meta()->apply($hessian_obj);
    $hessian_obj->input_string($hessian_data);
    my $result = $hessian_obj->process_message();
    is($hessian_obj->is_version_1(), 1, "Processing version 1.");
    is($result->[1], 5, "Correct integer parsed from hessian.");

} #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::v1Message - Parse Hessian version 1 messages.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


