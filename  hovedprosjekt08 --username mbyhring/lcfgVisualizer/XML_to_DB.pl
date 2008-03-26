#! /usr/bin/perl -w
use strict;
use lib 'lib';
use DBMETODER;
#use CGI qw/:standard/;


#This is the script which imports data from 
# the profile files and insert it into db.

my $cfgFile = 'cfg/vcsd.cfg'; #Config-file
my %config;
open(CONFIG, "$cfgFile") || die "Can't open vcsd.cfg --> $!\nPlease make sure you have a config-file in cfg/ , or make a new one \n";
while (<CONFIG>) {
    chomp;
    s/#.*//; # Remove comments
    s/^\s+//; # Remove opening whitespace
    s/\s+$//;  # Remove closing whitespace
    next unless length;
    my ($key, $value) = split(/\s*=\s*/, $_, 2);
    $config{$key} = $value;
}

my $db = delete $config{"db"};
my $dbType = delete $config{"dbtype"};
my $hostname = delete $config{"dbhost"};
my $username = delete $config{"dbuser"};
my $password = delete $config{"dbpass"};
my $port = delete $config{"dbport"};
#print "$db \n";
#print "$hostname \n";

DBMETODER->setConnectionInfo($db,$hostname,$username,$password);

my $result = DBMETODER->testDB();

unless( $result)
{
	print "Database OK! \n"
}
#die;
foreach my $key (sort keys %config)
{
	
	print "$key : $config{$key}\n";
}


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
