#! c:\Perl\bin\perl.exe

use strict;
use IO::All;
use Getopt::Long;
use POSIX;
use DateTime;
use File::Copy qw(copy);
use File::Path qw(rmtree);
use DBI;

#FOR VERSION AND BUILDDATE
my $version = '1.1';
my $build = '20201118';
my ($DIR, $FILE, $osversion, $bmpcounter, $odabspathname, $commandlineslash, @contents, $fnamekey, %fname, %fnamelookup, %originalfilepath, $dataoutputdir, $rebuiltoutputdir, %counts, @matches, @uniqmatches, %matchesinhash, $filecounter);
my (@tbmatches, @tbuniqmatches, $tbfilecounter, $tbfilecounter, %tbcorrelatedfiles, %tboriginalfilepath);
my $onelessvalue=0;
my $tbonelessvalue=0;
my %correlatedfiles;
my $lrcorrelatedfilename="LRFile1";
my $tbcorrelatedfilename="TBFile1";
my @options=(
	'source=s'	=>	"source directory to parse",
	'output=s'		=>	"directory output will be saved to",
	'info'			=>	"	shows script information",
);
die &usage if (@ARGV == 0); #A nice die at usage



# Getopt::Long stuff happens here
my @getopt_opts;
for(my $i =0;$i<@options;$i+=2){
	push @getopt_opts,$options[$i];
}
%Getopt::Long::options = ();
$Getopt::Long::autoabbrev=1;
&Getopt::Long::GetOptions( \%Getopt::Long::options,@getopt_opts) or &usage;

my $dirname=$Getopt::Long::options{source} if (defined $Getopt::Long::options{source}); #Looks to see if source is defined
my $outputdir=$Getopt::Long::options{output} if (defined $Getopt::Long::options{output}); #Looks to see if output is defined
die &nosource if (not defined $Getopt::Long::options{source}); #Dies at info if info is defined
die &nooutput if (not defined $Getopt::Long::options{output}); #Dies at info if info is defined
die &info if (defined $Getopt::Long::options{info}); #Dies at info if info is defined

#Determines Operating System, and as such, makes the slashes go the proper way
my $ostype=$^O;
if (($ostype =~ /darwin/i) || ($ostype =~ /linux/i)) #This is if the OS is detected as linux or MacOS
{
	print STDERR "\nOperating System is listed as $ostype\nFound the funky slashes\n";
	$commandlineslash='/';
	my $macuxmagickcheck=`magick -version`; #Checks to see if the imagemagick alias exists on the system
	if ($macuxmagickcheck =~ /License: http/) #Pattern matching the output
	{
		print STDERR "\nImagemagick is installed on this system. Continuing with script\n"; #Yup
	}
	else
	{
		print STDERR "\nImagemagick is NOT installed on this system. \nPlease visit https://imagemagick.org and install imagemagick\n\n"; #Nope Nope Nope
		exit (-1); #A clean exit
	}
}
elsif ($ostype =~ /MSWin32/)
{
	print STDERR "\nOperating System is listed as $ostype\nFound the Windows slashes\n";
	$commandlineslash='\\';
	my $macuxmagickcheck=`magick -version`; #Checks to see if the imagemagick alias exists on the system
	if ($macuxmagickcheck =~ /License: http/) #Pattern matching the output
	{
		print STDERR "\nImagemagick is installed on this system. Continuing with script\n"; #Yup
	}
	else
	{
		print STDERR "\nImagemagick is NOT installed on this system. \nPlease visit https://imagemagick.org and install imagemagick\n\n"; #Nope Nope Nope
		exit (-1); #A clean exit
	}
}
else
{
	print STDERR "\nOperating System is listed as $ostype\nThis script will exit due to unsupported operating system\n\n";
	exit (-1);
}

if (defined $Getopt::Long::options{source})
{
	my $io = io($dirname);
	@contents= $io->all_files(0); #Recursively, read all the files in the directory
}

