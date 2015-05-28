# minhaz mahmud
# flask app to monitor Plex server

from flask import Flask, render_template, redirect, url_for
from pprint import pprint
import subprocess

app = Flask(__name__)

from functools import wraps
from flask import request, Response


def check_auth(username, password):
    """This function is called to check if a username /
    password combination is valid.
    """
    return username == 'plex' and password == 'status'

def authenticate():
    """Sends a 401 response that enables basic auth"""
    return Response(
    'Could not verify your access level for that URL.\n'
    'You have to login with proper credentials', 401,
    {'WWW-Authenticate': 'Basic realm="Login Required"'})

def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated

@app.route('/')
@requires_auth
def index():
	return redirect(url_for('status'))

@app.route('/status/')
@app.route('/status/<flag>')
@requires_auth
def status(flag=0):
	
	# Check if Plex is running
	p1 = subprocess.Popen(["ps", "-ef"], stdout=subprocess.PIPE)
	p2 = subprocess.Popen(["grep", "Plex Media Server$"], stdin=p1.stdout, stdout=subprocess.PIPE)
	
	output = p2.communicate()[0]
	plex_status = True
	
	# if plex isn't running, set to false
	if(output.strip() == ""):
		plex_status = False
	
	# Check if Rsync is already running
	
	p1 = subprocess.Popen(['pgrep', 'rsync'], stdout=subprocess.PIPE)
	output = p1.communicate()[0]
	rsync_status = True
	if(output.strip() == "" and flag != '1'):
		rsync_status = False
	
	
	# Check Disk Information for /data
	df = subprocess.Popen(["df", "-h", "/data"], stdout=subprocess.PIPE)
	output = df.communicate()[0].split("\n")[1].split()
	storage_status = {
		'device': output[0],
		'size': output[1],
		'used': output[2],
		'available': output[3],
		'percent': output[4],
		'mountpoint': output[-1]
	}
	
	return render_template('index.html', plex_status=plex_status, rsync_status=rsync_status, storage=storage_status)

@app.route('/update', methods=['POST'])
@requires_auth
def update():
	subprocess.Popen(["sh", "/plex/plexscript.sh"])
	return redirect(url_for('status', flag=1))
	

if __name__ == '__main__':
    app.run(
#		debug=True,
		host='0.0.0.0'
    )