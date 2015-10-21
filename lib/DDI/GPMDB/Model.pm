package DDI::GPMDB::Model;

use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $self  = {

        title                       =>  "none",
        brenda_tissue               =>  "none",
        cell_type                   =>  "none",
        go_subcell                  =>  "none",
        email                       =>  "none",
        institution                 =>  "none",
        name                        =>  "none",
        project                     =>  "none",
        comment                     =>  "none",
        pxd		                    =>  "none",
        pubmed                      =>  "none",
        C_terminal_mod_mass         =>  0,
        N_terminal_mod_mass         =>  0,
        C_terminal_mass_change      =>  0,
        N_terminal_mass_change      =>  0,
        cleavage_site               =>  "none",
        cleavage_semi               =>  "none",
        taxon                       =>  "none",
        potential_mod_mass          =>  "none",
        fragment_mass_type          =>  "none",
        frag_mono_mass_error        =>  0,
        frag_mono_mass_unit         =>  "none",
        parent_mono_mass_error_m    =>  0,
        parent_mono_mass_error_p    =>  0,
        parent_mono_mass_error_unit =>  "none",
        total_spectra_assigned      =>  0,
        total_unique_assigned       =>  0,
        total_spectrum              =>  0,
        partial_cleavage            =>  0,
    };

    bless($self, $class);
    return $self;
}

1;
