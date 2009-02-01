package  Communication::v2Serialization;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Communication';

use Test::More;
use Test::Deep;
use DateTime;
use URI;
use Hessian::Translator;
use Hessian::Serializer;
use Hessian::Translator::V2;
use YAML;

sub t007_compose_serializer : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    Hessian::Translator::V2->meta()->apply($client);
    Hessian::Serializer->meta()->apply($client);
    ok(
        $client->does('Hessian::Serializer'),
        "Serializer role has been composed."
    );

    can_ok( $client, qw/serialize_chunk/, );
}    #}}}

sub t009_serialize_string : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $hessian_string = $client->serialize_chunk("hello");
    like( $hessian_string, qr/S\x{00}\x{05}hello/, "Created Hessian string." );
}    #}}}

sub t011_serialize_integer : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $hessian_string = $client->serialize_chunk(-256);
    like( $hessian_string, qr/  \x{c7} \x{00} /x, "Processed integer." );

    $hessian_string = $client->serialize_chunk(-1);
    like( $hessian_string, qr/\x8f/, "Processed -1." );

}    #}}}

sub t015_serialize_float : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $hessian_string = $client->serialize_chunk(12.25);
    like(
        $hessian_string,
        qr/D\x40\x28\x80\x00\x00\x00\x00\x00/,
        "Processed 12.25"
    );
}    #}}}

sub t017_serialize_array : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $datastructure = [ 0, 'foobar' ];
    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/\x57\x90S\x00\x06foobarZ/,
        "Interpreted a perl array." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_message();
    cmp_deeply( $datastructure, $processed_datastructure,
        "Mapped a simple array back to itself." );

}    #}}}

sub t020_serialize_hash_map : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $datastructure = { 1 => 'fee', 16 => 'fie', 256 => 'foe' };

    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/S\x00\x03fee/, "Found proper string key." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_data();
    cmp_deeply( $datastructure, $processed_datastructure,
        "Mapped a simple hash back to itself." );
}    #}}}

sub t021_serialize_mixed : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $datastructure = [
        qw/hello goodbye/,
        {
            1     => 'fee',
            2     => 'fie',
            three => 3
        }
    ];
    my $hessianized = $client->serialize_chunk($datastructure);
    $client->input_string($hessianized);
    my $processed = $client->deserialize_message();
    cmp_deeply( $processed, $datastructure,
        "Matched a complex datastructure to itself." );
}    #}}}

sub t023_serialize_date : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    $client->serializer();
    my $date = DateTime->new(
        year      => 1998,
        month     => 5,
        day       => 8,
        hour      => 9,
        minute    => 51,
        time_zone => 'UTC'
    );
    my $hessian_date = $client->serialize_chunk($date);
    like(
        $hessian_date,
        qr/\x4b\x{35}\x{52}\x{d5}\x{84}/,
        "Processed a hessian date."
    );
    $client->input_string($hessian_date);
    my $processed_time = $client->deserialize_message();
    $self->compare_date( $date, $processed_time );

}    #}}}

sub t025_serialize_call : Test(3) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    Hessian::Translator::V2->meta()->apply($client);
    Hessian::Serializer->meta()->apply($client);
    can_ok( $client, 'serialize_message' );
    my $datastructure = {
        call => {
            method    => 'add2',
            arguments => [ 2, 3 ]
        },
    };
    my $hessian_data = $client->serialize_message($datastructure);
    like(
        $hessian_data,
        qr/H\x02\x00CS\x00\x04add2\x92\x92\x93/,
        "Received expected string for hessian call."
    );
    $client->input_string($hessian_data);
    my $processed_data = $client->process_message();
    print "Processed " . Dump($processed_data) . "\n";
    cmp_deeply(
        $processed_data->[1]->{call},
        $datastructure->{call},
        "Received same structure as call."
    );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication::v2Serialization - Test serialization of Hessian version 2

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


