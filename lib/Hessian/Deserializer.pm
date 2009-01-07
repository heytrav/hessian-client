package Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');
use YAML;

use Hessian::Translator::Composite ':deserialize';
use Hessian::Translator::Envelope ':deserialize';
use Hessian::Exception;
use Simple;

has 'is_nested'    => ( is => 'rw', isa => 'Bool', default => 0 );
has 'is_version_1' => ( is => 'rw', isa => 'Bool', default => 0 );

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
    my $result = read_hessian_chunk( $self->input_handle(), $self,$args );
    return $result;
}    #}}}

sub deserialize_message {    #{{{
    my ( $self, $args ) = @_;
    my $result;
    eval {
        $result = read_message_chunk( $self->input_handle(), $self );
    };
    return if Exception::Class->caught('EndOfInput::X');
    return $result;
}    #}}}

sub next_token {    #{{{
    my $self = shift;
    return $self->deserialize_message();
}    #}}}

sub process_message {    #{{{
    my $self = shift;
    my @tokens;
    while ( my $token = $self->next_token() ) {
        push @tokens, $token;
    }
    return \@tokens;
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

        # We're going to assume that fields are submitted in the same order
        # the class fields were defined.  If a field should be empty, then a
        # NULL should be submitted
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


