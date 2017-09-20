#!/usr/bin/env python2
# -*- coding: utf8 -*-

import json, os, requests
from termcolor import colored

# variables
script_path=os.path.dirname(os.path.realpath(__file__)) + os.sep + '..' + os.sep 

# global actions
requests.packages.urllib3.disable_warnings()

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

###################################################
# Get knocktone path file
###################################################
def get_knocktone_filepath(file):
    global script_path
    return script_path + file

###################################################
# Return valid http response (try http/https)
# Do not follow redirection
###################################################
def get_http_response(domain,port):
    response = None
    try:
        response = requests.get('http://%s:%s' % (domain,port), allow_redirects=False)
        if (response is None or (response is not None and response.status_code == 400)):
            response = requests.get('https://%s:%s' % (domain,port), allow_redirects=False, verify=False)
    except Exception as e:
        print colored(e.message,'red')

    return response
