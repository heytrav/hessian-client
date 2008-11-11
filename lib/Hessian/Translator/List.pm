package Hessian::Translator::List;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;

sub read_list : Export(:from_hessian) {    #{{{
    my $hessian_list = shift;
    my $array        = [];
    if ( $hessian_list =~ /^\x57(.*)Z/)  {
        $array =        read_variable_untyped_list($1);
    }
    return $array;
}    #}}}

sub write_list : Export(:to_hessian) {    #{{{
    my $list = shift;
}    #}}}

sub read_variable_untyped_list {    #{{{
    my $hessian_list = shift;

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


