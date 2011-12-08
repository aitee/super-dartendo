#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
import json

default_settings = {
    "rom": "roms/IceHockey.nes",
    "scale": True,
    "sound": True,
    "stereo": True,
    "scanLines": False,
    "fps": True,
    "timeemulation": True,
    "showsoundbuffer": False,
    "p1_controls": {
        # these are based on the html key codes
        # see http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
        "up": 87,     # 'w' key
        "down": 83,   # 's' key
        "left": 65,   # 'a' key
        "right": 68,  # 'd' key
        "a": 70,      # 'f' key
        "b": 71,      # 'g' key
        "start": 49, # '1' key
        "select": 50 # '2' key
    },
    "p2_controls": {
        "up": 38,     # up arrow
        "down": 40,   # down arrow
        "left": 37,   # left arrow
        "right": 39,  # right arrow
        "a": 57,      # 9 key
        "b": 48,      # 0 key
        "start": 189, # '-' key
        "select": 187 # '=' key
    }
}

class JsonHandler(webapp2.RequestHandler):
    """
    Treats all requests as requiring a JSON object response,
    and data carrying methods (like POST, PUT) as carrying
    a JSON object describing the request. The decode step is
    done here then passed to a json_*() method for processing,
    and the return value of that function then encoded to JSON
    for the response.
    """
    def get(self):
        self.send_response(self.json_get())
    
    def json_get(self):
        return None
    
    def post(self):
        req_obj = json.loads(self.request.body)
        response_obj = self.json_post(req_obj)
        self.send_response(response_obj)
    
    def send_response(self, obj):
        if obj:
            json_resp = json.dumps(obj)
            self.response.content_type = "application/json"
            self.response.write(json_resp)
        else:
            self.response.status = 404


class SettingsHandler(JsonHandler):
    def json_get(self):
        return default_settings


app = webapp2.WSGIApplication([
    ('/settings', SettingsHandler),
], debug=True)


def main():
    app.run()


if __name__ == '__main__':
    main()