if (defined $Getopt::Long::options{output})
{
	# My output directory stuff will go in here
	my $odio = io($outputdir);
	$odabspathname=io($odio)->absolute->pathname; #IO All Pathname
	if (-e "$odabspathname" and -d "$odabspathname") #Testing to see if output directory exists. If so, we exit the script
	{
    print STDERR "\n***** WARNING! *****\nDirectory $outputdir found under the path $odabspathname\n***** WARNING ! *****\n\nPlease specify a directory that does not already exist!\nThis script will now exit.\n\n";
		exit(-1); #Clean exit
	}
	else
	{
		#The directory check passed. So now we will create the output directories. With another test to ensure that we can read/write to the directory in that path.
		$dataoutputdir="$odabspathname"."$commandlineslash"."Data"."$commandlineslash"; #Creating data directory to save bitmap image segments to
		$rebuiltoutputdir="$odabspathname"."$commandlineslash"."Rebuilt"."$commandlineslash"; #Creating data directory to rebuilt images
		mkdir("$odabspathname") or die "Can't create \"$odabspathname\"\n"; #Creating the raw output directory
		mkdir("$dataoutputdir") or die "Can't create \"$dataoutputdir\"\n"; #Creating the data output directory
		mkdir("$rebuiltoutputdir") or die "Can't create \"$rebuiltoutputdir\"\n"; #Creating the rebuilt output directory
		if ((-e "$odabspathname" and -d "$odabspathname")and(-e "$dataoutputdir" and -d "$dataoutputdir")and(-e "$rebuiltoutputdir" and -d "$rebuiltoutputdir")) #Double check to make sure directory now exists. Just to be safe
		{
			print STDERR "\n***** Created directory $outputdir under the path $odabspathname\n";
			print STDERR "***** Created directory $dataoutputdir under the path $dataoutputdir\n";
			print STDERR "***** Created directory $rebuiltoutputdir under the path $rebuiltoutputdir\n";

		}
		else
		{
			print STDERR "\n!!!!! Script encountered an error trying to create $outputdir\nunder the path $odabspathname\n***** or *****\n";
			print STDERR "\n!!!!! Script encountered an error trying to create $dataoutputdir\n***** or *****\n";
			print STDERR "\n!!!!! Script encountered an error trying to create $rebuiltoutputdir\n";
			print STDERR "\n!!!!! The script will now exit.\n\n";
			exit(-1); #Clean exit
		}
		#Now the checks are done, and we can continue! Also, Python sucks
	}
}
#This is where we open up the SQLite database in memory only (for now, may change to write it to disk eventually)
my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:");
$dbh->do("CREATE TABLE IF NOT EXISTS TOPFILES (id INTEGER PRIMARY KEY, TOPFILENAME VARCHAR(255), TOP_COLORS VARCHAR(255), TOP_RED_STDDEV VARCHAR(255), TOP_GREEN_STDDEV VARCHAR(255), TOP_BLUE_STDDEV VARCHAR(255))");
$dbh->do("CREATE TABLE IF NOT EXISTS BOTTOMFILES (id INTEGER PRIMARY KEY, BOTTOMFILENAME VARCHAR(255), BOTTOM_COLORS VARCHAR(255), BOTTOM_RED_STDDEV VARCHAR(255), BOTTOM_GREEN_STDDEV VARCHAR(255), BOTTOM_BLUE_STDDEV VARCHAR(255))");
$dbh->do("CREATE TABLE IF NOT EXISTS LEFTFILES (id INTEGER PRIMARY KEY, LEFTFILENAME VARCHAR(255), LEFT_COLORS VARCHAR(255), LEFT_RED_STDDEV VARCHAR(255), LEFT_GREEN_STDDEV VARCHAR(255), LEFT_BLUE_STDDEV VARCHAR(255))");
$dbh->do("CREATE TABLE IF NOT EXISTS RIGHTFILES (id INTEGER PRIMARY KEY, RIGHTFILENAME VARCHAR(255), RIGHT_COLORS VARCHAR(255), RIGHT_RED_STDDEV VARCHAR(255), RIGHT_GREEN_STDDEV VARCHAR(255), RIGHT_BLUE_STDDEV VARCHAR(255))");

