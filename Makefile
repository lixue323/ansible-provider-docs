SITELIB = $(shell python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")
FORMATTER=hacking/module_formatter.py
DUMPER=hacking/dump_playbook_attributes.py
ifeq ($(shell echo $(OS) | egrep -c 'Darwin|FreeBSD|OpenBSD|DragonFly'),1)
CPUS := $(shell sysctl hw.ncpu|awk '{print $2}')
else
CPUS := $(shell nproc)
endif

all: clean docs

docs: clean directives modules htmldocs
	-(cp *.ico htmlout/)
	-(cp *.jpg htmlout/)
	-(cp *.png htmlout/)

variables:
	(mkdir -p htmlout/)
	dot variables.dot -Tpng -o htmlout/variables.png

htmldocs: directives modules staticmin
	CPUS=$(CPUS) $(MAKE) -f Makefile.sphinx html

webdocs: htmldocs

clean:
	-rm -rf htmlout
	-rm -rf _build
	-rm -f .buildinfo
	-rm -f *.inv
	-rm -rf *.doctrees
	@echo "Cleaning up minified css files"
	find . -type f -name "*.min.css" -delete
	@echo "Cleaning up byte compiled python stuff"
	find . -regex ".*\.py[co]$$" -delete
	@echo "Cleaning up editor backup files"
	find . -type f \( -name "*~" -or -name "#*" \) -delete
	find . -type f \( -name "*.swp" \) -delete
	@echo "Cleaning up generated rst"
	-rm rst/list_of_*.rst
	-rm rst/*_by_category.rst
	-rm rst/*_module.rst

.PHONEY: docs clean

directives: $(FORMATTER) hacking/templates/rst.j2
	PYTHONPATH=lib $(DUMPER) --template-dir=hacking/templates --output-dir=rst/

modules: $(FORMATTER) hacking/templates/rst.j2
	PYTHONPATH=lib $(FORMATTER) -t rst --template-dir=hacking/templates --module-dir=lib/aliyun/modules -o rst/

staticmin:
	cat _themes/srtd/static/css/theme.css | sed -e 's/^[ 	]*//g; s/[ 	]*$$//g; s/\([:{;,]\) /\1/g; s/ {/{/g; s/\/\*.*\*\///g; /^$$/d' | sed -e :a -e '$$!N; s/\n\(.\)/\1/; ta' > _themes/sphinx_rtd_theme/static/css/theme.min.css
