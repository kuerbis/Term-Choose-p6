use v6;
use Test;


ok run( 'tput', '-V', :out ).out.slurp, 'tput available';


for <cuu cud cuf cub> -> $cap {
    my $proc = run 'tput', $cap, '107', :out, :err;
    ok $proc.out.slurp(:close), qq|tput: cap "$cap"| or diag $proc.err.slurp(:close);
}


for <cols lines clear ed el> -> $cap {
    my $proc = run 'tput', $cap, :out, :err;
    ok $proc.out.slurp(:close), qq|tput: cap "$cap"| or diag $proc.err.slurp(:close);
}


for <bel smcup rmcup cnorm civis> -> $cap {
    my $proc = run 'tput', $cap, :out, :err;
    $proc.out.slurp(:close) or diag $proc.err.slurp(:close);
}


done-testing();
