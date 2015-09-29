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
use Archive::Tar;
use DDI::GPMDB::Sync;

#list of downloaded files
my $data = 'data/files.txt';
my $ignore = 'data/ignore.txt';
my $source_files = '/home/felipevl/Servers/Pathbio/gpmdump/gpmdb';

# create a sync object that connects to GPMDB ftp server and check if the
# files from the server are also present in the local storage folder.
# The local files directory is defined by the $data variable. The fucntions
# return the list of files that are not yet on the local storage.
my $sync = DDI::GPMDB::Sync->new();
my @files_to_download = $sync->process_files($data, $ignore);

for my $file ( @files_to_download ) {
    
    chomp $file;
    $file =~ m/GPM(\d{3})\d{5,15}/g;
    my $folder = $1;

    $sync->{ftp}->cwd('/gpmdb/');

    if ( $sync->{ftp}->get("gpmdb/$folder/$file.xml.gz", "$source_files/$folder/$file.xml.gz") ) { 
      
      say "Fetching zipped model $file";

      if ( my $test = `gzip --test $source_files/$folder/$file.xml.gz || echo 0`) {
          system("rm -f $source_files/$folder/$file.xml.gz");
          system("echo $file >> $ignore");
      } else {
          system("gunzip -f $source_files/$folder/$file.xml.gz");
      }
      
    } else {

        if ( $sync->{ftp}->get("$folder/$file.xml", "$source_files/$folder/$file.xml") or die $sync->{ftp}->message) {
            say "Fetching model $file";
        }
    }

    system("find $source_files -type f > $data");
}

1;
