package DDI::GPMDB::Reader;

use strict;
use warnings;
use v5.010;
use IO::Zlib;
use MongoDB;
use Parallel::ForkManager 0.7.6;
use DDI::GPMDB::Parser;

sub new {
    my $class   = shift;
    my $mongodb = shift;
    my $self  = {
        client      =>  undef,
        collection  =>  undef,
        };

    $self->{client} = MongoDB->connect('localhost');
    $self->{collection} = $self->{client}->ns($mongodb);

    bless($self, $class);
    return $self;
}


sub process_and_store {
    my $self    = shift;
    my $source  = shift;
    my $data    = shift;
    my $dir     = shift;

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

            MongoDB::force_double($model->{model}->{C_terminal_mod_mass});
            MongoDB::force_double($model->{model}->{N_terminal_mod_mass});
            MongoDB::force_double($model->{model}->{C_terminal_mass_change});
            MongoDB::force_double($model->{model}->{N_terminal_mass_change});
            MongoDB::force_double($model->{model}->{frag_mono_mass_error});
            MongoDB::force_double($model->{model}->{parent_mono_mass_error_m});
            MongoDB::force_double($model->{model}->{parent_mono_mass_error_p});
            MongoDB::force_double($model->{model}->{total_spectra_assigned});
            MongoDB::force_double($model->{model}->{total_unique_assigned});
            MongoDB::force_double($model->{model}->{total_spectrum});
            MongoDB::force_double($model->{model}->{partial_cleavage});


            $reg = (
            {

                "title"                       =>  $model->{model}->{title},
                "brenda_tissue"               =>  $model->{model}->{brenda_tissue},
    		    "cell_type"                   =>  $model->{model}->{cell_type},
                "go_subcell"                  =>  $model->{model}->{go_subcell},
                "email"                       =>  $model->{model}->{email},
                "institution"                 =>  $model->{model}->{institution},
                "name"                        =>  $model->{model}->{name},
                "project"                     =>  $model->{model}->{project},
                "comment"                     =>  $model->{model}->{comment},
                "pxd"	                      =>  $model->{model}->{pxd},
                "pubmed"                      =>  $model->{model}->{pubmed},
                "taxon"                       =>  $model->{model}->{taxon},
                "modification" => {
                    "c_terminal_mass"             =>  $model->{model}->{C_terminal_mod_mass},
                    "n_terminal_mass"             =>  $model->{model}->{N_terminal_mod_mass},
                    "c_terminal_mass_change"      =>  $model->{model}->{C_termianl_mass_change},
                    "n_terminal_mass_change"      =>  $model->{model}->{N_terminal_mass_change},
                    "potential_mass"              =>  $model->{model}->{potential_mod_mass},
                },
                "restriction" => {
                    "cleavage_site"               =>  $model->{model}->{cleavage_site},
                    "cleavage_semi"               =>  $model->{model}->{cleavage_semi},
                    "partial_cleavage"            =>  $model->{model}->{partial_cleavage},

                },
                "fragment" => {
                    "mass_type"              =>  $model->{model}->{fragment_mass_type},
                    "mono_mass_error"        =>  $model->{model}->{frag_mono_mass_error},
                    "mono_mass_unit"         =>  $model->{model}->{frag_mono_mass_unit},
                },
                "parent" => {
                    "mono_mass_error_m"    =>  $model->{model}->{parent_mono_mass_error_m},
                    "mono_mass_error_p"    =>  $model->{model}->{parent_mono_mass_error_p},
                    "mono_mass_error_unit" =>  $model->{model}->{parent_mono_mass_unit},
                },
                "spetra" => {
                    "total_assigned"          =>  $model->{model}->{total_spectra_assigned},
                    "total_unique_assigned"   =>  $model->{model}->{total_unique_assigned},
                    "total"                   =>  $model->{model}->{total_spectrum},
                },

            });

        }

      $pm->finish(0, \$reg);
        
    }
    $pm->wait_all_children;

    say "ok";
    say "loading...";
    my $result = $self->{collection}->insert_many(\@responses);            

    return;
}

1;
