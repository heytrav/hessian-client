#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

 use Communication::TestServlet1;
 Communication::TestServlet1->runtests();
