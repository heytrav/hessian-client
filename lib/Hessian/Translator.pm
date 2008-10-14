package  Hessian::Translator;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;

sub write_string {    #{{{
    my $string = shift;
    my $message = pack 'n/a*', $string;
    return $message;
}    #}}}

sub write_string_chunks : Export(:to_hessian) {    #{{{
    my @string_chunks = @_;
    my $last_chunk    = pop @string_chunks;
    my $message       = apply {
        's' . write_string($_);
    }
    @string_chunks[ 0 .. ( $#string_chunks - 1 ) ];
    $message .= 'S' . write_string($last_chunk);
    return $message;
}    #}}}

sub write_xml {    #{{{
    my $xml_chunk = shift;
    return write_string($xml_chunk);
}    #}}}

sub write_xml_chunks :Export(:to_hessian) {    #{{{
    my @xml_chunks = @_;
    my $last_chunk = pop @xml_chunks;
    my $message    = apply {
        'x' . write_xml($_);
    }
    @xml_chunks[ 0 .. ( $#xml_chunks - 1 ) ];
    $message .= 'X' . write_xml($last_chunk);
    return $message;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator - Provide some basis methods for translating to/from
Hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


