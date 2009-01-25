package  Hessian::Deserializer::Date;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

sub read_date_handle_chunk  {    #{{{
    my ( $self, $first_bit,) = @_;
    my $input_handle = $self->input_handle();
    my ( $date, $data );
    switch ($first_bit) {
        case /\x4a/ {
            $data = $self->read_long_handle_chunk( 'L');
        }
        case /[\x4b\x64]/ {
            $data = $self->read_integer_handle_chunk( 'I');
        }
    }
    return $data;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Date - Methods for deserializing hessian dates.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


