package Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

with qw/
  Hessian::Deserializer::Numeric
  Hessian::Deserializer::String
  Hessian::Deserializer::Date
  Hessian::Deserializer::Binary
  /;


has 'input_handle' => (    #{{{
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
);    #}}}

after 'input_string' => sub {    #{{{
    my $self = shift;

    # Get rid of the input file handle if user has given us a new string to
    # process. input handle should then re-initialize itself the next time it
    # is called.
    delete $self->{input_handle} if $self->{input_handle};
};    #}}}

before qw/deserialize_data deserialize_message/ => sub {    #{{{
    my ( $self, $input ) = @_;
    my $input_string = $input->{input_string};
    $self->input_string($input_string) if $input_string;
};    #}}}

sub deserialize_data {    #{{{
    my ( $self, $args ) = @_;
    my $result = $self->read_hessian_chunk($args);
    return $result;
}    #}}}

sub deserialize_message {    #{{{
    my ( $self, $args ) = @_;
    my $result;
    eval { $result = $self->read_message_chunk(); };
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

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer - Add deserialization capabilities to processor.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


=head2    deserialize_data


=head2    deserialize_message


