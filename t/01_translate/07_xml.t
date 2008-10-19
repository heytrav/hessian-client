#!/usr/bin/perl

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');


use Test::More qw( no_plan ); 
use Hessian::Translator qw/:to_hessian :from_hessian/; 