#This part reads in each of the filenames for us to process
foreach my $content(@contents)
{
	my $filename = $content->filename; #IO All-filename
	my $abspathname=io($content)->absolute->pathname; #IO All Pathname
	$originalfilepath{$filename} = $abspathname;
	open($FILE, "$abspathname") || die "Cannot open $content $!\n";
	my $data = do {local $/; binmode $FILE; <$FILE>};
	close($FILE);
	my $header=substr($data,0,4);
	if ( ($header !~ /BM../) || ($filename =~/_collage/) ) #If this is not the first line, we are going to skip it. Also skipping "collage" bitmap file(s)
	{
		print STDERR "\nSkipping $abspathname, does not appear to be valid bitmap file\n"; #We skip it if it does not have the proper header
	}
	else
	{
		#The awesome part of this program goes here!
		print STDERR "\n***** Processing $abspathname\n";
		#Frst, we just imagemagick to determine the verbose details of the file
		my $imagemagickdata=`magick identify -verbose -quiet "$abspathname"`;
		#Second, we look at the Histogram data to ensure there is color varaince in the image
		if ($imagemagickdata=~/\x0a\x20\x20Histogram\x3a\x0a([\w\W]+?)\x0a\x20\x20Rendering intent\x3a/)
		{
			my $histogram=$1; #The results of the above regex looking for Histogram data
			my $hgcolorcount = ((() = $histogram =~ /\x0a/g) +1); #Looking for the number of newlines in the histogram.
			if ($hgcolorcount <= 5) #We want to have at least five unique colors for our script
			{
				print STDERR "***** NOTICE: Histogram contains only $hgcolorcount color(s), moving to next file\n";
			}
			else
			{
				$fname{$filename}=$filename; #Pushing filename to hash for future lookups
				#We can now extract the top, bottom, left, and right from each of the images, since it passed the test(s)
				my $topfilenameoutput = $filename =~ s/\.bmp/-T\.bmp/gr;
				my $bottomfilenameoutput= $filename =~ s/\.bmp/-B\.bmp/gr;
				my $leftfilenameoutput= $filename =~ s/\.bmp/-L\.bmp/gr;
				my $rightfilenameoutput= $filename =~ s/\.bmp/-R\.bmp/gr;
				#This is where we test to see what the height and width of the tile is. Usually it will be 64 x 64, but not always
				# We have to do this in the loop, because the values can (and do) change
				my $tilewidthstring = substr($data,18,2); #Getting the width
				my $tileheightstring = substr($data,22,2); #Getting the height
				my $twval=unpack 'n*', $tilewidthstring;
				my $thval=unpack 'n*', $tileheightstring;
				my $tilewidth=($twval / 256);
				my $tileheight=($thval / 256);
				my $tilewidthminusfive=($tilewidth - 5);
				my $tileheightminusfive=($tileheight -5);
				#Now we extract the top slice
				my $topextraction=`magick -extract "$tilewidth"x5+00+00 -quiet "$abspathname" "$dataoutputdir$topfilenameoutput"`;
				my $topimagemagickdata=`magick identify -verbose -quiet "$dataoutputdir$topfilenameoutput"`;
				#We identfy the key elements of the top image data chunk
					my ($topcolors) = $topimagemagickdata =~ /\x0a\x20\x20Colors:\x20([\d]+?)\x0a/; #Finding out the color count
					if ($topcolors >=2)
					{
						#Now We find the Red, Green, and Blue standard deviations
						my ($topredstddev, $topgreenstddev, $topbluestddev) = $topimagemagickdata =~ /\x0a\x20\x20\x20\x20Red:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Green:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Blue:[\w\W]+?standard deviation:\x20([\d.]+?)\x20/; #Finding out the color count
						$dbh->do("INSERT INTO TOPFILES (TOPFILENAME, TOP_COLORS, TOP_RED_STDDEV, TOP_GREEN_STDDEV, TOP_BLUE_STDDEV) VALUES (?,?,?,?,?)", undef, $filename, $topcolors, $topredstddev, $topgreenstddev, $topbluestddev);
					}
				my $bottomextraction=`magick -extract "$tilewidth"x5+00+"$tileheightminusfive" -quiet "$abspathname" "$dataoutputdir$bottomfilenameoutput"`;
				my $bottomimagemagickdata=`magick identify -verbose -quiet "$dataoutputdir$bottomfilenameoutput"`;
				#We identfy the key elements of the bottom image data chunk
					my ($bottomcolors) = $bottomimagemagickdata =~ /\x0a\x20\x20Colors:\x20([\d]+?)\x0a/; #Finding out the color count
					if ($bottomcolors >=2)
					{
						#Now We find the Red, Green, and Blue standard deviations
						my ($bottomredstddev, $bottomgreenstddev, $bottombluestddev) = $bottomimagemagickdata =~ /\x0a\x20\x20\x20\x20Red:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Green:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Blue:[\w\W]+?standard deviation:\x20([\d.]+?)\x20/; #Finding out the color count
						$dbh->do("INSERT INTO BOTTOMFILES (BOTTOMFILENAME, BOTTOM_COLORS, BOTTOM_RED_STDDEV, BOTTOM_GREEN_STDDEV, BOTTOM_BLUE_STDDEV) VALUES (?,?,?,?,?)", undef, $filename, $bottomcolors, $bottomredstddev, $bottomgreenstddev, $bottombluestddev);
					}
				my $leftextraction=`magick -extract 5x"$tileheight"+00+00 -quiet "$abspathname" "$dataoutputdir$leftfilenameoutput"`;
				my $leftimagemagickdata=`magick identify -verbose -quiet "$dataoutputdir$leftfilenameoutput"`;
				#We identfy the key elements of the left image data chunk
					my ($leftcolors) = $leftimagemagickdata =~ /\x0a\x20\x20Colors:\x20([\d]+?)\x0a/; #Finding out the color count
					if ($leftcolors >=2)
					{
						#Now We find the Red, Green, and Blue standard deviations
						my ($leftredstddev, $leftgreenstddev, $leftbluestddev) = $leftimagemagickdata =~ /\x0a\x20\x20\x20\x20Red:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Green:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Blue:[\w\W]+?standard deviation:\x20([\d.]+?)\x20/; #Finding out the color count
						$dbh->do("INSERT INTO LEFTFILES (LEFTFILENAME, LEFT_COLORS, LEFT_RED_STDDEV, LEFT_GREEN_STDDEV, LEFT_BLUE_STDDEV) VALUES (?,?,?,?,?)", undef, $filename, $leftcolors, $leftredstddev, $leftgreenstddev, $leftbluestddev);
					}
				my $rightextraction=`magick -extract 5x"$tileheight"+"$tilewidthminusfive"+00 -quiet "$abspathname" "$dataoutputdir$rightfilenameoutput"`;
				my $rightimagemagickdata=`magick identify -verbose -quiet "$dataoutputdir$rightfilenameoutput"`;
				#We identfy the key elements of the right image data chunk
					my ($rightcolors) = $rightimagemagickdata =~ /\x0a\x20\x20Colors:\x20([\d]+?)\x0a/; #Finding out the color count
					if ($rightcolors >=2)
					{
						#Now We find the Red, Green, and Blue standard deviations
						my ($rightredstddev, $rightgreenstddev, $rightbluestddev) = $rightimagemagickdata =~ /\x0a\x20\x20\x20\x20Red:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Green:[\w\W]+?standard deviation:\x20([\d.]+?)\x20[\w\W]+?Blue:[\w\W]+?standard deviation:\x20([\d.]+?)\x20/; #Finding out the color count
						$dbh->do("INSERT INTO RIGHTFILES (RIGHTFILENAME, RIGHT_COLORS, RIGHT_RED_STDDEV, RIGHT_GREEN_STDDEV, RIGHT_BLUE_STDDEV) VALUES (?,?,?,?,?)", undef, $filename, $rightcolors, $rightredstddev, $rightgreenstddev, $rightbluestddev);
					}
			}
		}
		else
		{
			print STDERR "\n***** WARNING: Imagemagick could not determine histogram variance of colors\nMoving to next file\n\n";
		}
	}
}

