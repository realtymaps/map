import sys
import simplejson
import requests
import random
from urllib import quote

# pass in a single argument of a url that returns a json list of urls [ "url1","url2"]


def main(argv):
    if(len(argv) != 2):
        print "Must be 2 arguments ( url and range)!!!"
        return
    gen = RandomUrlGenerator()
    url = argv[0]
    _range = int(argv[1])
    gen.fetch(url, _range)


class RandomUrlGenerator:

    # http://stackoverflow.com/questions/120951/how-can-i-normalize-a-url-in-python
    def fix_url(self, url):
        # percent encode url, fixing lame server errors for e.g, like space
        # within url paths.
        fullurl = quote(url, safe="%/:=&?~#+!$,;'@()*[]")
        return fullurl

    def fetch(self, url, _range):
        raw = requests.get(url)
        json_objects = simplejson.loads(raw.content)

        urls = []
        for i in range(_range):
            urls.append(self.fix_url(random.choice(json_objects)))

        for s in urls:
            print s
        return urls

if __name__ == "__main__":
    main(sys.argv[1:])
