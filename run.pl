#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: main.pl
#
#        USAGE: ./main.pl  
#
#  DESCRIPTION: This program objective is to synchronize a local storage wit
#               model files from GPMDB website. The program query the ftp
#               server and fetch new files, storing them on the proper place.
#
#      OPTIONS: ---
# REQUIREMENTS: see dependency file.
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, FV),felipe@leprevost.com.br
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

### PARAMETERS ###
my $data = 'data/files.txt';  # location for the mode listing.
my $ignore = 'data/ignore.txt'; # location for the ignore file list. 
my $source_files = '/home/felipevl/Servers/Pathbio/gpmdump/gpmdb';  # location of the gpmdb folders
my @dir = qw(003 066 101 111 112 201 319 320 321 323 330 451 600 642 643 644 645 652 701 777 874 999);  # list of folders to check
my $mongodb = 'nesvidb.gpmdb';  # name of the database and collection
### % ###

# getting the latest file list
system("find $source_files -type f > $data");

# initialize sync object and query GPMDB FTP server for new files.
# New files are downloaded and stores as .gz file on the proper folder.
my $sync = DDI::GPMDB::Sync->new();
my @files_to_download = $sync->process_files($data, $ignore);
$sync->fetch($source_files, $data, $ignore, \@files_to_download);

for my $dir ( @dir ) {
    my $reader = DDI::GPMDB::Reader->new($mongodb);
    $reader->process_and_store($source_files, $data, $dir);
    say "done with directory $dir";
}

1;
