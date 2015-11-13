package DDI::GPMDB::XMLFile;

use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $self  = {
      title           =>  "none",
      brenda_tissue   =>  "none",
      cell_type       =>  "none",
      go_subcell      =>  "none",
      email           =>  "none",
      institution     =>  "none",
      name            =>  "none",
      project         =>  "none",
      comment         =>  "none",
      pxd		          =>  "none",
      tranche         =>  "none",
      massive         =>  "none",
      pubmed          =>  "none",
      pride           =>  "none",
      taxon           =>  "none",
      pepatlas        =>  "none",
      subdate         =>  "none",
      models			    => [],
    };

    bless($self, $class);
    return $self;
}

1;
