SHELL:=/bin/bash --rcfile bash-init.sh

EPOCH:=2020-04-06
TODAY:=$(shell date +"%Y-%m-%d")
YESTERDAY:=$(shell date --date "$(TODAY) -1 day" +"%Y-%m-%d")
ONEWEEK:=$(shell date --date "$(TODAY) -7 day" +"%Y-%m-%d")
THREEWEEK:=$(shell date --date "$(TODAY) -21 day" +"%Y-%m-%d")

MESSAGES:="messages/$(TODAY).messages"

PYTHON:=env/bin/python
QUALTRICS=$(shell $(PYTHON) -m delphi_utils get input_dir)
WEIGHTS=$(shell $(PYTHON) -m delphi_utils get weights_in_dir)
CIDS=$(shell $(PYTHON) -m delphi_utils get weights_out_dir)
INDIVIDUAL=$(shell $(PYTHON) -m delphi_utils get individual_dir)
INDIVIDUAL_RACEETH=$(shell $(PYTHON) -m delphi_utils get individual_raceeth_dir)
ARCHIVE=$(shell $(PYTHON) -m delphi_utils get archive_dir)
RECEIVING=$(shell $(PYTHON) -m delphi_utils get export_dir)
FB_CC=$(shell $(PYTHON) -m delphi_utils get qualtrics.notify-bad-weights)
DELPHI_SURVEY_SFTP_PASSWORD=$(shell $(PYTHON) -m delphi_utils get delphi_survey_sftp_password)
DELPHI_SURVEY_SFTP_USER=$(shell $(PYTHON) -m delphi_utils get delphi_survey_sftp_user)
DELPHI_SURVEY_EMAIL_USER=$(shell $(PYTHON) -m delphi_utils get delphi_survey_email_user)
SFTP_OPTIONS=$(shell $(PYTHON) -m delphi_utils get sftp_options)

MAX_WEIGHTED=ls -1 $(WEIGHTS) | grep dap | tail -1 | sed 's/_.*//;s/-//g;'

ANTIJOIN:="antijoin.cids.sorted.txt"
CIDS_DEST:="fb-interchange/cmu_respondent_ids"
INDIVID_DEST:="fb-public-results/"
INDIVID_RACEETH_DEST:="protected-race-ethnicity-data/"
RAW_DEST:="raw"

# dry-run mode: generate all files, but do not post them anywhere, and disable all emails to outside parties.
DRY:=yes
ifeq ($(DRY),yes)
	SFTP_POST:=echo -e "Would run: sshpass -p $(DELPHI_SURVEY_SFTP_PASSWORD) sftp $(SFTP_OPTIONS) -b <(echo -e \"\$${BATCH}\") -P 2222 $(DELPHI_SURVEY_SFTP_USER)\n$${BATCH}"
	DRY_MESSAGE:="[DRY-RUN] "
else
	SFTP_POST:=sshpass -p $(DELPHI_SURVEY_SFTP_PASSWORD) sftp $(SFTP_OPTIONS) -b <(echo -e "$${BATCH}") -P 2222 $(DELPHI_SURVEY_SFTP_USER)
endif

default:
	@echo No default implemented yet

