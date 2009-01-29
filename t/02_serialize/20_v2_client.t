#!/usr/bin/perl

use lib q{./t/lib };
use strict;
use warnings;

use Communication::v2Serialization;
Communication::v2Serialization->runtests();
