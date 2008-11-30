package  Datatype::Date;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Test::Class';

use Test::More;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::Epoch;
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
    $self->{date_with_sec} = DateTime->new(
        year      => 1998,
        month     => 5,
        day       => 8,
        hour      => 9,
        minute    => 51,
        second    => 31,
        time_zone => 'UTC'
    );
    $self->{epoch_formatter} = DateTime::Format::Epoch->new(
        unit  => 'milliseconds',
        type  => 'bigint',
        epoch => DateTime->new(
            year      => 1970,
            month     => 1,
            day       => 1,
            time_zone => 'UTC'
        )
    );
    $self->{byte_string} = "\x{4b}\x{35}\x{52}\x{d5}\x{84}";

}    #}}}

sub t010_to_hessian : Test(1) {    #{{{
    my $self         = shift;
    my $date_epoch   = $self->{date}->epoch();
    my $hessian_date = write_date($date_epoch);
    my $byte_string  = $self->{byte_string};
    like( $hessian_date, qr/  $byte_string /xms,
        "Simple translation of date." );

}    #}}}

sub t020_from_hessian : Test(1) {    #{{{
    my $self              = shift;
    my $byte_string       = $self->{byte_string};
    my $processed_time    = read_date($byte_string);
    my $from_hessian_date = DateTime->from_epoch( epoch => $processed_time );
    my $readable_date     = $self->{formatter}->format_datetime($from_hessian_date);
    $from_hessian_date->set_time_zone('UTC');

    my $cmp = DateTime->compare( $self->{date}, $from_hessian_date );
    is( $cmp, 0, "Hessian date as expected." );

}    #}}}

sub t030_eight_byte_dates : Test(2) {    #{{{
    my $self        = shift;
    my $byte_string = "\x{4a}\x{00}\x{00}\x{00}\x{d0}\x{4b}\x{92}\x{84}\x{b8}";
    my $date        = $self->{date_with_sec};
    my $formatter   = $self->{epoch_formatter};
    my $formatted   = $formatter->format_datetime($date);

    #print "formatted epoch time: $formatted\n";
    my $hessian_date = write_date($formatted);
    like( $hessian_date, qr/  $byte_string /xms,
        "Simple translation of date." );
    my $processed_time    = read_date($byte_string);
    my $from_hessian_date = $formatter->parse_datetime($processed_time);
    my $readable_date =
      $self->{formatter}->format_datetime($from_hessian_date);
#    print "Interpreted datetime: $readable_date\n";
    $from_hessian_date->set_time_zone('UTC');

    my $cmp = DateTime->compare( $date, $from_hessian_date );
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


