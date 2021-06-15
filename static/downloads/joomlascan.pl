#!/usr/bin/perl -wT
#Joomla version scanner
#Suitable for use on cPanel and other hosted server systems
#ver 1.0 - 22/05/2012
#technion@lolware.net

use LWP::UserAgent;

use strict;

sub latestjl();
sub gethosts($$@);
sub getaccount($);
sub lget($);

my $latestjlver = latestjl();
my $latestlegjlver = "1.5.1";

print "The latest version of Joomla is $latestjlver\n";
print "The latest version of the 1.5.x legacy train is $latestlegjlver\n";

my @file = </home/*/public_html/libraries/joomla/version.php>;
push(@file, </home/*/public_html/libraries/cms/version/version.php>);

unless (@file) {
    print "No Joomla installations found\n";
    exit;
}

gethosts( $latestjlver, $latestlegjlver, @file );


exit;    #Just pointing out we end here

sub gethosts($$@) {
    my ( $latest, $legacylatest, @myfile ) = @_;

    foreach my $vfile (@myfile) {
        open VF, $vfile or die "Failed to open $vfile: $!";
        my $release = undef;
        while (<VF>) {

            if (/RELEASE\s*=\s*'(\d+)/) {
                tr/[.0-9]//cd;
                $release = $_;
		next;
	    }

	    if(/DEV_LEVEL\s*=\s*'(\d+)/) {
		tr/[.0-9]//cd;
		my $dev = $_;
	        die "DEV without RELEASE" unless (defined $release);

                my $account = getaccount($vfile);
		my $version = "$release.$dev";
		if ( $version =~ /1.5/ ) {
		    print "  Account $account is running legacy 1.5.x version ";
                    ( $version eq $legacylatest )
                	? print " $version - UP TO DATE\n"
                	: print " $version - OUT OF DATE\n";
		} else {
		    print "  Account $account is running version ";
                    ( $version eq $latest )
                	? print " $version - UP TO DATE\n"
                	: print " $version - OUT OF DATE\n";
		}
                last;
            }
        }
        close VF;
    }
}

sub lget($) { 
    my $url = shift; 
    my $ua = LWP::UserAgent->new();
    $ua->agent('IE11 Beta'); 
    my $res = $ua->get($url, accept => 'text/html'); 
 
    die ("Could not retrieve $url: " . $res->status_line) 
		unless($res->is_success); 
    return $res->content; 
} 

sub latestjl() {
    my $apiget = lget('http://update.joomla.org/core/list.xml');
    die "Invalid return from Joomla website"
    	unless ( $apiget =~ /version="(\d\.\d\.\d+)"/ );
    return $1;

}


sub getaccount($) {
    my $path = $_[0];
    die "Invalid path given" unless ( $path =~ /home\/(.*)\/public_html/ );
    return $1;
}
