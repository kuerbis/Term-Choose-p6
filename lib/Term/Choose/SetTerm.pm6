use v6;

unit class Term::Choose::SetTerm;

use Term::termios;

use Term::Choose::Screen;


has Int $.mouse;
has Int $.hide-cursor;
has Int $.save-screen;
has Int $.loop is rw;

has $!saved_termios;



method init-term {
    $!saved_termios := Term::termios.new(fd => 1).getattr;
    my $termios := Term::termios.new(fd => 1).getattr;
    $termios.makeraw;
    #$termios.set_lflags(<ISIG>); # SIGINT (Ctrl-c), SIGQUIT (Ctrl-\),  SIGSUSP (Ctrl-z), SIGDSUSP
    $termios.setattr(:DRAIN);
    if $!save-screen {
        print save-screen;
    }
    if $!hide-cursor && ! $!loop {
        print hide-cursor;
    }
    if $!mouse {
        print set-mouse1003;
        print set-mouse1006;
    }
}


method restore-term ( $up ) {
    if $!mouse {
        print unset-mouse1003;
        print unset-mouse1006;
    }
    if $!saved_termios.defined { # ### 
        $!saved_termios.setattr(:DRAIN);
    }
    if $!save-screen {
        print restore-screen;
    }
    else {
        if $up {
            print up( $up );
        }
        if ! $!loop {
            print clr-lines-to-bot;
        }
    }
    if $!hide-cursor && ! $!loop {
        print show-cursor;
    }
}

