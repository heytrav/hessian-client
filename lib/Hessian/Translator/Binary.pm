package  Hessian::Translator::Binary;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use Switch;

sub read_binary_handle_chunk : Export(:input_handle) {    #{{{
    my ( $first_bit, $input_handle ) = @_;
    my ( $binary, $data, $length );

    switch ($first_bit) {
        case /[\x42\x62]/ {
            read $input_handle, $data, 2;
            $length = unpack "n",  $data;

        }
        case /[\x20-\x2f]/ { 
        $length = $first_bit - 0x20; # standard octet shift    

        #perl -e 'my $hessian = "\x23"; my $raw_octet = unpack "C", $hessian;
#        my $shifted_octet = $raw_octet - x20; print "Shifted octet as hex =
#        ".$shifted_octet."\n"; my $new_char = pack "n*",
#        "\x00",$shifted_octet;print "new char: $new_char\n"; print "shifted
#        octet: ".chr($shifted_octet)."\n"'

            }

    }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Binary - Translate Hessian to and from binary data

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


