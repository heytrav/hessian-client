package Hessian::Translator::V2;

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



sub read_composite_datastructure { #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my ( $datastructure, $save_reference );
    binmode( $input_handle, 'bytes' );
    switch ($first_bit) {
        case /[\x55\x56\x70-\x77]/ {                          # typed lists
            $save_reference = 1;
            $datastructure = $self->read_typed_list( $first_bit,);
        }

        case /[\x57\x58\x78-\x7f]/ {                          # untyped lists
            $save_reference = 1;
            $datastructure = $self->read_untyped_list( $first_bit, );
        }
        case /\x48/ {
            $save_reference = 1;
            $datastructure  = $self->read_map_handle();
        }
        case /\x4d/ {                                         # typed map

            $save_reference = 1;

            # Get the type for this map. This seems to be more like a
            # perl style object or "blessed hash".

            my $map;
            my $map_type = $self->read_hessian_chunk();
            if ( $map_type !~ /^\d+$/ ) {
                push @{ $self->type_list() }, $map_type;
            }
            else {
                $map_type = $self->type_list()->[$map_type];
            }
            $map = $self->read_map_handle();
            $datastructure = bless $map, $map_type;

        }
        case /[\x43\x4f\x60-\x6f]/ {
            $datastructure = $self->read_class_handle( $first_bit, );

        }
    }
    push @{ $self->reference_list() }, $datastructure
      if $save_reference;
    return $datastructure;

}    #}}}

sub read_typed_list {    #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my $type          = $self->read_hessian_chunk();
    my $array_length  = $self->read_list_length( $first_bit );
    my $datastructure = [];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_typed_list_element( $type); };
        last LISTLOOP
          if $first_bit =~ /\x55/
              && Exception::Class->caught('EndOfInput::X');

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

# version 2 specific
sub read_class_handle {    #{{{
    my ($self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my ( $save_reference, $datastructure );
    switch ($first_bit) {
        case /\x43/ {      # Read class definition
            my $class_type = $self->read_hessian_chunk();
            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
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
        case /\x4f/ {    # Read hessian data and create instance of class
            my $length;
            $save_reference = 1;
            read $input_handle, $length, 1;
            my $class_definition_number =
              read_integer_handle_chunk( $length, $input_handle );
            $datastructure =
              $self->instantiate_class($class_definition_number);

        }
        case /[\x60-\x6f]/ {    # The class definition is in the ref list
            $save_reference = 1;
            my $hex_bit = unpack 'C*', $first_bit;
            my $class_definition_number = $hex_bit - 0x60;
            $datastructure =
              $self->instantiate_class($class_definition_number);
        }
    }
    push @{ $self->reference_list() }, $datastructure
      if $save_reference;
    return $datastructure;
}    #}}}

# mostly version 2 specific
sub read_map_handle {    #{{{
    my $self  = shift;
    my $input_handle = $self->input_handle();

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        my $key;
        eval { $key = $self->read_hessian_chunk($input_handle); };
        last MAPLOOP if Exception::Class->caught('EndOfInput::X');
        my $value = $self->read_hessian_chunk($input_handle);
        push @key_value_pairs, $key => $value;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements
    my $datastructure = {@key_value_pairs};
    return $datastructure;

}    #}}}

# version 2 specific
sub read_list_length {    #{{{
    my ($self, $first_bit) = @_;
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
    return $array_length;
}    #}}}

# version 2 specific
sub read_untyped_list {    #{{{
    my ($self, $first_bit) = @_;
    my $input_handle = $self->input_handle();
    my $array_length = $self->read_list_length( $first_bit, );

    my $datastructure = [];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_hessian_chunk(); };
        last LISTLOOP
          if $first_bit =~ /\x57/
              && Exception::Class->caught('EndOfInput::X');

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}    #}}}

# version 2 specific
sub read_hessian_chunk {   #{{{
    my ( $self, $args ) = @_;
    my $input_handle = $self->input_handle();
    binmode( $input_handle, 'bytes' );
    my ( $first_bit, $element );
    if ( 'HASH' eq (ref $args) and $args->{first_bit}) {
        $first_bit = $args->{first_bit};
    }
    else {
      read $input_handle, $first_bit, 1;    
    }
     
    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit =~ /z/i;

    switch ($first_bit) {
        case /\x4e/ {    # 'N' for NULL
            $element = undef;
        }
        case /[\x46\x54]/ {    # 'T'rue or 'F'alse
            $element = read_boolean_handle_chunk($first_bit);
        }
        case /[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ {
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
        case /[\x52\x53\x00-\x1f\x30-\x33]/ {#   for version 1: \x73
            $element = read_string_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x41\x42\x20-\x2f\x34-\x37\x62]/ {
            $element = read_binary_handle_chunk( $first_bit, $input_handle );
        }
        case /[\x43\x4d\x4f\x48\x55-\x58\x60-\x6f\x70-\x7f]/
        {    # recursive datastructure
            $element =
              $self->read_composite_datastructure( $first_bit, );
        }
        case /\x51/ {
            my $reference_id = $self->read_hessian_chunk();
            $element = $self->reference_list()->[$reference_id];

        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::List - Translate list datastructures to and from hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE




