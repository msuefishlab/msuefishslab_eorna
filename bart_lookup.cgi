#!/usr/bin/perl

use eorna;
use barleyrtd_wrapper;
use CGI;
use strict;

my $cgi_query = CGI->new();
my $list    = $cgi_query->param("list");


print "Content-type: text/html\n\n";

eorna::printHeader("HORVU to BART");


my $db_query = barleyrtd_wrapper->new('barleyrtd_new');

my $temp_dir = '/var/www/html/barleyrtd-new/temp';


print "<div class='container-fluid'>
      <div class='row'>
        <nav class='col-md-2 d-none d-md-block grey sidebar'>
          <div class='sidebar-sticky'>
            <ul class='nav flex-column'>

                <li class='nav-item nav-link'  id='nav-title'><img class='img-fluid' src='images/eorna-logo.png' width=150'><span class='app-title'>EoRNA</span></li>

                <li class='nav-item nav-link'  id='nav-header'><b>Utilities Menu</b></li>
                <div class='list-group'>
                  <li class='nav-item'><a class='nav-link' href='index.html'>Home</a></li>
                  <li class='nav-item'><a class='nav-link' href='blast.html'>Homology Search</a></li>
                  <li class='nav-item'><a class='nav-link' href='keyword.html'>Annotation Search</a></li>
                  <li class='nav-item'><a class='nav-link' href='download.html'>Bulk Data Download</a></li>
                  <li class='nav-item'><a class='nav-link active' href='bart_lookup.html'>Translate HORVU to BART IDs</a></li>
                  <li class='nav-item'><a class='nav-link' href='go.html'>GO Enrichment</a></li>
                </div>
                <li class='nav-item nav-link'  id='nav-title'></li>
                <li class='nav-item nav-link'  id='nav-header'><b>Links</b></li>
                <li class='nav-item nav-link'  id='nav-title'></li>
                <li class='nav-item'><a class='nav-link ext-links' href='contact.html'>Citation / About Authors</a></li>
                <li class='nav-item'><a class='nav-link ext-links' href='http://ics.hutton.ac.uk/barleyrtd'>BarleyRTD Website</a></li>
                <li class='nav-item'><a class='nav-link ext-links' href='http://ics.hutton.ac.uk'>Information and Computing Sciences \@Hutton</a></li>
                <li class='nav-item'><a class='nav-link ext-links' href='http://www.hutton.ac.uk'>The James Hutton Institute</a></li>
                <li class='nav-item'><a class='nav-link ext-links' href='https://www.barleyhub.org/'>International Barley Hub</a></li>
                <li class='nav-item nav-link'  id='nav-title'></li>

                <li class='nav-item nav-link'  id='nav-header'><b>Funders</b></li>
                <li class='nav-item nav-link'  id='nav-title'></li>
                <li class='nav-item nav-link'  id='nav-title'><img class='img-fluid' src='images/resas.svg' width=150'></li>
                <li class='nav-item nav-link'  id='nav-title'><img class='img-fluid' src='images/bbsrc.svg' width=150'></li>
            </ul>
          </div>
        </nav>
        <main role='main' class='col-md-9 ml-sm-auto col-lg-10 pt-3 px-4'>\n\n";



if (($list eq "") || ($list =~ /^\s+$/)){
  # if nothing is in the sequence box
  print "No ID's submited<BR>\n";
  eorna::printFooter();
  die("No ID's given");

}

my @list = split(/\n/, $list);

print "<div class='data-header'>ID Search Result</div>\n<div class='data-body'> <p>Please note that not every HORVU ID will have an equivalent BART ID, and some HORVU IDs will overlap with more  than one BART ID. In the table the Overlap Status column has the following meaning: Containing  = HORVU is shorter than the BART, Contained = BART is shorter than the HORVU, Partial-Overlap = Overlap exists, and Undefined = the BART transcript has no overlapping HORVU.</p>\n";

print "<div id=\"keyword_results\">\n";

print "<table class='table-bordered' width='100%'><tbody><th>Search ID</th><th>BART ID</th><th>BART Length</th><th>BART Gene Dir</th><th>HORVU Gene Length</th><th>HORVU Gene Dir</th><th>Overlap Length</th><th>Length Difference</th><th>Overlap Status</th></tr><tbody>\n";

foreach my $id(@list){

    $id =~ s/\s+//g;

    # Get all BARTs that match these HORVUs

    my %matchingBARTs= %{$db_query->getMatchingBART($id)};


    my @trackDetails = keys(%matchingBARTs);

    if(scalar(@trackDetails)<1){

        print "<tr><td>$id</td><td>None</td><td>-</td><td>-</td><td>-</td><td>-</td><td>-</td><td>-</td><td>-</td></tr>\n";

    
    } else {


        my $count;
        
        foreach my $seq_name(sort (keys %matchingBARTs)) {
            
            my ($bart_gene_length, $bart_gene_direction, $horvu_gene_id, $horvu_gene_length, $horvu_gene_direction, $overlap_length, $diff_horvu_bart_length, $overlapping_status) = split(/\t/, $matchingBARTs{$seq_name});

            print "<tr><td>$id</td><td><a href='gene.cgi?seq_name=$seq_name&dataset=150831_barley_pseudomolecules'>$seq_name</a></td><td>$bart_gene_length</td><td>$bart_gene_direction</td><td>$horvu_gene_length</td><td>$horvu_gene_direction</td><td>$overlap_length</td><td>$diff_horvu_bart_length</td><td>$overlapping_status</td></tr>\n";

            $count++;
      
        }

 
    }
    
}
print "</tbody></table></div>\n";

eorna::printFooter();
