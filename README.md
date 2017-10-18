# ctan-o-mat

Scripted upload of a package to CTAN

## NAME

ctan-o-mat.pl - Upload or validate a package for CTAN

## SYNOPSIS

```
ctan-o-mat.pl [options] [<package configuration>]
```

## DESCRIPTION

This program can be used to automate the upload of a package to CTAN
(https://www.ctan.org). The description of the package is contained in
a configuration file.

The provided information is validated in any case. If the validation
succeeds and not only the validation is requested then the provided
archive file is placed in the incoming area of the CTAN.

In any case any finding during the validation is reported at the end
of the processing.

ctan-o-mat requires an internet connection to the CTAN server. Even the
validation retrieves the known attributes and the basic constraints
from the server.


## CONFIGURATION

The default configuration is read from a file with the same name as
the current directory an the extension .cfg. This file name can be
overwritten on the command line.

The configuration depends on the features supported by the CTAN server.
Since these features can change over time the configuration is not
hard-coded in ctan-o-mat. You can request a template of the
configuration via the command line parameter *-init*.


## OPTIONS

<dl>
  <dt><code>-h</code></dt>
  <dt><code>--help</code></dt>
  <dd>
    Print this short summary about the usage and exit the program.
  </dd>

  <dt><code>--validate</code></dt>
  <dt><code>-n</code></dt>
  <dt><code>--noaction</code></dt>
  <dd>
    Do not perform the final upload. The package is validated and the
    resulting messages are printed.
  </dd> 

  <dt><code>-i</code></dt>
  <dt><code>--init</code></dt>
  <dd>
    Create an empty template for a configuration.
  </dd>
  
  <dt><code>-v</code></dt>
  <dt><code>--verbose</code></dt>
  <dd>
    Print some more information during the processing (verbose mode).
  </dd>

  <dt><code>--validate</code></dt>
  <dd>
    Print some additional debugging information.
  </dd>

  <dt>&lt;package&gt;</dt>
  <dd>
    This parameter is the name of a package configuration (see section
    CONFIUGURATION) contained in a file.
  </dd>
</dl>

## AUTHOR

[Gerd Neugebauer](mailto:gene@gerd-neugebauer.de)

