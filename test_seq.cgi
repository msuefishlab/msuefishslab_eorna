#!/usr/bin/perl

use barleyrtd_wrapper;
use eorna;

use CGI;
use GD;
use strict;

my $cgi_query = CGI->new();
my $gene_name = $cgi_query->param("seq_name");
my $dataset  = $cgi_query->param("dataset");

my $image_dir = "/var/www/html/barleyrtd-new/blast_net_images";


print "Content-type: text/html\n\n";




my $db_query = barleyrtd_wrapper->new('efish_genomics');


#Get the contig that this gene is from
my ($contig_id) = $db_query->{'dbh'}->
  selectrow_array("select contig_id from transcript_sequences where gene_id = '$gene_name' and dataset_name=\'$dataset\'");
  
my ($contig_length) = $db_query->{'dbh'}->
  selectrow_array("select seq_length from genomic_sequences where contig_id = '$contig_id' and dataset_name=\'$dataset\'");
    
my ($transcript_start, $transcript_stop, $chromosome) = $db_query->{'dbh'}->
  selectrow_array("select min(f_start), max(f_stop), contig_id from transcript_structure where gene_id = '$gene_name' and dataset_name=\'$dataset\' group by contig_id");

my $matching_genes_link = "<a class='nav-link' href='#matchingGenes'>Matching BARTs</a>";
if ($gene_name =~ /BART/){
    $matching_genes_link = "<a class='nav-link' href='#matchingGenes'>Matching HORVUs</a>";
}

my %transcripts = %{$db_query->getTranscriptsByGene($gene_name, $dataset)};

{
    my @temp = %transcripts;
    print "@temp";
}
#eorna::drawTranscriptTable($gene_name, $dataset);

#eorna::drawTranscriptsGbrowse($gene_name, $dataset, "y");




