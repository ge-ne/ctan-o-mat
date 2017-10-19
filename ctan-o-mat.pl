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

=head1 NAME

ctan-o-mat - Upload or validate a package for CTAN

=head1 SYNOPSIS

ctan-o-mat [options] [<package configuration>]

=head1 DESCRIPTION

This program can be used to automate the upload of a package to CTAN
(https://www.ctan.org). The description of the package is contained in
a configuration file.

The provided information is validated in any case. If the validation
succeeds and not only the validation is requested then the provided
archive file is placed in the incoming area of the CTAN.

In any case any finding during the validation is reported at the end
of the processing.

B<ctan-o-mat> requires an internet connection to the CTAN server. Even the
validation retrieves the known attributes and the basic constraints
from the server.


=head1 CONFIGURATION

The default configuration is read from a file with the same name as
the current directory an the extension .cfg. This file name can be
overwritten on the command line.

The configuration depends on the features supported by the CTAN server.
Since these features can change over time the configuration is not
hard-coded in B<ctan-o-mat>. You can request a template of the
configuration via the command line parameter C<-init>.


=head1 OPTIONS

=over 4

=item -h

=item --help

Print this short summary about the usage and exit the program.

=item --validate

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

=head1 CONNECTING VIA PROXIES

If you need to connect to the Internet via a proxy then this can be achieved
by setting some environment variables before running B<ctan-o-mat>.
To redirect the request via the proxy simply define an environment variable
C<http_proxy> to point to the proxy host -- including protocol and port as
required. Note that the name of the environment variable is supposed to be in
B<lower> case.


=head1 AUTHOR

Gerd Neugebauer (gene@gerd-neugebauer.de)

=head1 BUGS

=over 4

=item *

The program can not be used without a working connection to the
Internet.

=back

=cut

use strict;
use FileHandle;
use File::Basename;
use Cwd;

use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common;

use constant PARAMETER_URL => 'file:dev/ctan.cfg';

use constant CTAN_URL => 'http://localhost:8080/submit/';

use constant UPLOAD_URL   => CTAN_URL . 'upload';
use constant VALIDATE_URL => CTAN_URL . 'validate';
use constant FIELDS_URL   => CTAN_URL . 'fields';

use constant NEW_CONFIG => 0;
use constant UPLOAD     => 1;
use constant VALIDATE   => 2;

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
# Variable:	$method
# Description:	The validation indicator.
#
my $method = UPLOAD;

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
# Variable:	@fields
# Description:
#
my %fields = ();

#------------------------------------------------------------------------------
# Variable:	%parameter
# Description:
#
my %parameter = ();

use Getopt::Long;
GetOptions(
	"config=s"   => \$config,
	"pkg=s"      => \$config,
	"package=s"  => \$config,
	"debug"      => \$debug,
	"h|help"     => \&usage,
	"init"       => sub { $method = NEW_CONFIG },
	"n|noaction" => sub { $upload = undef; },
	"v|verbose"  => \$verbose,
	"validate"   => sub { $method = VALIDATE },
);

$config = $ARGV[0] if defined $ARGV[0];
if ( not defined $config ) {
	$config = cwd();
	$config =~ s|.*[/\\]||;
	$config = $config . '.cfg';
}

fields();

if ( $method == NEW_CONFIG ) {
	new_config();
}
else {
	upload( read_config() );
}

#------------------------------------------------------------------------------
# Function:	upload
# Arguments:	none
# Description:
#
sub upload {
	my $f = shift;

	print STDERR "Uploading to CTAN..." if $verbose;
	my $service_url = UPLOAD_URL;
	$service_url = VALIDATE_URL if $method == VALIDATE;
	my $ua      = LWP::UserAgent->new();
	my $request = POST $service_url,
	  Content_Type => 'multipart/form-data',
	  Content      => $f;
	print STDERR "done\n" if $verbose;
	my $response = $ua->request($request);

	die format_errors( $response->decoded_content, $response->status_line ),
	  "\n"
	  if not $response->is_success;

	if ( $method == VALIDATE and $response->decoded_content eq '[]' ) {
		print "ok\n";
	}
	else {
		print format_errors( $response->decoded_content, 'ok' ), "\n"
	}
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
# Function:	fields
# Arguments:	none
# Description:
#
sub fields {
	print STDERR "Retrieving fields from CTAN..." if $verbose;
	print STDERR FIELDS_URL if $debug;
	my $response;
	eval {
		my $ua      = LWP::UserAgent->new();
		my $request = GET FIELDS_URL;
		print STDERR "done\n" if $verbose;
		$response = $ua->request($request);
	};

	die format_errors( $response->decoded_content, $response->status_line ),
	  "\n"
	  if not $response->is_success;

	local $_ = $response->decoded_content;
	print STDERR $response->decoded_content, "\n\n" if $debug;
	while (m/\"([a-z0-9]+)\":\{([^{}]*)\}/i) {
		my $f = $1;
		my %a = ();
		$_ = $';
		my $attr = $2;
		while ( $attr =~ m/\"([a-z0-9]+)\":([a-z0-9]+|"[^"]*")/i ) {
			$attr = $';
			$a{$1} = $2;
			$a{$1} =~ s/(^"|"$)//g;
		}
		$fields{$f} = \%a;
	}
}

#------------------------------------------------------------------------------
# Function:	read_config
# Arguments:
# Description:
#
sub read_config {
	my %cfg = ();
	my $fd  = new FileHandle($config)
	  || die "*** Configuration file `$config' could not be read.\n";
	my $slurp = undef;
	local $_;

	while (<$fd>) {
		s/^[ \t]*%.*//;
		s/([^\\])%.*/$1/;
		while (m/\\([a-z]+)/i) {
			$_ = $';
			if ( $1 eq 'begin' ) {
				die "$config: missing {environment} instead of $_\n"
				  if not m/^[ \t]*\{([a-z]*)\}/i;
				my $tag = $1;
				my $val = '';
				$_ = $';
				while ( not m/\\end\{$tag\}/ ) {
					$val .= $_;
					$_ = <$fd>;
					die "$config: unexpected end of file while searching end of $tag\n"
					  if not defined $_;
				}
				$val .= $`;
				$val =~ s/^[ \t\n\r]*//m;
				$val =~ s/[ \t\n\r]*$//m;
				$cfg{$tag} = $val;
				$_ = $';
			}
			elsif ( $1 eq 'endinput' ) {
				last;
			}
			elsif ( defined $fields{$1} ) {
				my $key = $1;
				die "$config: missing {environment} instead of $_\n"
				  if not m/^[ \t]*\{([^{}]*)\}/i;

				if ( $key eq 'file' ) {
					$cfg{$key} = [$1];
				}
				else { $cfg{$key} = $1; }
				$_ = $';
			}
			else {
				die "$config: undefined keyword $&\n";
			}
			s/^[ \t]*%.*//;
		}
	}
	$fd->close();
	return \%cfg;
}

#------------------------------------------------------------------------------
# Function:	new_config
# Arguments:	none
# Description:
#
sub new_config {

	print <<__EOF__;
% This is a description file for ctan-o-mat.
% It manages uploads of a package to 
% CTAN -- the Comprehensive TeX Archive Network.
%
% The syntax is roughly oriented towards (La)TeX.
% Two form of the macros are used. The simple macros take one argument
% in braces. Here the argument may not contain embedded macros.
%
% The second form uses an environment enclosed in \\begin{}/\\end{}.
% In the long text fields logo macros can be used.
%
% You should enter your values between the begin and the end of the
% named type.
__EOF__
	local $_;
	foreach ( keys(%fields) ) {
		print <<__EOF__;
% -------------------------------------------------------------------------
% This field contains the $fields{$_}->{'text'}.
__EOF__
		if ( defined $fields{$_}->{'nullable'} ) {
			print "% The value is optional.\n";
		}
		if ( defined $fields{$_}->{'url'} ) {
			print "% The value is a URL.\n";
		}
		if ( defined $fields{$_}->{'email'} ) {
			print "% The value is an email address.\n";
		}
		if ( defined $fields{$_}->{'file'} ) {
			print
			  "% The value is the file name of the archive to be uploaded.\n";
			print "% It may have a relative or absolute directory.\n";
		}
		if ( defined $fields{$_}->{'maxsize'} ) {
			print "% The value is restricted to $fields{$_}->{'maxsize'} characters.\n";
		}
		if ( defined $fields{$_}->{'list'} ) {
			print "% Multiple values are allowed.\n\\$_\{}\n";
		}
		elsif ( $fields{$_}->{'maxsize'} ne 'null'
			and $fields{$_}->{'maxsize'} < 256 )
		{
			print "\\$_\{}\n";
		}
		else {
			print "\\begin{$_}\\end{$_}\n";
		}
	}
}

#------------------------------------------------------------------------------
# Local Variables:
# mode: perl
# End:
