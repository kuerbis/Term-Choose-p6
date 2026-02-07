use v6;
unit module Term::Choose::Screen;

use Term::Choose::Constant;


my ( $t_up, $t_down, $t_right, $t_left, $clear_screen, $clear_to_end_of_screen, $clear_to_end_of_line, $reverse, $bold,
     $underline, $normal, $save_screen, $restore_screen, $show_cursor, $hide_cursor, $bell );


my $term = %*ENV<TERM> || 'vt100'; # also in tput.t

my $tput_ok = run( 'tput', '-T', $term, 'cuu', :out, :err ).so && ! %*ENV<TC_ANSI_ESCAPES>;

if ! $tput_ok {
        $t_up    = ( "\e[", "A" );
        $t_down  = ( "\e[", "B" );
        $t_right = ( "\e[", "C" );
        $t_left  = ( "\e[", "D" );

        $clear_screen           = "\e[H\e[J";
        $clear_to_end_of_screen = "\e[0J";
        $clear_to_end_of_line   = "\e[K";

        $reverse   = "\e[7m";
        $bold      = "\e[1m";
        $underline = "\e[4m";
        $normal    = "\e[0m";

        $save_screen    = "\e[?1049h";
        $restore_screen = "\e[?1049l";
        $show_cursor = "\e[?25h";
        $hide_cursor = "\e[?25l";
        $bell = "\a";
}
else {
    $t_up    = |run( 'tput', '-T', $term, 'cuu', '107', :out ).out.slurp.split( '107' );
    $t_down  = |run( 'tput', '-T', $term, 'cud', '107', :out ).out.slurp.split( '107' );
    $t_right = |run( 'tput', '-T', $term, 'cuf', '107', :out ).out.slurp.split( '107' );
    $t_left  = |run( 'tput', '-T', $term, 'cub', '107', :out ).out.slurp.split( '107' );

    $clear_screen           = run( 'tput', '-T', $term, 'clear', :out ).out.slurp;
    $clear_to_end_of_screen = run( 'tput', '-T', $term, 'ed',    :out ).out.slurp;
    $clear_to_end_of_line   = run( 'tput', '-T', $term, 'el',    :out ).out.slurp;

    $reverse   = run( 'tput', '-T', $term, 'rev',   :out, :err ).out.slurp;
    $bold      = run( 'tput', '-T', $term, 'bold',  :out, :err ).out.slurp;
    $underline = run( 'tput', '-T', $term, 'smul',  :out, :err ).out.slurp;
    $normal    = run( 'tput', '-T', $term, 'sgr0',  :out, :err ).out.slurp;

    $save_screen    = run( 'tput', '-T', $term, 'smcup', :out, :err ).out.slurp;
    $restore_screen = run( 'tput', '-T', $term, 'rmcup', :out, :err ).out.slurp;
    $show_cursor    = run( 'tput', '-T', $term, 'cnorm', :out, :err ).out.slurp;
    $hide_cursor    = run( 'tput', '-T', $term, 'civis', :out, :err ).out.slurp;
    $bell           = run( 'tput', '-T', $term, 'bel',   :out, :err ).out.slurp;
}


sub    up ( $steps ) is export( :DEFAULT, :up    ) { return $t_up.join: $steps    if $steps }
sub  down ( $steps ) is export( :DEFAULT, :down  ) { return $t_down.join: $steps  if $steps }
sub right ( $steps ) is export( :DEFAULT, :right ) { return $t_right.join: $steps if $steps }
sub  left ( $steps ) is export( :DEFAULT, :left  ) { return $t_left.join: $steps  if $steps }

sub clear-screen           is export( :DEFAULT, :clear-screen           ) { return $clear_screen }
sub clear-to-end-of-screen is export( :DEFAULT, :clear-to-end-of-screen ) { return "\r" ~ $clear_to_end_of_screen } # name 
sub clear-to-end-of-line   is export( :DEFAULT, :clear-to-end-of-line   ) { return $clear_to_end_of_line }

sub reverse   is export( :DEFAULT, :reverse   ) { return $reverse }
sub bold      is export( :DEFAULT, :bold      ) { return $bold }
sub underline is export( :DEFAULT, :underline ) { return $underline } # marked
sub normal    is export( :DEFAULT, :normal    ) { return $normal }

sub    save-screen is export( :DEFAULT, :save-screen    ) { return $save_screen }
sub restore-screen is export( :DEFAULT, :restore-screen ) { return $restore_screen  }
sub show-cursor    is export( :DEFAULT, :show-cursor    ) { return $show_cursor }
sub hide-cursor    is export( :DEFAULT, :hide-cursor    ) { return $hide_cursor }
sub beep           is export( :DEFAULT, :beep           ) { return $bell }

sub   set-mouse1003 is export( :DEFAULT, :set-mouse1003   ) { return "\e[?1003h" }
sub unset-mouse1003 is export( :DEFAULT, :unset-mouse1003 ) { return "\e[?1003l" }
sub   set-mouse1006 is export( :DEFAULT, :set-mouse1006   ) { return "\e[?1006h" }
sub unset-mouse1006 is export( :DEFAULT, :unset-mouse1006 ) { return "\e[?1006l" }

sub get-cursor-position is export( :DEFAULT, :get-cursor-position ) { return "\e[6n" }

sub num-threads is export( :DEFAULT, :num-threads ) {
    return %*ENV<TC_NUM_THREADS> || Kernel.cpu-cores;
}

sub get-term-size is export( :DEFAULT, :get-term-size  ) {
    if ( $tput_ok ) {
        my $width  = run( 'tput', '-T', $term, 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
        my $height = run( 'tput', '-T', $term, 'lines', :out ).out.get.chomp.Int or die "No terminal heigth!";
        return $width - cursor-width, $height;
    }
    else {
        my $size = run( 'stty', 'size', :out ).out.slurp;
        if $size && $size ~~ / ( \d+ ) \s ( \d+ ) / {
            my ( $hight, $width ) = ( $0, $1 );
            die "No terminal heigth!" if ! $hight;
            die "No terminal width!" if ! $width;
            return $width - cursor-width, $hight.Int;
        }
    }
}

sub get-term-width is export( :DEFAULT, :get-term-width  ) {
    if ( $tput_ok ) {
        my $width  = run( 'tput', '-T', $term, 'cols',  :out ).out.get.chomp.Int or die "No terminal width!";
        return $width - cursor-width;
    }
    else {
        my $size = run( 'stty', 'size', :out ).out.slurp;
        if $size && $size ~~ / \d+ \s ( \d+ ) / {
            my $width = $0;
            die "No terminal width!" if ! $width;
            return $width - cursor-width;
        }
    }
}


