package Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');
use YAML;

use Hessian::Translator::Composite ':deserialize';
use Hessian::Translator::Envelope ':deserialize';
use Simple;

has 'input_handle' => ( is => 'rw', isa => 'GlobRef' );

before qw/deserialize_chunk deserialize_message/ => sub {    #{{{
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

sub deserialize_chunk {    #{{{
    my ( $self, $args ) = @_;
    my $input_handle = $self->input_handle();
    my ( $line, $output );

    # Yes, I'm passing the object itself as a parameter so I can add
    # references, class definitions and objects to the different lists as they
    # occur.
    my $result = read_hessian_chunk( $input_handle, $self );
    return $result;
}    #}}}

sub  deserialize_message { #{{{
    my ($self, $args) = @_;
    my $input_handle = $self->input_handle();
    my $result = read_message_chunk($input_handle, $self);
    return $result;
} #}}}

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

        # We're going to assume that fields are submitted in the same order
        # the class fields were defined.  If a field should be empty, then a
        # NULL should be submitted
        my $value =
          $self->deserialize_chunk( { input_handle => $self->input_handle() } );
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


