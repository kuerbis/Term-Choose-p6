use v6;
unit module Term::Choose::Screen;



my \t_up    = |run( 'tput', 'cuu', '107', :out ).out.slurp.split( '107' );
my \t_down  = |run( 'tput', 'cud', '107', :out ).out.slurp.split( '107' );
my \t_right = |run( 'tput', 'cuf', '107', :out ).out.slurp.split( '107' );
my \t_left  = |run( 'tput', 'cub', '107', :out ).out.slurp.split( '107' );

sub    up ( $steps ) is export( :DEFAULT, :up    ) {    t_up.join: $steps if $steps }
sub  down ( $steps ) is export( :DEFAULT, :down  ) {  t_down.join: $steps if $steps }
sub right ( $steps ) is export( :DEFAULT, :right ) { t_right.join: $steps if $steps }
sub  left ( $steps ) is export( :DEFAULT, :left  ) {  t_left.join: $steps if $steps }



my \clear          = run( 'tput', 'clear', :out ).out.slurp;
my \clr-to-bot     = run( 'tput', 'ed',    :out ).out.slurp;
my \clr-to-eol     = run( 'tput', 'el',    :out ).out.slurp;

my \save-screen    = run( 'tput', 'smcup', :out, :err ).out.slurp;
my \restore-screen = run( 'tput', 'rmcup', :out, :err ).out.slurp;
my \show-cursor    = run( 'tput', 'cnorm', :out, :err ).out.slurp;
my \hide-cursor    = run( 'tput', 'civis', :out, :err ).out.slurp;
my \bell           = run( 'tput', 'bel',   :out, :err ).out.slurp;


sub clear            is export( :DEFAULT, :clear            ) { clear }
sub clr-lines-to-bot is export( :DEFAULT, :clr-lines-to-bot ) { "\r" ~ clr-to-bot }
sub clr-to-eol       is export( :DEFAULT, :clr-to-eol       ) { clr-to-eol }

sub    save-screen is export( :DEFAULT, :save-screen    ) { save-screen }
sub restore-screen is export( :DEFAULT, :restore-screen ) { restore-screen  }
sub show-cursor is export( :DEFAULT, :show-cursor ) { show-cursor }
sub hide-cursor is export( :DEFAULT, :hide-cursor ) { hide-cursor }
sub beep is export( :DEFAULT, :beep ) { bell }



sub   set-mouse1003 is export( :DEFAULT, :set-mouse1003   ) { "\e[?1003h" }
sub unset-mouse1003 is export( :DEFAULT, :unset-mouse1003 ) { "\e[?1003l" }
sub   set-mouse1006 is export( :DEFAULT, :set-mouse1006   ) { "\e[?1006h" }
sub unset-mouse1006 is export( :DEFAULT, :unset-mouse1006 ) { "\e[?1006l" }

sub get-cursor-position is export( :DEFAULT, :get-cursor-position ) { "\e[6n" }



sub num-threads is export( :DEFAULT, :num-threads ) {
    return %*ENV<TC_NUM_THREADS> || Kernel.cpu-cores;
}


sub get-term-size is export( :DEFAULT, :get-term-size  ) {
    my $width  = run( 'tput', 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
    my $height = run( 'tput', 'lines', :out ).out.get.chomp.Int or die "No terminal heigth!";
    return $width - 1, $height;
}


sub get-term-width is export( :DEFAULT, :get-term-width  ) {
    my $width  = run( 'tput', 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
    return $width - 1;
}
