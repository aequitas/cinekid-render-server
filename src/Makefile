# Makefile intended to be run periodically to manage process pipeline.
# Invocation: make all

# It should not take long and only check things to be done, dispatch jobs and check for uncompleted/hanging jobs and remove jobs state to allow a retry on the next run

## configurable variables

# directory in which everything happens
BASE_DIR ?= /srv/cinekid
# user which own's files and processes
USER ?= cinekid
# delay, as 'find' arg, to build in before processing incoming samba files to avoid processing uploads in progress
# DELAY ?= -cmin +10

# directory numbers for days
days = 9 10 11 12 13 14 15 16 17 18

## internal variables

# limit rendering to number of cores
render_limit = $(shell cat /proc/cpuinfo | grep processor | wc -l)

converter = ./convert.sh
render_cmd = ffmpeg
test = /usr/bin/test

# dir where files are uploaded
samba_dir = $(BASE_DIR)/samba
# dir with files (symlinks) ready for processing
in_dir = $(BASE_DIR)/in
# dir where files will be rendered to
render_dir = $(BASE_DIR)/render
# dir with completed files, ready for sync to webserver
out_dir = $(BASE_DIR)/out
# tmpdir used for rendering
tmp_dir = $(BASE_DIR)/render_tmp

.PHONY: status process
all: bootstrap status process done

## processing pipeline

# determine files in samba dir which are ready for processing
samba_ready = $(subst $(samba_dir)/,,$(shell find $(samba_dir) -type f $(DELAY)))

lockfiles = $(shell find $(render_dir) -type f -name *.lock)
done_rendering = $(shell find $(render_dir) -type f -! -name *.lock)
rendering = $(subst .lock,,$(subst $(render_dir)/,,$(lockfiles)))
not_rendering = $(filter-out $(rendering),$(samba_ready))

done_files = $(subst $(out_dir)/,, $(shell find $(out_dir) -type f))
missing_files = $(filter-out $(done_files),$(samba_ready))

rendering_count = $(words $(rendering))
render_slots = $(shell echo $(render_limit) - $(rendering_count) | bc)

# get at most $render_slots files to render
to_render = $(wordlist 1,$(render_slots),$(not_rendering))

backlog = $(filter-out $(to_render) $(rendering),$(missing_files))

status:
	$(info samba files ready for processing ($(words $(samba_ready)))($(samba_dir)): $(samba_ready))
	$(info files needing to be processed ($(words $(missing_files)))($(samba_dir)): $(missing_files))
	$(info rendering ($(rendering_count))($(render_dir)): $(rendering))
	$(info done rendering ($(words $(done_rendering)))($(render_dir)): $(done_rendering))
	$(info render backlog ($(words $(backlog)))($(render_dir)): $(not_rendering))
	$(info cpus: $(render_limit), rendering: $(words $(rendering)), \
		free render slots: $(render_slots), render backlog: $(words $(backlog)))
	$(info going to start render on ($(render_dir)): $(to_render))

# start processing tasks
render_targets = $(addsuffix .lock,$(addprefix $(render_dir)/,$(to_render)))
process: $(render_targets)
$(render_targets): $(render_dir)/%.lock: $(samba_dir)/%
	$(converter) $< $@ & echo $$! > $@.lock

# cleanup done processing tasks
done_targets = $(shell)
done: $(done_targets)
$(done_targets): $(render_dir)/%: $(render_dir)/%.lock
	rm $<

## cleanup and bootstrapping

# create all required directories
dirs = $(samba_dir) $(in_dir) $(out_dir) $(render_dir) $(tmp_dir) \
	$(foreach day,$(days),$(samba_dir)/$(day)) \
	$(foreach day,$(days),$(in_dir)/$(day)) \
	$(foreach day,$(days),$(out_dir)/$(day)) \
	$(foreach day,$(days),$(render_dir)/$(day))
$(dirs): | $(BASE_DIR)
	sudo mkdir -p $@
	sudo chown $(USER):$(USER) $@

bootstrap: | $(dirs)

reset_render:
	-pkill -f $(render_cmd)
	rm $(lockfiles)

mrproper:
	sudo rm -r $(in_dir) $(out_dir) $(render_dir)


# ## determine current state of processing
#
# # determine files in samba dir which are ready for processing (haven't been modified last few minutes)
# samba_ready = $(shell find $(samba_dir) -type f $(DELAY))
# # determine list of all files which we should eventually have in the out dir
# samba_in_targets = $(subst $(samba_dir),$(in_dir),$(samba_ready))
#
# ready_targets = $(subst $(in_dir),,$(shell find $(in_dir) -type l))
# processing_targets = $(subst $(render_dir),,$(shell find $(render_dir) -type f))
# done_targets = $(subst $(out_dir),,$(shell find $(out_dir) -type f))
#
# start_processing = $(filter-out $(processing_targets),$(ready_targets))
#
# $(info ready for processing: $(start_processing))
# $(info processing : $(processing_targets))
# $(info done: $(done_targets))
#
# # symlink new ready samba files to 'in' dir
# samba_in: $(samba_in_targets)
# $(samba_in_targets): $(in_dir)/%: $(samba_dir)/% | $(in_dir)
# 	mkdir -p $$(dirname $@)
# 	ln -s $< $@
#
# # determine which files need processing by looking which file in 'in' are not in 'out' and are not processing
# all_targets = $(subst $(in_dir),$(out_dir),$(samba_ready))
#
# lockfiles = $(addprefix $(render_dir),$(addsuffix .lock,$(start_processing)))
# # process files which are not currently being processed
# process: $(lockfiles)
# $(lockfiles): $(render_dir)/%.lock: $(in_dir)/%
# 	mkdir -p $(dirname $(render_dir)/$*)
# 	$(converter) & echo "$$!" > $@
#
# # %{render_dir}/%.done: %{}
#
