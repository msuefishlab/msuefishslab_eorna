use strict;
use DBI;
use Time::localtime;

package barleyrtd_wrapper;
require Exporter;

#------------------------------------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------------------------------------

sub new {
  my ($proto, $database) = @_;	
  my $class = ref($proto) || $proto;
  my $self = {};				
  bless ($self, $class);
  $self->__initialisation($database);
  return $self;
}

sub __initialisation {
  my($self, $database) = (@_);
  $self->{'dbh'} = $self->__databaseConnection($database);
}

#-----------------------------------------------------------------------
# Database connection methods
#-----------------------------------------------------------------------

sub __databaseConnection {
  my ($self, $database) = (@_);


  my $dbName = 'efish_genomics';
  my $dbDriver = 'mysql';

  # Connect to the database
  $self->{'dbh'} = DBI->connect("DBI:mysql:$database;host=localhost;mysql_socket=/opt/bitnami/mariadb/tmp/mysql.sock", "root", "lHUgLDKpa2Ip");



}


#------------------------------------------------------------------------------------
# doSQLStatement(SQL STATEMENT)
# 	Runs the SQL statement that is passed in and returns statements handle.
#------------------------------------------------------------------------------------
sub doSQLStatement {
  my ($self, $stmt) = (@_);
  my($sth) = $self->{'dbh'}->prepare($stmt) || die "Problems preparing the SQL statement:". DBI->errstr;;

  $sth->execute() || die "Problems running the SQL statement:". DBI->errstr;
  return $sth;
}


#////////////////////////////////////////////////////////////////////////////////////
#
# Data retrieval methods
#
#////////////////////////////////////////////////////////////////////////////////////




sub getPaddedTPMsJS{
  
  my ($self, $bart_gene_id) = @_;
  
  my $stmt = "SELECT transcript_id, e.experiment_name, tpm_value
	      FROM tpm_values as t, tpm_experiments as e
	      where t.gene_id = '$bart_gene_id'
	      and t.experiment_id = e.experiment_id
	      ";
	      
  my $sth = $self->doSQLStatement($stmt);
  
  my %dataStructure;
  my $dataRef = \%dataStructure;
  
  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $transcript_id = $hashRef->{transcript_id};
    my $expt_name     = $hashRef->{experiment_name};
    my $tpm_value     = $hashRef->{tpm_value};
    
    
    $dataStructure{$transcript_id}{$expt_name} = $tpm_value;
  }
  return $dataRef;
}

sub getPaddedTPMsJS_efishgenomics{
  
  my ($self, $bart_gene_id) = @_;
  
  my $stmt = "SELECT transcript_id, e.experiment_name, e.tissue, e.expt_condition, tpm_value 
  FROM tpm_values as t, tpm_experiments as e 
  where t.gene_id='$bart_gene_id' 
  and t.experiment_id = e.experiment_id;
        ";
        
  my $sth = $self->doSQLStatement($stmt);
  
  my %dataStructure;
  my $dataRef = \%dataStructure;
  
  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $transcript_id = $hashRef->{transcript_id};
    my $expt_name     = $hashRef->{experiment_name};
    my $tpm_value     = $hashRef->{tpm_value};
    my $tissue          = $hashRef->{tissue};
    my $expt_condition  = $hashRef->{expt_condition};
    
    my $joined_details = join("\t", $tissue, $expt_condition, $tpm_value); 
    $dataStructure{$transcript_id}{$expt_name} = joined_details
  }
  return $dataRef;
}

