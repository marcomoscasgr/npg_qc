#!/usr/bin/env perl

use strict;
use warnings;
use npg_qc::Schema;

my @libraries = (
	{id_run=>51362,position=>1,tag_index=>158},
	{id_run=>51403,position=>1,tag_index=>158},
	{id_run=>51404,position=>1,tag_index=>158},
	{id_run=>51401,position=>1,tag_index=>158},
	{id_run=>51453,position=>1,tag_index=>158},
	{id_run=>51454,position=>1,tag_index=>158},
	{id_run=>51491,position=>1,tag_index=>89},
	{id_run=>51534,position=>1,tag_index=>89},
	{id_run=>51535,position=>1,tag_index=>89},
	{id_run=>51621,position=>1,tag_index=>186},
	{id_run=>51668,position=>1,tag_index=>186},
	{id_run=>51699,position=>1,tag_index=>186},
);

for my $library (@libraries){
	my $rs=npg_qc::Schema->connect()->resultset("MqcLibraryOutcomeEnt")
		->search_autoqc($library);
	print sprintf "Considering library: id_run: %s - position: %s - tag_index: %s%s",
		$library->{id_run}, $library->{position}, $library->{tag_index}, qq[\n];
	if ($rs->count == 1) {
		my $row = $rs->next;
		print sprintf "Current outcome: %s%s",
			$row->mqc_outcome->short_desc, qq[\n];
		$row->toggle_final_outcome($ENV{"USER"}, "RT#834648");
		print sprintf "New outcome: %s%s",
			$row->mqc_outcome->short_desc, qq[\n];
	} else {
		print "no result or multiple results in the MqcLibraryOutcomeEnt table";
	}
}
