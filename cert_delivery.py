#!/usr/bin/python

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from SimpleHTTPServer import SimpleHTTPRequestHandler

server = HTTPServer(('0.0.0.0', 80), SimpleHTTPRequestHandler)
server.serve_forever()
