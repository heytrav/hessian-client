package Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

with 'Hessian::Translator::Composite';

use YAML;

#use Hessian::Translator::Composite ':deserialize';
#use Hessian::Translator::Envelope ':deserialize';
use Hessian::Exception;
use Simple;

#has 'is_nested'    => ( is => 'rw', isa => 'Bool', default => 0 );
has 'is_version_1' => ( is => 'rw', isa => 'Bool', default => 0 );
#has 'input_string' => ( is => 'rw', isa => 'Str' );

#after 'input_string' => sub {
#    my $self = shift;

#    # Get rid of the input file handle if user has given us a new string to
#    # process. input handle should then re-initialize itself the next time it
#    # is called.
#    delete $self->{input_handle} if $self->{input_handle};
#};

#has 'input_handle' => (
#    is      => 'rw',
#    isa     => 'GlobRef',
#    lazy    => 1,
#    default => sub {
#        my $self = shift;
#        my $input_handle;
#        my $input_string = $self->{input_string};
#        if ($input_string) {
#            open $input_handle, "<", \$input_string
#              or InputOutput::X->throw(
#                error => "Unable to read from string input." );
#            return $input_handle;
#        }
#    }
#);

before qw/deserialize_data deserialize_message/ => sub {    #{{{
    my ( $self, $input ) = @_;
    my $input_string = $input->{input_string};
    $self->input_string($input_string) if $input_string;
};    #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer - Add deserialization capabilities to processor.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


