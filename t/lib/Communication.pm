package Communication;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use DateTime;
use DateTime::Format::Strptime;
use Hessian::Translator;

__PACKAGE__->SKIP_CLASS(1);

sub compare_date {    #{{{
    my ( $self, $original_date, $processed_time ) = @_;

    my $cmp = DateTime->compare( $original_date, $processed_time );
    is( $cmp, 0, "Hessian date as expected." );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication - Test communication in Hessian

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


