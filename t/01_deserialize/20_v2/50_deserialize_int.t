#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|t050.*';

use Test::Hessian::V2::Deserializer;
Test::Hessian::V2::Deserializer->runtests();
