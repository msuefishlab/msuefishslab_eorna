#!/usr/bin/perl

use eorna;
use barleyrtd_wrapper;
use CGI;
use strict;

my $cgi_query = CGI->new();
my $seq_name    = $cgi_query->param("seq_name");


print "Content-type: text/html\n\n";


my $query = barleyrtd_wrapper->new('efish_genomics');


if (($seq_name =~ /^XM/) || ($seq_name =~ /^BART/)){
  
  my $redirect;

  if($seq_name =~ /XM/) {
  
    if($seq_name =~ /\./){

      $redirect = "transcript.cgi?seq_name=$seq_name&dataset=BBRACH_0.4_ncbi";
  
    } else {
 
      $redirect = "gene.cgi?seq_name=$seq_name&dataset=150831_barley_pseudomolecules";

    }
  }
    
        
  if($seq_name =~ /^BART/) {
    
    $seq_name =~ s/p/u/;
  
    if($seq_name =~ /\./){

      $redirect = "transcript.cgi?seq_name=$seq_name&dataset=150831_barley_pseudomolecules";
  
    } else {
 
      $redirect = "gene.cgi?seq_name=$seq_name&dataset=150831_barley_pseudomolecules";

    }
    
    
  }
    
  print "<html>
<head>
<meta http-equiv=\"Refresh\" content=\"0;url=$redirect\" />
</head>

<body>

</body>
</html>";

} else {
  
  eorna::printHeader("Error");


print "<div class='container-fluid'>
      <div class='row'>
        <nav class='col-md-2 d-none d-md-block grey sidebar'>
          <div class='sidebar-sticky'>
            <ul class='nav flex-column'>

                <li class='nav-item nav-link'  id='nav-title'><img src='images/eorna-logo.svg' width='150'></li>

                <li class='nav-item nav-link'  id='nav-header'><b>Utilities Menu</b></li>
                <div class='list-group'>
                  <li class='nav-item'><a class='nav-link' href='index.html'>Home</a></li>
                  <li class='nav-item'><a class='nav-link' href='blast.html'>Homology Search</a></li>
                  <li class='nav-item'><a class='nav-link' href='keyword.html'>Annotation Search</a></li>
                  <li class='nav-item'><a class='nav-link' href='download.html'>Bulk Data Download</a></li>
                  <li class='nav-item'><a class='nav-link' href='bart_lookup.html'>Translate HORVU to BART IDs</a></li>
                  <li class='nav-item'><a class='nav-link' href='go.html'>GO Enrichment</a></li>
                </div>
            </ul>
          </div>
        </nav>
        <main role='main' class='col-md-9 ml-sm-auto col-lg-10 pt-3 px-4'>\n\n";
  
  print "<div class='data-header'>Error Message</div>
                    <br>
                    <div class='data-body'>
                        <span class='error'>The search term \"$seq_name\" does not match any sequence ID in the database. <br>Please enter a valid sequence identifier for the search.</span>

                    <div class='card-deck  m-3'>
                            <div class='card border-dark'>
                                <div class='card-header option-header'>Search for a Sequence by ID</div>
                                <div class='card-body'>

                                    <p><b>Barley RTD</b> : The predicted genes have the nomenclature 'BART1_0-u00001'. Transcript models are named after the the gene loci like 'BART1_0-u00001.001'. 
                                    <p><b>Morex 2017 Pseudomolecules Annotation</b> : The predicted genes have the nomenclature 'HORVU1Hr1G000010'. Transcript models are named after the the gene loci like 'HORVU1Hr1G000010.1'.
                                    <table class='table-bordered' width='100%'><theader><tr><th>Dataset</th><th>Transcript IDs</th><th># Genes</th><th> # Transcripts</th></tr></theader>
                                        <tbody>
                                        <tr><td>Barley RTD</td><td>BART1_0-u00001.001</td><td>60,444</td><td>177,240</td></tr>
                                        <tr><td>HORVU 2017</td><td>HORVU1Hr1G000010.1</td><td>81,683</td><td>334,126</td></tr>
                                        </tbody>
                                    </table>
                                    <br>
                                    <p>Searching for a gene ID will return all the transcript models from that gene region. You can go directly to a gene or transcript by using this search box:</p>

                                    <form action='search_ids.cgi' method='get'>
                                        <div class='input-group mb-3'>
                                            <div class='input-group-prepend'>
                                                <span class='input-group-text'>Search for Sequence ID</span>
                                            </div>
                                            <input type='text' class='form-control' name='seq_name' value='BART1_0-u00001' onfocus=\"this.value=''\">
                                            <div class='input-group-append'><input class='btn btn-success' type='submit' value='Search'></div>
                                        </div>
                                    
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>\n";
  
  eorna::printFooter();
    
}









