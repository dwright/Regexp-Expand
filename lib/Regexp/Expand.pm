package Regexp::Expand;

use 5.008003;
use strict;
use warnings;
use Regexp::Parser;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Regexp::Expand ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    expand_regexp
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

our $RETAIN_PARENS = 0;


# Preloaded methods go here.

1;

=head1 NAME

Regexp::Expand - Removes branchpoints from regexes, returns a list of regexes.

=head1 SYNOPSIS

  use Regexp::Expand 'expand_regexp';

  my @expanded = expand_regexp( 'Hello (joe)?!' );
  # returns ( 'Hello (joe)!', 'Hello !' );

  blah blah blah

=head1 DESCRIPTION

This module is used to take a regular expression, and expand it into a series
of regular expressions that are equivalent to the original when evaluated in
union.   It does this by creating a list of different regular expressions for
each possible path through a branchpoint.

Infinite lists are not expanded.

=head2 EXPORT

None by default.

=item C<expand_regexp>

This subroutine is passed a regular expression string and returns the list of
matching expanded regular expressions.

=cut 

sub expand_regexp {
    my $string = shift;

    my $parser = Regexp::Parser->new();
    $parser->parse( $string );

    my $root = $parser->root;

    return @{process_children(@$root)};
}


sub process_children {
    my @children = @_;
    my @paths;
    foreach my $node ( @children ) {
        @paths = cross_product( \@paths, build_list( $node ) );
    }
    return \@paths;
}

sub build_list {
    my $node = shift;

    my $t = $node->type;
    my $f = $node->family;

    return 
          $f eq 'exact' ? [$node->raw] 
          : $f eq 'open'  ? open_list( $node )
          : $f eq 'branch' ? branch_list( $node )
          : $f eq 'anyof' ? anyof_list ( $node )
          : $f eq 'anyof_char' ? [ $node->raw ]
          : $f eq 'quant' ? quant_list( $node )
          : unknown_list( $node );

}

sub unknown_list {
    my $node = shift;

    #print "Unknown node: ";
    #dump_node( $node );

    return [$node->visual];
}

sub open_list {
    my $node = shift;

    my @children = @{$node->data};

    my $paths = process_children( @children );

    return $RETAIN_PARENS ? [ map { '(' . $_ . ')' } @$paths ]
           : $paths;
}

sub branch_list {
    my $node = shift;

    my @children;
    @children = @{$node->data};

    my @paths;
    foreach my $nodes ( @children ) {
        push ( @paths, @{process_children(@$nodes)} );
    }

    return \@paths;
}

sub anyof_list {
    my $node = shift;

    my @children;
    @children = @{$node->data};
    #$node->walk( \@children );

    my @paths;
    foreach my $node ( @children ) {
        push ( @paths, @{build_list($node)} );
    }

    return \@paths;
}

sub quant_list {
    my $node = shift;

    my @children;
    @children = $node->data;

    my @child_paths = @{process_children( @children )};

    if ( $node->raw eq '?' ) {
        return [ '', @child_paths ];
    }

    if ( $node->raw =~ /\{(\d+),(\d+)\}/ ) {
        my ($top, $bottom) = ( $1, $2 );
        my @paths;
        foreach my $iter ( $top .. $bottom ) {
            foreach my $child_path ( @child_paths ) {
                push @paths, $child_path x $iter;
            }
        }
        return \@paths;
    }

    # No way to simplify *
    return [ $node->visual ];
}


sub cross_product {
    my ($first, $second) = @_;

    if ( ! @$first ) {
        return @$second;
    }
    if ( ! @$second ) {
        return @$first;
    }
    
    my @product;
    foreach my $fist_item( @$first ) {
        push @product, map{ $fist_item . $_ } @$second;
    }

    return @product;
}

sub dump_node {
    my $node = shift;
    print ref($node), "\n";
    print "\n---------------------------------------------\n";
#    print "Depth = $depth\n";
#    print "Max D = ", $iter->( -depth ), "\n";
    print "Vis   = ", $node->visual, "\n";
    print "Fam   = ", $node->family, "\n";
    print "Type  = ", $node->type,   "\n";
    print "Raw   = ", $node->raw,    "\n";
}


=head1 SEE ALSO

L<Regexp::Parser>

=head1 AUTHOR

Daniel Wright, E<lt>dwright@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Daniel Wright

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
