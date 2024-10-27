#!/usr/bin/env  sh
# Roll back Clique.lua if it gets updated, to restore raid functionality.
# This is a terrible idea; what needs to happen is


file='Clique.lua'


\git  commit  "$file"  --message='Checkin from the official Ascension update.'
# This will be a bad idea
\git  checkout  HEAD^^  "$file"
