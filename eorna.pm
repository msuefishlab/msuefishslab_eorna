use strict;

package eorna;
use barleyrtd_wrapper;


use GD;
require Exporter;

my $db_query = barleyrtd_wrapper->new('efish_genomics');

my $image_dir = "/home/bitnami/htdocs/blast_net_images";


sub printHeader {
  my ($page_title) = @_;


print "<!DOCTYPE html>
  <html lang='en'>
  <head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css'>
  <link rel='stylesheet' href='stylesheet/eorna.css'>
  <link rel='icon' href='images/eorna-mini-logo.png'>

  <title>EoRNA - $page_title</title>

  <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js'></script>
  <script src='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js'></script>
  <script src=\"https://cdn.plot.ly/plotly-latest.min.js\"></script>
  </head>
  
  <body class='body-pos' data-spy='scroll' data-target='#list-data' data-offset='35' id='content'>\n\n";
}



sub printFooter {

  print "
                </main>
            </div>
        </div>
    </body>
</html>";

}





sub createJSPlotlyGraph {
  my($gene_id) = @_;

  # Get a list of the transcript_ids for this gene
  my @transcripts = @{$db_query->getTranscriptListByGene($gene_id)};

  my $number_of_transcripts = @transcripts;

  print "<div class='anchor data-header' id='tpmgraph'>TPM Values of Transcripts</div><div class='data-body'>\n";

  #convert the unpadded gene id to a padded gene_id to access the tpm_values table
  $gene_id =~ s/-u/-p/;

  my %tpms_pivot; #going to want to pivot the data matrix to be able to print out as tab-delimited text later

  my %tpms= %{$db_query->getPaddedTPMsJS_efishgenomics($gene_id)};

  my @trackDetails = keys(%tpms);

  if(scalar(@trackDetails)<1){
    print "<span class='error'>No TPM values available for this gene's transcript models. Try any <a href='#matchingGenes'>matching BART genes below </a>.</span></div>\n";
  } else {

    # Make filename for the plotly page
    my $plotly_filename = $gene_id . "_plotly.html";
  
    print "<a href='plotly/$plotly_filename'>Link to larger plotly expression graph</a><br><br>\n";

    my $tpms_filename = $gene_id . "_tpms.txt";

    # Get meta-data for all the experiments
    my %metadata = %{$db_query->getExperimentMetadata()};

    # Turn this list of metadata data into text for labeling the graph
    my $graph_label_text;
    foreach my $experiment_name(sort keys %metadata){

      my($dataset_name, $cultivar, $tissue, $bio_replicate, $expt_condition, $sra_ids) = split(/\t/, $metadata{$experiment_name}, 6);

      $graph_label_text .="\"Dataset: $dataset_name<br>SRA ID: $sra_ids<br>Cultivar: $cultivar<br>Tissue: $tissue<br>Replicate: $bio_replicate &nbsp; &nbsp; Condition: $expt_condition\",\n";
    }
    $graph_label_text =~ s/\,$//;

  
  # Gather all the plotly javascript into a string to dump out into a separate html document so we can have a link out to it
    my $plotly_text_doc = "<div class='anchor data-header' id='tpmgraph'>TPM Values of Transcripts</div><div class='data-body'>
  <a download href='$tpms_filename'>Download tab-delimited text file of TPM values</a><br>
  <div id=\"plotly_tpm\">
  </div>
  <script>
  TESTER = document.getElementById('plotly_tpm');\n";
  
  # Print on page
    print "<div id=\"plotly_tpm\"></div>
  <script>
  TESTER = document.getElementById('plotly_tpm');\n";
  
    # Make a list of the names of the graph data lists that will be drawn on the plot
    my $trace_list;
    my $traceLabel_text;
  
    my $count_transcripts;
    foreach my $transcript_id(@transcripts){
    
      $count_transcripts++;
    
      my $tracevar = "trace" . $count_transcripts;
    
      $trace_list .= "$tracevar,";
    
     $transcript_id =~ s/-u/-p/;
    
      my $transcript_number = $transcript_id;
    
      $transcript_number =~ s/$gene_id\.//;

      #make the lists of data for the traces
      my $expt_name_list;
      my $tpm_value_list;
      my $label_value_list;

      foreach my $expt_name(sort keys %{$tpms{$transcript_id}}){
        my($tissue_val, $expt_condition_val, $tpm_val) = split(/\t/, $tpms{$transcript_id}{$expt_name}, 3);
        $label_value_list .= "\"0\",";
        $tissue_name_list .= "\"$tissue_val\",";
        $condition_name_list .= "\"$expt_condition_val\",";
        $tpm_value_list .= "$tpm_val,";

        # Need to pivot the data matrix for printing out in a tab-delimited text file later
        $tpms_pivot{$expt_name}{$transcript_id} = $tpm_val;
    
      }
    
      $expt_name_list =~ s/\,$//;
      $tpm_value_list =~ s/\,$//;
      $label_value_list =~ s/\,$//;
      $condition_name_list =~ s/\,$//;
      $tissue_name_list =~ s/\,$//;


    print  "var $tracevar = {
    type: 'box',
    boxpoints: 'all',
    whiskerwidth: 0.2,
    marker: {
        size: 4
    },
    line: {
        width: 1
    },
    name: '$transcript_number',
    hoverinfo: 'none',
    x: [$condition_name_list],
    y: [$tpm_value_list],
    hovertemplate: 'TPM: %{y}<extra></extra>'
    };\n";
    
    $plotly_text_doc .= "var $tracevar = {
    type: 'box',
    boxpoints: 'all',
    whiskerwidth: 0.2,
    marker: {
        size: 4
    },
    line: {
        width: 1
    },
    name: '$transcript_number',
    hoverinfo: 'none',
    x: [$condition_name_list],
    y: [$tpm_value_list],
    hovertemplate: 'TPM: %{y}<extra></extra>'
    };\n";

    
    }

    
    $trace_list =~ s/\,$//;
    
    print "var data = [$trace_list];
  var layout = {
    title: '$gene_id',
    autosize: false,
    width: 1000,
    height: 600,
    margin: {
      l: 50,
      r: 50,
      b: 50,
      t: 50,
      pad: 4
    },
    yaxis: {title: 'TPM'},
    xaxis: {
      title: 'Sample',
      showticklabels: false,
    },
    barmode: 'stack',
    colorway: ['#d11141', '#00b159', '#00aedb', '#2ca02c', '#f37735', '#ffc425', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22']
  };

  Plotly.newPlot('plotly_tpm', data, layout);

</script>
<a download href='plotly/$tpms_filename'>Download tab-delimited text file of TPM values</a></div>\n";
    
    $plotly_text_doc .= "var data = [traceLabels,$trace_list];
  var layout = {
    title: '$gene_id',
    autosize: false,
    width: 1200,
    height: 700,
    margin: {
      l: 50,
      r: 50,
      b: 50,
      t: 50,
      pad: 4
    },
    yaxis: {title: 'TPM'},
    xaxis: {
      title: 'Sample',
      showticklabels: false,
    },
    barmode: 'stack',
   colorway: ['#17becf', '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22']
  };

  Plotly.newPlot('plotly_tpm', data, layout);

</script>
</div>\n";
  
  
    # Open the stand-alone html file and print the javascript for the plot in it
    open(PLOTLY, ">/home/bitnami/htdocs/plotly/$plotly_filename") || die ("Cannot create file /home/bitnami/htdocs/plotly/$plotly_filename");

    print PLOTLY "<!DOCTYPE html>
  <html lang='en'>
  <head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css'>
  <link rel='stylesheet' href='/eorna/stylesheet/eorna.css'>
  <link rel='icon' href='/eorna/images/eorna-logo-pixil.png'>

  <title>EoRNA</title>

  <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js'></script>
  <script src='https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js'></script>
  <script src='https://cdn.plot.ly/plotly-latest.min.js'></script>


  </head>
  <body>
  $plotly_text_doc\n
  </body>
</html>\n";
  
    close PLOTLY;


    # Make a tab-delimited text file of the TPM values for downloading

    my $tpms_filename = $gene_id . "_tpms.txt";

    open(TPMS, ">/home/bitnami/htdocs/plotly/$tpms_filename") || die ("Cannot create file /home/bitnami/htdocs/plotly/$tpms_filename");

    print TPMS "Experiment name\tDataset Name\tSRA IDs\tCultivar\tTissue\tBio Replicate\tExpt Condition";
    foreach my $t_id(@transcripts){
      print TPMS"\t$t_id";
    }
    
    print TPMS "\n";
  
  
    foreach my $expt_name(sort keys %tpms_pivot){

      my($dataset_name, $cultivar, $tissue, $bio_replicate, $expt_condition, $sra_ids) = split(/\t/, $metadata{$expt_name}, 6);
    
      print TPMS "$expt_name\t$dataset_name\t$sra_ids\t$cultivar\t$tissue\t$bio_replicate\t$expt_condition";
      
      foreach my $transcript_id(@transcripts){
        
        $transcript_id =~ s/-u/-p/;
        
        print TPMS "\t$tpms_pivot{$expt_name}{$transcript_id}";
    
      }
      
      print TPMS "\n";
    }
    close TPMS;
  
  }
}