sub getExperimentMetadata{
    my ($self) = @_;
  
  my $stmt = "SELECT experiment_name, dataset_name, cultivar, tissue, bio_replicate, expt_condition, sra_ids
	      FROM tpm_experiments

	      ";
  
  my $sth = $self->doSQLStatement($stmt);
  
  my %dataStructure;
  my $dataRef = \%dataStructure;
  
  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $experiment_name = $hashRef->{experiment_name};
    my $dataset_name    = $hashRef->{dataset_name};
    my $cultivar        = $hashRef->{cultivar};
    my $tissue          = $hashRef->{tissue};
    my $bio_replicate   = $hashRef->{bio_replicate};
    my $expt_condition  = $hashRef->{expt_condition};
    my $sra_ids         = $hashRef->{sra_ids};

    my $joined_details = join("\t", $dataset_name, $cultivar, $tissue, $bio_replicate, $expt_condition, $sra_ids);
    
    $dataStructure{$experiment_name} = $joined_details;
  }
  return $dataRef;
}


sub getTranscriptListByGene {
  my($self, $gene_id) = @_;
  
  my $stmt = "SELECT transcript_id 
	      FROM transcript_sequences
	      where gene_id = '$gene_id'
	      ";
	
  
  my $sth = $self->doSQLStatement($stmt);
  
  my @dataStructure;
  my $dataRef = \@dataStructure;
  
  my $count;
  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $transcript_id = $hashRef->{transcript_id}; 
    
    $dataStructure[$count] = $transcript_id;
    $count++;
  }
  
  @dataStructure = sort(@dataStructure);
  
  return $dataRef;
  
}

sub getMatchingHORVU{
  my($self, $bart_id) = @_;
  
    my $stmt = "SELECT bart_gene_id, bart_gene_length, bart_gene_direction, horvu_gene_id, horvu_gene_length, horvu_gene_direction, overlap_length, diff_horvu_bart_length, overlapping_status
	      FROM bart_horvu_overlaps
	      where bart_gene_id = '$bart_id'
	      ";

  my $sth = $self->doSQLStatement($stmt);

  my %dataStructure;
  my $dataRef = \%dataStructure;
  
  my $count = 1;

  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $bart_gene_id           = $hashRef->{bart_gene_id};
    my $bart_gene_length       = $hashRef->{bart_gene_length};
    my $bart_gene_direction    = $hashRef->{bart_gene_direction};
    my $horvu_gene_id          = $hashRef->{horvu_gene_id};
    my $horvu_gene_length      = $hashRef->{horvu_gene_length};
    my $horvu_gene_direction   = $hashRef->{horvu_gene_direction};
    my $overlap_length         = $hashRef->{overlap_length};
    my $diff_horvu_bart_length = $hashRef->{diff_horvu_bart_length};
    my $overlapping_status     = $hashRef->{overlapping_status};
    
    my $joined_details = join("\t", $bart_gene_length, $bart_gene_direction, $horvu_gene_length, $horvu_gene_direction, $overlap_length, $diff_horvu_bart_length, $overlapping_status);
    
    $dataStructure{$horvu_gene_id} = $joined_details;
    
    
    $count++;
  }
  return $dataRef;
}

sub getMatchingBART{
  my($self, $horvu_id) = @_;
  
    my $stmt = "SELECT bart_gene_id, bart_gene_length, bart_gene_direction, horvu_gene_id, horvu_gene_length, horvu_gene_direction, overlap_length, diff_horvu_bart_length, overlapping_status
	      FROM bart_horvu_overlaps
	      where horvu_gene_id = '$horvu_id'
	      ";

  my $sth = $self->doSQLStatement($stmt);

  my %dataStructure;
  my $dataRef = \%dataStructure;
  
  my $count = 1;

  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $bart_gene_id           = $hashRef->{bart_gene_id};
    my $bart_gene_length       = $hashRef->{bart_gene_length};
    my $bart_gene_direction    = $hashRef->{bart_gene_direction};
    my $horvu_gene_id          = $hashRef->{horvu_gene_id};
    my $horvu_gene_length      = $hashRef->{horvu_gene_length};
    my $horvu_gene_direction   = $hashRef->{horvu_gene_direction};
    my $overlap_length         = $hashRef->{overlap_length};
    my $diff_horvu_bart_length = $hashRef->{diff_horvu_bart_length};
    my $overlapping_status     = $hashRef->{overlapping_status};
    
    my $joined_details = join("\t", $bart_gene_length, $bart_gene_direction, $horvu_gene_id, $horvu_gene_length, $horvu_gene_direction, $overlap_length, $diff_horvu_bart_length, $overlapping_status);
    
    $dataStructure{$bart_gene_id} = $joined_details;
    
    
    $count++;
  }
  return $dataRef;
}


