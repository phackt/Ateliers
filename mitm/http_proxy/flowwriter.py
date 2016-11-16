import sys

from netlib.http import decoded

class Writer:
    def __init__(self, path):
        if path == "-":
            self.f = sys.stdout
        else:
            self.f = open(path, "ab")

    def request(self, flow):
        with decoded(flow.request):
            self.f.write(b"method:" + flow.request.method)
            self.f.write(b"\nurl:" + flow.request.pretty_url)
            self.f.write(b"\nheaders:" + str(flow.request.headers))
            if flow.request.method == 'POST':
                self.f.write(b"\ncontent:" + flow.request.content)
            self.f.write(b"\n----------------------------------------------\n")

def start():
    if len(sys.argv) != 2:
        raise ValueError('Usage: -s "flowwriter.py filename"')
    return Writer(sys.argv[1])

def done():
    f.close