sub printGOAnnotation{
  my ($gene_id) = @_;
  
  if ($gene_id =~ /BART/) {
  
    my ($gene, $annotation, $go_ids, $go_terms) = $db_query->{'dbh'}-> selectrow_array("SELECT gene_id, annotation, go_ids, go_terms FROM go_annotation where gene_id = '$gene_id'");
    
    print "<div class='anchor data-header' id='go_annot'>GO Annotation</div><div class='data-body'>\n";
  
    if ($gene eq "") {
      
      print "There is no GO annotation for this gene<br><br>\n";
    
    } else {
    
      print "Generated by PANNZER<br><br>\n";
    
      print "<table  class='table-bordered' width='100%'><tbody><tr><th>GO ID</th><th>GO terms</th></tr>\n";
      
      my @go_ids = split(/\;/, $go_ids);
      my @go_terms = split(/\;/, $go_terms);
      
      for (my $i = 0; $i < @go_ids; $i++){
        
        print "<tr><td>$go_ids[$i]</td><td>$go_terms[$i]</td></tr>\n";
        
        
      }
      
      print "</tbody></table></div>\n";
    
    }
  }
  
}


sub printMatchingHORVU{
  my ($bart_id) = @_;
  
  my %matchingHORVUs= %{$db_query->getMatchingHORVU($bart_id)};
  
  my @trackDetails = keys(%matchingHORVUs);
  
  
  print "<div class='anchor data-header' id='matchingGenes'>Matching HORVU genes</div>\n<div class='data-body'>\n";


  if(scalar(@trackDetails)<1){

    print "<h5><font color='#cc3300'>No entries for this BART ID</font></h5>\n";

  } else {
    
    print "BarleyRTD transcripts were compared to the location of the HORVU 2017 Predicted Transcripts. Overlapping status is classified as Containing (HORVU is shorter than the BART), Contained (BART is shorter than the HORVU), Partial-Overlap (Overlap exists), and Undefined (the BART transcript has no overlapping HORVU).<br><br>\n";
    
    print "<table class='table-bordered' width='100%'><tbody><tr><th>HORVU ID</th><th>Percentage overlap</th><th>BART Gene Direction</th><th>HORVU Gene Direction</th><th>Overlap Length</th><th>Gene Length Difference</th><th>Overlapping Status</th></tr>\n";
    
    
  
  
    foreach my $horvu_id(sort {$a <=> $b} keys %matchingHORVUs){
      
      my ($bart_gene_length, $bart_gene_direction, $horvu_gene_length, $horvu_gene_direction, $overlap_length, $diff_horvu_bart_length, $overlapping_status) = split(/\t/, $matchingHORVUs{$horvu_id}, 7);
      
      if ($horvu_id eq "-") {
        print "<tr><td>None</td><td>-</td><td>-</td><td>-</td><td>-</td><td>-</td><td>$overlapping_status</td></tr>\n";
      
      } else {
      
        my $percentage_overlap = ($overlap_length / $bart_gene_length) * 100;
      
        $percentage_overlap = sprintf("%.1f", $percentage_overlap);
      
        print "<tr><td><a href='gene.cgi?seq_name=$horvu_id&dataset=150831_barley_pseudomolecules'>$horvu_id</a></td><td>$percentage_overlap</td><td>$bart_gene_direction</td><td>$horvu_gene_direction</td><td>$overlap_length</td><td>$diff_horvu_bart_length</td><td>$overlapping_status</td></tr>\n";

      }
    }
    
    print "</tbody></table></div>\n";
    
    
    
    
  }
  
}


