# plex_status
Plex server information


Description
-----------

    This is a plex app or something


Installation
-----------

Install Python Pip: https://pip.pypa.io/en/latest/installing.html

Install virtualenv: 
    
    sudo pip install virtualenv
    
Create a virtual environment:
    
    virtualenv venv
    
Activate virtual environment:
    
    . venv/bin/activate

Now that the python virtual environment is running go ahead and install Flask into the virtual environment
    
    pip install Flask

Build/Develop
-----------

Run flask application:
    
    python app.py
    
During development you may find it useful to set debug to True.

``` python    
app.run(
    debug=True,
	host='0.0.0.0'
)
```
    
How to view in browser
-----------
    - Open browser and visit http://127.0.0.1:5000/
    
    
Resources
-----------
    1. Flask: http://flask.pocoo.org
    2. Jinja Templating: http://jinja.pocoo.org/docs/dev/templates/
