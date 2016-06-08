#******************************************************************************
#* Author: Gerd Neugebauer
#*=============================================================================

FILES = ctan-o-map	\
	ctan-o-mat.bat	\
	ctan-o-mat.pl	\
	LICENSE		\
	README.md	\
	makefile

all:

clean: 
	$(RM) -f *~

dist ctan-o-mat.zip:
	$(RM) ctan-o-mat.zip
	(cd ..; zip ctan-o-mat/ctan-o-mat.zip $(addprefix ctan-o-mat/,$(FILES)))

#