sub printMatchingBART{
  my ($horvu_id) = @_;
  
    my %matchingBARTs= %{$db_query->getMatchingBART($horvu_id)};
  
  my @trackDetails = keys(%matchingBARTs);
  
  
  print "<div class='anchor data-header' id='matchingGenes'>Matching BART genes</div>\n<div class='data-body'>\n";


  if(scalar(@trackDetails)<1){

    print "<h5><font color='#cc3300'>No entries for this BART ID</font></h5>\n";

  } else {
    
    print "BarleyRTD transcripts were compared to the location of the HORVU 2017 Predicted Transcripts. Overlapping status is classified as Containing (HORVU is shorter than the BART), Contained (BART is shorter than the HORVU), Partial-Overlap (Overlap exists), and Undefined (the BART transcript has no overlapping HORVU).<br><br>\n";

    print "<table class='table-bordered' width='100%'><tbody><tr><th>BART ID</th><th>Percentage overlap</th><th>BART Gene Direction</th><th>HORVU Gene Direction</th><th>Overlap Length</th><th>Gene Length Difference</th><th>Overlapping Status</th></tr>\n";
  
    foreach my $bart_id(sort {$a <=> $b} keys %matchingBARTs){
    

      my ($bart_gene_length, $bart_gene_direction, $horvu_gene_id, $horvu_gene_length, $horvu_gene_direction, $overlap_length, $diff_horvu_bart_length, $overlapping_status) = split(/\t/, $matchingBARTs{$bart_id}, 8);
      
      my $percentage_overlap = ($overlap_length / $bart_gene_length) * 100;
      
      $percentage_overlap = sprintf("%.1f", $percentage_overlap);
      
      print "<tr><td nowrap><a href='gene.cgi?seq_name=$bart_id&dataset=150831_barley_pseudomolecules'>$bart_id</a></td><td>$percentage_overlap</td><td>$bart_gene_direction</td><td>$horvu_gene_direction</td><td>$overlap_length</td><td>$diff_horvu_bart_length</td><td>$overlapping_status</td></tr>\n";

    }
    
    print "</tbody></table></div>\n";
    
    
    
    
  }
}

