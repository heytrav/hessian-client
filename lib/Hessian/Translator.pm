package  Hessian::Translator;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

use Perl6::Export::Attrs;
use List::MoreUtils qw/apply/;
use Math::Int64 qw/int64_to_net int64 net_to_int64/;
use Math::BigInt;
use Switch;

sub write_chunk {    #{{{
    my $string = shift;
    my $hessian_message = pack 'n/a*', $string;
    return $hessian_message;
}    #}}}

sub write_string : Export(:to_hessian) {    #{{{
    my @string_chunks = @_;
    my $message = hessianify_chunks( 's', @string_chunks );
    return $message;
}    #}}}

sub read_string : Export(:from_hessian) {    #{{{
    my $string_body = shift;
    my $message = de_hessianify_chunks( 's', $string_body );
    return $message;
}    #}}}

sub read_xml : Export(:from_hessian) {    #{{{
    my $xml_body = shift;
    my $message = de_hessianify_chunks( 'x', $xml_body );
    return $message;
}    #}}}

sub read_chunk {    #{{{
    my $string_chunk = shift;
    my ($message) = unpack 'n/a', $string_chunk;
    return $message;
}    #}}}

sub write_xml : Export(:to_hessian) {    #{{{
    my @xml_chunks = @_;
    my $message = hessianify_chunks( 'x', @xml_chunks );
    return $message;
}    #}}}

sub de_hessianify_chunks {    #{{{
    my ( $prefix, $body ) = @_;
    my $first_prefix = lc $prefix;
    my $prefix_regex = qr/
       $prefix 
       (
        \d+  
         (?:  
             (?! $prefix \d+ ) 
             . 
         ) * 
       ) 
    /x;
    my @chunks = apply { read_chunk($_) } $body =~ /$prefix_regex/g;
    my $message = join "" => @chunks;
    return $message;
}    #}}}

sub hessianify_chunks {    #{{{
    my ( $prefix, @chunks ) = @_;
    my $last_chunk = pop @chunks;
    my @message    = apply {
        ( lc $prefix ) . write_chunk($_);
    }
    @chunks[ 0 .. ( $#chunks - 1 ) ];
    my $last_prefix = uc $prefix;
    push @message, $last_prefix . write_chunk($last_chunk);
    my $result = join "" => @message;
    return $result;
}    #}}}

sub write_integer : Export(:to_hessian) {    #{{{
    my $integer            = shift;
    my $single_octet_range = [ -16 .. 31 ];
    my $double_octet_range = [ -2048 .. 2047 ];
    my $triple_octet_range = [ -262144 .. 262143 ];
    my $result;
    switch ($integer) {
        case [ -16 .. 31 ]         { $result = write_single_octet($integer) }
        case [ -2048 .. 2047 ]     { $result = write_double_octet($integer) }
        case [ -262144 .. 262143 ] { $result = write_triple_octet($integer) }
        else { $result = write_quadruple_octet($integer) }
    }
    return 'I' . $result;
}    #}}}

sub  write_quadruple_octet : Export(:to_hessian) { #{{{
    my $integer = shift;
    my $new_int = pack 'N', $integer;
    return $new_int;
} #}}}

sub write_single_octet : Export(:to_hessian) {    #{{{
    my $number = shift;

    # {-16 >= x >= 31: x + x90 = b0}
    my $new_int = pack "C*", ( $number + 0x90 );
    return $new_int;
}    #}}}

sub write_double_octet : Export(:to_hessian) {    #{{{
    my $integer = shift;
    # {-2048 >= x >= 2047: x = 256 * (b0 - xd8) + b1 }
    my $big_short = pack "n", $integer;
    my @bytes = reverse unpack "C*", $big_short;
    my $high_bit = ( ( $integer - $bytes[0] ) >> 8 ) + 0xc8;
    my $new_int = pack 'C*', $high_bit, $bytes[0];
    return $new_int;
}    #}}}

sub write_triple_octet  : Export(:to_hessian){    #{{{
    my $integer = shift;
    # { -262144 >= x >= 262143: x = 65536 * (b0 - x5c) + 256 * b1 + b0}
    my $big_short = pack "N", $integer;
    my @bytes     = reverse unpack "C*", $big_short;
    my $high_bit = ( ( $integer - $bytes[0] - ( $bytes[1] >> 8 ) ) >> 16 ) + 0xd4;
    my $new_int = pack 'C*', $high_bit, $bytes[1], $bytes[0];
    return $new_int;

}    #}}}

sub write_date : Export(:to_hessian ) {    #{{{
    my $epoch_time    = shift;
    my $epoch_big_int = Math::BigInt->new($epoch_time);

    # Note: Hessian expects 64 bit dates.  Since some systems, including my
    # are 32 bit, I need to some hacking to get around this.
    $epoch_big_int->bmul(1000);            # to add milliseconds

    my $time64          = int64($epoch_big_int);
    my $time_in_network = int64_to_net($epoch_big_int);
    return 'd' . $time_in_network;
}    #}}}

sub read_date : Export(:from_hessian) {    #{{{
    my $hessian_date = shift;
    $hessian_date =~ s/^d(.*)/$1/;

    # Assume caller has already filtered out the leading 'd'
    my @unpacked_input = unpack 'CCCCCCCC', $hessian_date;
    my $int            = Math::BigInt->new(0);
    my $shift_val      = 0;
    foreach my $bit_pos ( reverse @unpacked_input ) {
        my $to_shift = Math::BigInt->new($bit_pos);
        $to_shift->blsft($shift_val);
        $int->bxor($to_shift);
        $shift_val += 8;
    }
    $int->bdiv(1000);    # drop milliseconds
    return $int;
}    #}}}

sub write_boolean {    #{{{
    my $bool_val = shift;
    return
        $bool_val =~ /t(?:rue)?/i  ? 'T'
      : $bool_val =~ /f(?:alse)?/i ? 'F'
      :                              'N';

    # throw a fault
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator - Provide some basis methods for translating to/from
Hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 INTERFACE

=head2 write_chunk

Proxy method for preparing I<chunks> of character sequences (a.k.a strings)
for transmission as Hessian strings.  This entails putting a 16 bit short at
the start of each chunk indicating the length of each chunk.

=head2 write_string

What to call to translate an ordinary text string into Hessian string.

=head2 read_string

The inverse of L</read_string>. Reads a Hessian string and returns a normal
text string.

=head2 read_xml

Like L</read_string> except intended for xml documents.

=head2 read_chunk

=head2 write_xml

=head2 de_hessianify_chunks

=head2 hessianify_chunks

=head2 write_integer

=head2 write_date

=head2 read_date

=head2 write_boolean


