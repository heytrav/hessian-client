#!/usr/bin/env perl

if ( !require Test::Perl::Critic ) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance" );
}

if ( not( $ENV{AUTHOR_TESTING} OR $ENV{RELEASE_TESTING} ) ) {
    Test::More::plan( skip_all => "This test is for authors only" );
}

Test::Perl::Critic::all_critic_ok(qw/lib/);
