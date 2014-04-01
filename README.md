# Lunch 

[![Build Status](https://travis-ci.org/verath/lunch.svg)](https://travis-ci.org/verath/lunch)

_Where do we eat!?_

# Quick Installation 
1. Install [Node.JS](http://nodejs.org/) and [PostgreSQL](http://www.postgresql.org/).
2. Set up and start PostgreSQL.
3. Clone the repository `git clone https://github.com/verath/lunch.git`.
4. Install dependencies local `npm install`.
5. Install coffee-script globally `npm install -g coffee-script`.
6. (optional) Install grunt-cli globally, for running unit tests `npm install -g grunt-cli`.
7. Set up the database `psql -U <username> -f setup.sql`. The default root username is _postgres_.
8. Copy app/config.example.coffee to app/config.coffee and modify it to your liking.

# Starting the app
Run `coffee app/app.coffee` from the console. The server should now be
listening on the port and ip specified in the config.coffee file.
