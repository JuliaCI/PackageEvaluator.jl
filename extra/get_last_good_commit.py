#!/usr/bin/env python

import requests, subprocess, os, sys
jsondata = requests.get("https://api.travis-ci.org/builds/?owner_name=JuliaLang&name=julia")

builds = []
try:
    builds = jsondata.json()
except:
    print builds
    raise

# Get a list of passing builds
passing_builds = [b for b in builds if b[u'result'] == 0 and b[u'duration'] != None]

if len(passing_builds):
    # Check to make sure those builds still exist in master.
    commits_in_master = subprocess.check_output(["git", "log", "--pretty=format:%H", "-n100"])
    if not len(commits_in_master):
        sys.stderr.write('No commits detected!  (Are you inside a git repository?)')
        sys.exit(-1)
    commits_in_master = [unicode(commit) for commit in commits_in_master.split("\n")]

    for p in passing_builds:
        if p[u'commit'] in commits_in_master:
            print p[u'commit']
            sys.exit( 0 )
else:
    sys.stderr.write('No passing builds!')
    sys.exit(-1)
