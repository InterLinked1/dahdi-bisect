# dahdi-bisect

**Tool to automatically find the kernel commit causing a compilation failure in DAHDI Linux**

`dahdi-bisect` is simply a wrapper around `git bisect`. This can help to quickly determine the kernel change that has caused breakage in the DAHDI kernel modules, allowing the issue to be quickly identified and fixed. This tool is used internally to ensure that [DAHDI Linux](https://github.com/asterisk/dahdi-linux) builds when using [PhreakScript](https://github.com/InterLinked1/phreakscript) and to submit fixes upstream as needed.

This tool clones the entire Linux kernel repository and rebuilds the kernel multiple times. A compute-optimized instance is recommended (as many CPU cores as possible, at least 10 GB of free disk space, and 2 GB of memory). This script is designed for Debian Linux, modifications are needed to accomodate non-apt package managers.

## Usage

1. `cd /usr/src && git clone https://github.com/InterLinked1/dahdi-bisect.git && cd dahdi-bisect`

2. Update the `GOOD_COMMIT` and, optionally, `BAD_COMMIT` variables at the top of `dahdi-bisect.sh`. This will narrow down the search space.

3. When ready to start, run `./dahdi-bisect.sh`. Depending on the size of the search space and how powerful the machine is, this may take several hours to run.
