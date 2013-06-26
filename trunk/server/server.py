import cherrypy
import os

try:
    import json
except ImportError:
    import simplejson as json
    
matchPlayerTimeInputs = {}

class HelloWorld(object):
    def index(self):
        return "Hello World!"
    index.exposed = True

    def sendStatus(self, status = None):
        frames = json.loads(status)
        #print frames
        playerid = int(frames['-1']['playerid'])
        matchid = int(frames['-1']['matchid'])
        for key,value in frames.iteritems():
          if key == '-1': continue
          #print "STATUS:",status
          args = value
          framecount = int(key)
          #print "ARGS:",args
          if matchid not in matchPlayerTimeInputs:
              matchPlayerTimeInputs[matchid] = {}
          playerTimeInputs = matchPlayerTimeInputs[matchid]
          if playerid not in playerTimeInputs:
              playerTimeInputs[playerid] = {}
          timeInputs = playerTimeInputs[playerid]
          timeInputs[framecount] = {
              'left':int(args[u'left']),
              'right':int(args[u'right']),
              'up':int(args[u'up']),
              'down':int(args[u'down']),
              'a':int(args[u'a']),
              'b':int(args[u'b']),
              'select':int(args[u'select']),
              'start':int(args[u'start']),
              }
          #print timeInputs

        if playerid==1: lookupplayerid=2
        else: lookupplayerid=1
        if matchid not in matchPlayerTimeInputs:
            matchPlayerTimeInputs[matchid] = {}
        playerTimeInputs = matchPlayerTimeInputs[matchid]
        if int(lookupplayerid) not in playerTimeInputs:
            playerTimeInputs[int(lookupplayerid)] = {}
            
        prevFrame = cherrypy.session.get('framecount',-1)
        #print "PREVFRAME",prevFrame
        timeInputs = matchPlayerTimeInputs[matchid][lookupplayerid]
        #print timeInputs
        retval = {}
        for framecount,inputs in timeInputs.iteritems():
            #print framecount,inputs
            cherrypy.session['framecount'] = max(cherrypy.session.get('framecount',-1),framecount)
            if framecount>prevFrame:
                retval[int(framecount)] = inputs
        return json.dumps(retval)
        #return "HELLO WORLD"
    sendStatus.exposed = True
        
    
conf = {
    'global': {
        'server.socket_host': '0.0.0.0',
        'server.socket_port': 8000,
        'server.nodelay':False,
    },
    '/': {
'tools.sessions.on' : True,
'tools.sessions.storage_type' : "file",
'tools.sessions.storage_path' : "./sessions/",
'tools.sessions.timeout' : 60,
'tools.staticdir.on' : True,
'tools.staticdir.root' : os.getcwd(),
'tools.staticdir.dir' : '../dartendo/',
    }
}

if __name__ == '__main__':
    #Clean out old sessions
    folder = './sessions/'
    for the_file in os.listdir(folder):
        file_path = os.path.join(folder, the_file)
        try:
            if os.path.isfile(file_path):
                print 'Deleting session',file_path
                os.unlink(file_path)
        except Exception, e:
            print e
    cherrypy.quickstart(HelloWorld(), '/', conf)
