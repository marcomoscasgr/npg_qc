#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use npg_qc::mqc::outcomes::keys qw/ $SEQ_OUTCOMES $LIB_OUTCOMES/;
use npg_qc::Schema;
use npg_qc::mqc::outcomes;
use WTSI::DNAP::Warehouse::Schema;

my @id_runs = qw/
	51343
	51348
	51352
	51353
	51355
	51357
	51358
	51362
	51364
	51365
	51368
	51370
	51372
	51376
	51377
	51379
	51380
	51381
	51383
	51401
	51402
	51403
	51404
	51405
	51415
	51451
	51452
	51453
	51454
	51466
	51470
	51491
	51492
	51493
	51494
	51502
	51507
	51533
	51534
	51535
	51536
	51537
	51576
	51577
	51578
	51620
	51621
	51622
	51624
	51649
	51654
	51655
	51656
	51666
	51667
	51668
	51699
	51701
	51738
	51815
	51816
	51817
	51818
	51835
	51850
	51851
	51852
	51853
	51854
	51855
	51863
	51864
	51892
	51893/;
my $position = 1;
my $user = 'useq_pipeline';
my $outcome = q(Accepted final); # Must match the database dictionary value.
# End of inputs from the RT ticket.
my $manufacturer = 'Ultima Genomics';
my $mqcoutcometable = 'MqcOutcomeEnt';

for my $id_run (@id_runs) {
	print sprintf '%sConsidering outcomes for run %i position %i as user %s%s',
	qq[\n], $id_run, $position, $user, qq[\n];

	my $mlwh_schema = WTSI::DNAP::Warehouse::Schema->connect();
	my $rs = $mlwh_schema->resultset('UseqProductMetric')->search(
		{'me.id_run' => $id_run,
			'me.tag_index' => {'!=', 0},
			'me.is_sequencing_control' => 0},
		{order_by => 'me.tag_index',
			columns => 'tag_index' }
	);
	my @tag_indexes = map {$_->tag_index} $rs->all();

	print "NUMBER OF TAGS: " . @tag_indexes . qq[\n];
	print "MIN TAG " . $tag_indexes[0] . qq[\n];
	print "MAX TAG " . $tag_indexes[-1] . qq[\n];

	my $qc_schema = npg_qc::Schema->connect();
	my $outcomes = {};
	my $info = {};

	$rs = $qc_schema->resultset($mqcoutcometable)->search({'id_run'=>$id_run,'position'=>$position})->all();
	if ($rs) {
		print sprintf 'Records found in QC DB for run %i position %i. Record skipped.%s',
			$id_run, $position, qq[\n];
		next;
	}
	
	print sprintf 'Initializing run records for run %i position %i with outcome "%s"%s',
		$id_run, $position, $outcome, qq[\n];
	my $idrun_key= join q(:),$id_run,$position;
	$outcomes->{$SEQ_OUTCOMES}->{$idrun_key} = {mqc_outcome => $outcome};
	$info->{$idrun_key}=\@tag_indexes;

	print sprintf 'Initializing tag records for run %i position %i with outcome "%s"%s',
		$id_run, $position, $outcome, qq[\n];

	foreach my $tag_index (@tag_indexes) {
		my $key= join q(:),$id_run,$position,$tag_index;
		$outcomes->{$LIB_OUTCOMES}->{$key} = {mqc_outcome => $outcome};
	}

	my $o = npg_qc::mqc::outcomes->new(qc_schema => $qc_schema);
	my $saved;
	print sprintf 'Creating run and library outcome records for run %i position %i with outcome "%s"%s',
		$id_run, $position, $outcome, qq[\n];
	$qc_schema->txn_do( sub {
		$saved = $o->save($outcomes, $user, $info, $manufacturer);
	});

	if ($saved) {
		print Dumper $saved;
	}
}
