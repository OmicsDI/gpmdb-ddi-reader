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
use DDI::GPMDB::Reader;
use Data::Printer;

#list of downloaded files
my $data = 'data/files.txt';
my $ignore = 'data/ignore.txt';
my $source_files = '/home/felipevl/Servers/Pathbio/gpmdump/gpmdb';
#my @dir = qw(003 066 101 111 112 201 319 320 321 323 330 451 600 642 643 644 645 652 701 777 874 999);
my @dir = qw(003 066 101 111 112);

# getting the latest file list
system("find $source_files -type f > $data");

my $sync = DDI::GPMDB::Sync->new();
#my @files_to_download = $sync->process_files($data, $ignore);
#$sync->fetch($source_files, $data, $ignore, \@files_to_download);

for my $dir ( @dir ) {
    my $reader = DDI::GPMDB::Reader->new();
    $reader->process_and_store($source_files, $data, $dir);
}

1;
