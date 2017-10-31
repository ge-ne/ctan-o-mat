#!/usr/bin/perl -w
##-----------------------------------------------------------------------------
## This file is part of ctan-o-mat.
## This program is distributed under BSD-like license. See file LICENSE
##
## (c) 2016-2017 Gerd Neugebauer
##
## Net: gene@gerd-neugebauer.de
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of a 3-clause BSD-like license as stated in the file
## LICENSE contained in this distribution.
##
## You should have received a copy of the LICENSE along with this program; if
## not, see the repository under https://github.com/ge-ne/ctan-o-mat.
##
##-----------------------------------------------------------------------------

use strict;

use constant MODE_NORMAL => 0;
use constant MODE_PRE => 1;
use constant MODE_AUTHOR => 10;

#------------------------------------------------------------------------------
# Function:	usage
# Arguments:	none
# Returns:	nothing
# Description:	Print the POD to stderr and exit
#
sub usage {
	use Pod::Text;
	Pod::Text->new()
	  ->parse_from_filehandle( new FileHandle( $0, 'r' ), \*STDERR );
	exit(0);
}

#------------------------------------------------------------------------------
# Variable:	$verbose
# Description:	The verbosity indicator.
#
my $verbose = 0;

my $version = '';

use Getopt::Long;
GetOptions(
	"h|help"     => \&usage,
	"version=s"  => \$version,
	"v|verbose"  => \$verbose,
);

my $mode = MODE_NORMAL;
my $body = '';
my $author = '';
my $title = '';

while(<>) {
	if (m/## AUTHOR/) {
		$mode = MODE_AUTHOR;
		next;
	}
	if ($mode == MODE_AUTHOR) {
		
		if (m/^##/) {
			$mode = MODE_NORMAL;
		} else {
			$author .= $_;
			next;
		}
	}
	next if m|</dd>|;
	if (m/^```/) {
		if ($mode == MODE_NORMAL) {
			$mode = MODE_PRE;
			$body .= "\\begin{verbatim}\n";
		} else {
			$mode = MODE_NORMAL;
			$body .= "\\end{verbatim}\n";
		}
		next
	}
	if ($mode == MODE_PRE) {
		$body .= $_;
		next;
	}
	$_ = "\\subsection*{".ucfirst(lc($1))."}\\label{$1}" if m/^### (.*)/;
	$_ = "\\section*{".ucfirst(lc($1))."}\\label{$1}" if m/^## (.*)/;
	if (m/^# (.*)/) {
		$title = $1;
		$title =~ s/--/\\\\/;
		next;
	}
	$_ = "$`see section~\\ref{$1}$'" if m/see section ([a-z0-9]*)/i;
	while (m/`([^`]+)`/) {
		$_ = "$`\\texttt{$1}$'";
	}
	while (m/\*([^*]+)\*/) {
		$_ = "$`\\textbf{$1}$'";
	}
	s/<dl>/\\begin{description}/;
	s/<\/dl>/\\end{description}/;
	s/<code>(.*)<\/code>/\\texttt{$1}/;
	s/<dt>/\\item[/;
	s/<\/dt>/]/;
	s/<dd>/\\ \\\\/;
	s/ - / -- /;
	s/TeX /\\TeX{} /;
	s/(&gt;|>)/\$>\$/;
	s/(&lt;|<)/\$<\$/;
	s/_/\\_/g;
	s|https?://[.a-z\/]*|\\url{$&}|;
	s|mailto:([\@a-z-]*)|\\href{$&}{$1}|;
	$body .= $_;
}

my $author_long = '';
my $subject = '';
if ($title =~ m/ +-+ +/) {
	$title = $`;
	$subject = $';
}
if ($author =~ m/\[([a-z0-9.,:; ]*)\]\(mailto:([^()]*)\)/i) {
	$author = $1;
	$author_long = "$1 (\\href{mailto:$2}{$2})";
} elsif ($author =~ m/\[([a-z0-9.,:; ]*)\]\(([^()]*)\)/i) {
	$author = $1;
	$author_long = "$1 ($2)";
}


print <<__EOF__;
\\documentclass[a4paper,12pt]{scrartcl}
\\usepackage[colorlinks=true,urlcolor=blue]{hyperref}
\\date{}
\\hypersetup{
    pdfinfo={
        Title={$title},
        Subject={$subject},
        Author={$author}
    }
}

\\author{$author_long}
\\title{$title\\thanks{This document describes \\textbf{$title} version $version}}
\\subtitle{$subject}
\\begin{document}
\\maketitle

$body
\\end{document}
__EOF__

#------------------------------------------------------------------------------
# Local Variables:
# mode: perl
# End:
