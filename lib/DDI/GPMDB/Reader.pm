package DDI::GPMDB::Reader;

use strict;
use warnings;
use v5.010;
use IO::Zlib;
use Parallel::ForkManager 0.7.6;
use DDI::GPMDB::Parser;
use Data::Printer;

sub new {
    my $class   = shift;
    my $mongodb = shift;
    my $self  = { };

    bless($self, $class);
    return $self;
}


sub screen_and_generate {
    my $self    = shift;
    my $source  = shift;
    my $data    = shift;
    my $dir     = shift;

	say "Processing directory $dir...";

    my $pm = Parallel::ForkManager->new(14, '/home/felipevl/Workspace/DDI-GPMDB-Reader/data/temp');
    my %responses = ();
    my @responses;

    my %files;
    open(my $file_list, '<', $data) or die "Cannot open file list";
    while( my $line = <$file_list> ) {
        chomp $line;
        if ( $line =~ m/(GPM(\d{3})\d{5,15})/g ) {
            if ( $2 == $dir ) {
                $files{$1} = $2;
            }
        }
    }

	$pm->run_on_finish (
	  sub {
	    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
	 
	    # retrieve data structure from child
	    if (defined($data_structure_reference)) {
            
            my $reftype = ref($data_structure_reference);
            #$responses{$pid} = $data_structure_reference;
            push(@responses, $$data_structure_reference);

        } else {
	      print qq|No message received from child process $pid!\n|;
	    }

	  }
	);


    DATA_LOOP:
    for my $file ( keys %files ) {

        my $pid = $pm->start and next DATA_LOOP;
        my $reg;

        chomp $file;

        $file =~ m/GPM(\d{3})\d{5,15}/g;
        my $folder = $1;

        my $status_flag = 0;
        if ( -e "$source/$folder/$file.xml.gz") {
            
            $status_flag = 1;

        } else {

            die "Unknown file format for $file";
        }

        if ( $status_flag == 1 ) {

            my $gz = IO::Zlib->new();
            $gz->open("$source/$folder/$file.xml.gz","rb");

            my $parser = DDI::GPMDB::Parser->new();
            my $model = $parser->parse_model($gz);
			$reg = $model;

        }

      $pm->finish(0, \$reg);
        
    }
    $pm->wait_all_children;

    say "Creating reference files";
	create_csv_file($dir, \@responses);

	say "Grouping and printing XML files";
	create_xml_files($dir);

    return;
}

sub generate {
    my $self    = shift;
    my $source  = shift;
    my $data    = shift;
    my $dir     = shift;

	say "Grouping and printing XML files";
	create_xml_files($dir);

    return;
}

sub create_csv_file {
	my $dir = shift;
	my $ref = shift;
	my @reg = @{$ref};

	open( my $out, '>', "data/records/$dir.tsv") or die "Cannot create csv for directory $dir";

	for my $m ( @reg ) {
		
		say $out $m->{model}->{project}, "\t", $m->{model}->{pxd}, "\t", $m->{model}->{pubmed}, "\t", $m->{model}->{title}, "\t", $m->{model}->{taxon}, "\t", $m->{model}->{brenda_tissue}, "\t", $m->{model}->{cell_type}, "\t", $m->{model}->{email}, "\t", $m->{model}->{go_subcell}, "\t", $m->{model}->{institution}, "\t", $m->{model}->{name};
	}

	return;
}

sub create_xml_files {
	my $dir = shift;

	open(my $in, '<', "data/records/$dir.tsv") or die "Cannot open tsv file from directory $dir";

	my %group;

	while( my $line = <$in> ) {
		chomp $line;

		my @terms = split(/\t/, $line);

		if ( $terms[0] eq 'none' && $terms[1] eq 'none' && $terms[2] eq 'none' ) {
			next;
		}

		my $key = "$terms[0]-$terms[1]-$terms[2]";

		if ( exists($group{$key}) ) {
			my @entries = @{$group{$key}};
			push(@entries, \@terms);
			$group{$key} = \@entries;
		} else {
			my @entries;
			push(@entries, \@terms);
			$group{$key} = \@entries;
		}
	}

	print_xml($dir, \%group);
}


sub print_xml {
	my $dir = shift;
	my $ref = shift;
	my %group = %{$ref};

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	$year = $year += 1900;
	my $release_date = "$year-$mon-$mday";

	my $counter = 1;
	for my $key ( keys %group ) {

		my @terms = @{$group{$key}};
		my $ref_model = 

		my $filename = "data/records/GPMDB_".$dir."_EBE_".$counter.".xml";

		open( my $xml, '>', $filename) or die "Cannot create XML file";

		say $xml "<database>";
		say $xml "  <name>PRIDE Archive</name>";
		say $xml "  <description/>";
		say $xml "  <release>3</release>";
		say $xml "  <release_date>$release_date</release_date>";
		say $xml "  <entry_count>1</entry_count>";
		say $xml "  <entries>";
		say $xml "    <entry id=\"$terms[1]\">";
		say $xml "      <name><%%><\/name>";
		say $xml "      <description><%%><\/description>";
		say $xml "      <cross_references>";
		say $xml "	...	...";
		say $xml "    </entry>";
		say $xml "  </entries>";
		say $xml "</database>";



		$counter++;
	}

}

1;

































