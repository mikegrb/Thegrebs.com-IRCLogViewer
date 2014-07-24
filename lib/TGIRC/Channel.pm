package TGIRC::Channel;

use strict;
use warnings;
use 5.010;

use base 'Mojolicious::Controller';

use Data::Dumper;
use Date::Calc 'Add_Delta_Days';

sub info {
    my $self = shift;
    $self->_validate_channel();
    my $channel = $self->stash('channel');

    my %years;
    $years{ ( split /\./ )[0] }++
        for @{ TheGrebs::IRC::Logs::get_available_logs($channel) };
    $self->stash( years => [ sort keys %years ] );

}

sub year {
    my $self = shift;
    $self->_validate_channel();
    my $channel = $self->stash('channel');
    my $year    = $self->stash('year');

    $year = undef unless $year && $year =~ /^\d{4}$/;

    unless ($year) {
        $self->render(
            text   => 'Somebody tried to set us up the bomb.',
            status => '403'
        );
        return;
    }

    my $this_month = (localtime)[4] + 1 if (localtime)[5] + 1900 == $year;
    my @months_html;
    for my $month ( 1 .. 12 ) {
        last if $this_month and $month > $this_month;
        push @months_html,
            TheGrebs::IRC::Logs::get_channel_month_html( $channel, $year,
            $month );
    }

    $self->stash( months_html => [@months_html] );
}

sub month {
    my $self = shift;
    $self->_validate_channel();
    my $channel = $self->stash('channel');
    my $year    = $self->stash('year');
    my $month   = $self->stash('month');

    $year = undef unless $year && $year =~ /^\d{4}$/;
    $month = undef unless $year && $month && $month =~ /^\d{2}$/;

    $self->stash(
        month_html => TheGrebs::IRC::Logs::get_channel_month_html(
            $channel, $year, $month
        ) );
}

sub view {
    my $self = shift;
    $self->_validate_channel();

    my $channel = $self->stash('channel');
    my $year    = $self->stash('year');
    my $month   = $self->stash('month');
    my $day     = $self->stash('day');

    unless ( $year
        && $month
        && $day
        && $year  =~ /^\d{4}$/
        && $month =~ /^\d{2}$/
        && $day   =~ /^\d{2}$/ )
    {   $self->render(
            text   => 'Somebody tried to set us up the bomb.',
            status => 403
        );
        return;
    }

    my $file_path = $self->_get_file_path( $channel, $year, $month, $day );
    $self->render( text => 'Sorry, 404 :<', status => 404 ) unless -e $file_path;

    $self->_stash_rel_day_link( $channel, $year, $month, $day, 'next_lnk', 1 );
    $self->_stash_rel_day_link( $channel, $year, $month, $day, 'prev_lnk', -1 );

    $self->stash( parsed_lines =>
            TheGrebs::IRC::Logs::get_log_html( $channel, $file_path ) );
}

sub _stash_rel_day_link {
    my ( $self, $channel, $year, $month, $day, $stash_name, $diff ) = @_;
    my @date = Add_Delta_Days( $year, $month, $day, $diff );
    my @result = TheGrebs::IRC::Logs::get_available_logs( $channel, @date );
    return $self->stash( $stash_name => undef) unless @{$result[0]};
    return $self->stash( $stash_name => sprintf '/%s/%4i/%02i/%02i', $channel, @date );
}

sub _get_file_path {
    my ( $self, $channel, $year, $month, $day ) = @_;
    return
          $self->stash('config')->{log_path} . '/#' 
        . $channel . '/'
        . join '.',
        $year, $month, $day;
}

sub _validate_channel {
    my $self    = shift;
    my $channel = $self->stash('channel');
    $self->render( text => "not allowed" )
        unless $channel ~~ $self->stash('config')->{allowed_channels};
}

1;
