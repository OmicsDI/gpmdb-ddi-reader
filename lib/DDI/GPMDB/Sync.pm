package DDI::GPMDB::Sync;
#===============================================================================
#
#         FILE: Sync.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, FV), leprevost@cpan.org
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09/25/15 23:26:32
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use v5.10;
use Net::FTP;
use Data::Printer;

# class constructor
sub new {
    my $class = shift;
    my $self  = {
        ftp => undef,
    };

    bless($self, $class);

    $self->{ftp} = Net::FTP::->new('ftp.thegpm.org', Debug => 0) or die "Cannot connect to host";
    $self->{ftp}->login('anonymous','-anonymous@') or die "Cannot login to GPMDB";

    return $self;
}

# methods #
sub process_files {
    my $self   = shift;
    my $data   = shift;
    my $ignore = shift;

    #my @dir = qw(003 066 101 111 112 201 319 320 321 323 330 451 600 642 643 644 645 652 701 777 874 999);
    my @dir = qw(003 066 101);
    $self->{ftp}->cwd('/gpmdb/');

    my %toignore;
    open(my $ignore_file, '<', $ignore) or die "Cannot open ignore file";
    while( my $line = <$ignore_file> ) {
        chomp $line;
        $toignore{$line} = '';
    }

    my %files;
    open(my $file_list, '<', $data) or die "Cannot open file list";
    while( my $line = <$file_list> ) {
        chomp $line;
        if ( $line =~ m/(GPM\d{5,15})/g ) {
            $files{$1} = '';
        }
    }

    my @files_to_download;
    for my $folder ( @dir ) {
        say "processing $folder";
        my @list = $self->lookup($folder, \%files, \%toignore);
        push(@files_to_download, @list);
    }

    return @files_to_download;
}

sub lookup {
    my $self    = shift;
    my $folder  = shift;
    my $ref     = shift;
    my $igref   = shift;
    
    my %files  = %{$ref};
    my %ignore = %{$igref};
    my @list;
    
    say "fetching file list";
    my @ftp_lists = $self->{ftp}->ls("/gpmdb/$folder");

    say "searching";
    for my $ftp_file (@ftp_lists) {

        if ( $ftp_file =~ m/(GPM\d{5,15})/g ) {

          next if exists $ignore{$1};
          next if $ftp_file =~ m/\.pl$/g;
          next if $ftp_file =~ m/\.txt/g;
          next if $ftp_file =~ m/\.xls/g;
          next if $ftp_file =~ m/c$/g;

          if( !exists($files{$1}) ) {
              push(@list, $1);
          }
        }

    }

    my $size = scalar @list;
    say "found $size new models";

    return @list;
}

1;
