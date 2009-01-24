package Datatype::String;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Test::More;
use Carp;

use Hessian::Translator::String qw/:to_hessian :from_hessian :input_handle/;

sub t010_read_hessian_string : Test(1) {    #{{{
    my $self           = shift;
    my $params = { 
        prefix => 's',
        last_prefix => 'S',
        chunks => [ qw/hello/]
        };
    my $hessian_string = write_string($params);
    like(
        $hessian_string,
        qr/ S \x{00}\x{05} hello /xms,
        'Simple translation of string.'
    );

}    #}}}

sub t020_read_handle_terminal_chunk : Test(1) {    #{{{
    my $hessian_string = "S\x{00}\x{05}hello";
    open my $ih, "<", \$hessian_string
      or croak "Could not read from string.";
    my $first_bit;
    read $ih, $first_bit, 1;
    my $string = read_string_handle_chunk( $first_bit, $ih );
    is( $string, 'hello', "Successfully read simple string handle chunk" );
}    #}}}

sub t021_read_simple_string : Test(1) {    #{{{
    my $hessian_string = "\x05hello";
    open my $ih, "<", \$hessian_string or croak "Could not read from string.";
    my $first_bit;
    read $ih, $first_bit, 1;
    my $string = read_string_handle_chunk( $first_bit, $ih );
    is( $string, 'hello', "Successfully read simple string handle chunk" );

}    #}}}

sub t022_read_two_chunk_string : Test(1) {    #{{{
    my $hessian_string = "\x52\x00\x07hello, \x05wörld";
    open my $ih, "<", \$hessian_string or croak "Could not read from string.";
    my $first_bit;
    my $raw_string;
    while ( read $ih, $first_bit, 1 ) {
        $raw_string .= read_string_handle_chunk( $first_bit, $ih );
    }
    my $string = $raw_string;
    is(
        $string,
        "hello, w\xf6rld",
        "Successfully read two chunk strink from string handle"
    );

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

String - Test string methods

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