sub getTranscriptsByGene {
  my($self, $gene_id, $dataset) = (@_);


  my $stmt = "SELECT transcript_id, seq_length, description
	      FROM transcript_sequences
	      where gene_id = '$gene_id'
	      and dataset_name = '$dataset'
	      ";

  my $sth = $self->doSQLStatement($stmt);

  my %dataStructure;
  my $dataRef = \%dataStructure;
  my $number = 1;
  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $transcript_id      = $hashRef->{transcript_id};
    my $seq_length         = $hashRef->{seq_length};
    my $description        = $hashRef->{description};

    #my($id, $number) = split(/\./, $transcript_id, 2);
    my $id = $transcript_id;
    my $joined_details = join("\t", $transcript_id, $seq_length, $description);
    
    
    $dataStructure{$number} = $joined_details;
    $number++;
  }
  return $dataRef;
}


sub getStructures{
  my($self, $seq_id, $dataset) = @_;
  
  my $stmt;
  
  if($seq_id =~ /\./){ # if pass a transcript ID, just fetch structure of that transcript
  
    $stmt = "SELECT transcript_id, f_start, f_stop, strand, total_exons, contig_id
	      FROM transcript_structure
	      where transcript_id = '$seq_id'
	      and dataset_name = '$dataset'
	      ";

    
  } else { # if pass a gene ID, fetch all transcripts from that gene
    
    $stmt = "SELECT transcript_id, f_start, f_stop, strand, total_exons, contig_id
	      FROM transcript_structure
	      where gene_id = '$seq_id'
	      and dataset_name = '$dataset'
	      ";

  }

  my $sth = $self->doSQLStatement($stmt);

  my %dataStructure;
  my $dataRef = \%dataStructure;


  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){
    my $transcript_id = $hashRef->{transcript_id};
    my $f_start       = $hashRef->{f_start};
    my $f_stop        = $hashRef->{f_stop};
    my $strand        = $hashRef->{strand};
    my $total_exons   = $hashRef->{total_exons};
    my $seq_length    = $hashRef->{seq_length};
    my $chromosome    = $hashRef->{contig_id};
    
    
    my($id, $number) = split(/\./, $transcript_id, 2);
    
    my $joined_details = join("\t", $f_stop, $f_start, $strand, $total_exons, $seq_length, $chromosome);

    $dataStructure{$number}{$total_exons} = $joined_details;
  }
  return $dataRef;
  
  
  
}


sub searchContigDescription {

  my($self, $phrase, $dataset) = @_;

  my($stmt) = "SELECT query_name, gene_id, dataset_name, blast_db, hit_name, aln_match, aln_length, percent_id, evalue, description
               FROM representative_blast_hits where $phrase and hit_rank = 1 order by gene_id";


  my ($sth) = $self->doSQLStatement($stmt);	

  my %dataStructure;
  my $dataRef = \%dataStructure;

  while(my $hashRef = $sth->fetchrow_hashref('NAME_lc')){

    my $query_name  = $hashRef->{query_name};
    my $gene_id     = $hashRef->{gene_id};
    my $blast_db    = $hashRef->{blast_db};
    my $match_name  = $hashRef->{hit_name};
    my $aln_match   = $hashRef->{aln_match};
    my $aln_length  = $hashRef->{aln_length};
    my $percent_id  = $hashRef->{percent_id};
    my $evalue      = $hashRef->{evalue}; 
    my $description = $hashRef->{description};

    my($joined_details) = join ("\t", $gene_id, $blast_db, $match_name, $aln_match, $aln_length, $percent_id, $evalue, $description);

    $dataStructure{$query_name} = $joined_details;
  }
	
  return $dataRef

}


