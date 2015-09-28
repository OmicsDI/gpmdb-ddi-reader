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
my $source_files = '/home/felipevl/Servers/Pathbio/gpmdump/gpmdb';

# create a sync object that connects to GPMDB ftp server and check if the
# files from the server are also present in the local storage folder.
# The local files directory is defined by the $data variable. The fucntions
# return the list of files that are not yet on the local storage.
my $sync = DDI::GPMDB::Sync->new();
my @files_to_download = $sync->process_files($data);

for my $file ( @files_to_download ) {
    chomp $file;
    my @path = split(/\//, $file);
    $sync->{ftp}->get("$file", "$source_files/$path[2]/$path[3]") 
      or die "Failed to retrieve files:", $sync->{ftp}->message;
}

system("find $source_files -type f > $data");

1;
