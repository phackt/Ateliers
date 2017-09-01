#!/usr/bin/env python2
# -*- coding: utf8 -*-
import json, sys, os, argparse
import dns.resolver
from termcolor import colored

###################################################
# knocktone is a swiss-knife in DNS recon
# Feature 1: It converts knockpy format into aquatone ones
# Feature 2: It takes a list of subdomains and resolve them
#            then format them for aquatone
###################################################

# Requirements:
# dnspython
# termcolor

# variables
aquatone_json_data = {}
aquatone_csv_data = ''

###################################################
# main procedure
###################################################
def main(argv):

    # Main variables
    aquatone_csv_output_filename = 'hosts.txt'
    aquatone_json_output_filename = 'hosts.json'

    # Parse input args
    parser = argparse.ArgumentParser(prog='knocktone.py', description='A swiss-knife for DNS recon methodoly')
    parser.add_argument('action', choices=('convert', 'dns'), help='convert knockpy for aquatone-scan / resolve domains list')
    parser.add_argument('action_arg', help='knockpy json input file / domains list file')
    args = parser.parse_args()
  
    # Some arguments are required
    if not os.path.isfile(args.action_arg):
        parser.error('File %s does not exist' % args.action_arg)

    # Select action
    if args.action == 'convert':
        aquatone_format(args.action_arg)
    elif args.action == 'dns':
        dns_resolve_from_file(args.action_arg)

    create_json(aquatone_json_output_filename,aquatone_json_data);
    create_csv(aquatone_csv_output_filename,aquatone_csv_data);

###################################################
# convert knockpy output json file into 
# csv and json aquatone expected format
###################################################
def aquatone_format(knockpy_input_file):

    global aquatone_json_data
    global aquatone_csv_data

    # Reading knockpy input file
    with open(knockpy_input_file) as input_file:

        # Loading knockpy json data
        data = json.load(input_file)
        
        # Retrieving domain
        aquatone_json_data[data['target_response']['target']] = data['target_response']['ipaddress'][0]
        aquatone_csv_data += '%s,%s\n' % (data['target_response']['target'],data['target_response']['ipaddress'][0])

        for subdomain in data['subdomain_response']:
            
            # Retrieving subdomains
            aquatone_json_data[subdomain['target']] = subdomain['ipaddress'][0]
            aquatone_csv_data += '%s,%s\n' % (subdomain['target'],subdomain['ipaddress'][0])

            # Printing if alias found for further investigation (subdomain takeover)
            if(subdomain['alias']):
                print colored('Alias found for %s (%s)' % (subdomain['target'],', '.join(subdomain['alias'])),'yellow')

                # We are looping on each alias and resolve them
                print_unresolved_alias(subdomain['alias'])
 
###################################################
# read a list of a list of domains
###################################################
def dns_resolve_from_file(file):

    global aquatone_json_data
    global aquatone_csv_data

    with open(file) as domains_input_file:
        # Delete newline
        domains = domains_input_file.read().splitlines()
        for domain in domains:
            ip = dns_resolve_A(domain)

            # The domain has been resolved
            if ip:
                aquatone_json_data[domain] = ip
                aquatone_csv_data += '%s,%s\n' % (domain,ip)

                ##########################################
                # We are looking if we can find some alias
                ##########################################
                aliases = []
                alias=dns_resolve_CNAME(domain)

                # Recursive check
                while(alias):
                    aliases.append(alias)
                    alias=dns_resolve_CNAME(alias)

                if aliases:
                    print colored('Alias found for %s (%s)' % (domain,', '.join(aliases)),'yellow')
                    print_unresolved_alias(aliases)

###################################################
# send a DNS type A request
###################################################
def dns_resolve_A(domain):
    try:
        answers_IPv4 = dns.resolver.query(domain, 'A')
        # We are returning the first ip address found
        return str(answers_IPv4[0].address)
    except Exception as e:
        return None

###################################################
# send a DNS type CNAME request
###################################################
def dns_resolve_CNAME(domain):
    aliases = []
    try:
        answers_IPv4 = dns.resolver.query(domain, 'CNAME')
        return str(answers_IPv4[0].target)
    except Exception as e:
        return None

###################################################
# create CSV file
###################################################
def create_csv(file,data):       
    # Opening hosts.csv
    with open(file, 'w') as output_csv:
        output_csv.write('%s' % data)

###################################################
# create JSON file
###################################################
def create_json(file,data):       
    # Opening hosts.json
    with open(file, 'w') as output_json:
        json.dump(data, output_json)

###################################################
# print unresolved alias
###################################################
def print_unresolved_alias(aliases):       
    for alias in aliases:
        if(not dns_resolve_A(alias)):
            print colored('We found an unresolved alias: %s' % alias,'green')

###################################################
# only for command line
###################################################
if __name__ == '__main__':
    # if os.geteuid() != 0:
    #     sys.exit('You need to have root privileges to run this script.')
    main(sys.argv)