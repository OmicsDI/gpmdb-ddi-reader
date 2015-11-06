package DDI::GPMDB::Reader;

use strict;
use warnings;
use v5.010;
use IO::Zlib;
use Parallel::ForkManager 0.7.6;
use DDI::GPMDB::Parser;
use DDI::GPMDB::XMLFile;

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
    my $self       = shift;
    my $source     = shift;
    my $data       = shift;
    my $dir_ref    = shift;

	say "Grouping and printing XML files";
    create_xml_files($dir_ref);

    return;
}

sub create_csv_file {
	my $dir = shift;
	my $ref = shift;
	my @reg = @{$ref};

	open( my $out, '>', "data/reference/$dir/$dir.tsv" ) or die "Cannot create csv for directory $dir";

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
    my @dir = @{$dir};

    my @global_reg;

  {
    no warnings;
    for my $d ( @dir) {
  	   open(my $in, '<', "data/reference/$d/$d.tsv") or warn "no reference file at $d";
       while ( my $line = <$in> ) {
         push(@global_reg, $line);
       }
    }
  }

	my %group;
    my @group;

	for my $line ( @global_reg ) {
		chomp $line;

		my @terms = split(/\t/, $line);

		if ( $terms[0] eq 'none' && $terms[1] eq 'none' && $terms[2] eq 'none' ) {
			next;
		}

		my $key = "$terms[0]";

        if ( exists($group{$key}) ) {

            my $xml = $group{$key};

            $xml->{project} = $terms[0] if $terms[0] ne "none";
            $xml->{pxd} = $terms[1] if $terms[1] ne "none";
            $xml->{pubmed} = $terms[2] if $terms[2] ne "none";
    	    $xml->{title} = $terms[3] if $terms[3] ne "none";
    	    $xml->{taxon} = $terms[4] if $terms[4] ne "none";
    	    $xml->{brenda_tissue} = $terms[5] if $terms[5] ne "none";
    	    $xml->{cell_type} = $terms[6] if $terms[6] ne "none";
    	    $xml->{email} = $terms[7] if $terms[7] ne "none";
    	    $xml->{go_subcell} = $terms[8] if $terms[8] ne "none";
    	    $xml->{institution} = $terms[9] if $terms[9] ne "none";
    	    $xml->{name} = $terms[10]if $terms[10] ne "none";
    	    $xml->{comment} = $terms[11] if $terms[11] ne "none";
    	    $xml->{massive} = $terms[12] if $terms[12] ne "none";
    	    $xml->{pride} = $terms[13] if $terms[13] ne "none";
    	    $xml->{tranche} = $terms[14] if $terms[14] ne "none";
            push($xml->{models}, $terms[3]);

            $group{$key} = $xml;
            
        } else {

            my $xml = DDI::GPMDB::XMLFile->new();

            $xml->{project} = $terms[0];
            $xml->{pxd} = $terms[1];
            $xml->{pubmed} = $terms[2];
    	    $xml->{title} = $terms[3];
    	    $xml->{taxon} = $terms[4];
    	    $xml->{brenda_tissue} = $terms[5];
    	    $xml->{cell_type} = $terms[6];
    	    $xml->{email} = $terms[7];
    	    $xml->{go_subcell} = $terms[8];
    	    $xml->{institution} = $terms[9];
    	    $xml->{name} = $terms[10];
    	    $xml->{comment} = $terms[11];
    	    $xml->{massive} = $terms[12];
    	    $xml->{pride} = $terms[13];
    	    $xml->{tranche} = $terms[14];

            $group{$key} = $xml;
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

		my $xml = $group{$key};

		my $filename = "data/xml/GPMDB_EBE_".$counter.".xml";

        $xml->{pubmed} = "Not available" if $xml->{pubmed} eq "none";
        $xml->{taxon} = "Not available" if $xml->{taxon} eq "none";
        $xml->{brenda_tissue} = "Not available" if $xml->{brenda_tissue} eq "none";
        $xml->{cell_type} = "Not available" if $xml->{cell_type} eq "none";
        $xml->{email} = "Not available" if $xml->{email} eq "none";
        $xml->{institution} = "Not available" if $xml->{institution} eq "none";
        $xml->{name} = "Not available" if $xml->{name} eq "none";
        $xml->{comment} = "Not available" if $xml->{comment} eq "none";

		open( my $xmlfile, '>', $filename) or die "Cannot create XML file";

		say $xmlfile "<database>";
		say $xmlfile "  <name>PRIDE Archive</name>";
		say $xmlfile "  <description/>";
		say $xmlfile "  <release>3</release>";
		say $xmlfile "  <release_date>$release_date</release_date>";
		say $xmlfile "  <entry_count>1</entry_count>";
		say $xmlfile "  <entries>";
		say $xmlfile "    <entry id=\"$xml->{title}\">";
		say $xmlfile "      <name><%%><\/name>";
		say $xmlfile "      <description>\"$xml->{comment}\"<\/description>";
        
        if ( $xml->{pxd} eq "none" && ($xml->{pubmed} eq "none" || $xml->{pubmed} eq "Not available") && $xml->{massive} eq "none" && $xml->{pride} eq "none") {
            say $xmlfile "      <cross_references><\/cross_references>";
        } else {
            say $xmlfile "      <cross_references>";
            say $xmlfile "      <ref dbkey=\"$xml->{pxd}\" dbname=\"ProteomeExchange\"\/>" if $xml->{pxd} ne "none";
            say $xmlfile "      <ref dbkey=\"$xml->{pubmed}\" dbname=\"pubmed\"\/>" if $xml->{pubmed} ne "Not available";
            say $xmlfile "      <ref dbkey=\"$xml->{massive}\" dbname=\"massive\"\/>" if $xml->{massive} ne "none";
            say $xmlfile "      <ref dbkey=\"$xml->{pride}\" dbname=\"PRIDE\"\/>" if $xml->{pride} ne "none";
            say $xmlfile "      <\/cross_references>";
	    }

        say $xmlfile "      <additional_fields>";
        say $xmlfile "        <field name=\"omics_type\">Proteomics</field>";
        say $xmlfile "        <field name=\"repository\">GPMDB</field>";
        say $xmlfile "        <field name=\"instrument_platform\">Instrument</field>";
        say $xmlfile "        <field name=\"disease\">Not available</field>";
        say $xmlfile "        <field name=\"species\">$xml->{taxon}</field>";
        say $xmlfile "        <field name=\"publication\">$xml->{pubmed}</field>";
        say $xmlfile "        <field name=\"brenda_tissue\">$xml->{brenda_tissue}</field>";
        say $xmlfile "        <field name=\"cell_type\">$xml->{cell_type}</field>";
        say $xmlfile "        <field name=\"submitter\">$xml->{name}</field>";
        say $xmlfile "        <field name=\"submitter_mail\">$xml->{email}</field>";
        say $xmlfile "        <field name=\"submitter_affiliation\">$xml->{institution}</field>";

        my @models = @{$xml->{models}};
        my $title_flag = 0;
        for my $model ( @models ) {
            $title_flag = 1 if $model eq $xml->{title};
            say $xmlfile "        <field name=\"model\">http://gpmdb.thegpm.org/~/dblist_gpmnum/gpmnum=$model</field>" if $model ne "none";
        }
        if ( $title_flag == 0 ) {
	        say $xmlfile "        <field name=\"model\">http://gpmdb.thegpm.org/~/dblist_gpmnum/gpmnum=$xml->{title}</field>";
        }

        say $xmlfile "      <\/additional_fields>";
		say $xmlfile "    </entry>";
		say $xmlfile "  </entries>";
		say $xmlfile "</database>";

		$counter++;
	}
}
}

1;
