#!/bin/bash
# test for "subvolume list -f"

source "$TEST_TOP/common"

check_prereq mkfs.btrfs
check_prereq btrfs

setup_root_helper
setup_loopdevs 2
prepare_loopdevs
dev1=${loopdevs[1]}
dev2=${loopdevs[2]}

# test if the ids returned by "sub list" match expected ids
# $1  ... option for subvolume list
# $2  ... PATH to be specified by sub list command
# $3~ ... expected return ids
test_list()
{
	result=$(run_check_stdout $SUDO "$TOP/btrfs" subvolume list $1 "$2" | \
		awk '{print $2}' | xargs | sort -n)

	shift
	shift
	expected=($(echo "$@" | tr " " "\n" | sort -n))
	expected=$(IFS=" "; echo "${expected[*]}")

	if [ "$result" != "$expected" ]; then
		echo "result  : $result"
		echo "expected: $expected"
		_fail "ids returned by sub list does not match expected ids"
	fi
}

run_check $SUDO_HELPER "$TOP/mkfs.btrfs" -f "$dev1"
run_check $SUDO_HELPER "$TOP/mkfs.btrfs" -f "$dev2"

run_check $SUDO_HELPER mount "$dev1" "$TEST_MNT"
cd "$TEST_MNT"

# Create some subvolumes and directories
# <FS_TREE> (id 5)
#   |- AAA (id 256)
#   |   |- top
#   |   |- bbb
#   |   -- ccc
#   |
#   |- BBB (id 258)
#   -- CCC (id 259)
run_check $SUDO_HELPER "$TOP/btrfs" subvolume create AAA
run_check $SUDO_HELPER "$TOP/btrfs" subvolume create BBB
run_check $SUDO_HELPER "$TOP/btrfs" subvolume create CCC
run_check $SUDO_HELPER mkdir AAA/top
run_check $SUDO_HELPER mkdir AAA/bbb
run_check $SUDO_HELPER mkdir AAA/ccc

test_list "" "." "256 258 259"
test_list "-f" "." "256 258 259"
cd ..
run_check $SUDO_HELPER umount "$TEST_MNT"

# Mount as follows:
#
# "TEST_MNT" (AAA)
#   |- top (FS_TREE)
#   |   |- AAA
#   |   |- BBB
#   |   -- CCC
#   |
#   |- bbb (BBB)
#   -- ccc (CCC)
run_check $SUDO_HELPER mount -o subvol=AAA "$dev1" "$TEST_MNT"
run_check $SUDO_HELPER mount "$dev1" "$TEST_MNT/top"
run_check $SUDO_HELPER mount -o subvol=BBB "$dev1" "$TEST_MNT/bbb"
run_check $SUDO_HELPER mount -o subvol=CCC "$dev1" "$TEST_MNT/ccc"

cd "$TEST_MNT"
test_list "" "." "256"
# With -f option, subvolume AAA/BBB/CCC will be counted twice.
# Also, it will list FS_TREE (5) if it is mounted below the specified path.
test_list "-f" "." "5 256 256 258 258 259 259"

cd ..
run_check $SUDO_HELPER umount -R "$TEST_MNT"
cleanup_loopdevs
