import sys

from mitmproxy.flow import FlowWriter
from netlib.http import decoded

class Writer:
    def __init__(self, path):
        if path == "-":
            self.f = sys.stdout
        else:
            self.f = open(path, "wb")
        self.w = FlowWriter(self.f)

    def request(self, flow):
        with decoded(flow.request):
            self.w.add(flow.request)
            self.f.write(b"\n\nmethod:" + flow.request.method)
            self.f.write(b"\nurl:" + flow.request.pretty_url)
            self.f.write(b"\nheaders:" + str(flow.request.headers))
            self.f.write(b"\ncontent:" + flow.request.content)
            self.f.write(b"\n----------------------------------------------\n")

def start():
    if len(sys.argv) != 2:
        raise ValueError('Usage: -s "flowwriter.py filename"')
    return Writer(sys.argv[1])

def done():
    f.close
