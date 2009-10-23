#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

use Test::Hessian::Service::V2;
Test::Hessian::Service::V2->runtests();
