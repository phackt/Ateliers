#!/usr/bin/env python2
# -*- coding: utf8 -*-
import json, sys, argparse, collections
import dns.resolver
from termcolor import colored
from utils.common import *

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
config_data = {}

###################################################
# main procedure
###################################################
def main(argv):

    global config_data

    # Main variables
    create_files=True

    # Parse input args
    parser = argparse.ArgumentParser(prog='knocktone.py', description='A swiss-knife for DNS recon methodoly', formatter_class=argparse.RawTextHelpFormatter)
    subparsers = parser.add_subparsers(help='convert: convert knockpy for aquatone-scan\ndns: resolve domains list\ngenerate: generate subdomains list', dest='action')

    # create the parser for the command convert
    parser_convert = subparsers.add_parser('convert', help='convert knockpy for aquatone-scan')
    parser_convert.add_argument('input_file', help='knockpy json input file')

    # create the parser for the command dns
    parser_dns = subparsers.add_parser('dns', help='resolve domains list')
    parser_dns.add_argument('input_file', help='domains file')

    # create the parser for the command generate
    parser_generate = subparsers.add_parser('generate', help='generate subdomains list')
    parser_generate.add_argument('input_file', help='words file')
    parser_generate.add_argument('domain', help='domain used in subdomains generation')

    # create the parser for the command scan
    parser_generate = subparsers.add_parser('scan', help='scan aquatone headers post aquatone-scan')
    parser_generate.add_argument('domain', help='domain in aquatone directory')

    # create the parser for the command concat
    parser_generate = subparsers.add_parser('concat', help='concat hosts.json files from aquatone-discover')
    parser_generate.add_argument('input_file_1', help='first input file hosts.json')
    parser_generate.add_argument('input_file_2', help='second input file hosts.json')
    parser_generate.add_argument('output_file', help='output file')

    args = parser.parse_args()

    # Reading config.json
    with open(get_knocktone_filepath('config.json')) as config_file:
        config_data = json.load(config_file)

    # Select action
    if args.action == 'convert':
        file_exists(args.input_file)
        aquatone_format(args.input_file)
    elif args.action == 'dns':
        file_exists(args.input_file)
        dns_resolve_from_file(args.input_file)
    elif args.action == 'generate':
        # No need to generate hosts files
        create_files=False
        file_exists(args.input_file)
        generate_subdomains(args.input_file,args.domain)
    elif args.action == 'scan':
        aquatone_headersdir = config_data['aquatone_homedir'] + os.sep + args.domain + os.sep + config_data['aquatone_headersdir']
        # No need to generate hosts files
        create_files=False
        dir_exists(aquatone_headersdir)
        check_aquatonescan_headers(aquatone_headersdir)
    elif args.action == 'concat':
        # No need to generate hosts files
        create_files=False
        file_exists(args.input_file_1)
        file_exists(args.input_file_2)
        concat_aquatone_hosts_files(args.input_file_1,args.input_file_2,args.output_file)

    # Creating hosts files for aquatone-scan (csv,json)
    if create_files:
        create_json(get_knocktone_filepath(config_data['aquatone_json_output_filename']),aquatone_json_data);
        create_csv(get_knocktone_filepath(config_data['aquatone_csv_output_filename']),aquatone_csv_data);

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
    nb_processed = 0
    nb_domains = 0

    # Opening the file with subdomains
    with open(file) as domains_input_file:

        # Delete newline
        domains = domains_input_file.read().splitlines()
        nb_domains = len(domains)

        print 'Resolving file %s with %d domains' % (file,nb_domains)

        for domain in domains:
            ip = dns_resolve_A(domain)

            # The domain has been resolved
            if ip:
                print colored('Domain found %s (%s)' % (domain,ip),'green')

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

            # Counting processed lines
            nb_processed += 1
            if nb_processed % 1000 == 0:
                print '%s processed on %s' % (nb_processed,nb_domains)
        
        print '%s processed on %s' % (nb_domains,nb_domains)

###################################################
# generate subdomains file
###################################################
def generate_subdomains(file,domain):

    output_file=config_data['subdomains_output_file'];
    output_file_data='';

    # Opening the file with words to add to the domain
    with open(file) as words_input_file:
        subdomains = words_input_file.read().splitlines()
        for subdomain in subdomains:
            output_file_data += '%s.%s\n' % (subdomain,domain)

    # Saving sudomains list
    with open(get_knocktone_filepath(output_file), 'w') as result_file:
        result_file.write(output_file_data)

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
# print unresolved alias
###################################################
def print_unresolved_alias(aliases):  

    for alias in aliases:
        if(not dns_resolve_A(alias)):
            print colored('/!\ We found an unresolved alias: %s' % alias,'red')

###################################################
# check post aquatone-scan headers
###################################################
def check_aquatonescan_headers(directory):

    # Looping on each subdomains headers txt files
    for file in os.listdir(directory):
        if file.endswith('.txt'):
            print 'Scanning file %s' % file

            # Opening txt file
            with open(directory + os.sep + file) as headers_file:
                headers_lines = headers_file.read().splitlines()

                # Reading each line of the headers txt file
                for line in headers_lines:

                    # Checking is some headers are present
                    for value in config_data['headers']['present']:
                        if value.lower() in line.lower():
                            print colored(line,'green')

                missing_headers = []
                # Checking if some headers are missing
                for value in config_data['headers']['missing']:
                    if not value.lower() in map(lambda x:x.lower(),headers_lines):
                        missing_headers.append(value)
                        
                if missing_headers:
                    print colored('Missing patterns (%s)' % ', '.join(missing_headers),'yellow')


###################################################
# concat aquatone-discover hosts.json files
###################################################
def concat_aquatone_hosts_files(input_file_1,input_file_2,output_file):

    input_data_1 = {}
    input_data_2 = {}

    # Reading input files
    with open(input_file_1) as input_file_1, open(input_file_2) as input_file_2:
        input_data_1 = json.load(input_file_1)
        input_data_2 = json.load(input_file_2)

    # concat dictionaries
    input_data_1.update(input_data_2)

    # write resulting output file
    with open(output_file, 'w') as result_file:
        json.dump(collections.OrderedDict(sorted(input_data_1.items())), result_file)


###################################################
# only for command line
###################################################
if __name__ == '__main__':
    # if os.geteuid() != 0:
    #     sys.exit('You need to have root privileges to run this script.')
    main(sys.argv)