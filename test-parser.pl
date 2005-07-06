#!/usr/local/bin/perl
use strict;
use lib '/usr/home/ehdonhon/lib';
use Regexp::Parser;
use Data::Dumper;

my $string = '(Foo|Bar)xxx?[abc]y(qx)';

my $parser = Regexp::Parser->new();

$parser->parse( $string );
#my $root = $parser->root;
#print Dumper( $root );

my $iter = $parser->walker;

while ( my( $node, $depth) = $iter->() ) {
    print "\n---------------------------------------------\n";
    print "Depth = $depth\n";
    print "Max D = ", $iter->( -depth ), "\n";
    print "Vis   = ", $node->visual, "\n";
    print "Fam   = ", $node->family, "\n";
    print "Type  = ", $node->type,   "\n";
    print "Raw   = ", $node->raw,    "\n";
}
