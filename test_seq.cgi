#!/usr/bin/perl

use barleyrtd_wrapper;
use eorna;

use CGI;
use GD;
use strict;

my $cgi_query = CGI->new();
my $seq_name = $cgi_query->param("seq_name");
my $dataset  = $cgi_query->param("dataset");


my $db_query = barleyrtd_wrapper->new('efish_genomics');

my ($gene_name) = $db_query->{'dbh'}->
  selectrow_array("select gene_id from transcript_sequences where transcript_id = '$seq_name' and dataset_name=\'$dataset\'");

my ($contig_id) = $db_query->{'dbh'}->
  selectrow_array("select contig_id from transcript_sequences where transcript_id = '$seq_name' and dataset_name=\'$dataset\'");
    
my ($nuc_seq_length, $nuc_seq) = $db_query->{'dbh'}->
  selectrow_array("SELECT seq_length, seq_sequence FROM transcript_sequences WHERE transcript_id= '$seq_name' and dataset_name=\'$dataset\'");

print $nuc_seq


