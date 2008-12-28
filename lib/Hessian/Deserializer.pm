package  Hessian::Deserializer;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

use Hessian::Translator::Composite ':deserialize';

sub  deserialize { #{{{
    my ($self, $args) = @_;
    my $input_handle =  $self->input_handle();
   my ($line,$output);
   while ( $line = read_hessian_chunk($input_handle)) {
   }
    
    

} #}}}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer - Add deserialization capabilities to processor.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


