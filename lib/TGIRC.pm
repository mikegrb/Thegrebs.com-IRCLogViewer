package TGIRC;
use Mojo::Base 'Mojolicious';

use 5.010;
use strict;
use warnings;

use POSIX;
use TheGrebs::IRC::Logs;

our ( $allowed_channels, $channels_on_index );

sub startup {
    my $self = shift;

    my $config = $self->plugin('config', { file => 'TGIRC.conf'});

    $TheGrebs::IRC::Logs::log_path = $ENV{TGIRC_LOG_PATH} || $config->{log_path};
    $allowed_channels = $ENV{TGIRC_CHANNELS} ? [ split /,/, $ENV{TGIRC_CHANNELS} ] : $config->{allowed_channels};
    $channels_on_index
      = $ENV{TGIRC_CHANNELS_INDEX} ? [ split /,/, $ENV{TGIRC_CHANNELS_INDEX} ] : $config->{channels_on_index};

    # Routes
    my $r = $self->routes;

    $r->route('/:channel/:year/:month/:day')->to(controller => 'channel', action => 'view');
    $r->route('/:channel/:year/:month')->to(controller => 'channel', action => 'month');
    $r->route('/:channel/:year')->to(controller => 'channel', action => 'year');
    $r->route('/:channel')->to( controller => 'channel', action => 'info' );

    $r->route('/')->to( cb => sub { shift->render( template => 'index' ) } );

}

1;
