# plex_status

Description
-----------

    Plex server information


Installation
-----------

Install Python Pip: https://pip.pypa.io/en/latest/installing.html

Install virtualenv: 
    
    sudo pip install virtualenv
    
Create a virtual environment:
    
    virtualenv venv
    
Activate virtual environment:
    
    source venv/bin/activate

Now that the python virtual environment is running go ahead and install Flask and all dependencies into the virtual environment
    
    pip install -r requirements.txt

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
