package Hessian::Client;

use Moose;
use version; our $VERSION = qv('0.0.1');

use Module::Load;
use YAML;
use List::MoreUtils qw/any/;

use Hessian::Exception;

has 'class_definitions' => ( is => 'rw', default => sub { [] } );
has 'type_list'         => ( is => 'rw', default => sub { [] } );
has 'reference_list'    => ( is => 'rw', default => sub { [] } );
has 'input_string'      => ( is => 'rw', isa     => 'Str' );
has 'version'           => ( is => 'ro', isa     => 'Int' );

before qw/input_string / => sub {    #{{{
    my $self = shift;
    if ( !$self->does('Hessian::Translator::Composite') ) {
        load 'Hessian::Translator::Composite';
        Hessian::Translator::Composite->meta()->apply($self);
    }
    if ( !$self->does('Hessian::Deserializer') ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);
    }
    $self->version();
};    #}}}

after 'version' => sub {    #{{{
    my ($self) = @_;
    my $version = $self->{version};
  PROCESSVERSION: {
        last PROCESSVERSION unless $version;
        Parameter::X->throw( error => "Version should be either 1 or 2." )
          if $version !~ /^(?:1|2)$/;
        last PROCESSVERSION
          if $self->does('Hessian::Translator::V1')
              or $self->does('Hessian::Translator::V2');
        last PROCESSVERSION if ! $self->does('Hessian::Deserializer');
        my $version_role = 'Hessian::Translator::V' . $version;
        load $version_role;
        $version_role->meta()->apply($self);
    }    #PROCESSVERSION
};    #}}}

sub BUILD {    #{{{
    my ( $self, $params ) = @_;
    if ( any { defined $params->{$_} } qw/input_string input_handle/ ) {
        load 'Hessian::Deserializer';
        load 'Hessian::Translator::Composite';
        Hessian::Translator::Composite->meta()->apply($self);
        Hessian::Deserializer->meta()->apply($self);

        $self->version();
    }

    #    if ( any { defined $params->{$_} } qw/output_string output_handle/ ) {
    #        print "composing serialier\n";
    #    }
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Client - Base class for Hessian serialization/deserialization.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


