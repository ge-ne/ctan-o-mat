#!/usr/bin/perl -w
##-----------------------------------------------------------------------------
## This file is part of ctan-o-mat.
## This program is distributed under BSD-like license. See file LICENSE
## 
## (c) 2016-2017 Gerd Neugebauer
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

=item -v

=item --verbose

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
#use JSON qw( decode_json );
use HTTP::Request::Common;

use constant PARAMETER_URL => "file:dev/ctan.cfg";
#use constant UPLOAD_URL => "file:ctan.upload";
use constant UPLOAD_URL => "http://localhost:8080/submit/1.0/upload";

use constant API_VERSION => "1.0";

#------------------------------------------------------------------------------
# Function:	usage
# Arguments:	none	
# Returns:	nothing
# Description:	Print the POD to stderr and exit
#
sub usage
{ use Pod::Text;
  Pod::Text->new()->parse_from_filehandle(new FileHandle($0,'r'),\*STDERR);
  exit(0);
}

#------------------------------------------------------------------------------
# Variable:	$verbose
# Description:	The verbosity indicator.
#
my $verbose = 0;

#------------------------------------------------------------------------------
# Variable:	$debug
# Description:	The debug level.
#
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
my $upload = undef;

#------------------------------------------------------------------------------
# Variable:	$update
# Description:	
#
my $update = 'true';

#------------------------------------------------------------------------------
# Variable:	%parameter
# Description:	
#
my %parameter = ();

use Getopt::Long;
GetOptions("config=s"	=> \$config,
	   "pkg=s"	=> \$config,
	   "package=s"	=> \$config,
	   "debug"	=> \$debug,
	   "h|help"	=> \&usage,
	   "init"	=> \&init,
	   "new"	=> sub { $update = "false"; },
	   "update"	=> sub { $update = "true"; },
	   "noaction"	=> sub { $upload = undef; },
	   "v|verbose"	=> \$verbose,
	  );

retrieve_params();

foreach $_ (@ARGV) {
  die "Several configuration files are not supported: $_\n" if $config;
  $config = $_;
}
$config = basename(getcwd).'.pkg' if not defined $config;

my $cfg = read_config();
if (defined $update) {
  $cfg->{'update'} = $update;
}

exit(1) if validate_config($cfg) != 0;

if ($debug) {
  foreach $_ (keys $cfg) {
    print STDERR "$_ = $cfg->{$_}\n"; 
  }
}

upload() if $upload;


#------------------------------------------------------------------------------
# Function:	upload
# Arguments:	none
# Description:	
#
sub upload {

  print STDERR "Uploading to CTAN..." if $verbose;
  local $_;
  my $ua       = LWP::UserAgent->new();
  my $request  = POST UPLOAD_URL,
                 Content_Type => 'multipart/form-data',
		 Content => $cfg;
  my $response = $ua->request($request);

  die "\nError: ", $response->status_line, "\n" if not $response->is_success;

  my @a = split /\n/, $response->decoded_content;

  print @a;
}

#------------------------------------------------------------------------------
# Function:	retrieve_params
# Arguments:	
# Description:	
#
sub retrieve_params {

  print STDERR "Connecting to CTAN..." if $verbose;
  local $_;
  my $ua	     = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
  my $response	     = $ua->get(PARAMETER_URL);
  my $server_version = "";

  die "\nError ", $response->status_line, "\n"  if not $response->is_success;

  my @a = split /\n/, $response->decoded_content;
  foreach $_ (@a) {
    $server_version = $1 if m/^[ \t]*\#ctan-o-mat[ \t]+([0-9.]+)/;
    next if m/^[ \ŧ]*\#/;
    die "remote parameter definition could not be understood: $_\n"
	if not m/^([a-z0-9_]+) ([a-z]+)\(([0-9]+)\) ([0-9]+)(\.\.([0-9*]+))?$/i;
    $parameter{$1} = [$2, $3, $4, $6];
  }
  print STDERR "parameters received\n" if $verbose;

  die "The CTAN server expects version $server_version of the API.\n"
      . "This program supports only version " . API_VERSION . ".\n"
      . "Please consider to upgrade this program in order to use it properly.\n"
      . "\n"
      if $server_version ne API_VERSION;
}

#------------------------------------------------------------------------------
# Function:	validate_config
# Arguments:	
# Description:	
#
sub validate_config {
  my $cfg = shift;
  my $err = check_file($cfg, 'file');
  local $_;

  foreach $_ (keys %parameter) {
    $err += check($cfg, $_, $parameter{$_}[1], $parameter{$_}[2] == 0);
  }

  return $err;
}

#------------------------------------------------------------------------------
# Function:	check_file
# Arguments:	
# Description:	
#
sub check_file {
  my $cfg = shift;
  my $key = shift;
  my $ret = check($cfg, $key, 1024);
  if ($ret == 0) {
    if (not -e $cfg->{$key}) {
      print STDERR "*** File not found: $cfg->{$key}\n";
      return 1;
    }
    if (not -r $cfg->{$key}) {
      print STDERR "*** File not readable: $cfg->{$key}\n";
      return 1;
    }
  }
  return $ret;
}

