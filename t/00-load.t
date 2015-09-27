#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DDI::GPMDB::Reader' ) || print "Bail out!\n";
}

diag( "Testing DDI::GPMDB::Reader $DDI::GPMDB::Reader::VERSION, Perl $], $^X" );
