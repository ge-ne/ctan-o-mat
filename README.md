# ctan-o-mat - Upload or validate a package for CTAN

## SYNOPSIS

```
ctan-o-mat [options] [<package configuration>]
```

## DESCRIPTION

This program can be used to automate the upload of a package to the
TeX Archive Network (https://www.ctan.org). The description of the
package is contained in a configuration file. Thus it can be updated
easily without the need to fill a Web form with the same old
information again and again.

The provided information is validated in any case. If the validation
succeeds and not only the validation is requested then the provided
archive file is placed in the incoming area of the CTAN for further
processing by the CTAN team.

In any case any finding during the validation is reported at the end
of the processing. Note that the validation is the default and a
official submission has to be requested by the an appropriate command
line option.

*ctan-o-mat* requires an Internet connection to the CTAN server. Even the
validation retrieves the known attributes and the basic constraints
from the server.


## CONFIGURATION

The default configuration is read from a file with the same name as
the current directory an the extension `.pkg`. This file name can be
overwritten on the command line.

The configuration depends on the features supported by the CTAN server.
Since these features can change over time the configuration is not
hard-coded in *ctan-o-mat*. You can request a template of the
configuration via the command line parameter `-init`.


## OPTIONS

<dl>
  <dt><code>-h</code></dt>
  <dt><code>--help</code></dt>
  <dd>
    Print this short summary about the usage and exit the program.
  </dd>

  <dt><code>--validate</code></dt>
  <dd>
    Do not perform the final upload. The package is validated and the
    resulting messages are printed.
  </dd> 

  <dt><code>--init</code></dt>
  <dd>
    Create an empty template for a configuration.
  </dd>
  
  <dt><code>--submit</code></dt>
  <dd>
    Upload the submission, validate it and officially submit it to
    CTAN it the validation succeeds.
  </dd>
  
  <dt><code>-v</code></dt>
  <dt><code>--verbose</code></dt>
  <dd>
    Print some more information during the processing (verbose mode).
  </dd>

  <dt><code>--version</code></dt>
  <dd>
    Print the version number of this program and exit.
  </dd>

  <dt><code>--validate</code></dt>
  <dd>
    Print some additional debugging information.
  </dd>

  <dt><code>&lt;package&gt;</code></dt>
  <dd>
    This parameter is the name of a package configuration
    (see section CONFIGURATION) contained in a file.
  </dd>
</dl>

## CONNECTING VIA PROXIES

If you need to connect to the Internet via a proxy then this can be achieved
by setting some environment variables before running *ctan-o-mat*.
To redirect the request via the proxy simply define an environment variable
`http_proxy` to point to the proxy host -- including protocol and port as
required. Note that the name of the environment variable is supposed to be in *lower* case.


## INSTALLATION

### PREREQUISITE: PERL

*ctan-o-mat* is written in Perl. Thus a Perl interpreter has to be installed,
at least in version 5. It is assumed that the Perl interpreter is reachable
under the name `perl` on the program path.


### PREREQUISITE: LWP

*ctan-o-mat* uses the LWP bundle to connect to the remote server and such.
Thus it has to be installed. With the help of Perl you can install it with
the following command line: 

```
perl -MCPAN -e 'install Bundle::LWP'
```

You might want to check whether LWP can be installed with your package manager. In this case this is the preferred way.

### INSTALLATION STEPS

The installation is straight forward. Just put the file `ctan-o-mat.pl` and one of `ctan-o-mat` or `ctan-o-mat.bat` on your path.

Make sure that these files are executable (if required). Now you are done.


## AUTHOR

[Gerd Neugebauer](mailto:gene@gerd-neugebauer.de)

