package Hessian;

use Moose;
use version; our $VERSION = qv('0.0.1');

use Module::Load;
use YAML;
use List::MoreUtils qw/any/;
use Hessian::Exception;

has 'class_definitions' => ( is => 'rw', default => sub { [] } );
has 'type_list'         => ( is => 'rw', default => sub { [] } );
has 'reference_list'    => ( is => 'rw', default => sub { [] } );
has 'input_string'      => (
    is  => 'rw',
    isa => 'Str',
);
has 'input_handle' => (
    is      => 'rw',
    isa     => 'GlobRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $input_handle;
        my $input_string = $self->input_string();
        if ($input_string) {
            open $input_handle, "<", \$input_string
              or InputOutput::X->throw(
                error => "Unable to read from string input." );
            my $ih_type = ref $input_handle;

            print "handle type is $ih_type\n";
            Hessian::Exception->throw( error => "Must pass an input handle "
                  . "('input_handle') or string "
                  . "('input_string') to translate" )
              unless $ih_type and $ih_type eq 'GLOB';
            print "setting input handle\n";
            return $input_handle;
        }
      }

);

sub BUILD {    #{{{
    my ( $self, $params ) = @_;
    print "Data to Build\n".Dump($params)."\n";
        if ( any { defined $params->{$_} } qw/input_string input_handle/ ) {
            print "composing deserializer\n";
            load 'Hessian::Deserializer';
            Hessian::Deserializer->meta()->apply($self);
        }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian - Base class for Hessian serialization/deserialization.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


