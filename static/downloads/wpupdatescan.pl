#!/usr/bin/perl -wT
#Wordpress version scanner
#Suitable for use on cPanel and other hosted server systems
#ver 1.0 - 22/05/2012
#technion@lolware.net

use LWP::Simple;

use strict;

sub latestwp();
sub gethosts($@);
sub getaccount($);

my $latestwpver = latestwp;

print "The latest version of Wordpress is $latestwpver\n";

my @file = </home/*/public_html/wp-includes/version.php>;

unless (@file) {
    print "No wordpress installations found\n";
    exit;
}

gethosts( $latestwpver, @file );

exit;    #Just pointing out we end here

sub gethosts($@) {
    my ( $latest, @myfile ) = @_;

    foreach my $vfile (@myfile) {
        open VF, $vfile or die "Failed to open $vfile: $!";
        while (<VF>) {
            if (/wp_version = /) {
                tr/[.0-9]//cd;
                my $version = $_;
                my $account = getaccount($vfile);
                ( $version eq $latest )
                  ? print "Account $account is running $version - UP TO DATE\n"
                  : print
                  "Account $account is running $version - OUT OF DATE\n";
                last;
            }
        }
        close VF;
    }
}

sub latestwp() {
    my $apiget = get('http://api.wordpress.org/core/version-check/1.2/');
    die "Failed to connect to Wordpress update API" unless $apiget;
    my @ver = grep( /^\d\.\d(\.\d)?/, split( /\n/, $apiget ) );
    die "Invalid return from Wordpress website" unless $ver[0];
    return $ver[0];

}

sub getaccount($) {
    my $path = $_[0];
    die "Invalid path given" unless ( $path =~ /home\/(.*)\/public_html/ );
    return $1;
}
