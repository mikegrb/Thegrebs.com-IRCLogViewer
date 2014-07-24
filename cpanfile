requires 'perl', '5.010';

requires 'Mojolicious';
requires 'Date::Calc';
requires 'URI::Find';
requires 'HTML::CalendarMonth';


on test => sub {
    requires 'Test::More', '0.88';
};