my $sql = 'SELECT
LEFTFILENAME,
LEFT_COLORS,
LEFT_RED_STDDEV,
LEFT_GREEN_STDDEV,
LEFT_BLUE_STDDEV,
RIGHTFILENAME,
RIGHT_COLORS,
RIGHT_RED_STDDEV,
RIGHT_GREEN_STDDEV,
RIGHT_BLUE_STDDEV
FROM LEFTFILES, RIGHTFILES
WHERE
(
(ABS
(SUBSTR(RIGHTFILENAME,15,4)) - (SUBSTR(LEFTFILENAME,15,4)) <= 20)
AND
(ABS
(SUBSTR(RIGHTFILENAME,15,4)) - (SUBSTR(LEFTFILENAME,15,4)) > 0)
)
AND
( (ABS(LEFT_COLORS - RIGHT_COLORS) <= 15) )
AND
(
( (ABS(LEFT_RED_STDDEV - RIGHT_RED_STDDEV) <= 10) ) AND
( (ABS(LEFT_BLUE_STDDEV - RIGHT_BLUE_STDDEV) <= 10) ) AND
( (ABS(LEFT_GREEN_STDDEV - RIGHT_GREEN_STDDEV) <= 10) )
)';
my $sth = $dbh->prepare($sql);
$sth->execute();
while(my @row = $sth->fetchrow_array())
{
			push @matches, $row[0];
			push @matches, $row[5];
			my $twotilefilename=$row[5].$row[0];
			my $leftrealfilepath =	$originalfilepath{$row[0]};
			my $rightrealfilepath = $originalfilepath{$row[5]};
}

