use v6;
unit module Term::Choose::Screen;


my $term = %*ENV<TERM> || 'vt100'; # also in tput.t


my \t_up    = |run( 'tput', '-T', $term, 'cuu', '107', :out ).out.slurp.split( '107' );
my \t_down  = |run( 'tput', '-T', $term, 'cud', '107', :out ).out.slurp.split( '107' );
my \t_right = |run( 'tput', '-T', $term, 'cuf', '107', :out ).out.slurp.split( '107' );
my \t_left  = |run( 'tput', '-T', $term, 'cub', '107', :out ).out.slurp.split( '107' );

sub    up ( $steps ) is export( :DEFAULT, :up    ) { return t_up.join: $steps    if $steps }
sub  down ( $steps ) is export( :DEFAULT, :down  ) { return t_down.join: $steps  if $steps }
sub right ( $steps ) is export( :DEFAULT, :right ) { return t_right.join: $steps if $steps }
sub  left ( $steps ) is export( :DEFAULT, :left  ) { return t_left.join: $steps  if $steps }



my \clear      = run( 'tput', '-T', $term, 'clear', :out ).out.slurp;
my \clr-to-bot = run( 'tput', '-T', $term, 'ed',    :out ).out.slurp;
my \clr-to-eol = run( 'tput', '-T', $term, 'el',    :out ).out.slurp;

my \reverse   = run( 'tput', '-T', $term, 'rev',   :out, :err ).out.slurp;
my \bold      = run( 'tput', '-T', $term, 'bold',  :out, :err ).out.slurp;
my \underline = run( 'tput', '-T', $term, 'smul',  :out, :err ).out.slurp;
my \normal    = run( 'tput', '-T', $term, 'sgr0',  :out, :err ).out.slurp;

my \save-screen    = run( 'tput', '-T', $term, 'smcup', :out, :err ).out.slurp;
my \restore-screen = run( 'tput', '-T', $term, 'rmcup', :out, :err ).out.slurp;
my \show-cursor    = run( 'tput', '-T', $term, 'cnorm', :out, :err ).out.slurp;
my \hide-cursor    = run( 'tput', '-T', $term, 'civis', :out, :err ).out.slurp;
my \bell           = run( 'tput', '-T', $term, 'bel',   :out, :err ).out.slurp;

sub clear            is export( :DEFAULT, :clear            ) { return clear }
sub clr-lines-to-bot is export( :DEFAULT, :clr-lines-to-bot ) { return "\r" ~ clr-to-bot }
sub clr-to-eol       is export( :DEFAULT, :clr-to-eol       ) { return clr-to-eol }

sub reverse   is export( :DEFAULT, :reverse   ) { return reverse }
sub bold      is export( :DEFAULT, :bold      ) { return bold }
sub underline is export( :DEFAULT, :underline ) { return underline } # ### marked
sub normal    is export( :DEFAULT, :normal    ) { return normal }

sub    save-screen is export( :DEFAULT, :save-screen    ) { return save-screen }
sub restore-screen is export( :DEFAULT, :restore-screen ) { return restore-screen  }
sub show-cursor    is export( :DEFAULT, :show-cursor    ) { return show-cursor }
sub hide-cursor    is export( :DEFAULT, :hide-cursor    ) { return hide-cursor }
sub beep           is export( :DEFAULT, :beep           ) { return bell }



sub   set-mouse1003 is export( :DEFAULT, :set-mouse1003   ) { return "\e[?1003h" }
sub unset-mouse1003 is export( :DEFAULT, :unset-mouse1003 ) { return "\e[?1003l" }
sub   set-mouse1006 is export( :DEFAULT, :set-mouse1006   ) { return "\e[?1006h" }
sub unset-mouse1006 is export( :DEFAULT, :unset-mouse1006 ) { return "\e[?1006l" }

sub get-cursor-position is export( :DEFAULT, :get-cursor-position ) { return "\e[6n" }



sub num-threads is export( :DEFAULT, :num-threads ) {
    return %*ENV<TC_NUM_THREADS> || Kernel.cpu-cores;
}


sub get-term-size is export( :DEFAULT, :get-term-size  ) {
    my $width  = run( 'tput', '-T', $term, 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
    my $height = run( 'tput', '-T', $term, 'lines', :out ).out.get.chomp.Int or die "No terminal heigth!";
    return $width - 1, $height;
}


sub get-term-width is export( :DEFAULT, :get-term-width  ) {
    my $width  = run( 'tput', '-T', $term, 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
    return $width - 1;
}
