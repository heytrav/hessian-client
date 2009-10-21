#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't005_.*|t007_.*|t009_.*';

use Communication::v2Serialization;
Communication::v2Serialization->runtests();
