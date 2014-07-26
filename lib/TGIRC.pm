package TGIRC;
use Mojo::Base 'Mojolicious';

use 5.010;
use strict;
use warnings;

use TheGrebs::IRC::Logs;

sub startup {
    my $self = shift;

    my $config = $self->plugin('config', { file => 'TGIRC.conf'});

    $TheGrebs::IRC::Logs::log_path = $ENV{TGIRC_LOG_PATH} || $config->{log_path};

    # Routes
    my $r = $self->routes;

    $r->route('/:channel/:year/:month/:day')->to(controller => 'channel', action => 'view');
    $r->route('/:channel/:year/:month')->to(controller => 'channel', action => 'month');
    $r->route('/:channel/:year')->to(controller => 'channel', action => 'year');
    $r->route('/:channel')->to( controller => 'channel', action => 'info' );

    $r->route('/')->to( cb => sub { shift->render( template => 'index' ) } );

}

1;
