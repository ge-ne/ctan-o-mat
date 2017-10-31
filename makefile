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

FILES = ctan-o-mat	\
	ctan-o-mat.bat	\
	ctan-o-mat.pl	\
	ctan-o-mat.pkg	\
	LICENSE		\
	README.md	\
	makefile	\
	ctan-o-mat.pdf	\
	lib/md2ltx.pl

VERSION = `ctan-o-mat --version`
LATEX   = xelatex

#------------------------------------------------------------------------------

all:

clean distclean:
	$(RM) -f *~ *.out *.log *.aux ctan-o-mat.ltx

pdf doc ctan-o-mat.pdf: README.md makefile lib/md2ltx.pl
	@perl lib/md2ltx.pl --version "$(VERSION)" README.md > ctan-o-mat.latex
	@$(LATEX) -interaction=batchmode ctan-o-mat.latex > /dev/null
	@$(LATEX) -interaction=batchmode ctan-o-mat.latex
	@$(RM) ctan-o-mat.out ctan-o-mat.aux ctan-o-mat.log ctan-o-mat.latex

dist ctan-o-mat.zip: $(FILES)
	$(RM) ctan-o-mat.zip
	(cd ..; zip ctan-o-mat/ctan-o-mat.zip $(addprefix ctan-o-mat/,$(FILES)))

#
