# Capistrano Django

**A set of tasks built ontop of Capistrano to assist with Django deployments**

**Author:** Matthew J. Morrison.  [Follow me on Twitter][twitter]

# Requirements

**Python**

* Virtualenv
* Django
* South
* django-compressor

**Node.js**

* npm

**Other**

* Apache

# Configuring

**Django Project**

The name of the project must be "project"


**Capfile**

Add

	require 'capistrano/django'
	set :django_env, "requirements.txt"


**manage.py**

The first command line argument must be a settings file to use, like this

		#!/usr/bin/env python
		import os
		import sys
		
		if __name__ == "__main__":
		    os.environ.setdefault(
		    	"DJANGO_SETTINGS_MODULE",
		    	"project.settings.{}".format(sys.argv[1]))
		    	
		    from django.core.management import execute_from_command_line
		    args = sys.argv[:1] + sys.argv[2:]
		    execute_from_command_line(args)

**wsgi.py**

The django settings must default to project.settings.deployed, like this
		
		import os
		
		os.environ.setdefault(
			"DJANGO_SETTINGS_MODULE",
			"project.settings.deployed")

		from django.core.wsgi import get_wsgi_application
		application = get_wsgi_application()

# How it works

1. npm will be used to install all dependencies in devops/package.json
2. a virtualenv called 'virtualen' will be created in the project's directory
3. pip will be used to install all python dependencies defined in

		"devops/requirements/#{django_env}.txt"

4. django-compressor will run like this

		python manage.py django_env compress 
		
5. Django's collectstatic command will run like this

		python manage.py django_env collectstatic -i *.coffee -i *.less --noinput
		
6. Django's syncdb command (modified by South) will run like this

		python manage.py django_env syncdb --migrate --noinput
		
7. The settings file in "project/settings/#{django_env}" will be symlinked to "project/settings/deployed.py".
8. Apache will be restarted gracefully


# Example

For a working example check out [django-everything-template][django-everything] on github.


[twitter]: https://twitter.com/mattjmorrison
[django-everything]: http://github.com/mattjmorrison/django-everything-template