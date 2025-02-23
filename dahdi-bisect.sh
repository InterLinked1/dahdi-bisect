#!/bin/sh

# Required: Latest commit as of which things were working
# Replace this with a commit on a date just before date of last known successful build
GOOD_COMMIT="9183e033ec4f8bdac778070ebccdd41727da2305"

# Optional: Earliest commit we know of where things were broken. Defaults to current HEAD if empty (not specified).
BAD_COMMIT=""

FILE_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# First time only
if [ ! -f /usr/local/src/phreaknet.sh ]; then
	export DEBIAN_FRONTEND=noninteractive
	apt-get -y update
	apt-get -y upgrade
	apt-get -y install git gcc make perl-modules flex bison wget libssl-dev libelf-dev bc
	cd /usr/local/src && wget https://docs.phreaknet.org/script/phreaknet.sh && chmod +x phreaknet.sh && ./phreaknet.sh make
fi

# Disable detached head warnings while git bisect is running
git config --global advice.detachedHead false

# Clone linux-next with full history. It's gonna take a while.
if [ ! -d /usr/src/linux-next ]; then
	cd /usr/src
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
	cd /usr/src/linux-next
else
	cd /usr/src/linux-next
	git checkout master
	git log --pretty=format:"%H%x09%an%x09%ad%x09%s" -1
fi
HEAD_COMMIT=$( git rev-parse HEAD )

if [ "$BAD_COMMIT" = "" ]; then
	BAD_COMMIT=$HEAD_COMMIT
fi

# Build latest kernel
make -j$(nproc) kernelversion > /dev/null
make -j$(nproc) x86_64_defconfig > /dev/null
make -j$(nproc) modules_prepare > /dev/null
make -j$(nproc) > /dev/null
make -j$(nproc) modules > /dev/null

# Start by kicking off a build with HEAD, which is expected to fail
rm -rf /usr/src/dahdi-linux-3.4.0 /usr/src/dahdi-tools-3.4.0
# Print just what failed
KSRC=/usr/src/linux-next phreaknet dahdi --drivers > /dev/null
if [ $? -eq 0 ]; then
	# Latest HEAD works fine, not a bad commit?
	echo "Build succeeded on HEAD?"
	exit 0
fi

cd /usr/src/linux-next

# Make sure the commit we think is bad really is.
if [ "$BAD_COMMIT" != "$HEAD_COMMIT" ]; then
	git checkout $BAD_COMMIT
	$FILE_DIR/dahdi-bisect-run.sh
	if [ $? -eq 0 ]; then
		echo "Build succeeds on supposedly bad commit $BAD_COMMIT?"
		exit 1
	fi
fi

# Make sure it actually worked at the good commit
git checkout $GOOD_COMMIT
$FILE_DIR/dahdi-bisect-run.sh
if [ $? -ne 0 ]; then
	# The commit we thought was good, wasn't?
	echo "Build fails on supposedly good commit $GOOD_COMMIT?"
	exit 1
fi

# Now, bisect!
git checkout master
git bisect reset
git bisect start
git bisect bad $BAD_COMMIT
git bisect good $GOOD_COMMIT
git bisect run $FILE_DIR/dahdi-bisect-run.sh
printf "\n" # It seems the last line of git bisect (bisect found first bad commit) doesn't end in a newline
