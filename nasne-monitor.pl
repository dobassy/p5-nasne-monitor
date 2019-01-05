#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $gf_site   = $ENV{GF_SITE} || "http://set-me.local"; 
my $nasne_uri = $ENV{NASNE_URI} or die "you must set a NASNE_URI";

my $ua = LWP::UserAgent->new;

sub post2growthforecast {
    my ( $service, $section, $graph_name, $value, $option ) = @_;

    my $api = "$gf_site/api/$service/$section/$graph_name";

    die 'undefined graph value. script exit.' unless defined $value;

    sleep 1;
    my $res = $ua->post(
        $api,
        {
            number => $value,
        }
    );
}

sub lwp_get_and_reshash {
    my ($path) = @_;

    my $url = sprintf( "%s:64210%s", $nasne_uri, $path );
    return JSON->new->decode( $ua->get($url)->content );
}

sub get_hddinfo {
    my $json_res = lwp_get_and_reshash("/status/HDDInfoGet?id=0");

    return {
        usedVolumeSize  => $json_res->{HDD}->{usedVolumeSize},
        totalVolumeSize => $json_res->{HDD}->{totalVolumeSize},
        freeVolumeSize  => $json_res->{HDD}->{freeVolumeSize}
    };
}

sub get_status {
    my ( $recording, $playing, $live );

    my $json_res;

    $json_res = lwp_get_and_reshash("/status/boxStatusListGet");
    $recording = ( $json_res->{tvTimerInfoStatus}->{nowId} ) ? 1 : 0;

    $json_res = lwp_get_and_reshash("/status/dtcpipClientListGet");
    $playing = ( $json_res->{client} ) ? 1 : 0;

    return {
        rec  => $recording,
        play => $playing,
    };
}

my $service_name = "Entertaiment";
my $section_name = "nasne";

my $hdd = get_hddinfo();

post2growthforecast( $service_name, "nasne", "volumeSize_used",
    $hdd->{usedVolumeSize} );
post2growthforecast( $service_name, "nasne", "volumeSize_used_percent",
    int( ( $hdd->{usedVolumeSize} / $hdd->{totalVolumeSize} * 100 ) + 0.9 ) );

post2growthforecast( $service_name, "nasne", "volumeSize_free",
    $hdd->{freeVolumeSize} );
post2growthforecast( $service_name, "nasne", "volumeSize_free_percent",
    int( ( $hdd->{freeVolumeSize} / $hdd->{totalVolumeSize} * 100 ) + 0.9 ) );

my $status = get_status();
post2growthforecast( $service_name, "nasne", "status_play", $status->{play} );
post2growthforecast( $service_name, "nasne", "status_rec",  $status->{rec} );
