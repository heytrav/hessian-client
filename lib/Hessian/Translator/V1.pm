package Hessian::Translator::V1;

use Moose::Role;
use version; our $VERSION = qv('0.0.1');

use Switch;
use YAML;
use Hessian::Exception;
use Hessian::Translator::Numeric qw/:input_handle/;
use Hessian::Translator::String qw/:input_handle/;
use Hessian::Translator::Date qw/:input_handle/;
use Hessian::Translator::Binary qw/:input_handle/;
use Simple;

sub read_message_chunk_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $datastructure;
    switch ($first_bit) {
        case /\x63/ {            # version 1 call
            my $hessian_version = $self->read_version();
            my $rpc_data = $self->read_rpc();
            $datastructure = { 
                hessian_version => $hessian_version,
                call => $rpc_data
                };

        }
        case /\x66/ {            # version 1 fault
            my @tokens;
            while ( my $token = $self->deserialize_data() ) {
                push @tokens, $token;
            }
            my $exception_name        = $tokens[1];
            my $exception_description = $tokens[3];
        }
        case /\x72/ {            # version 1 reply
            my $hessian_version = $self->read_version();
            $datastructure =
              { hessian_version => $hessian_version, state => 'reply' };
        }
        else {
            $datastructure = $self->deserialize_data(
                {
                    first_bit => $first_bit
                }
            );
        }
    }
    return $datastructure;

}    #}}}

sub read_composite_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $datastructure, $save_reference );
    switch ($first_bit) {
        case /\x72/ {
            $datastructure = $self->read_remote_object();
        }
        case /[\x56\x76]/ {    # typed lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list($first_bit);
        }
        case /\x4d/ {          # typed map
            push @{ $self->reference_list() }, {};
            $datastructure = $self->read_map_handle();
        }
        case /[\x4f\x6f]/ {    # object definition or reference
            push @{ $self->reference_list() }, {};
            $datastructure = $self->read_class_handle( $first_bit, );
        }
    }
    return $datastructure;

}    #}}}

sub read_typed_list {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $v1_type      = $self->read_v1_type($first_bit);
    my ( $entity_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
    return $self->read_untyped_list($next_bit) unless defined $entity_type;

    my $type = $self->store_fetch_type($entity_type);
    my $array_length;
    read $input_handle, $next_bit, 1 unless $next_bit;
    if ( $next_bit eq 'l' ) {
        $array_length = $self->read_list_length($next_bit);
    }

    my $datastructure = $self->reference_list()->[-1];
    my $index         = 0;
  LISTLOOP:
    {

        #  last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_typed_list_element($type); };
        last LISTLOOP if Exception::Class->caught('EndOfInput::X');
        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_remote_object {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $remote_type  = $self->read_v1_type()->{type};
    $remote_type =~ s/\./::/g;
    my $class_definition = {
        type   => $remote_type,
        fields => ['remote_url']
    };
    return $self->assemble_class(
        {
            type      => $remote_type,
            data      => {},
            class_def => $class_definition
        }
    );
}    #}}}

sub read_v1_type {    #{{{
    my ( $self, $list_bit ) = @_;
    my ( $type, $first_bit, $array_length );
    my $input_handle = $self->input_handle();
    if ( $list_bit and $list_bit =~ /\x76/ ) {    # v
        read $input_handle, $type,         1;
        read $input_handle, $array_length, 1;
    }
    else {
        read $input_handle, $first_bit, 1;
        if ( $first_bit =~ /t/ ) {
            $type = $self->read_hessian_chunk({ first_bit => 'S'});
        }
    }
#    print "Got type $type, first_bit $first_bit\n";
    return { type => $type, next_bit => $array_length } if $type;
    return { next_bit => $first_bit };
}    #}}}

sub read_class_handle {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $save_reference, $datastructure );
    switch ($first_bit) {
        case /\x4f/ {      # Read class definition
            my $class_name_length = $self->read_hessian_chunk();
            my $class_type;
            read $input_handle, $class_type, $class_name_length;

            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            $datastructure = $self->store_class_definition($class_type);
        }
        case /\x6f/ {    # The class definition is in the ref list
            $save_reference = 1;
            $datastructure  = $self->fetch_class_for_data();
        }
    }

    return $datastructure;
}    #}}}

sub read_map_handle {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $v1_type      = $self->read_v1_type();
    my ( $entity_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
    my $type = $self->store_fetch_type($entity_type) if $entity_type;
    my $key;
    if ($next_bit) {
        $key = $self->read_hessian_chunk( { first_bit => $next_bit } );
    }

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        eval { $key = $self->read_hessian_chunk(); } unless $key;
        last MAPLOOP if Exception::Class->caught('EndOfInput::X');
        my $value = $self->read_hessian_chunk();
        push @key_value_pairs, $key => $value;
        undef $key;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements

    my $datastructure = $self->reference_list()->[-1];
    my $hash          = {@key_value_pairs};
    foreach my $key ( keys %{$hash} ) {
        $datastructure->{$key} = $hash->{$key};
    }
    my $map = defined $type ? bless $datastructure => $type : $datastructure;
    return $map;

}    #}}}

sub read_untyped_list {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $array_length = $self->read_list_length( $first_bit, );

    my $datastructure = $self->reference_list()->[-1];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_hessian_chunk(); };
        last LISTLOOP
          if Exception::Class->caught('EndOfInput::X');

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_simple_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $element;
    switch ($first_bit) {
        case /\x00/ {
            $element = $self->read_hessian_chunk();
        }
        case /\x4e/ {              # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {        # 'T'rue or 'F'alse
            $element = read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xaf\xc0-\xcf\xd0-\xd7]/ {
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4c\xd8-\xef\xf0-\xff\x38-\x3f]/ {
            $element = read_long_handle_chunk( $first_bit, $input_handle );
        }
        case /\x44/ {
            $element = read_double_handle_chunk( $first_bit, $input_handle );
        }
        case /\x64/ {
            $element = read_date_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x53\x58\x73\x78\x00-\x0f]/ {    #   for version 1: \x73
            $element = read_string_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x42\x62]/ {
            $element = read_binary_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4d\x4f\x56\x6f\x72\x76]/ {     # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        case /\x52/ {
            my $reference_id = read_integer_handle_chunk( 'I', $input_handle );
            $element = $self->reference_list()->[$reference_id];
        }
        case /[\x48\x6d]/ {                     # a header or method name
            $element = read_string_handle_chunk( 'S', $input_handle );
        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

}    #}}}

sub read_list_type {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $type_length;
    read $input_handle, $type_length, 1;
    my $type = read_string_handle_chunk( $type_length, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $type;
}    #}}}

sub read_rpc {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $call_data    = {};
    my $call_args;
    my $in_header;
  RPCSTRUCTURE: {
        my $first_bit;
        read $input_handle, $first_bit, 1;
        my $element;
        eval {
            $element = $self->read_hessian_chunk( { first_bit => $first_bit } );
        };
        last RPCSTRUCTURE if Exception::Class->caught('EndOfInput::X');
        switch ($first_bit) {
            case /\x6d/ {
                $in_header = 0;
                $call_data->{method} = $element;
            }
            case /\x48/ {
                $in_header = 1;
                push @{ $call_data->{headers} }, { header => $element };
            }

            else {
                if ($in_header) {
                    push @{ $call_data->{headers}->[-1]->{elements} }, $element;
                }
                else {
                    push @{$call_args}, $element;
                }
            }
        }
        redo RPCSTRUCTURE;
    }
   $call_data->{arguments} = $call_args;
   return $call_data;
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




