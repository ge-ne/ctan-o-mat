#!/usr/bin/perl -w
##-----------------------------------------------------------------------------
## This file is part of ctan-o-mat.
## This program is distributed under BSD-like license. See file LICENSE
##
## (c) 2016 Gerd Neugebauer
##
## Net: gene@gerd-neugebauer.de
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of a 3-clause BSD-like license as stated in the
## file LICENSE contained in this distribution.
##
## You should have received a copy of the LICENSE along with this
## program; if not, see the repository under http://***.
##
##-----------------------------------------------------------------------------

=head1 NAME

ctan-o-mat.pl - Upload a package to CTAN

=head1 SYNOPSIS

ctan-o-mat.pl [options] [<package>]

=head1 DESCRIPTION

This program can be used to automate the upload of a package to CTAN
(https://www.ctan.org). The description of the package is contained in
a configuration file.

=head1 CONFIGURATION

The default configuration is read from a file with the same name as
the current directory an the extension .cfg. This file name can be
overwritten on the command line.

...

=head1 OPTIONS

=over 4

=item -h

=item --help

Print this short summary about the usage and exit the program.

=item -n

=item --noaction

Do not perform the final upload. The package is validated and the
resulting messages are printed. 

=item -i

=item --init

Create an empty template for a configuration.

=item -v

=item --verbose

Print some more information during the processing (verbose mode).

=item --validate

Print some additional debugging information.

=item <package>

This parameter is the name of a package configuration (see section
CONFIUGURATION) contained in a file.

=back

=head1 AUTHOR

Gerd Neugebauer

=head1 BUGS

=over 4

=item *

The program can not be used without a working connection to the
internet.

=back

=cut

use strict;
use FileHandle;
use File::Basename;
use Cwd;

use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common;

use constant PARAMETER_URL => "file:dev/ctan.cfg";

use constant UPLOAD_URL => "http://localhost:8080/submit/upload";
use constant VALIDATE_URL => "http://localhost:8080/submit/validate";

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

#------------------------------------------------------------------------------
# Variable:	$validate
# Description:	The validation indicator.
#
my $validate = 0;

my $debug = 0;

#------------------------------------------------------------------------------
# Variable:	$config
# Description:	The name of the configuration file.
#
my $config = undef;

#------------------------------------------------------------------------------
# Variable:	$upload
# Description:
#
my $upload = 1;

#------------------------------------------------------------------------------
# Variable:	%parameter
# Description:
#
my %parameter = ();

use Getopt::Long;
GetOptions(
	"config=s"  => \$config,
	"pkg=s"     => \$config,
	"package=s" => \$config,
	"debug"     => \$debug,
	"h|help"    => \&usage,
	"init"      => \&init,
	"noaction"  => sub { $upload = undef; },
	"v|verbose" => \$verbose,
	"validate"  => \$validate,
);

upload( $ARGV[0] );
print "\n";

#------------------------------------------------------------------------------
# Function:	upload
# Arguments:	none
# Description:
#
sub upload {
	my $f = shift;

	print STDERR "Uploading to CTAN..." if $verbose;
	my $service_url = UPLOAD_URL;
	$service_url = VALIDATE_URL if $validate;
	my $ua      = LWP::UserAgent->new();
	my $request = POST $service_url,
	  Content_Type => 'multipart/form-data',
	  Content      => [
		name        => 'Gerd Neugebauer',
		email       => 'gene@gerd-neugebauer.de',
		author      => 'x',
		uploader    => 'x',
		description => 'x',
		pkg         => 'bibtool',
		version     => '1.2.3',
		update      => 'true',
		note        => 'x',
		license     => 'gpl',
		license     => 'lppl',
		file        => [$f]
	  ];
	println STDERR "done" if $verbose;
	my $response = $ua->request($request);

	die format_errors( $response->decoded_content, $response->status_line ),
	  "\n"
	  if not $response->is_success;

	my @a = split /\n/, $response->decoded_content;

	print @a;
}

#------------------------------------------------------------------------------
# Function:	format_errors
# Arguments:
#	$json		the JSON list with the messages
#   $fallback	the fallback message if the first parameter is empty
# Description:
#
sub format_errors {
	local $_ = shift;
	if ( $_ eq '' ) {
		return shift;
	}
	s/^\[*\"//g;
	s/\]$//g;
	my @a = map {
		s/^ERROR\",\"/*** ERROR: /g;
		s/^WARNING\",\"/+++ WARNING: /g;
		s/^INFO\",\"/--- INFO: /g;
		s/\",\"/ /g;
		s/\"\]$//g;
		$_
	} split /\"\],\[\"/;
	return join( "\n", @a );
}

#------------------------------------------------------------------------------
# Local Variables:
# mode: perl
# End:
