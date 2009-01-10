package Hessian::Client;

use Moose;
use version; our $VERSION = qv('0.0.1');

use Module::Load;
use YAML;
use List::MoreUtils qw/any/;

use Hessian::Exception;

#with 'Hessian::Deserializer';

has 'class_definitions' => ( is => 'rw', default => sub { [] } );
has 'type_list'         => ( is => 'rw', default => sub { [] } );
has 'reference_list'    => ( is => 'rw', default => sub { [] } );
has 'input_string'      => ( is  => 'rw', isa => 'Str');

after 'input_string' => sub {
    my $self = shift;
    # Get rid of the input file handle if user has given us a new string to
    # process. input handle should then re-initialize itself the next time it
    # is called.
    delete $self->{input_handle} if $self->{input_handle};
};

has 'input_handle' => (
    is      => 'rw',
    isa     => 'GlobRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $input_handle;
        my $input_string = $self->{input_string};
        if ($input_string) {
            open $input_handle, "<", \$input_string
              or InputOutput::X->throw(
                error => "Unable to read from string input." );
            return $input_handle;
        }
    }
);

sub BUILD {    #{{{
    my ( $self, $params ) = @_;
    if ( any { defined $params->{$_} } qw/input_string input_handle/ ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);
    }

#    if ( any { defined $params->{$_} } qw/output_string output_handle/ ) {
#        print "composing serialier\n";
#    }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Client - Base class for Hessian serialization/deserialization.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