scratch:
	mkdir scratch
	rm -rf scratch/*

tidy: receiving
	rm -rf tidy/$(RECEIVING)
	rm -rf tidy/$(INDIVIDUAL)
	rm -f tidy/params.json
	mkdir -p tidy tidy/$(RECEIVING) tidy/$(INDIVIDUAL)
	cp params.json tidy/
	mv $(RECEIVING)/*.csv tidy/$(RECEIVING)
	mv $(INDIVIDUAL)/*.csv* tidy/$(INDIVIDUAL)
	mv $(INDIVIDUAL_RACEETH)/*.csv* tidy/$(INDIVIDUAL_RACEETH)
	tar -czf scratch/tidy-`date +"%Y-%m-%d-%H%M%S"`.tgz --exclude='tidy-*.tgz' tidy
	mv scratch/*.tgz tidy/

clean:
	rm -f $(RECEIVING)/*.csv $(INDIVIDUAL)/*.csv $(INDIVIDUAL_RACEETH)/*.csv  $(CIDS)/*.csv

clean-archive:
	rm -f $(ARCHIVE)/*.Rds

install-python:
	python3.8 -m venv env
	source env/bin/activate && \
	pip install wheel && \
	pip install delphi_utils && \
	pip install -e delphiFacebook/python

install-R:dev

install: install-python install-R

$(CIDS):
	[ -f $(CIDS) ] || mkdir -p $(CIDS)

init-qualtrics:
	grep '"token": "..*"' params.json

$(TODAY):
	[ -f $(QUALTRICS) ] || mkdir -p $(QUALTRICS)
	rm -rf tmp
	touch -d "$(TODAY) 01:00" tmp
	$(PYTHON) -m delphi_utils set end_date $(YESTERDAY)
	source env/bin/activate && \
	python -m delphi_facebook
	BATCH=""; \
	for f in `find $(QUALTRICS) -maxdepth 1 -newer tmp -type f -name "*.csv"`; do \
	  BATCH="$${BATCH}put $$f $(RAW_DEST)\n"; \
	done; \
	$(SFTP_POST); \
	echo "SUCCESS: $(DRY_MESSAGE)Posted `echo -e $${BATCH} | wc -l` raw files" >> $(MESSAGES)
	touch -d $(YESTERDAY) params.json
	mv tmp $@

params.json: $(TODAY)
	PAT=`grep fb-survey params.json | awk 'BEGIN{FS="\""}{print $$2}' | sed 's/ /_/g;s/^/-e /'`; \
	$(PYTHON) -m delphi_utils set \
		debug false \
		produce_individual_raceeth true \
		end_date $(YESTERDAY) \
		input <(find $(QUALTRICS) -maxdepth 1 -newer $< -type f -name "*.csv" | sort | grep $${PAT}  | tr '\n' ',' | sed 's_$(QUALTRICS)/__g;s/,$$//' ) \
		parallel true \
		output cids,individual,covidalert,archive,community \
		start_date $(YESTERDAY)

$(WEIGHTS): $(TODAY)
	[ -f $(WEIGHTS) ] || mkdir -p $(WEIGHTS)
	cd "$(WEIGHTS)"; \
	BATCH="cd fb-interchange/cmu_respondent_weights\nls -1"; \
	NEW=`LC_ALL=C comm -23 <(sshpass -p $(DELPHI_SURVEY_SFTP_PASSWORD) sftp $(SFTP_OPTIONS) -b <(echo -e "$${BATCH}") -P 2222 $(DELPHI_SURVEY_SFTP_USER) | grep "^202" | LC_ALL=C sort) <(ls -1 | LC_ALL=C sort)`; \
	echo "New weights files:"; \
	echo $${NEW}; \
	for f in $${NEW}; do \
	  BATCH="$${BATCH}\nget $$f"; \
	done; \
	sshpass -p $(DELPHI_SURVEY_SFTP_PASSWORD) sftp $(SFTP_OPTIONS) -b <(echo -e "$${BATCH}") -P 2222 $(DELPHI_SURVEY_SFTP_USER) || exit 90; \
	cd -; \
	MAX_WEIGHTED=`$(MAX_WEIGHTED)`; \
	EXPECTED_MAX_WEIGHTED=`date --date='$(TODAY) -3 day' +'%Y%m%d'`; \
	if [[ $$EXPECTED_MAX_WEIGHTED -gt $$MAX_WEIGHTED ]]; then \
	  MSG="Expected most recent file: $$EXPECTED_MAX_WEIGHTED; Actual most recent file: $$MAX_WEIGHTED"; \
	  echo "WARNING: $${MSG}" >> $(MESSAGES); \
	fi

dev: delphiFacebook_1.0.tar.gz
	R CMD INSTALL delphiFacebook_1.0.tar.gz

lib:
	R -e 'roxygen2::roxygenise("delphiFacebook")'

run-R: $(CIDS)
	rm -rf tmp
	time Rscript run.R 2>&1 |tee tmp
	grep "run_facebook completed successfully" tmp
	grep "scheduled core" tmp ; \
	[ "$$?" -eq 1 ]

pipeline: scratch init-qualtrics params.json $(WEIGHTS) run-R post-cids post-individual post-individual-raceeth post-done tidy
	grep $(TODAY) params.json
	[ -f $(YESTERDAY) ] && rm $(YESTERDAY) || true
	touch $@
	echo "SUCCESS: $(DRY_MESSAGE)pipeline complete" >> $(MESSAGES)
	chmod o+w $(MESSAGES)

coverage:
	Rscript -e 'covr::package_coverage("delphiFacebook")'

# best we can do
lint: coverage

test: delphiFacebook_1.0.tar.gz
	if [ ! -f params.json ]; then cp params.json.template params.json; fi
	grep testthat params.json
	R CMD check --test-dir=unit-tests $<
	R CMD check --test-dir=integration-tests $<

delphiFacebook_1.0.tar.gz: $(wildcard delphiFacebook/R/*.R)
	R CMD build delphiFacebook

post-cids: $(TODAY) $(CIDS)
	rm -rf tmp
	touch $(ANTIJOIN)
	POST=`find $(CIDS) -maxdepth 1 -newer $(TODAY) -name "cvid_cids_*.csv"`; \
	[ -n "$${POST}" ]; \
	LC_ALL=C find $(CIDS) -maxdepth 1 -daystart -mtime +0 -name "cvid_cids*.csv" -exec sort -u -o ${ANTIJOIN} {} +; \
	BATCH=""; \
	for f in $${POST}; do \
	    LC_ALL=C comm -23 <(LC_ALL=C sort $$f) ${ANTIJOIN} >tmp; \
	    diff -q tmp $$f || mv $$f $$f.bak; \
	    mv tmp $$f; \
	    ncids=`wc -l $$f | awk '{print $$1}'`; \
	    if [[ $$ncids == "0" ]]; then \
		echo "ERROR: 0 CIDs reported for $$f"; \
		exit 73; \
	    fi; \
	    BATCH="$${BATCH}put $$f ${CIDS_DEST}\n"; \
	done; \
	$(SFTP_POST); \
	echo "SUCCESS: $(DRY_MESSAGE)Posted `echo $${POST} | wc -w` cid files" >> $(MESSAGES)
	touch $@

post-individual: $(TODAY) $(INDIVIDUAL)
	POST=`find $(INDIVIDUAL) -maxdepth 1 -newer $(TODAY) -name "cvid_responses_*.csv"`; \
	[ -n "$${POST}" ]; \
	BATCH=""; \
	for f in $${POST}; do \
	    (grep token $$f; [[ $$? -eq 1 ]]); \
	    gzip -f $$f; \
	    BATCH="$${BATCH}put $${f}.gz ${INDIVID_DEST}\n"; \
	done; \
	$(SFTP_POST); \
	echo "SUCCESS: $(DRY_MESSAGE)Posted `echo $${POST} | wc -w` microresponse files" >> $(MESSAGES)
	touch $@

post-individual-raceeth: $(TODAY) $(INDIVIDUAL_RACEETH)
	POST=`find $(INDIVIDUAL_RACEETH) -maxdepth 1 -newer $(TODAY) -name "cvid_responses_*.csv"`; \
	[ -n "$${POST}" ]; \
	BATCH=""; \
	for f in $${POST}; do \
	    (grep token $$f; [[ $$? -eq 1 ]]); \
	    gzip -f $$f; \
	    BATCH="$${BATCH}put $${f}.gz ${INDIVID_RACEETH_DEST}\n"; \
	done; \
	$(SFTP_POST); \
	echo "SUCCESS: $(DRY_MESSAGE)Posted `echo $${POST} | wc -w` race-ethnicity microresponse files" >> $(MESSAGES)
	touch $@

post-done: post-cids
	touch $(YESTERDAY).done
	BATCH="put $(YESTERDAY).done $(CIDS_DEST)\n"; \
	$(SFTP_POST)
	echo "SUCCESS: $(DRY_MESSAGE)Posted $(YESTERDAY).done" >> $(MESSAGES)

validate-covidcast:
	@echo validate-covidcast not yet implemented
