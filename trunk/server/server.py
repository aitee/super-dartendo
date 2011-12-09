import cherrypy
import json
import os

matchPlayerTimeInputs = {}

class HelloWorld(object):
    def index(self):
        return "Hello World!"
    index.exposed = True

    def sendStatus(self, **args):
        if int(args['matchid']) not in matchPlayerTimeInputs:
            matchPlayerTimeInputs[int(args['matchid'])] = {}
        playerTimeInputs = matchPlayerTimeInputs[int(args['matchid'])]
        if int(args['playerid']) not in playerTimeInputs:
            playerTimeInputs[int(args['playerid'])] = {}
        timeInputs = playerTimeInputs[int(args['playerid'])]
        timeInputs[int(args['framecount'])] = {
            'left':int(args['left']),
            'right':int(args['right']),
            'up':int(args['up']),
            'down':int(args['down']),
            'a':int(args['a']),
            'b':int(args['b']),
            'select':int(args['select']),
            'start':int(args['start']),
            }
        print timeInputs

        playerid = int(args['playerid'])
        if playerid==1: lookupplayerid=2
        else: lookupplayerid=1
        if int(args['matchid']) not in matchPlayerTimeInputs:
            matchPlayerTimeInputs[int(args['matchid'])] = {}
        playerTimeInputs = matchPlayerTimeInputs[int(args['matchid'])]
        if int(lookupplayerid) not in playerTimeInputs:
            playerTimeInputs[int(lookupplayerid)] = {}
            
        prevFrame = cherrypy.session.get('framecount',-1)
        print "PREVFRAME",prevFrame
        timeInputs = matchPlayerTimeInputs[int(args['matchid'])][lookupplayerid]
        print timeInputs
        retval = {}
        for framecount,inputs in timeInputs.iteritems():
            print framecount,inputs
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
