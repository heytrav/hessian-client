#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

use Communication::TestServlet2;
Communication::TestServlet2->runtests();
