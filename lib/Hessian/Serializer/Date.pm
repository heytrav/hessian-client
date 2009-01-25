package  Hessian::Serializer::Date;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

requires qw/write_integer write_long/;

sub write_date  {    #{{{
    my ($self, $epoch_time) = @_;
    my $time =
      $epoch_time <= 4_294_967_295
      ? $self->write_integer($epoch_time)
      : $self->write_long($epoch_time);
    if ($self->version() == 1) {
        $time =~ s/^(?:I|L )/d/;
    }
    else {
        $time =~ s/^L/\x4a/;
        $time =~ s/^I/\x4b/;

    }
    return $time;
}    #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer::Date - Role for serializing dates into Hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 write_date
