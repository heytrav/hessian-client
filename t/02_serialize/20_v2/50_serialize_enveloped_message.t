#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't005.*|t007.*|t025.*';

use Communication::v2Serialization;
Communication::v2Serialization->runtests();
