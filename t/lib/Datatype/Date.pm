package  Datatype::Date;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use DateTime;
use DateTime::Format::Strptime;
use Hessian::Translator::Date qw/:to_hessian :from_hessian/;

sub prepare_date : Test(setup) {    #{{{
    my $self = shift;
    $self->{formatter} = DateTime::Format::Strptime->new(
        pattern   => '%F %T',
        time_zone => 'GMT'
    );
    $self->{date} = DateTime->new(
        year      => 1998,
        month     => 5,
        day       => 8,
        hour      => 9,
        minute    => 51,
        time_zone => 'UTC'
    );
    $self->{byte_string} = "\x{4b}\x{35}\x{52}\x{d5}\x{84}";

}    #}}}

sub t010_to_hessian : Test(1) {    #{{{
    my $self = shift;
    my $date_epoch   = $self->{date}->epoch();
    my $hessian_date = write_date($date_epoch);
    my $byte_string  = $self->{byte_string};
    like( $hessian_date, qr/  $byte_string /xms,
        "Simple translation of date." );

}    #}}}

sub t020_from_hessian {    #{{{
    my $self = shift;
    my $byte_string       = $self->{byte_string};
    my $processed_time    = read_date($byte_string);
    my $from_hessian_date = DateTime->from_epoch( epoch => $processed_time );
    my $readable_date =
      $self->{self}->format_datetime($from_hessian_date);
    $from_hessian_date->set_time_zone('UTC');

    my $cmp = DateTime->compare( $self->{date}, $from_hessian_date );
    is( $cmp, 0, "Hessian date as expected." );

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::Date - Test Date conversion to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE


