#!/usr/bin/env python3
"""Tiny static server for GLM Arcade - no dependencies. Run: py server.py [port]"""
import http.server
import mimetypes
import os
import sys

mimetypes.add_type('application/manifest+json', '.webmanifest')
mimetypes.add_type('text/javascript', '.js')

os.chdir(os.path.dirname(os.path.abspath(__file__)))
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8137


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, **{
        '.webmanifest': 'application/manifest+json',
        '.js': 'text/javascript; charset=utf-8',
    }}

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


http.server.HTTPServer(('127.0.0.1', port), Handler).serve_forever()
