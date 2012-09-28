HipChat Logger
===========
HipChat Logger is a ruby script to backup/archive your HipChat rooms. 

Requirements
------------
Tested with Ruby 1.9.3

Installation
------------
Run:

    bundle install
    cp config/config.yml.example config/config.yml

Edit config.yml:
* `hipchat.api.key` - Add your HipChat API token/key config.yml (Note: This requires an admin level API token)
* `user_netid_mappings` - will map HipChat user full name to the user's netid and add `netid=` to the log files
* `ignored_users` - Add any username or user_id that you want to ignore when archiving messages

Usage
-----
Run:

    ./run_hipchat_logger.rb

Run with options
* `-l` - specifies the logging level  (Note: This does not affect the hipchat message log files) -- supports debug|warn|info|error -- default is info
* `-d` - specify the day you want archived -- defaults to today -- must be formatted as `YYYY-mm-dd`

Example:

    ./run_hipchat_logger.rb -l debug -d 2012-09-01

This will turn debugging on and archive any HipChat content from September 1, 2012.