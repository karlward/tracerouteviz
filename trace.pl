#!/usr/bin/env perl

use strict;
use warnings;
use Net::Traceroute;

my $index = 0;
my @nodes; 
my %node_index;
my @links; 

while(<>) {
  chomp;
  my ($host) = $_;
  #warn("looking up $host\n");
  my $tr = Net::Traceroute->new(host => $host); 
  if ($tr->found) {
    my $hops = $tr->hops;
    if($hops > 1) {
      my $skip = 0;
      for (my $i=1; $i< $tr->hops; $i++) {
        if ((defined($tr->hop_query_host($i, 0))) && ($tr->hop_query_host($i, 0) =~ /(\d+\.){3}\d+/)) {
          if (exists $node_index{$tr->hop_query_host($i, 0)}) {
          }
          else {
            #warn("first sight of ", $tr->hop_query_host($i, 0), "\n");
            $node_index{$tr->hop_query_host($i, 0)} = $index;
            push(@nodes, $tr->hop_query_host($i, 0));
            $index++;
          }
#          print $tr->hop_query_host($i, 0), "\n"; 
          if ($i > 1) {
            my %link;
            $link{source} = $node_index{$tr->hop_query_host($i - 1 - $skip, 0)};
            $link{target} = $node_index{$tr->hop_query_host($i, 0)};
            $link{value} = $node_index{$tr->hop_query_time($i, 0)};
            push(@links, \%link);
            if ($skip > 0) { $skip -= 1; }
          }
        }
        else { $skip++; }
      }
    }
  }
}

# make reverse hash
my %index_node;
foreach my $node (keys %node_index) {
  $index_node{$node_index{$node}} = $node;
}

# print the JSON, by hand, because it's the nineties 
print "{\n\"nodes\":[\n";
foreach my $n (@nodes) {
  my $lookup = `host $n`;
  if ((defined($lookup)) && ($lookup =~ /.+domain name pointer.+/)) {
    $lookup =~ s/.+name pointer (.+)$/$1/;
    chomp $lookup;
    print "    {\"name\":\"$lookup\",\"group\":1}";
  }
  else { 
    print "    {\"name\":\"$n\",\"group\":1}";
  }
  if ($n ne $nodes[-1]) { print ","; }
  print "\n";
}
print "  ],\n  \"links\":[\n";
foreach my $l (@links) {
  print "    {\"source\":$$l{source},\"target\":$$l{target},\"value\":1}";
  if ($l ne $links[-1]) { print ","; }
  print "\n";
}
print "  ]\n}\n";

