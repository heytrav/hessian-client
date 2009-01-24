package  Hessian::Deserializer::String;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');


sub read_string : Export(:from_hessian) {    #{{{
    my $string_body = shift;
    my $message = de_hessianify_chunks( 'R', $string_body );
    return $message;
}    #}}}

sub read_xml : Export(:from_hessian) {    #{{{
    my $xml_body = shift;
    my $message = de_hessianify_chunks( 'x', $xml_body );
    return $message;
}    #}}}

sub read_chunk {    #{{{
    my $string_chunk = shift;
    my ($message) = unpack 'n/a', $string_chunk;
    return $message;
}    #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::String - Methods for serialization of strings

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


