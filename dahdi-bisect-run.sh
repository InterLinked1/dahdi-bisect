#!/bin/sh

cd /usr/src/linux-next

# Rebuild anything that's changed
CURRENT_COMMIT=$( git rev-parse HEAD )
# git log -1 --pretty=short is almost appropriate but is ultimately unsuitable, since it's missing the date.
git log --pretty=format:"%H%x09%an%x09%ad%x09%s" -1
make -j$(nproc) kernelversion > /dev/null
make -j$(nproc) x86_64_defconfig > /dev/null
make -j$(nproc) modules_prepare > /dev/null
make -j$(nproc) > /dev/null # Don't print out the whole kernel build, it's just noise
make -j$(nproc) modules > /dev/null

cd /usr/src/dahdi-linux-3.4.0
KSRC=/usr/src/linux-next make clean > /dev/null
KSRC=/usr/src/linux-next make -j$(nproc) > /dev/null
EXIT_STATUS=$?
# git bisect run doesn't print out success or failure after each step, so do it here
DATE=$( date "+%Y-%m-%d %H:%M:%S" )
if [ $EXIT_STATUS -ne 0 ]; then
	printf "%s: Build failed, $CURRENT_COMMIT is a bad commit!\n" "$DATE"
else
	printf "%s: Build succeeded, $CURRENT_COMMIT is a good commit!\n" "$DATE"
fi
exit $EXIT_STATUS
