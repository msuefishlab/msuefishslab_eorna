#!/usr/bin/perl

use eorna;
use barleyrtd_wrapper;
use CGI;
use strict;

my $cgi_query = CGI->new();
my $keywords    = $cgi_query->param("keywords");
my $separator   = $cgi_query->param("sep");
my $neg         = $cgi_query->param("neg");
my $dataset     = $cgi_query->param("dataset");
my $output_file = $cgi_query->param("output");

print "Content-type: text/html\n\n";

eorna::printHeader("Keyword Search Results");


my $query = barleyrtd_wrapper->new('efish_genomics');

my $temp_dir = '/home/bitnami/htdocs/tmp';


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
                  <li class='nav-item'><a class='nav-link active' href='keyword.html'>Annotation Search</a></li>
                  <li class='nav-item'><a class='nav-link' href='download.html'>Bulk Data Download</a></li>
                  <li class='nav-item'><a class='nav-link' href='bart_lookup.html'>Translate HORVU to BART IDs</a></li>
                  <li class='nav-item'><a class='nav-link' href='go.html'>GO Enrichment</a></li>
                </div>
                <li class='nav-item nav-link'  id='nav-title'></li>
                <li class='nav-item nav-link'  id='nav-header'><b>Links</b></li>
                <li class='nav-item nav-link'  id='nav-title'></li>
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



if (($keywords eq "") || ($keywords =~ /^\s+$/)){
  # if nothing is in the sequence box
  print "No keywords submitted<BR>\n";
  eorna::printFooter();
  die("No keywords given");

}

my $and_chosen = "";
my $or_chosen = "";
if ($separator eq "AND") {
  $and_chosen = "checked";
} elsif ($separator eq "OR"){
  $or_chosen = "checked";
}


my @keywords = split(/\s+/, $keywords);
my $n = 0;
my @clean_keywords;
foreach my $word(@keywords) {

  if ($word ne "") {
    $word =~ s/\W+//g;
    $clean_keywords[$n] = "\%$word\%";
    $n++;
  }
  
}
my $clean_keywords = join(" $separator ", @clean_keywords);


my @clean_negs;

if ($neg ne "") {

  my @neg_keywords = split(/\s+/, $neg);
  my $n = 0;

  foreach my $word(@neg_keywords) {
    if ($word ne "") {
      $word =~ s/\W+//g;
      $clean_negs[$n] = "\%$word\%";
      $n++;
    }
  }
}

my $phrase = "(description like '$clean_keywords[0]'";

for(my $i = 1; $i < @clean_keywords; $i++) {

  $phrase .= " $separator description like '$clean_keywords[$i]'";

}
$phrase = $phrase . ") ";



foreach my $neg(@clean_negs){

  $phrase .= " AND description not like '$neg'";
  
}

  my $db_phrase;
  if ($dataset ne "All"){
  
    $db_phrase = "AND dataset_name = '$dataset'";
  
  }

  my $total;
  if ($total == 0 ) {

    ($output_file, $total) = &make_data_file($phrase, $dataset);

  }
  
  

my %matchingSequences = %{$query->searchTranscriptDescription($phrase, $dataset)};


my @trackDetails = keys(%matchingSequences);

if(scalar(@trackDetails)<1){
    print "<h4><font color='#cc3300'>Sorry there are no transcripts matching these keywords.</font></h4>\n";
    print "<form><input onClick=\'history.go(-1);return true;\' type=\'button\' value=\'Back\'> </form><br>\n";

} else {

  print "<div class='data-header'>Transcripts matching keyword search</div>\n<div class='data-body'>
  <br><br><div id=\"return\">The query has returned $total results: <br><br>
  <div id=\"return\"><a download href='temp/$output_file'>Download Data as Tab-delimited Text</a><br><br>
  </div><br><br>\n";

  
  print "<div id=\"keyword_results\">\n";

  print "<table class='table-bordered' width='100%'><tbody><th>Sequence ID</th><th>Gene ID</th><<th>Description</th></tr>\n";
  
  my $count;
  
  foreach my $seq_name(sort (keys %matchingSequences)) {
    
    my ($gene_id, $dataset_name, $description) = split(/\t/, $matchingSequences{$seq_name});
    
    my $seq_link = "<a href='transcript.cgi?seq_name=$seq_name&dataset=$dataset'>$seq_name</a>";
    
    
    my $gene_link = "<a href='gene.cgi?seq_name=$gene_id&dataset=$dataset'>$gene_id</a>";
    


    
    my $match_link;
    
    if($blast_db eq "RICEPP7"){
      $match_link = "<a href='http://rice.plantbiology.msu.edu/cgi-bin/gbrowse/rice/?name=$match_name' target='_blank'>$match_name</a>"
    } elsif($blast_db eq "TAIRPP10"){
      $match_link = "<a href='http://www.arabidopsis.org/servlets/TairObject?type=gene&name=$match_name' target='_blank'>$match_name</a>"
    }

    print "<tr><td>$seq_link</td><td>$gene_link</td><td>$dataset</td><td>$description</td><tr>\n";
    
    $count++;
      
  }

  print "</tbody></table></div>\n";
  

  print "</div><br>\n";
 
}

eorna::printFooter();
 
 

# sub make_data_file{
  
#   my($phrase, $dataset) = @_;
  
#   my %allmatchingSequences = %{$query->searchContigDescription($phrase, $dataset)};


#   my @trackDetails = keys(%allmatchingSequences);
  
#   my $output_file;
#   my $total;

#   if(scalar(@trackDetails)<1){
  
#   } else {
  
  
#     my $random_number = int(rand 1000);
  
#     my $datestamp = `date '+%d%m%y_%H%M%S'`;
#     chomp $datestamp;

#     $output_file = $datestamp . "_" . $random_number . ".txt";
  
#     if (-e "$temp_dir/$output_file"){
      
#       print "<br><div id='return'><font color='#cc3300'>There has been an error in creating the output file</font></div><br><br>\n";
    
#       eorna::printFooter();
      
#       die("Error: file '$temp_dir/$output_file' already exists\n");
#     }
    
#     open (OUT, ">$temp_dir/$output_file");
    
    
#     print OUT "Sequence ID\tGene ID\tBLAST DB\tHit Name\tIdentities\t% identity\tE-value\tDescription\n";
  
    
  
#     foreach my $seq_name(sort (keys %allmatchingSequences)) {
    
#       my ($gene_id, $blast_db, $match_name, $aln_match, $aln_length, $percent_id, $evalue, $description) = split(/\t/, $allmatchingSequences{$seq_name});
      
#       print OUT "$seq_name\t$gene_id\t$blast_db\t$match_name\t$aln_match/$aln_length\t$percent_id\t$evalue\t$description\n";
      
#       $total++;
    
#     }
    
#     close OUT;
    
    

#   }

#   return ($output_file, $total);


# }


