#!/usr/bin/perl

use lib qw{./t/lib };
use strict;
use warnings;

use Communication::v1Serialization;
Communication::v1Serialization->runtests();
