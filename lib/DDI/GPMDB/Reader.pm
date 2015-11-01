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


sub create_reference_files {
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

	#say "Grouping and printing XML files";
	#create_xml_files($dir);

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

	open( my $out, '>', "data/records/$dir/$dir.tsv" ) or die "Cannot create csv for directory $dir";

	for my $m ( @reg ) {

		say $out $m->{model}->{project}, "\t",
    $m->{model}->{pxd}, "\t",
    $m->{model}->{pubmed}, "\t",
    $m->{model}->{title}, "\t",
    $m->{model}->{taxon}, "\t",
    $m->{model}->{brenda_tissue}, "\t",
    $m->{model}->{cell_type}, "\t",
    $m->{model}->{email}, "\t",
    $m->{model}->{go_subcell}, "\t",
    $m->{model}->{institution}, "\t",
    $m->{model}->{name}, "\t",
    $m->{model}->{comment}, "\t",
    $m->{model}->{massive}, "\t",
    $m->{model}->{pride}, "\t",
    $m->{model}->{tranche};
	}

	return;
}

sub create_xml_files {
	my $dir = shift;

  my @dir = qw(003 066 101 111 112 201 319 320 321 323 330 451 600 642 643 644 645 652 701 777 874 999);
  my @global_reg;

  {
    no warnings;
    for my $d ( @dir) {
  	   open(my $in, '<', "data/records/$d/$d.tsv") or warn "no reference file at $d";
       while ( my $line = <$in> ) {
         push(@global_reg, $line);
       }
    }
  }

	my %group;

	for my $line ( @global_reg ) {
		chomp $line;

		my @terms = split(/\t/, $line);

		if ( $terms[0] eq 'none' && $terms[1] eq 'none' && $terms[2] eq 'none' ) {
			next;
		}

		my $key = "$terms[0]";

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

  # my %tranche;
  # open( my $tr, '<', "data/tranche-to-massive.txt" ) or die "Cannot find tranche-to-massive convertion file";
  # while( my $line = <$tr> ) {
  #   chomp $line;
  #   my ($m, $t) = split(/\t/, $line);
  #   $tr =~ s/\s+//;
  #   $tranche{$t} = $m;
  # }

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = $year += 1900;
	my $release_date = "$year-$mon-$mday";

	my $counter = 1;
	for my $key ( keys %group ) {

		my @terms = @{$group{$key}};

    # my $tc = $terms[0][14];
    # if ( defined($tc) && exists $tranche{$tc} ) {
    #   $terms[0][12] = $tranche{$tc};
    # }

		my $filename = "data/records/$dir/GPMDB_".$dir."_EBE_".$counter.".xml";

		open( my $xml, '>', $filename) or die "Cannot create XML file";

		say $xml "<database>";
		say $xml "  <name>PRIDE Archive</name>";
		say $xml "  <description/>";
		say $xml "  <release>3</release>";
		say $xml "  <release_date>$release_date</release_date>";
		say $xml "  <entry_count>1</entry_count>";
		say $xml "  <entries>";
		say $xml "    <entry id=\"$terms[0][3]\">";
		say $xml "      <name><%%><\/name>";
		say $xml "      <description>\"$terms[0][11]\"<\/description>" if $terms[0][11] ne "none";
		say $xml "      <cross_references>";
    say $xml "      <ref dbkey=\"$terms[0][1]\" dbname=\"ProteomeExchange\"\/>" if $terms[0][1] ne "none";
    say $xml "      <ref dbkey=\"$terms[0][2]\" dbname=\"pubmed\"\/>" if $terms[0][2] ne "none";
    say $xml "      <ref dbkey=\"$terms[0][12]\" dbname=\"massive\"\/>" if $terms[0][12] ne "none";
    say $xml "      <ref dbkey=\"$terms[0][13]\" dbname=\"PRIDE\"\/>" if $terms[0][13] ne "none";
    say $xml "      <\/cross_references>";
    say $xml "      <additional_fields>";
    say $xml "        <field name=\"omics_type\">Proteomics</field>";
    say $xml "        <field name=\"repository\">GPMDB</field>";
    say $xml "        <field name=\"instrument_platform\">Instrument</field>";
    say $xml "        <field name=\"species\">$terms[0][4]</field>" if $terms[0][4] ne "none";
    say $xml "        <field name=\"publication\">$terms[0][2]</field>" if $terms[0][2] ne "none";
    say $xml "        <field name=\"brenda_tissue\">$terms[0][5]</field>" if $terms[0][5] ne "none";
    say $xml "        <field name=\"cell_type\">$terms[0][6]</field>" if $terms[0][6] ne "none";
    say $xml "        <field name=\"submitter\">$terms[0][10]</field>" if $terms[0][10] ne "none";
    say $xml "        <field name=\"submitter_mail\">$terms[0][7]</field>" if $terms[0][7] ne "none";
    say $xml "        <field name=\"submitter_affiliation\">$terms[0][9]</field>" if $terms[0][7] ne "none";
    for my $model ( @terms ) {
      say $xml "        <field name=\"model\">http://gpmdb.thegpm.org/~/dblist_gpmnum/gpmnum=$model->[3]</field>" if $model->[3] ne "none";;
    }
    say $xml "      <\/additional_fields>";
		say $xml "    </entry>";
		say $xml "  </entries>";
		say $xml "</database>";

		$counter++;
	}
}

1;
