use v6;
use Test;

plan 6;


my $meta-file = 'META6.json';
my $version-meta;

for $meta-file.IO.lines -> $line {
    if $line ~~ / ^ \s* '"version"' \s* ':' \s* \" ( \d+ \. \d+ \. \d+ ) \" / {
        $version-meta = $0;
    }
}


my $pm-file = 'lib/Term/Choose.rakumod';
my $choose-pm;

for $pm-file.IO.lines -> $line {
    if $line ~~ / ':ver<' ( \d+ '.' \d+ '.' \d+ ) '>' / {
        $choose-pm = $0;
    }
}

my $linefold-file = 'lib/Term/Choose/LineFold.rakumod';
my $linefold-pm;

for $linefold-file.IO.lines -> $line {
    if $line ~~ / ':ver<' ( \d+ '.' \d+ '.' \d+ ) '>' / {
        $linefold-pm = $0;
    }
}


my $change-file = 'Changes';
my $version-change;
my $release-date;

for $change-file.IO.lines -> $line {
    if $line ~~ / ^ \s* ( \d+ \. \d+ \. \d+ ) \s+ ( \d\d\d\d '-' \d\d '-' \d\d) \s* $/ {
        $version-change = $0;
        $release-date = $1;
        last;
    }
}


my Date $today = Date.today;


ok( $choose-pm.defined,          'Choose version defined  OK' );
ok( $linefold-pm.defined,        'LineFold version defined  OK' );

is( $version-meta, $choose-pm,   'Choose version eq version "META6"  OK' );
is( $version-meta, $linefold-pm, 'LineFold version eq version in "META6"  OK' );

is( $version-change, $choose-pm, 'Version in "Changes"  OK' );
is( $release-date,   $today,      'Release date in Changes is date from today  OK' );
