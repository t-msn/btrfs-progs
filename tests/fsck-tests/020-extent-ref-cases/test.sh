#!/bin/bash
# In order to confirm that 'btrfs check' supports checking a variety of refs,
# add the following cases:
#
# * keyed_block_ref
# * keyed_data_ref
# * shared_block_ref
# * shared_data_ref
# * no_inline_ref (a extent item without inline ref)
# * no_skinny_ref
#
# Special check for lowmem regression
# * block_group_item_false_alert
#   Containing a block group and its first extent at
#   the beginning of leaf.
#   Which caused false alert for lowmem mode.

source "$TOP/tests/common"

check_prereq btrfs

check_image() {
	local image

	image=$1
	run_check "$TOP/btrfs" check "$image"
}

check_all_images
