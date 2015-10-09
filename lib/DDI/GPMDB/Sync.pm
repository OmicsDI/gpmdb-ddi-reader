package DDI::GPMDB::Sync;

use strict;
use warnings;
use v5.10;
use Net::FTP;
use Archive::Tar;

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
    my $self    = shift;
    my $data    = shift;
    my $ignore  = shift;
    my $dir_ref = shift;

    my @dir = @{$dir_ref};
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

# this is the function that actually touches GPMD FTP server list and get the missing files
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
          next if $ftp_file =~ m/\.xml$/g;
          next if $ftp_file =~ m/\.pl$/g;
          next if $ftp_file =~ m/\.txt$/g;
          next if $ftp_file =~ m/\.xls$/g;
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

sub fetch {
    my $sync         = shift;
    my $source_files = shift;
    my $data         = shift;
    my $ignore       = shift;
    my $files_ref    =shift;

    my @files_to_download = @{$files_ref};

	for my $file ( @files_to_download ) {

	    chomp $file;
	    $file =~ m/GPM(\d{3})\d{5,15}/g;
	    my $folder = $1;

	    $sync->{ftp}->cwd('/gpmdb/');

	    say "gpmdb/$folder/$file.xml.gz";

	    if ( $sync->{ftp}->get("$folder/$file.xml.gz", "$source_files/$folder/$file.xml.gz") ) {

	      say "Fetching zipped model $file";

	      if ( -z("$source_files/$folder/$file.xml.gz") ) {
            
            say "[Sanity Test Failed]: Adding model $file to ignore list";
		    system("rm -f $source_files/$folder/$file.xml.gz");
		    system("echo $file >> $ignore");

	      } else {
            
            say "[Test OK]: storing model $file";
		    #system("gunzip -f $source_files/$folder/$file.xml.gz");
	      }

	    } else {

		    if ( $sync->{ftp}->get("$folder/$file.xml", "$source_files/$folder/$file.xml") or die $sync->{ftp}->message) {
		    
              say "Fetching model $file";
	    	}
        }

	}

    system("find $source_files -type f > $data");
}

1;
