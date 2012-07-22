#!/usr/bin/python

import glob, os
from optparse import OptionParser
from sys import stderr

#### BEGIN OF FIXME ####
tasks = [
	("./vim", "~/.vim"),
	("./vimrc", "~/.vimrc")
]
#### END OF FIXME ####

# command line arguments
def option():
	parser = OptionParser()
	parser.add_option("-f", "--force", action="store_true", default=False)
	(options, args) = parser.parse_args()
	return options

# get current directory (absolute path) and options
current_dir = os.path.abspath(os.path.dirname(__file__))
options = option()

for source, target in tasks:
	# normalize paths
	source_abspath = os.path.join(current_dir, source)
	target = os.path.expanduser(target)

	# if --force option is given, delete the previously existing symlink
	if os.path.lexists(target) and options.force == True:
		os.unlink(target)

	# make a symbolic link!
	if os.path.lexists(target):
		print >> stderr, ("%s : already exists" % target)
	else:
		os.symlink(source_abspath, target)
		print >> stderr, ("%s : created (%s)" % (target, source_abspath))

