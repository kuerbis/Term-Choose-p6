use v6;
use Test;

plan 1;

my Int $this_year = Date.new( now ).year;


my Str @files = (
    'README.md',
    'lib/Term/Choose.pm6',
);

my Str $author = 'Matth..?us\sKiem';

my Int $error = 0;
my Str $diag  = '';

for @files -> $file {
    my $line_nr = 1;
    for $file.IO.lines -> $line {
        if $line ~~ m:i/ copyright [ \( c \) ]? .* <$author> / {
            if  $line !~~ m:i/ copyright [ \s \( c \) ]? \s 20\d\d '-' <$this_year> / && $line !~~ m:i/ copyright [ \s \( c \) ]? \s <$this_year> / {
                $diag ~= sprintf( "%15s - line %d: %s\n", $file, $line_nr, $line );
                $error++;
            }
        }
        $line_nr++;
    }
}


ok( $error == 0, "Copyright year" ) or diag( $diag );
diag( "\n" );