#This is where we print the left to right comparison matches
my %seen = ();
foreach my $item (@matches)
{
    push(@uniqmatches, $item) unless $seen{$item}++;
}
my @sorteduniqmatches=sort(@uniqmatches);
foreach my $uniquematch (@sorteduniqmatches)
{
	 	$filecounter=substr($uniquematch,14,4);
		if (($onelessvalue == 0) || ($filecounter - $onelessvalue == 1))
		{
			$correlatedfiles{$uniquematch} = $lrcorrelatedfilename;
			$onelessvalue=$filecounter;
		}
		else
		{
			my $nextfilenamenumber=substr($lrcorrelatedfilename,6,100);
			$nextfilenamenumber=($nextfilenamenumber + 1);
			my $nextfilename=substr($lrcorrelatedfilename,0,6).$nextfilenamenumber;
			$lrcorrelatedfilename=$nextfilename;
			$correlatedfiles{$uniquematch} = $lrcorrelatedfilename;
			$onelessvalue=$filecounter;
		}
}

my @rawuniquefinalfiles;
my %seenfinalfiles;
foreach my $value (sort {$a cmp $b} values %correlatedfiles)
{
	push (@rawuniquefinalfiles, $value) unless $seenfinalfiles{$value}++;
}
my @uniquefinalfiles = sort {substr($a,6) <=> substr($b,6)} @rawuniquefinalfiles;
foreach my $uniqfinalfile (@uniquefinalfiles)
{
	my @alluniquefinalfiles = grep { $correlatedfiles{$_} eq $uniqfinalfile } keys %correlatedfiles;
	my $finalcount=@alluniquefinalfiles;
	my @tileswithfullfilepaths;
	if (($finalcount >= 4) && ($finalcount <= 25))
	{
		# print "File $uniqfinalfile will have total $finalcount files, containing the files\n";
		my $reconstructiondirectory=$rebuiltoutputdir.$uniqfinalfile;
		mkdir("$reconstructiondirectory") or die "Can't create \"$reconstructiondirectory\"\n"; #Creating the Directory for each rebuilt file, to manually reconstruct if need be
		foreach my $processedtile (@alluniquefinalfiles)
		{
			# print "Processing $processedtile\n";
			my $realfilepath=	"\"" . $originalfilepath{$processedtile} . "\"";
			push (@tileswithfullfilepaths, $realfilepath);
		}
		my @sortedtileswithfullfilepaths = sort { substr($a,-9,4) <=> substr($b,-9,4)} @tileswithfullfilepaths;
		# print "Testing: @sortedtileswithfullfilepaths\n";
		my $rebuildingthelrmatching=`magick convert -quiet @sortedtileswithfullfilepaths +append "$rebuiltoutputdir$uniqfinalfile.bmp" `;
		$bmpcounter=$bmpcounter+1;
		foreach my $lastfile (@sortedtileswithfullfilepaths)
		{
			my $filecopy=copy ($lastfile, $reconstructiondirectory); #Copying file to new directory, for rebuilding purposes
		}
	}
}

