#!/usr/bin/perl

use lib qw{./t/lib };
use strict;
use warnings;

use Communication::v2Serialization;
Communication::v2Serialization->runtests();
