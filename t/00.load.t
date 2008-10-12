use Test::More tests => 7;

BEGIN {
use_ok( 'Hessian' );
use_ok( 'Hessian::Config' );
use_ok( 'Hessian::Message::Request' );
use_ok( 'Hessian::Message::Request::Top' );
use_ok( 'Hessian::Message::Request::Envelope' );
use_ok( 'Hessian::Message::Request::Call' );
use_ok( 'Hessian::Message::Response' );
}

diag( "Testing Hessian $Hessian::VERSION" );
