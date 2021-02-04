#!/usr/bin/perl

use barleyrtd_wrapper;
use eorna;

use CGI;
use GD;
use strict;

my $cgi_query = CGI->new();
my $seq_name = $cgi_query->param("seq_name");
my $dataset  = $cgi_query->param("dataset");

my $image_dir = "/var/www/html/barleyrtd-new/blast_net_images";

print "Content-type: text/html\n\n";


my $db_query = barleyrtd_wrapper->new('barleyrtd_new');

my($gene_name, $number) = split(/\./, $seq_name,2);

my ($contig_id) = $db_query->{'dbh'}->
  selectrow_array("select contig_id from transcript_sequences where transcript_id = '$seq_name' and dataset_name=\'$dataset\'");


if ($contig_id eq ""){ 

  eorna::printHeader("Error");

  print "<div class='container-fluid'>
            <div class='row'>


                <nav class='col-md-2 d-none d-md-block grey sidebar'>
                    <div class='sidebar-sticky'>
                        <ul class='nav flex-column'>
                            <li class='nav-item nav-link'  id='nav-title'><img class='img-fluid' src='images/eorna-logo.png' width=150'><span class='app-title'>EoRNA</span></li>
                            <li class='nav-item nav-link'  id='nav-header'><b>Utilities Menu</b></li>
                            <div class='list-group'>
                            <li class='nav-item'><a class='nav-link active' href='index.html'>Home</a></li>
                            <li class='nav-item'><a class='nav-link' href='blast.html'>Homology Search</a></li>
                            <li class='nav-item'><a class='nav-link' href='keyword.html'>Annotation Search</a></li>
                            <li class='nav-item'><a class='nav-link' href='download.html'>Bulk Data Download</a></li>
                            <li class='nav-item'><a class='nav-link' href='bart_lookup.html'>Translate HORVU to BART IDs</a></li>
                            <li class='nav-item'><a class='nav-link' href='go.html'>GO Enrichment</a></li>
                            </div>
                        </ul>
                    </div>
                </nav>

                <main role='main' class='col-md-9 ml-sm-auto col-lg-10 pt-3 px-4'>

                    <div class='data-header'>Error Message</div>
                    <br>
                    <div class='data-body'>\n
                      <span class='error'>There are no transcripts in the database with ID \"$seq_name\". <br>Please enter a valid sequence identifier for the search.</span><br><br>
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
                    </div>
                </main>
            </div>
        </div>
    </body>
</html>";

  die("eorna/transcript.cgi: Can't find contig source for $seq_name, $dataset\n");
}



  
my ($transcript_start, $transcript_stop, $chromosome) = $db_query->{'dbh'}->
  selectrow_array("select min(f_start), max(f_stop), contig_id from transcript_structure where transcript_id = '$seq_name' and dataset_name=\'$dataset\' group by contig_id");
  
my ($nuc_seq_length, $nuc_seq) = $db_query->{'dbh'}->
  selectrow_array("SELECT seq_length, seq_sequence FROM transcript_sequences WHERE transcript_id= '$seq_name' and dataset_name=\'$dataset\'");

my $protein_seq_link;
if ($seq_name =~ /BART/) {
    $protein_seq_link = "<li class='nav-item'><a class='nav-link text-dark' href='#protseq'>Protein Sequence</a></li>"
}

eorna::printHeader($seq_name);
  
print "
        <div class='container-fluid'>
            <div class='row'>
                <nav class='col-md-2 d-none d-md-block grey sidebar'>
                <div class='sidebar-sticky'>
                    <ul class='nav flex-column'>
                    <li class='nav-item'>
                        <li class='nav-item nav-link'  id='nav-title'><img class='img-fluid' src='images/eorna-logo.png' width=150'><span class='app-title'>EoRNA</span></li>
                        <li class='nav-item nav-link' id='nav-header'><b>Gene ID</b></li>

                        <li class='nav-item' id='nav-info'>$gene_name <a class='nav-link' href='gene.cgi?seq_name=$gene_name&dataset=$dataset'> &#10140; View Gene</a></li>

                        <li class='nav-item nav-link' id='nav-header'><b>Transcript ID</b></li>
                        <li class='nav-item' id='nav-info'>$seq_name</li>
                        <li class='nav-item nav-link' id='nav-header'><b>Location</b></li>
                        <li class='nav-item' id='nav-info'>$chromosome: $transcript_start - $transcript_stop</li>
                        <li class='nav-item nav-link' id='nav-header'><b>Data</b></li>
                        <div class='list-group ' id='list-data'>
                        <li class='nav-item'><a class='nav-link text-dark' href='#alt_cds'>CDS Structure</a></li>
                        <li class='nav-item'><a class='nav-link text-dark' href='#loc_cds'>Exon Locations</a></li>
                        <li class='nav-item'><a class='nav-link text-dark' href='#seq'>Nucleotide Sequence</a></li>
                        $protein_seq_link
                        </div>
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
                </nav>\n\n
                <main role='main' class='col-md-9 ml-sm-auto col-lg-10 pt-3 px-4'>\n";


############## Draw the transcript on the contig ###########################################
eorna::drawTranscriptsGbrowse($seq_name, $dataset, "n");

eorna::printTranscriptStructureTable($seq_name, $dataset);


############### Print out the transcript sequence ##########################################

eorna::printSequence($seq_name, "CDS", $nuc_seq, $dataset);

############### Print out the protein sequence ##########################################

if ($seq_name =~ /BART/) {
    eorna::printProteinSequence($seq_name, $dataset);
}


eorna::printFooter();





