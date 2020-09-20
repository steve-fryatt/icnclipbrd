IcnClipBrd
==========

Bring the Global Clipboard to Writable Icons.


Introduction
------------

The global clipboard provides a way of transferring data between applications. You select the data in one application and cut or copy it onto the clipboard (usually using Ctrl-X and Ctrl-C). You then move to the other application and paste the data from the clipboard (usually Ctrl-V).

IcnClipBrd, is a small module for users with RISC OS 3.5 or later, which allows you to cut and paste in writeable icons using the global clipboard.

The module was originally written by Thomas Leonard, and has been converted to 32-bit for use on RISC OS 5 by myself (Stephen Fryatt). I would like to thank Thomas for allowing the module to be placed in the Public Domain; any problems encountered using the updated module are likely to be my fault and should be reported first to the address below.


Building
--------

IcnClipBrd consists of a collection of ARM assembler and un-tokenised BASIC, which must be assembled using the [SFTools build environment](https://github.com/steve-fryatt). It will be necessary to have suitable Linux system with a working installation of the [GCCSDK](http://www.riscos.info/index.php/GCCSDK) to be able to make use of this.

With a suitable build environment set up, making IcnClipBrd is a matter of running

	make

from the root folder of the project. This will build everything from source, and assemble a working !IcnClipBrd application and its associated files within the build folder. If you have access to this folder from RISC OS (either via HostFS, LanManFS, NFS, Sunfish or similar), it will be possible to run it directly once built.

To clean out all of the build files, use

	make clean

To make a release version and package it into Zip files for distribution, use

	make release

This will clean the project and re-build it all, then create a distribution archive (no source), source archive and RiscPkg package in the folder within which the project folder is located. By default the output of `git describe` is used to version the build, but a specific version can be applied by setting the `VERSION` variable -- for example

	make release VERSION=1.23


Licence
-------

IcnClipBrd is in the public domain and may be freely copied.