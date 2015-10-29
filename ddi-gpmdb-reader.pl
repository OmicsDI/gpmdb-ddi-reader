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

my ($mode) = @ARGV;

### PARAMETERS ###
my $data = 'data/files.txt';  # location for the mode listing.
my $ignore = 'data/ignore.txt'; # location for the ignore file list.
my $source_files = '/home/felipevl/Servers/Pathbio/gpmdump/gpmdb';  # location of the gpmdb folders
#my @dir = qw(003 066 101 111 112 201 319 320 321 323 330 451 600 642 643 644 645 652 701 777 874 999);  # list of folders to check
my @dir = qw(451);
### % ###

my @files_to_download;

if ( defined($mode) && $mode eq 'update' ) {

    # getting the latest file list
    say "Generating local model list";
    system("find $source_files -type f > $data");

    # initialize sync object and query GPMDB FTP server for new files.
    # New files are downloaded and stores as .gz file on the proper folder.
    my $sync = DDI::GPMDB::Sync->new();
    @files_to_download = $sync->process_files($data, $ignore, \@dir);
    $sync->fetch($source_files, $data, $ignore, \@files_to_download);

} elsif ( defined($mode) && $mode eq 'generate' ) {

    for my $dir ( @dir ) {
        my $reader = DDI::GPMDB::Reader->new();
        $reader->screen_and_generate($source_files, $data, $dir);
        say "done with directory $dir";
    }

} elsif ( defined($mode) && $mode eq 'process' ) {

    for my $dir ( @dir ) {
		my $reader = DDI::GPMDB::Reader->new();
		$reader->generate($source_files, $data, $dir);
		say "done with directory $dir";
	}

} else {
    say "DDI::GPMDB Usage: perl run.pl <option>";
    say "update: Synchronize your local GPMDB files with the FTP server";
    say "generate: Create XML Registry files for each project";
}

1;
