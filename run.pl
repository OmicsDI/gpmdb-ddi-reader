#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: main.pl
#
#        USAGE: ./main.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, FV), leprevost@cpan.org
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09/25/15 23:26:02
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.10;
use lib 'lib';
use DDI::GPMDB::Sync;

#list of downloaded files
my $data = 'data/files.txt';

my $sync = DDI::GPMDB::Sync->new();
$sync->process_files($data);






