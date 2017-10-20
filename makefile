#******************************************************************************
#* (c) 2017 Gerd Neugebauer
#*=============================================================================

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

all:

clean: 
	$(RM) -f *~ *.out *.log *.aux ctan-o-mat.ltx

ctan-o-mat.pdf: README.md makefile lib/md2ltx.pl
	@perl lib/md2ltx.pl --version "$(VERSION)" README.md > ctan-o-mat.ltx
	@xelatex -interaction=batchmode ctan-o-mat.ltx > /dev/null
	@xelatex -interaction=batchmode ctan-o-mat.ltx
	@$(RM) ctan-o-mat.out ctan-o-mat.aux ctan-o-mat.log

dist ctan-o-mat.zip: $(FILES)
	$(RM) ctan-o-mat.zip
	(cd ..; zip ctan-o-mat/ctan-o-mat.zip $(addprefix ctan-o-mat/,$(FILES)))

#