############### Draw genes on the contig ############################################
sub printTranscriptStructureTable {
  
  my ($seq_name, $dataset) = @_;
  
  my %transcript_structures= %{$db_query->getStructures($seq_name, $dataset)};
  
  my @trackDetails = keys(%transcript_structures);
  
  
  print "
            <div class='anchor data-header' id='loc_cds'>Locations of Exons of $seq_name</div>
            <div class='data-body'>\n";


  if(scalar(@trackDetails)<1){

    print "<h5><font color='#cc3300'>There are no CDS ID for this entry.</font></h5>\n";

  } else {
    
    print "         
            <table  class='table-bordered' width='100%'>
                <tbody><tr><th>Chromosome</th><th>Exon</th><th>Start</th><th>Stop</th><th>Direction</th></tr>\n";
  
  
    foreach my $number(sort {$a <=> $b} keys %transcript_structures){
    
      foreach my $exon_number(sort {$a <=> $b} keys %{$transcript_structures{$number}}){

        my ($stop, $start, $strand, $total_exons, $chromosome) = split(/\t/, $transcript_structures{$number}{$exon_number}, 5);
      
        print "         <tr><td>$chromosome</td><td>$total_exons</td><td>$start</td><td>$stop</td><td>$strand</td></tr>\n";

      }
    }
    
    print "
                </tbody>
            </table>
        </div>\n";
    
  }
}



