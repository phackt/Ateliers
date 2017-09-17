#!/usr/bin/env python2
# -*- coding: utf8 -*-

import json, os


###################################################
# create CSV file
###################################################
def create_csv(file,data):       
    # Opening hosts.csv
    with open(file, 'w') as output_csv:
        output_csv.write(data)

###################################################
# create JSON file
###################################################
def create_json(file,data):       
    # Opening hosts.json
    with open(file, 'w') as output_json:
        json.dump(data, output_json)

###################################################
# Check existing file
###################################################
def file_exists(file):
    if not os.path.isfile(file):
        raise Exception('File %s does not exist' % file)

###################################################
# Check existing directory
###################################################
def dir_exists(file):
    if not os.path.isdir(file):
        raise Exception('Directory %s does not exist' % file)