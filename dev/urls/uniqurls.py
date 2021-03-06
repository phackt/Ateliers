#!/usr/bin/env python3
# -*- coding: utf8 -*-

import sys, argparse, hashlib
from urllib.parse import urlparse
from urllib.parse import parse_qs

class Url():
    
    # Static list of Url
    LIST = set()
    NETLOC_PARAMS = {}
    
    def __init__(self,surl):
        purl = urlparse(surl)
        self.url = surl
        self.scheme = purl.scheme
        self.netloc = purl.netloc
        self.path = '' if purl.path == '/' else purl.path
        self.params = list(parse_qs(purl.query,keep_blank_values=True).keys())

    """
    Compare if it matches with some Url objects
    """
    @staticmethod
    def exists(url):
        key = hashlib.sha1(bytes('%s%s%s' % (url.scheme,url.netloc,url.path),'utf8')).hexdigest()

        if key in Url.NETLOC_PARAMS.keys():
            for param in url.params:
                if param not in Url.NETLOC_PARAMS[key]:
                    return False
        else:
            # Never see before
            return False

        # All params have been found for this key
        return True

##################################################
# main procedure
###################################################
def main(argv):

    nb_processed = 0

    ###################
    # parse args
    ###################
    parser = argparse.ArgumentParser(description='Look for duplicate urls')
    parser.add_argument("-i", "--input", dest="inputfile",help="input file")
    parser.add_argument("-o", "--output", dest="outputfile", help="output file")
    args = parser.parse_args()

    if not args.inputfile or not args.outputfile:
        parser.print_help()
        sys.exit(1)

    with open(args.inputfile) as inputfile:

        urls = inputfile.read().splitlines()
        
        print('[*] Processing %d urls' % len(urls))
    
        ###################
        # Pushing urls onto queue
        ###################
        for url in urls:  
            ourl = Url(url)

            if not Url.exists(ourl):
                Url.LIST.add(ourl)

                # compute sha1 of netloc
                key = hashlib.sha1(bytes('%s%s%s' % (ourl.scheme,ourl.netloc,ourl.path),'utf8')).hexdigest()

                # Add all params in key set
                if key in Url.NETLOC_PARAMS.keys():

                    for param in ourl.params:
                        Url.NETLOC_PARAMS[key].add(param)

                else:
                    Url.NETLOC_PARAMS[key] = set([param for param in ourl.params])


            nb_processed += 1

            if nb_processed % 1000 == 0:
                print('[*] %s urls processed' % nb_processed)

        print('[*] Output file: %s' % args.outputfile)
        print('[*] Done')

    # Writing results file
    with open(args.outputfile,'w') as result_file:

        for ourl in Url.LIST:
            print(ourl.url,file=result_file)
        

###################################################
# only for command line
###################################################
if __name__ == '__main__':
    # if os.geteuid() != 0:
    #     sys.exit('You need to have root privileges to run this script.')
    main(sys.argv)