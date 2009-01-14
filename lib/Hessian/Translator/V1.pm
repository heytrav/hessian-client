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

sub read_composite_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $datastructure, $save_reference );
    binmode( $input_handle, 'bytes' );
    switch ($first_bit) {
        case /[\x56\x76]/ {           # typed lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list($first_bit);
        }

        case /[\x57\x58\x78-\x7f]/ {    # untyped lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_untyped_list( $first_bit, );
        }
        case /\x48/ {
            push @{ $self->reference_list() }, {};
            $datastructure = $self->read_map_handle();
        }
        case /\x4d/ {                   # typed map
            push @{ $self->reference_list() }, {};
            $datastructure = $self->read_map_handle();
        }
        case /[\x4f\x6f]/ {
            push @{ $self->reference_list() }, {};
            $datastructure = $self->read_class_handle( $first_bit, );

        }
    }

    return $datastructure;

}    #}}}

# version 1 specific
sub read_version1_map {    #{{{
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $version1_t;
    read $input_handle, $version1_t, 1;
    my ( $type, $first_key_value_pair );
    if ( $version1_t eq 't' ) {
        $type = $self->read_hessian_chunk();
    }
    else {

        # no type, so read the rest of the chunk to get the actual
        # datastructure
        my $key;
        switch ($version1_t) {
            case /[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ {
                $key = read_integer_handle_chunk( $version1_t, $input_handle );
            }
            case /[\x52\x53\x00-\x1f\x30-\x33\x73]/ {
                $key = read_string_handle_chunk( $version1_t, $input_handle );
            }
        }

        # now read the next element out to make sure the remaining has has
        # an even number of elements
        my $value = $self->read_hessian_chunk();
    }

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
            $type = $self->read_hessian_chunk();
        }
    }
    return { type => $type, next_bit => $array_length } if $type;
    return { next_bit => $first_bit };
}    #}}}

# version 2 specific
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
            print "Class type $class_type\n";
            my $length;
            read $input_handle, $length, 1;
            my $number_of_fields =
              read_integer_handle_chunk( $length, $input_handle );
            my @field_list;

            foreach my $field_index ( 1 .. $number_of_fields ) {

                # using the wrong function here, but who cares?
                my $field = $self->read_hessian_chunk();
                push @field_list, $field;

            }

            my $class_definition =
              { type => $class_type, fields => \@field_list };
            push @{ $self->class_definitions() }, $class_definition;
            $datastructure = $class_definition;
        }
        case /\x6f/ {    # The class definition is in the ref list
            $save_reference = 1;
            my $class_number;
            read $input_handle, $class_number, 1;
            my $class_definition_number =
              read_integer_handle_chunk( $class_number, $input_handle );
            $datastructure = $self->instantiate_class($class_definition_number);
        }
    }

    #    push @{ $self->reference_list() }, $datastructure
    #      if $save_reference;
    return $datastructure;
}    #}}}

# mostly version 2 specific
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

# version 2 specific
sub read_list_length {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();

    my $array_length;
    if ( $first_bit =~ /[\x56\x58]/ ) {    # read array length
        my $length;
        read $input_handle, $length, 1;
        $array_length = read_integer_handle_chunk( $length, $input_handle );
    }
    elsif ( $first_bit =~ /[\x70-\x77]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x70;
    }
    elsif ( $first_bit =~ /[\x78-\x7f]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x78;
    }
    elsif ( $first_bit =~ /\x6c/ ) {
        $array_length = read_integer_handle_chunk( 'I', $input_handle );
        print "received array length of $array_length\n";
    }
    return $array_length;
}    #}}}

# version 2 specific
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
          if

            #            $first_bit =~ /\x57/ &&
            Exception::Class->caught('EndOfInput::X');

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

sub read_hessian_chunk {    #{{{
    my ( $self, $args ) = @_;
    my $input_handle = $self->input_handle();
    binmode( $input_handle, 'bytes' );
    my ( $first_bit, $element );
    if ( 'HASH' eq ( ref $args ) and $args->{first_bit} ) {
        $first_bit = $args->{first_bit};
    }
    else {
        read $input_handle, $first_bit, 1;
    }

    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit =~ /z/i;

    switch ($first_bit) {
        case /\x00/ {
            $element = $self->read_hessian_chunk();
        }
        case /\x4e/ {    # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {    # 'T'rue or 'F'alse
            $element = read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xaf\xc0-\xcf\xd0-\xd7]/ {
            $element = read_integer_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4c\x59\xd8-\xef\xf0-\xff\x38-\x3f]/ {
            $element = read_long_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x44\x5b-\x5f]/ {
            $element = read_double_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x4a\x4b]/ {
            $element = read_date_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x53\x00-\x1f\x30-\x33]/ {    #   for version 1: \x73
            $element = read_string_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x41\x42\x20-\x2f\x34-\x37\x62]/ {
            $element = read_binary_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x43\x4d\x4f\x48\x55-\x58\x60-\x6f\x70-\x7f]/
        {                                        # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        case /\x52/ {
            my $reference_id = read_integer_handle_chunk( 'I', $input_handle );
            $element = $self->reference_list()->[$reference_id];

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

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