$dbh->sqlite_backup_to_file( "$odabspathname"."$commandlineslash"."SQLitedb.db" ); #Copies database from memory to a file.


#Cleanup, deleting the "Data" output directory (this is last, after the database gets saved)
print STDERR "\nNow deleting the directory $dataoutputdir\n";
print STDERR "\nA total of $bmpcounter files have been copied\n";
my $datadirdeletion=rmtree(["$dataoutputdir"]);


my $end = time(); #When the script ended
my $runtime = ($end - $^T); #$^T is when the script started. Who knew?

printf STDERR ("\nThe script took %02d:%02d:%02d to complete\n\n", int ($runtime/3600), int ( ($runtime % 3600) / 60), int ($runtime % 60) ); #Mathiness to compute total run time

exit (-1); #A clean exit

#Usage subroutine
sub usage() #This is where the usage statement goes. Hooray usage!
{
	my %defs=(
		s => "string",
	);
	print "\n";
	print "This script will parse extracted RDP Bitmap Cache directory(ies)\n";
	print "And attempt to rebuild some of the screenshots automatically\n";
	print "\n\n";
	print "A user is required to extract the bmp files already, best done by using the\nscript from\n";
	print "https://github.com/ANSSI-FR/bmc-tools\n";
	print "\nUsage example:\n\n";
	print "rdpieces.pl -source \"RDPBitmapFiles\" -output \"Rebuilt Images\"\n";
	print "\nOptions\n";
	for(my $c=0;$c<@options;$c+=2){
		my $arg="";
		my $exp=$options[$c+1];
		if($options[$c]=~s/([=:])([siof])$//){
			$arg="<".$defs{$2}.">" if $1 eq "=";
			$arg="[".$defs{$2}."]" if $1 eq ":";
			}
		$arg="(flag)" unless $arg;
		printf "	-%-15s $arg",$options[$c];
		print "\t",$exp if defined $exp;
		print "\n";
		}
		print "\n";
		print &changes;
		print &info;
		exit (-1);
}
#No source subroutine
sub nosource ()
{
	print STDERR "\n***** NOTICE *****\nPlease define a source directory\nThe script will now exit\n***** NOTICE *****\n\n";
	exit (-1);
}
#No output subroutine
sub nooutput ()
{
	print STDERR "\n***** NOTICE *****\nPlease define an output directory\nThe script will now exit\n***** NOTICE *****\n\n";
	exit (-1);
}
#Changes subroutine
sub changes ()
{
	print "\n\n";
	print "             ==========CHANGES/REVISIONS==========           \n";
	print "                 Version: $version (Build $build)            \n";
	print "      - Refined bitmap header processing/error checking      \n";
	print "      - Changed height/width to defined value, rather than   \n";
	print "            assumed value of 64 and 64, respectively         \n";
	print "            ========== Version 1.0 ==========              \n";
	print "                 Version: 1.0 (Build 20200511)            \n";
	print "            First version of script. Python sucks            \n";


	my $version = '1.0';
	my $build = '20200511';

	print &info;
}
#Info subroutine
sub info ()
{
	print "\n\nScript Information: rdpieces.pl\n";
	print "Version: $version (Build $build)\n";
	print "Author: Brian Moran (\@brianjmoran)\n";
	print "Email: (brian\@brimorlabs.com)\n";
	print "\n----- End of Line -----\n\n";
	exit (-1);
}
