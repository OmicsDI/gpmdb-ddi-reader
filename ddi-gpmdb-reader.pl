#!/usr/bin/env perl
#===============================================================================
#
#         FILE: ddi-gpmdb-reader.pl
#
#        USAGE: ./ddi-gpmdb-reader.pl
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
use Getopt::Long qw(GetOptions);

# parameter variables
my $up;
my $proc;
my $gen;
my $help;
my $data;
my $ignore;
my $source_files;
my @dir;

GetOptions(
  'update!'   =>  \$up,
  'process'   =>  \$proc,
  'generate!' =>  \$gen,
  'help!'     =>  \$help,
  ) or die "Incorrect usage!\n";

### PARAMETERS ###
open( my $param, '<', './ddi-gpmdb-params.txt' ) or die "Cannot open parameter file";
while( my $line = <$param> ) {
  chomp $line;
  if ( $line =~ m/data\_file\=data\/(.*)/ ) {
    $data = $1;
  } elsif( $line =~ m/ignore=(.*)/ ) {
    $ignore = $1;
  } elsif( $line =~ m/source_files=(.*)/ ) {
    $source_files = $1;
  } elsif ( $line =~ m/model_dirs= (.*)/ ) {
    @dir = split(/\s/, $line);
    shift @dir;
  }
}
### END PARAMETERS ###

if ( !$help && !$up && !$proc && !$gen) {
  say "No parameter found! Run -help for more information on how to use DDI::GPMDB";
  exit;
}

if( $help ) {

    say "DDI::GPMDB Module!";
    say "-update\t\tUpdates the local GPMDB files using GPMDB ftp server";
    say "-process\tCreates reference files for every model in each folder (long process!)";
    say "-generate\tGenereate XML files from reference files";

} else {

  my @files_to_download;

  if ( $up ) {

      # getting the latest file list
      say "Generating local model list";
      system("find $source_files -type f > $data");

      # initialize sync object and query GPMDB FTP server for new files.
      # New files are downloaded and stores as .gz file on the proper folder.
      my $sync = DDI::GPMDB::Sync->new();
      @files_to_download = $sync->process_files($data, $ignore, \@dir);
      $sync->fetch($source_files, $data, $ignore, \@files_to_download);

  } elsif ( $proc ) {

      for my $dir ( @dir ) {
          my $reader = DDI::GPMDB::Reader->new();
          $reader->create_reference_files($source_files, $data, $dir);
          say "done with directory $dir";
      }

  } elsif ( $gen ) {

  	  my $reader = DDI::GPMDB::Reader->new();
  	  $reader->generate($source_files, $data, \@dir);
  	  say "done";

  }

}

1;
