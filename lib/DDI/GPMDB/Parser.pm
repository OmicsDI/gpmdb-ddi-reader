package DDI::GPMDB::Parser;

use strict;
use warnings;
use v5.10;
use DDI::GPMDB::Model;

sub new {
    my $class = shift;
    my $self  = {
      model =>  undef,
    };

    $self->{model} = DDI::GPMDB::Model->new();

    bless($self, $class);
    return $self;
}


sub parse_model {
    my $self  = shift;
    my $fh    = shift;

    while( my $line = <$fh> ) {
        chomp $line;

        if ( $line =~ m/^\s+<note type=\"input\" label=\"output, title\">(.*)<\/note>/i ) {

            if ( length($1) > 0 ) {
              $self->{model}->{title} = $1;
            }

        } elsif( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, BRENDA tissue\">(.*)<note>/i ) {

            if ( length($1) > 0 ) {
              $self->{model}->{brenda_tissue} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, CELL cell type\">(.*)<\/note>/i ) {

            if ( length($1) > 0 ) {
              $self->{model}->{cell_type} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, GO subcellular\">(.*)<\/note>/i ) {

            if ( length($1) > 0 ) {
                $self->{model}->{go_subcell} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, email\">(.*)<\/note>/i ) {

            if ( length($1) > 0 ) {
              $self->{model}->{email} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, institution\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{institution} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, name\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{name} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, project\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{project} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"gpmdb, project comment\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
                $self->{model}->{comment} = $1;

                if ( $line =~ m/PubMed\s+?ID\:\s+(\d+)/ig ) {
                  $self->{model}->{pubmed} = $1;
                }

                if ( $line =~ m/(PXD\d{6})/ig ) {
                  $self->{model}->{pxd} = $1;
                }

                if ( $line =~ m/(MSV\d{9)/ig ) {
                  $self->{model}->{massive} = $1;
                }

                if ( $line =~ m/PRIDE ID:\s(\d{1,6})/ig ) {
                  $self->{model}->{pride} = $1;
                }

                if ( $line =~ m/TRANCHE KEY:\s(.*==)\s/ig ) {
                  $self->{model}->{tranche} = $1;
                }

            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, C-terminal residue modification mass\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{C_terminal_mod_mass} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, N-terminal residue modification mass\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{N_terminal_mod_mass} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, cleavage C-terminal mass change\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{C_terminal_mass_change} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, cleavage N-terminal mass change\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{N_terminal_mass_change} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, cleavage site\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{cleavage_site} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"protein, taxon\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{taxon} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"refine, potential modification mass\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{potential_mod_mass} = $1;
            }

        } elsif ( $line =~ m/^\s+fragment_mass_type()/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{fragment_mass_type} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"spectrum, fragment monoisotopic mass error\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{frag_mono_mass_error} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"spectrum, fragment monoisotopic mass error units\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{frag_mono_mass_unit} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"spectrum, parent monoisotopic mass error minus\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{parent_mono_mass_error_m} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"spectrum, parent monoisotopic mass error plus\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{parent_mono_mass_error_p} = $1;
            }

        } elsif ( $line =~ m/^\s+<note type=\"input\" label=\"spectrum, parent monoisotopic mass error units\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{parent_mono_mass_error_unit} = $1;
            }

        } elsif ( $line =~ m/^\s+<note label=\"modelling, total spectra assigned\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{total_spectra_assigned} = $1;
            }

        } elsif ( $line =~ m/^\s+<note label=\"modelling, total unique assigned\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{total_unique_assigned} = $1;
            }

        } elsif ( $line =~ m/^\s+<note label=\"modelling, total spectra used\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{total_spectrum} = $1;
            }
        } elsif ( $line =~ m/^\s+<note label=\"refining, \# partial cleavage\">(.*)<\/note>/ ) {

            if ( length($1) > 0 ) {
              $self->{model}->{partial_cleavage} = $1;
            }
        }
    }

    return $self;
}

1;
