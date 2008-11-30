package Hessian::Input;

use Moose;
use version; our $VERSION = qv('0.0.1');
use Switch;
use Hessian::Exception;
use Hessian::Translator::String qw/:from_hessian/;

has input_handle => ( is => 'rw', isa => 'GlobRef' );

before 'translate' => sub {    #{{{
    my ( $self, $input ) = @_;
    my $input_handle;
    $input_handle = $input->{input_handle};
    if ( !$input_handle and $input->{input_string} ) {
        open $input_handle, "<", \$input->{input_string}
          or
          InputOutput::X->throw( error => "Unable to read from string input." );
    }
    my $ih_type = ref $input_handle;
    Parameter::X->throw( error => "Must pass an input handle "
          . "('input_handle') or string "
          . "('input_string') to translate" )
      unless $ih_type and $ih_type eq 'GLOB';
    $self->input_handle($input_handle);
};    #}}}

sub translate {    #{{{
    my ( $self) = @_;
    my $handle = $self->{input_handle};
    my $first;
    read $handle, $first, 1;
    print "First character received:\n $first\n";
    switch ($first) {
       case 'S' { } 
        
        
        }
    close $handle;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Input - Process an hessian input string or filehandle.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 translate



