package  Communication::v2Serialization;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');
use base 'Communication';

use Test::More;
use Test::Deep;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::Epoch;
use URI;
use Hessian::Translator;
use Hessian::Serializer;
use Hessian::Translator::V2;
use SomeType;
use YAML;
use Data::Dumper;

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
    like( $hessian_data, qr/V\x90S\x00\x06foobarz/,
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

sub t022_serialize_object : Test(1) {    #{{{
    my $self     = shift;
    my $some_obj = SomeType->new(
        color   => 'aquamarine',
        model   => 'Beetle',
        mileage => 65536
    );
    my $client = Hessian::Translator->new( version => 2 );
    Hessian::Translator::V2->meta()->apply($client);
    Hessian::Serializer->meta()->apply($client);
    my $hessian_output = $client->serialize_chunk($some_obj);
    binmode( STDOUT, 'utf8' );
    my ($hessian_obj) = $hessian_output =~ /(O.*)/s;

    # Re-parse hessian to create object:
    $client->input_string($hessian_output);
    my $processed_obj = $client->deserialize_message();
    $processed_obj = $client->deserialize_message();
    cmp_deeply( $processed_obj, $some_obj, "Processed object as expected." );
}    #}}}

sub t023_serialize_date : Test(2) {    #{{{
    my $self = shift;
    my $client = Hessian::Translator->new( version => 2 );
    Hessian::Translator::V2->meta()->apply($client);
    Hessian::Serializer->meta()->apply($client);
    $client->serializer();
    my $date = DateTime->new(
        year      => 1998,
        month     => 5,
        day       => 8,
        hour      => 9,
        minute    => 51,
        second    => 31,
        time_zone => 'UTC'
    );

    my $hessian_date = $client->serialize_chunk($date);
    like(
        $hessian_date,
        qr/d\x00\x00\x00\xd0\x4b\x92\x84\xb8/,
        "Processed a hessian date."
    );
    $client->input_string($hessian_date);
    my $processed_time = $client->deserialize_message();
    $self->compare_date( $date, $processed_time );

}    #}}}

sub t025_serialize_call : Test(4) {    #{{{
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
        qr/c\x02\x00m\x00\x04add2\x92\x93z/,
        "Received expected string for hessian call."
    );
    $client->input_string($hessian_data);
    my $processed_data = $client->process_message();
    cmp_deeply(
        $processed_data->{call},
#        $processed_data->[0]->{call},
        $datastructure->{call},
        "Received same structure as call."
    );

    my $datastructure2 = {
        call => {
            method    => 'hello',
            arguments => ['hello, world']
        }
    };
    my $hessian_data2 = $client->serialize_message($datastructure2);
    like(
        $hessian_data2,
        qr/c\x02\x00m\x00\x05helloS\x00\x0chello, worldz/,
        "Created a hessian call."
    );
}    #}}}

sub t027_serialize_enveloped_message : Test(2) {    #{{{
    my $self          = shift;
    my $datastructure = {
        envelope => {
            call => {
                method    => 'hello',
                arguments => ['hello, world']
            },
            meta    => 'Identity',
            headers => [],
            footers => []
        }
    };
    my $client = Hessian::Translator->new( version => 2 );
    Hessian::Translator::V2->meta()->apply($client);
    Hessian::Serializer->meta()->apply($client);

    my $hessian_data = $client->serialize_message($datastructure);
    $client->input_string($hessian_data);
    my $processed_data = $client->process_message()->{envelope}->{packet};
    if ($processed_data) {
        my $reverse_datastructure = $processed_data;
        cmp_deeply(
            $reverse_datastructure,
            superhashof( $datastructure->{envelope} ),
            "Successfully mapped an enveloped datastructure back to itself."
        );
    }
    my $text           = "Lorem ipsum dolor sit amet, consectetur adipisicing";
    my $datastructure2 = {
        envelope => {
            data    => $text,
            meta    => 'Identity',
            headers => [],
            footers => []
        }
    };
    $hessian_data = $client->serialize_message($datastructure2);
    $client->input_string($hessian_data);
    my $processed_message =
      $client->process_message()->{envelope}->{packet};
    if ($processed_message) {
        is( $text, $processed_message, "Received expected message." );
    }

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Communication::v2Serialization - Test serialization of Hessian version 2

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