sub getHomologies{
  
  my ($seq_name, $dataset) = @_;
  
  
  my $title;
  my $query_name;
  
  # Figure out if passed a gene_id or a transcript_id
  if($seq_name =~ /\./){
    
    $query_name = $seq_name;
    
    $title = "Homology to Model Species (BLASTX to E-value < 1e-30)";
  
  } else {
    
    # Find the longest transcript for this gene
    my ($longest_transcript, $length) = $db_query->{'dbh'}->
        selectrow_array("select transcript_id, seq_length from transcript_sequences where gene_id = '$seq_name' and dataset_name = '$dataset' order by seq_length desc limit 1");
    
    $query_name = $longest_transcript;

    $title = "Homology of Longest Transcript to Model Species (BLASTX to E-value < 1e-30)";
    
  }

  # Get homology BLAST hits for gene and compose the table
  my ($rice_hit, $r_frame, $r_evalue, $r_score, $r_ident, $r_aln_match, $r_aln_length, $r_description) = $db_query->{'dbh'}->
  selectrow_array("select hit_name, frame, evalue, score, percent_id, aln_match, aln_length, description from representative_blast_hits where query_name = '$query_name' and dataset_name = '$dataset' and blast_db = \'RICEPP7\' and hit_rank = 1");

  my $rice_comment = "<td align='center'>Rice PP7</td><td align='center'>None</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td>";
  if($rice_hit ne ""){

  $rice_comment = "<td align='center'>Rice PP7</td>
  <td align='center'><a href='http://rice.plantbiology.msu.edu/cgi-bin/gbrowse/rice/?name=$rice_hit' target='_blank'>$rice_hit</a></td>
  <td align='center'>$r_frame</td>
  <td align='center'>$r_evalue</td>
  <td align='center'>$r_score</td>
  <td align='center' nowrap>$r_aln_match/$r_aln_length ($r_ident\%)</td>
  <td align='left'>$r_description</td>";
  }
  
  my ($tair_hit, $t_frame, $t_evalue, $t_score, $t_ident, $t_aln_match, $t_aln_length, $t_description) = $db_query->{'dbh'}->
  selectrow_array("select hit_name, frame, evalue, score, percent_id, aln_match, aln_length, description from representative_blast_hits where query_name = '$query_name' and dataset_name = '$dataset' and blast_db = \'TAIRPP10\' and hit_rank = 1");
  
  my $tair_comment = "<td align='center'>TAIR PP10</td><td align='center'>None</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td>";
  if($tair_hit ne ""){
    
    my($tair_locus_id, $rest) = split(/\./, $tair_hit, 2); 
    
  $tair_comment = "<td align='center'>TAIR PP10</td>
  <td align='center' nowrap><a href='http://www.araport.org/locus/$tair_locus_id' target='_blank'>$tair_locus_id @ ARAPORT</a><br><a href='http://www.arabidopsis.org/servlets/TairObject?type=gene&name=$tair_hit' target='_blank'>$tair_hit @ TAIR</a></td>
  <td align='center'>$t_frame</td>
  <td align='center'>$t_evalue</td>
  <td align='center'>$t_score</td>
  <td align='center' nowrap>$t_aln_match/$t_aln_length ($t_ident\%)</td>
  <td align='left'>$t_description</td>";
  }
  
    my ($brac_hit, $b_frame, $b_evalue, $b_score, $b_ident, $b_aln_match, $b_aln_length, $b_description) = $db_query->{'dbh'}->
  selectrow_array("select hit_name, frame, evalue, score, percent_id, aln_match, aln_length, description from representative_blast_hits where query_name = '$query_name' and dataset_name = '$dataset' and blast_db = \'BRACHPP3\' and hit_rank = 1");
  
  my $brac_comment = "<td align='center'>BRACH PP3</td><td align='center'>None</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td><td align='center'>-</td>";
  
  $b_evalue =~ s/\,//;
  
  if($brac_hit ne ""){

  $brac_comment = "<td align='center'>BRACH PP3</td>
  <td align='center'><a href='https://phytozome.jgi.doe.gov/pz/portal.html#!results?search=0&crown=1&star=1&method=5010&searchText=$brac_hit&offset=0' target='_blank'>$brac_hit</a></td>
  <td align='center'>$b_frame</td>
  <td align='center'>$b_evalue</td>
  <td align='center'>$b_score</td>
  <td align='center' nowrap>$b_aln_match/$b_aln_length ($b_ident\%)</td>
  <td align='left'>$b_description</td>";
  }
  
  # Print out the title and table contents
  print "<div class='anchor data-header' id='homologies'>$title</div><div class='data-body'>";
  print "<table  class='table-bordered' width='100%'><tbody><tr><th>Database</th><th>Hit</th><th>Frame</th><th>E-value</th><th>Score</th><th>%  Identity</th><th>Description</th><tr>$rice_comment</tr><tr>$tair_comment</tr><tr>$brac_comment</tr></tbody></table></div>\n";
  
}



sub get_GBrowse{
  
  my($seq_name) = @_;
  
  if (($seq_name =~ /HORVU/) && (!($seq_name =~ /\./))) {
    $seq_name = $seq_name . ".1";
  } elsif (($seq_name =~ /BART/) && (!($seq_name =~ /\./))) {
    $seq_name = $seq_name . ".001";
  }
  
  if ($seq_name =~ /chr/) {
    $seq_name =~ s/chr//;
    $seq_name =~ s/H//;
    
    $seq_name = "HORVU" . $seq_name . "Hr1G000010.1";
  }
  
  print "<div class='anchor data-header' id='mtp_gbrowse'>Barley PseudoMolecules GBrowse</div><div class='data_body'><br><br>
  <a href='https://ics.hutton.ac.uk/cgi-bin/gb2/gbrowse/barley_mtp?name=$seq_name&h_feat=$seq_name&enable=barley50k%1EmRNA%1Ebarleyrtd&width=1300' target='_blank'>Click here to see more tracks within GBrowse --></a><br>
 <img class='img-fluid' src='https://ics.hutton.ac.uk/cgi-bin/gb2/gbrowse_img/barley_mtp?name=$seq_name&h_feat=$seq_name&type=barleyrtd+barley50k+mRNA&width=1300'><br>
 <b>Key - </b>grey: non-coding, <font color='green'>green: Barley Morex IBSC 2017 Transcript CDS</font>, <font color='red'>red: Barley RTD exons</font></div><br><br>\n";
  
}




