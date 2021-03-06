indexer                   = backend/indexer.py
website_screen_css        = website/static/css/screen.css
website_source_screen_css = website/static/css/screen/*.css
global_screen_css         = global/static/css/screen.css
global_source_screen_css  = global/static/css/screen/*.css
PYTHON                   ?= ./ENV/bin/python

# Dev Django runserver variables
dev_webserver_ip         ?= 0.0.0.0
dev_webserver_port       ?= 8000
dev_global_port          ?= 8001

all: reindex productioncss s3assets statsporn

dirty: copyxapian productioncss s3assets copy_statsporn

reindex: $(indexer)
	rm -rf xappydb
	$(PYTHON) -m backend.indexer

# backwards compatibility
build_statsporn: statsporn

statsporn:
	$(PYTHON) -m backend.stats_porn

copy_statsporn:
	$(foreach d, $(wildcard ../current/missions/*/images/stats), cp -a $d `echo $d | sed 's#../current/##'`;)

productioncss:	$(website_screen_css) $(global_screen_css)

# only use this in production, it'll explode entertainingly otherwhere
copyxapian:
	cp -a ../current/xappydb xappydb

$(website_screen_css): $(website_source_screen_css)
	cssprepare --optimise --extended-syntax \
		$(website_source_screen_css) > $(website_screen_css)

$(global_screen_css): $(global_source_screen_css)
	cssprepare --optimise --extended-syntax \
		$(global_source_screen_css) > $(global_screen_css)

devserver:
	$(PYTHON) -m website.manage runserver $(dev_webserver_ip):$(dev_webserver_port)

devcss:
	cssprepare --optimise --extended-syntax \
		--pipe $(website_screen_css) $(website_source_screen_css)

devserver_global:
	$(PYTHON) -m global.manage runserver $(dev_webserver_ip):$(dev_global_port)

devcss_global:
	cssprepare --optimise --extended-syntax \
		--pipe $(global_screen_css) $(global_source_screen_css)

thumbnails:
	cd website/static/img/missions/a13/; $(PYTHON) resize.py

# Rather than continually downloading off S3, it's not a bad idea to
# pull the original-images.tar somewhere common. We choose two levels
# up since in deployment that is above the level of the `releases`
# directory, so feels about right.
s3assets:
ifeq ($(wildcard ../../original-images.tar), ../../original-images.tar)
	ln -s ../../original-images.tar original-images.tar
else
	wget http://s3.amazonaws.com/spacelog/original-images.tar
endif
	tar xf original-images.tar
