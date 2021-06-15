#!/usr/bin/perl -wT
#McAfee uvscan updater script
#Non-official
#technion [at] lolware.net
#To setup for this script, run the following:
#[root@turbonegro uvscan]# useradd uvupdate
#[root@turbonegro uvscan]# chmod -R 775 /usr/local/uvscan
#[root@turbonegro uvscan]# mkdir /usr/local/uvscan/tmp-update
#[root@turbonegro uvscan]# chmod  770 /usr/local/uvscan/tmp-update
#[root@turbonegro uvscan]# chgrp -R uvupdate /usr/local/uvscan/

#These Perl modules are prerequisites. All exist on a default CentOS box.
use Fcntl ':mode';
use File::Path 2.07 'remove_tree';
use LWP::Simple;
use Digest::MD5;
use File::Copy;

use strict;

#Some variables to play with.
use constant TMPUPDATE => '/usr/local/uvscan/tmp-update';
use constant EXE => '/usr/local/uvscan/uvscan';
use constant INSTALL => '/usr/local/uvscan/';
use constant DOWNLOAD => 'http://download.nai.com/products/commonupdater/';

sub checkfolders(); #Ensures temp folder is locked down
sub getinis(); 	#Downloads avvdat.ini to memory, and returns dat versions
sub checkinstalled(); #Exists if current DAT is up to date
sub settemp();	#Creates a temp folder. Main tmp folder already secure. 
		#Why have a second? So there's no conflict with multiple runs.
sub download(); #Get the DAT .tar file
sub install();	#Unzips our download, tests it (the important bit).
		#Copies it upstream after running a --decompress.
sub cleanup();	#Removes temp folder

#Global safety
$ENV{'PATH'} = '/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

my ($datversion, $filename, $md5, $tmpfolder); #Yes they are globals. Deal with it.
umask(0022);
checkfolders();
getinis();
checkinstalled();
settemp();
download();
install(); 
cleanup();
print "Successful update is successful\n";

#Main flow ends here.

sub checkfolders() {
	die "Unacceptable user" if ($< == 0);

	die "I don't do symlinks" if ( -l TMPUPDATE );
	die "Inappropriate permissions on " . TMPUPDATE 
		if (!-d TMPUPDATE || !-w TMPUPDATE  );
	die "Stat failed. WTF?" unless my $mode = (stat(TMPUPDATE))[2] ;
	die "World accessible folder" unless (($mode & S_IRWXO) == 0); 
}

sub getinis() {

	my $ini = 
		get(DOWNLOAD . 'avvdat.ini');
	die "Failed to download ini" unless $ini;
	die "Invalid ini file" unless ($ini =~ /\[AVV-ZIP\](.*?)\[/s);
	$ini = $1;

	$ini =~ s/\r//g;
	die "Invalid ini file" unless ($ini =~
		/DATVersion=(\d*)\nFileName=(.*)\nFilePath=.*\nFileSize=.*MD5=(.*)\n/s);
	($datversion, $filename, $md5) = ($1, $2, $3);
	print "Info from Dat file: Dat $datversion File $filename MD5 $md5\n";
}

sub checkinstalled() {
	my $cmd = EXE . " --version";
	my $version = `$cmd`;
	die unless $version =~ /Dat set version: (\d{4})/;
	$version = $1;
	if ($version >= $datversion) {
		print "Version already up to date\n";
		exit;
	}

	print "Installed is $version, downloading $datversion..\n";
}

sub settemp() {

	my $time = scalar(localtime());
	$time = Digest::MD5::md5_hex($time);
	#Aware this is not secure. It's not meant to be. 
	#It's meant to be unique.
	$tmpfolder = TMPUPDATE . "/$time";
	die "Failed to create tmpfolder" unless mkdir($tmpfolder, 0700);
}

sub download() {
	print "Downloading " . DOWNLOAD . "$filename\n";
	my $status = getstore(DOWNLOAD . $filename, "$tmpfolder/$filename");
	die "Error $status" unless is_success($status);
	
	open(FILE, "$tmpfolder/$filename") or die "Unable to hash download: $!";
	binmode(FILE);
	my $getmd5 = Digest::MD5->new->addfile(*FILE)->hexdigest;
	$getmd5 =~ s/\s//gs;	
	$md5 =~ s/\s//gs;	
	die "Invalid MD5 on download" unless ($md5 eq $getmd5);
}
sub install() {
	system("/usr/bin/unzip $tmpfolder/$filename -d $tmpfolder");
	die "Failed to execute unzip" if ($? == -1);
	system(EXE, "--DAT=$tmpfolder", "--decompress");
	die "Failed to execute decompress" if ($? == -1);
	copy("$tmpfolder/avvclean.dat", INSTALL);
	copy("$tmpfolder/avvnames.dat", INSTALL);
	copy("$tmpfolder/avvscan.dat", INSTALL);
	copy("$tmpfolder/runtime.dat", INSTALL);
}

sub cleanup() {
	remove_tree($tmpfolder, 0, 1); #Not verbose, safe
}
