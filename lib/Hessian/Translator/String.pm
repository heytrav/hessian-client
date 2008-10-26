package  Hessian::Translator::String;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;

sub write_chunk {    #{{{
    my $string = shift;
    my $hessian_message = pack 'n/a*', $string;
    return $hessian_message;
}    #}}}

sub write_string : Export(:to_hessian) {    #{{{
    my @string_chunks = @_;
    my $message = hessianify_chunks( 's', @string_chunks );
    return $message;
}    #}}}

sub read_string : Export(:from_hessian) {    #{{{
    my $string_body = shift;
    my $message = de_hessianify_chunks( 's', $string_body );
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

sub write_xml : Export(:to_hessian) {    #{{{
    my @xml_chunks = @_;
    my $message = hessianify_chunks( 'x', @xml_chunks );
    return $message;
}    #}}}

sub de_hessianify_chunks {    #{{{
    my ( $prefix, $body ) = @_;
    my $first_prefix = lc $prefix;
    my $prefix_regex = qr/
       $prefix 
       (
        \d+  
         (?:  
             (?! $prefix \d+ ) 
             . 
         ) * 
       ) 
    /x;
    my @chunks = apply { read_chunk($_) } $body =~ /$prefix_regex/g;
    my $message = join "" => @chunks;
    return $message;
}    #}}}

sub hessianify_chunks {    #{{{
    my ( $prefix, @chunks ) = @_;
    my $last_chunk = pop @chunks;
    my @message    = apply {
        ( lc $prefix ) . write_chunk($_);
    }
    @chunks[ 0 .. ( $#chunks - 1 ) ];
    my $last_prefix = uc $prefix;
    push @message, $last_prefix . write_chunk($last_chunk);
    my $result = join "" => @message;
    return $result;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::String - Translates string data into and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


