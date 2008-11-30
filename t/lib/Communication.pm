package  Communication;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';
use Test::More;
use Hessian::Input;

sub string_handle : Test(setup) {    #{{{
    my $self = shift;

}    #}}}

sub t010_initialize_input : Test(1) {    #{{{
    my $self         = shift;
    my $input_reader = Hessian::Input->new();
    my $desired_type = 'Hessian::Input';
    isa_ok( $input_reader, $desired_type, 'Successful object created' )
      or $self->SKIP_ALL("Can not instantiate a $desired_type object");

}    #}}}

sub test020_read_simple : Test(2) {    #{{{
    my $self = shift;
    pass("just for the hell of it");
    pass("also just for the hell of it");
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication - tests for Hessian communication protocol

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


