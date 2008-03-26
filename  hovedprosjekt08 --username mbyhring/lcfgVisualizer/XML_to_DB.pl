#! /usr/bin/perl -w

use strict;

#This is the script which imports data from 
# the profile files and insert it into db.

my $configFile = "";

#TODO:
# 1. Read configFile
#    Check that we have  parameters (fields to import)
# 2. Test db connection
# 3. Make / modify tables
# 4. Test path to tarball
# 5. Try to unzip, then
# 6. For every file in /tmp:
# 7. Test valid xml format
# 8. Find the values and build hashes with key / value pairs
# 9. If the database already existed, we must select the values from db 
     # and compare it to the new data. 
#10.  If the data differs, Insert the new into the DB with modified_date.
