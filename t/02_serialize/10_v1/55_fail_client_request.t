#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't005.*|t007.*|t032.*';

use Communication::v1Serialization;
Communication::v1Serialization->runtests();
