package Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

#with 'Hessian::Translator::Composite';

has 'is_version_1' => ( is => 'rw', isa => 'Bool', default => 0 );
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

after 'input_string' => sub {
    my $self = shift;
    # Get rid of the input file handle if user has given us a new string to
    # process. input handle should then re-initialize itself the next time it
    # is called.
    delete $self->{input_handle} if $self->{input_handle};
};

before qw/deserialize_data deserialize_message/ => sub {    #{{{
    my ( $self, $input ) = @_;
    my $input_string = $input->{input_string};
    $self->input_string($input_string) if $input_string;
};    #}}}

sub deserialize_data {    #{{{
    my ( $self, $args ) = @_;

    # Yes, I'm passing the object itself as a parameter so I can add
    # references, class definitions and objects to the different lists as they
    # occur.
    my $result = $self->read_hessian_chunk($args );
    return $result;
}    #}}}

sub instantiate_class {    #{{{
    my ( $self, $index ) = @_;
    my $class_definitions = $self->class_definitions;
    my $class_definition  = $self->class_definitions()->[$index];

    my $class_type = $class_definition->{type};
    my $simple_obj = bless {}, $class_type;
    {

        # This is so we can take advantage of Class::MOP/Moose's meta object
        # capabilities and add arbitrary fields to the new object.
        no strict 'refs';
        push @{ $class_type . '::ISA' }, 'Simple';
    }
    foreach my $field ( @{ $class_definition->{fields} } ) {
        $simple_obj->meta()->add_attribute( $field, is => 'rw' );
        my $value = $self->deserialize_data();
        $simple_obj->$field($value);
    }
    return $simple_obj;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer - Add deserialization capabilities to processor.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


