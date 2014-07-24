package TheGrebs::IRC::Logs;

use 5.010;

use warnings;
use strict;

use URI::Find;
use Data::Dumper;
use HTML::CalendarMonth;

our $log_path = '/var/log/irc';

sub get_available_logs {
    my ( $channel, $year, $month, $day ) = @_;

    my $channel_glob = my $channel_path = $log_path . '/#' . $channel . '/';
    $channel_glob .= $year if $year;
    $channel_glob .= sprintf '.%02i.', $month if $month;
    $channel_glob .= sprintf '%02i',    $day   if $day;
    $channel_glob .= '*';

    return [ map { s/^\Q$channel_path\E//; $_ } glob($channel_glob) ];
}

sub get_channel_month_html {
    my ( $channel, $year, $month, $full_days ) = @_;

    $month = sprintf '%02i', $month;
    my $link = "/$channel/$year/$month/";
    $full_days ||= -1;

    my $c = HTML::CalendarMonth->new(
        full_days => $full_days,
        year      => $year,
        month     => $month,
    );

    my %avail_days = map { $_ = ( split /\./ )[2]; s/^0//; $_ => 1 }
        @{ get_available_logs( $channel, $year, $month ) };

    for my $day ( $c->days() ) {
        next unless exists $avail_days{$day};
        $c->item($day)
            ->wrap_content(
            HTML::Element->new( 'a', href => $link . sprintf '%02i', $day ) );
    }

    return $c->as_HTML;
}

sub get_log_html {
    my ( $channel, $logfile ) = @_;

    open( my $fh, '<:encoding(UTF-8)', $logfile )
        or die "Couldn't open logfile $logfile: $!";

    my @response;
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return qq|<a href="$uri">$orig_uri</a>|;
        } );

    for (<$fh>) {
        next if (/\@$channel/o);                          # wallops
        next if m/is ".*?" on ([+@]?#\S+\s?)*$/o;    # joininfo
        chomp;

        s/^(\d{2}:\d{2}) <([+@]?) (\S+)>/$1 <$2$3>/o;     # standardize format

        # TODO html encode entities in place of next two
        s/</\&lt\;/go;                                    # html escaping
        s/>/\&gt\;/go;                                    # html escaping

        s|^(\d{2}:\d{2}) \* (\S+) (.*)|$1 * <b>$2</b> $3|o;    # actions

        my ( $time, $nick, $text ) = split( / /, $_, 3 );
        $nick .= $1 if ( $text =~ s/^\s+(\S+)\s?\|//o );       # unknown?
        $nick = '---' if $nick eq '---|';    # log open/log closed

        $time = qq{<a name="$time" href="#$time">$time</a>};    # time links
        $finder->find( \$text );                                # links in text

        my $tclass;
        given ($text) {
            when (/^\S+ \[.*?\] has joined \#/o)     { $tclass = 'join' }
            when (/^\S+ \[.*?\] has quit \[.*?\]$/o) { $tclass = 'quit' }
            when (/^\S+ \[.*?\] has left \#/o)       { $tclass = 'part' }
            default                                  { $tclass = 'irctxt' }
        }
        push @response, [ $time, $nick, $tclass, $text ];
    }

    # change last a name to end
    $response[$#response][0] =~ s|="(#?)[^"]+"|="$1end"|g;

    return \@response;
}

1;
