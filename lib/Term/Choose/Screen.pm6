use v6;
unit module Term::Choose::Screen;


sub            clear is export( :DEFAULT, :clear            ) { print "\e[H\e[J" }
sub clr-lines-to-bot is export( :DEFAULT, :clr-lines-to-bot ) { print "\r\e[0J"  }
sub       clr-to-eol is export( :DEFAULT, :clr-to-eol       ) { print "\e[0K"    }

sub beep is export( :DEFAULT, :beep ) { print "\a" }

sub    up ( $steps ) is export( :DEFAULT, :up    ) { print "\e[{$steps}A" if $steps }
sub  down ( $steps ) is export( :DEFAULT, :down  ) { print "\e[{$steps}B" if $steps }
sub right ( $steps ) is export( :DEFAULT, :right ) { print "\e[{$steps}C" if $steps }
sub  left ( $steps ) is export( :DEFAULT, :left  ) { print "\e[{$steps}D" if $steps }

sub    save-screen is export( :DEFAULT, :save-screen    ) { print "\e[?1049h" }
sub restore-screen is export( :DEFAULT, :restore-screen ) { print "\e[?1049l" }

sub show-cursor is export( :DEFAULT, :show-cursor ) { print "\e[?25h" }
sub hide-cursor is export( :DEFAULT, :hide-cursor ) { print "\e[?25l" }

sub   set-mouse1003 is export( :DEFAULT, :set-mouse1003   ) { print "\e[?1003h" }
sub unset-mouse1003 is export( :DEFAULT, :unset-mouse1003 ) { print "\e[?1003l" }
sub   set-mouse1006 is export( :DEFAULT, :set-mouse1006   ) { print "\e[?1006h" }
sub unset-mouse1006 is export( :DEFAULT, :unset-mouse1006 ) { print "\e[?1006l" }

sub get-cursor-position is export( :DEFAULT, :get-cursor-position ) { print "\e[6n" }


sub num-threads is export( :DEFAULT, :num-threads ) {
    return %*ENV<TC_NUM_THREADS> if %*ENV<TC_NUM_THREADS>;
    # return Kernel.cpu-cores;      # Perl 6.d
    my $proc = run( 'nproc', :out );
    return $proc.out.get.Int || 2;
}


sub get-term-size is export( :DEFAULT, :get-term-size  ) {
    my ( $width, $height );
    my $proc = run 'stty', 'size', :out;
    my $size = $proc.out.get.chomp.Int;
    if $size.defined && $size ~~ / ( \d+ ) \s ( \d+ ) / {
         $width  = $1;
         $height = $0;
    }
    if ! $width {
        my $proc = run 'tput', 'cols', :out;
        $width = $proc.out.get.chomp.Int;
    }
    if ! $height {
        my $proc = run 'tput', 'lines', :out;
        $height = $proc.out.get.chomp.Int;
    }
    die "No terminal width!"  if ! $width.defined;
    die "No terminal heigth!" if ! $height.defined;
    return $width - 1, $height;
}
