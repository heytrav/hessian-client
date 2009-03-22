package  Hessian::Deserializer::Date;

use Moose::Role;

use Switch;
use YAML;
use DateTime;
use DateTime::Format::Epoch;
use integer;

sub read_date_handle_chunk  {    #{{{
    my ( $self, $first_bit,) = @_;
    my $input_handle = $self->input_handle();
    my $formatter = DateTime::Format::Epoch->new(
        unit  => 'milliseconds',
        type  => 'bigint',
        epoch => DateTime->new(
            year      => 1970,
            month     => 1,
            day       => 1,
            time_zone => 'UTC'
        )
    );
    my ( $date, $data );
    switch ($first_bit) {
        case /[\x4a\x64]/ {
            $data = $self->read_long_handle_chunk( 'L');
        }
        case /\x4b/ {
            $data = $self->read_integer_handle_chunk( 'I');
        }
    }
    my $datetime = $formatter->parse_datetime($data);
    $datetime->set_time_zone('UTC');
    return $datetime;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Date - Methods for deserializing hessian dates.

=head1 VERSION

=head1 SYNOPSIS

These methods are only made to be used within the Hessian framework.

=head1 DESCRIPTION

This module reads the input file handle to deserialize Hessian dates.

=head1 INTERFACE

=head2 read_date_handle_chunk

Reads a date from the input handle;


