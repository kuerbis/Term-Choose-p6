use v6;
use Test;


my $term = %*ENV<TERM> || 'vt100'; # Screen.rakumod


#ok run( 'tput', '-T', $term, '-V', :out ).out.slurp, 'tput available';     # OpenBSD: tput: unknown option -- V    (#5)


for <cuu cud cuf cub> -> $cap {
    my $proc = run 'tput', '-T', $term, $cap, '107', :out, :err;
    ok $proc.out.slurp(:close), qq|tput: cap "$cap"| or diag $proc.err.slurp(:close);
}


for <cols lines clear ed el> -> $cap {
    my $proc = run 'tput', '-T', $term, $cap, :out, :err;
    ok $proc.out.slurp(:close), qq|tput: cap "$cap"| or diag $proc.err.slurp(:close);
}


for <bel smcup rmcup cnorm civis> -> $cap {
    my $proc = run 'tput', '-T', $term, $cap, :out, :err;
    $proc.out.slurp(:close) or diag $proc.err.slurp(:close);
}


done-testing();
