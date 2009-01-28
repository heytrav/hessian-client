package Hessian::Translator;

use Moose;
use version; our $VERSION = qv('0.0.1');

use Module::Load;
use YAML;
use List::MoreUtils qw/any/;

use Hessian::Exception;

has 'class_definitions' => ( is => 'rw', default => sub { [] } );
has 'type_list'         => ( is => 'rw', default => sub { [] } );
has 'reference_list'    => ( is => 'rw', default => sub { [] } );
has 'input_string'      => ( is => 'rw', isa     => 'Str' );
has 'version'           => ( is => 'ro', isa     => 'Int' );
has 'binary_mode'       => ( is => 'ro', isa => 'Bool', default => 0);
has 'serializer'           => (
    is      => 'rw',
    isa     => 'Bool',
);

before 'input_string' => sub {    #{{{
    my $self = shift;
    if ( !$self->does('Hessian::Deserializer') ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);
    }
    $self->version();
};    #}}}

before 'serializer' => sub   { #{{{
    my $self = shift;
    if ( !$self->does('Hessian::Serializer') ) {
        load 'Hessian::Serializer';
        Hessian::Serializer->meta()->apply($self);
    }
    $self->version();
}; #}}}

after 'version' => sub {    #{{{
    my ($self) = @_;
    my $version = $self->{version};
  PROCESSVERSION: {
        last PROCESSVERSION unless $version;
        Parameter::X->throw( error => "Version should be either 1 or 2." )
          if $version !~ /^(?:1|2)$/;
        last PROCESSVERSION
          if $self->does('Hessian::Translator::V1')
              or $self->does('Hessian::Translator::V2');
        last PROCESSVERSION
          if not(    $self->does('Hessian::Serializer')
                  or $self->does('Hessian::Deserializer') );
        my $version_role = 'Hessian::Translator::V' . $version;
        load $version_role;
        $version_role->meta()->apply($self);
    }    #PROCESSVERSION
};    #}}}

sub BUILD {    #{{{
    my ( $self, $params ) = @_;
    load 'Hessian::Translator::Composite';
    Hessian::Translator::Composite->meta()->apply($self);
    if ( any { defined $params->{$_} } qw/input_string input_handle/ ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);

    }

    if ( any { defined $params->{$_} } qw/service/ ) {
        load 'Hessian::Serializer';
        Hessian::Serializer->meta()->apply($self);
    }
    $self->version();

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator - Base class for Hessian serialization/deserialization.

=head1 SYNOPSIS

    my $translator = Hessian::Translator->new( version => 1 );

    my $hessian_string = "S\x00\x05hello";
    $translator->input_string($hessian_string);
    my $output = $translator->deserialize_message();


    # Apply serialization methods to the object.
    Hessian::Serializer->meta()->apply($translator);

=head1 DESCRIPTION

B<Hessian::Translator> is made to act as the base class (or whatever this is
called in Moose terminology) for serialization/deserialization methods.  

On its own the class really only provides some of the more basic functions
needed for Hessian processing such as the I<type list> for datatypes, the
I<reference list> for maps, objects and arrays; and the I<object class
definition list>.  Integration of the respective serialization and
deserialization behaviours only takes place I<when needed>. Depending on how
the translator is initialized and which methods are called on the object, it
is possibly to specialize the object for either Hessian 1.0 or Hessian 2.0
processing and to selectively include methods for serialization and or
deserialization.  

=head1 INTERFACE

=head2 BUILD

Not to be called directly.  


=head2 new


=over 2

=item
version

Allowed values are B<1> or B<2> and correspond to the respective Hessian
protocol version.


=back


=head2 input_string

=over 2

=item
string

The Hessian encoded string to be decoded.  This may represent an entire
message or a simple scalar or datastructure. Note that the first application
of this method causes the L<Hessian::Deserializer> role to be applied to this
class.


=back


=head2 version

Retrieves the current version for which this client was initialized. See
L</"new">.


=head2 class_definitions

Provides access to the internal class definition list.


=head2 type_list

Provides access to the internal type list.

=head2 reference_list

Provides access to the internal list of references.


=head2 serializer

Causes the L<Hessian::Serializer|Hessian::Serializer> methods to be applied to
the current object.
