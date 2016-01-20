#!/usr/bin/perl
#
# integrity_tool.pl
#
# A simple tool to check media files in given folders
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2005-2016 Richard Stride <fury@nexxus.net>

# include custom lib
require 'lib/perl/md5.pm';

# define default directories
@dirs = (  
	   "/vol/movies", 
           "/vol/tv" 
        );

# look for arguments
if ( ! $ARGV[0] ) {
    print "must have arg: verify|create\n";
    exit;
}
# take 2nd arg as a dir if it exists
if ( -d "$ARGV[1]" ) { 
    @dirs = ( $ARGV[1] );
}

# are we going to VERIFY?
if ( $ARGV[0] eq "verify" ) {
    foreach $dir (@dirs) {
	verify_integrity($dir);
    }
}

# are we going to CHECKSUM?
if ( $ARGV[0] eq "create" ) {
    foreach $dir (@dirs) {
	sum_directory( $dir );
    }
}