#------------------------------------------------------------------------------
# Function:	check_in
# Arguments:	
# Description:	
#
sub check_in {
  my $cfg = shift;
  my $key = shift;
  my $val = $cfg->{$key};
  local $_;

  if (not defined $val) {
    print STDERR "*** Missing $key.\n";
    return 1;
  }
  $val = lc($val);
  foreach $_ (@_) {
    return 0 if $val eq lc($_);
  }
  print STDERR "*** Missing proper value for $key (".join(' ').").\n";
  return 1;
}

#------------------------------------------------------------------------------
# Function:	check
# Arguments:	
# Description:	
#
sub check {
  my ($cfg, $key, $len, $canBeEmpty) = @_;

  print $key, ' ',$cfg->{$key}, "\n" if $verbose;

  if (not defined $cfg->{$key}) {
    print STDERR "*** Missing $key.\n";
    return 1;
  }
  if (length($cfg->{$key}) > $len) {
    print STDERR "*** $key exceeds the allowed $len characters.\n";
    return 1;
  }
  if (not $canBeEmpty and length($cfg->{$key})	== 0) {
    print STDERR "*** $key has an empty value.\n";
    return 1;
  }
  return 0;
}

#------------------------------------------------------------------------------
# Function:	read_config
# Arguments:	
# Description:	
#
sub read_config {
  my %cfg = ();
  my $fd  = new FileHandle($config) ||
      die "*** File `$config' could not be read.\n";
  my $slurp = undef;
  local $_;

  while (<$fd>) {
    s/^[ \t]*%.*//;
    s/([^\\])%.*/$1/;
    while (m/\\([a-z]+)/i) {
      $_ = $';
      if ($1 eq 'begin') {
	die "$config: missing {environment} instead of $_\n"
	    if not m/^[ \t]*\{([a-z]*)\}/i;
	my $tag	= $1;
	my $val = '';
	$_ = $';
	while (not m/\\end\{$tag\}/) {
	  $val .= $_;
	  $_ = <$fd>;
	  die "$config: unexpected end of file while searching end of $tag\n"
	      if not defined $_;
	}
	$val .= $`;
	$val =~ s/^[ \t\n\r]*//m;
	$val =~ s/[ \t\n\r]*$//m;
	$cfg{$tag} = $val;
	$_	   = $';
      } elsif ($1 eq 'endinput') {
	last;
      } elsif (defined $parameter{$1}) {
	my $key = $1;
	die "$config: missing {environment} instead of $_\n"
	    if not m/^[ \t]*\{([^{}]*)\}/i;

	if ($key eq 'file') { $cfg{$key} = [$1];
	} else {	      $cfg{$key} = $1; }
	$_ = $';
      } else {
	die "$config: undefined keyword $&\n";
      }
      s/^[ \t]*%.*//;
    }
  }
  $fd->close();
  return \%cfg;
}

#------------------------------------------------------------------------------
# Function:	init
# Arguments:	
# Description:	
#
sub init {
  my $file = $config;
  $file = basename(getcwd).'.pkg' if not defined $config;

  die "*** The file $file already exists. Please remove it before restarting the command.\n" if not defined $file or -e $file;

  my $fd = new FileHandle($file,'w') || die "*** Failed to open $file.\n";
  print $fd <<__EOF__;
% This is a description file for ctan-o-mat.
% It manages uploads of a package to 
% CTAN -- the Comprehensive TeX Archive Network.
%
% The syntax is roughly oriented towards (La)TeX.
% Two form of the macros are used. The simple macros take one argument
% in braces. Here the argument may not contain embedded macros.
%
% The second form uses an environment enclosed in \\begin{}/\\end{}.
%
\\usepackage[1.0]{ctan-o-mat}
% 
% You should enter your values between the begin and the end of the
% named type.
% -------------------------------------------------------------------------
%
\\pkg{}
% -------------------------------------------------------------------------
%
% The name is the name of the package in the catalogue.
% It is usually shorter than 64 characters and consists of letters,
% digits or the following characters: _ - .
%
\\name{}
% -------------------------------------------------------------------------
%
% The version is a unique version number or version date for the package.
\\version{}
% -------------------------------------------------------------------------
%
\\license{}
% -------------------------------------------------------------------------
%
\\author{}
% -------------------------------------------------------------------------
%
\\uploader{}
% -------------------------------------------------------------------------
%
\\email{}
% -------------------------------------------------------------------------
%
\\home{}
% -------------------------------------------------------------------------
%
\\repository{}
% -------------------------------------------------------------------------
%
\\mailinglist{}
% -------------------------------------------------------------------------
%
\\bugtracker{}
% -------------------------------------------------------------------------
%
\\path{}
% -------------------------------------------------------------------------
%
\\file{}
% -------------------------------------------------------------------------
%
\\topic{}
% -------------------------------------------------------------------------
%
\\begin{summary}
\\end{summary}
% -------------------------------------------------------------------------
%
\\begin{announcement}
\\end{announcement}
% -------------------------------------------------------------------------
%
\\begin{note}
\\end{note}
% -------------------------------------------------------------------------
\endinput
__EOF__
  $fd->close();
  print STDERR "--- $file written.\n";
  exit(0);
}

#------------------------------------------------------------------------------
# Local Variables: 
# mode: perl
# End: 
