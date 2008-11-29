package Datatype::String;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Test::More;

use Hessian::Translator::String qw/:to_hessian :from_hessian/;

sub t010_read_hessian_string : Test(1) {    #{{{
    my $self = shift;
    my $hessian_string = write_string("hello");

    like(
        $hessian_string,
        qr/ S \x{00}\x{05} hello /xms,
        'Simple translation of string.'
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