sub drawTranscriptTable{
  
  my ($gene_name, $dataset) = @_;
  
  my %transcripts = %{$db_query->getTranscriptsByGene($gene_name, $dataset)};
  
  print "<div class='anchor data-header' id='summary'>Transcripts from Gene $gene_name</div>\n";
  
  print "<div class='data-body'>
        <table class='table-bordered' width='100%'><tbody><tr><th>Transcript</th><th>Length(bp)</th><th>Description</th></tr>\n";
  
  foreach my $number(sort {$a <=> $b} keys %transcripts){
    
    my($transcript_id, $seq_length, $description) = split(/\t/, $transcripts{$number}, 3);
    
    print "<tr><td><a href='transcript.cgi?seq_name=$transcript_id&dataset=$dataset'>$transcript_id</a></td><td>$seq_length</td><td>$description</td></tr>\n";
    
  }
  
  print "</tbody></table></div>\n";

}

sub drawTranscriptsGbrowse{
  
  my ($seq_name, $dataset, $title_on) = @_;  # title_on turns on the printing of the title bar or not
  
  my $track_id;
  
  if ($seq_name =~ /BART/) {
    
    $track_id = "barleyrtd";

    if(!($seq_name =~ /\./)) {
      $seq_name = $seq_name . ".001";
    }
    
  }
  
  if ($seq_name =~ /HORVU/) {
    
    $track_id = "mRNA";

    if(!($seq_name =~ /\./)){
      $seq_name = $seq_name . ".1";
    }

  }


  my($gene_name, $transcript_number) = split(/\./, $seq_name, 2);

  print "
            <div class='anchor data-header' id='alt_cds'>Exon Structure of $gene_name Transcripts</div>
            <div class='data-body'>
                <img class='img-fluid' src='https://ics.hutton.ac.uk/cgi-bin/gb2/gbrowse_img/barley_mtp?name=$seq_name&h_feat=$seq_name&type=$track_id&width=1300' border=1>
            </div>\n\n";

}



sub printSequence{
  
  my ($seq_name, $title, $seq, $dataset) = @_;
  
  my $length = length($seq);
  
  # Get the transcripts sequence details

print "<div class='anchor data-header' id='seq'>$title Sequence ($length bp)</div><div class='data-body'>\n";


my @outarray = split(//, $seq);


print "<pre>\>$seq_name $length $dataset\n";
my $z = 0;
until ($z == @outarray) {
  print ("$outarray[$z]"); #print newarray into sequence file
  if ((($z+1)%60) == 0) {      #with a newline every 50 bases
    print ("\n");          #so that pressdb can compress it
  }
  $z++;
}
  
print "</pre>\n</div>\n";
  

}

sub printProteinSequence{
  
  my ($seq_name, $dataset) = @_;
  
  # Get the transcripts sequence details
  
  my ($prot_length, $prot_seq) = $db_query->{'dbh'}-> selectrow_array("SELECT seq_length, seq_sequence FROM protein_sequences where protein_id = '$seq_name' and dataset_name = '$dataset'");
  
  if ($prot_length == "") {
    print "<div class='anchor data-header' id='protseq'>Protein Sequence</div><div class='data-body'>\n";
    print "There is no protein translation for this sequence in the database<br>";
  } else {

  print "<div class='anchor data-header' id='protseq'>Protein Sequence ($prot_length aa)</div><div class='data-body'>\n";




  my @outarray = split(//, $prot_seq);


  print "<pre>\>$seq_name $prot_length $dataset\n";
  my $z = 0;
  until ($z == @outarray) {
    print ("$outarray[$z]"); #print newarray into sequence file
    if ((($z+1)%60) == 0) {      #with a newline every 50 bases
      print ("\n");          #so that pressdb can compress it
    }
    $z++;
  }
  
  print "</pre>\n</div>\n";
  
  }
}

