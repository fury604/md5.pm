#!/usr/bin/perl
#
# useful script for md5 summing 
# important files
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


# use case insensitive match /i
my $media_pattern = "\.avi|\.ogm|\.mpg|\.asf|.\mkv|\.flac|\.iso|\.mp4|\.wav|\.vob|\.m2ts|\.mp3|\.ts|\.dd";
my $md5cmd = "/usr/bin/md5sum";

#
# take a directory as an argument and
# evaluate all media files in it for 
# md5 sum files
#
sub sum_directory() {

    my $dir = shift;  # fully qualified
    my @files = `ls "$dir"`;

    foreach $file (@files) {
	chomp($file);
	# recursive nightmare!
	if ( -d "$dir/$file" ) {
	    sum_directory("$dir/$file");
	}
	# create md5 on all media files
	elsif ( file_matches($file,$dir) ) {
	    print "creating md5sum for $dir/$file\n";
	    create_md5($file,$dir);
	}
    }
}

#
# detemine if the given file
# is a media file
#
sub is_media_file {
    my $file = shift;

    if ( "$file" =~ /$media_pattern/i ) {
	return 1;
    }

    return 0;
}



#
# return 1 if a $dir/$file path is:
# a) media file
# b) lacking a .md5 checksum file
# otherwise return 0
#
sub file_matches {

    my $file = shift;
    my $dir = shift;
    my $is_media_file = 0;
    my $is_not_summed = 0;

    if ( ! -e "$dir/$file" ) {
	# special case
	return 1;
    }
    if ( ("$file" =~ /\md5/)  ) {
	# do not evaluate sum file
    }
    else {
	# is media file ?
	if ( "$file" =~ /$media_pattern/i ) {
	    $is_media_file = 1;
	}
	# is not .md5 sum file in the .md5 dir
	if ( ! -e "$dir/md5/$file.md5" ) {
	    $is_not_summed = 1;
	}
    }

    #print "$is_media_file : $is_not_summed\n";

    if ( $is_media_file && $is_not_summed ) {
	return 1;
    }

    return 0;
}

#
# create an md5 sum file for
# the given $file in $dir
#
sub create_md5() {

    my $file = shift;
    my $dir = shift;
    my $src = "$dir/$file";
    my $md5dir = "$dir/md5";
    my $dst = "$md5dir/$file.md5";

    if ( ! -e "$md5dir" ) {
	`mkdir "$md5dir"`;
    }

    my $tmp = `$md5cmd "$src"`;
    my @stuff = split /\s/, $tmp;
    $sum = $stuff[0];
    `echo $sum > "$dst"`;
}

#
# check the MD5 sum for a given
# file in a given dir
#
# return 1 if correct
# otherwise 0
#
sub checksum {

    my $file = shift;
    my $dir = shift;
    my $src = "$dir/$file";
    my $md5dir = "$dir/md5";
    my $dst = "$md5dir/$file.md5";
    my $csum = `cat "$dst"`;

    # uppercase weirdness, clean non printable crap
    $csum =~ s/\W+//g; 
    chomp($csum);

    #print "DEBUG: checking $dir/$file\n";

    my $tmp = `$md5cmd "$src"`;
    my @stuff = split /\s/, $tmp;
    $sum = $stuff[0];
    #print "DEBUG: calculated sum to be $sum\n";

    # lexical equality
    if ( lc($sum) eq lc($csum) ) {
	return 1;
    }
}

#
# verify all files under the given
# dir structure have not been changed
#
sub verify_integrity( $dir ) {

    my $dir = shift;

    # ensure we never process an md directory
    if ( $dir =~ /md5/ ) {
	return;
    }

    print "\nverifying files in $dir\n";
    @files = `ls "$dir"`;

    # we are given a dir so recurse 
    # through it and examine all files
    foreach $file ( @files ) {
	chomp($file);
	if ( -d "$dir/$file" ) {
	    # directory found, list all files 
            # push them onto the stack
	    #print "DEBUG: will verify directory $dir/$file\n";
	    my @cdir = `ls "$dir/$file"`;
	    for (@cdir) {
		if ( $_ !~ /md5/ ) {
		    push (@files, "$file/$_");
		}
	    }
	}
        else {
            # we always assume that we're at the top dir
	    my @dirbits = split /\//, "$dir/$file";
	    my $dirdepth = scalar @dirbits;

	    # reconstruct full path
	    my $end = pop @dirbits;
	    my $path = undef;
	    foreach my $part ( @dirbits ) {
		$path .= $part . "/" ;
	    }
	    chop($path);

	    # determine if this is a media file
	    if ( is_media_file( $end ) ) {
		verify_file( $path, $end );
	    }
        }  
    }
}

#
# verify the given file has a 
# valid MD5 checksum
#
sub verify_file( $dir, $file ) {

    my $dir = shift;
    my $file = shift;

    #print "DEBUG: $dir/$file \n";

    if ( -d "$dir/$file" ) {
	return;
    }

    # check this file lacks an MD5 sum
    if ( ! file_matches( "$file", "$dir" ) == 0 ) {
      print "ERROR: $dir/$file does not have MD5 sum!\n";
      return; 
    }

    my $ret = checksum($file,$dir);
    if ( $ret == 1 ) {
	#print "$dir/$file ok\n";
    }
    else {
	print "$dir/$file CORRUPT\n";
    }
}

