use v6;
unit class Term::Choose::Linux;

my $VERSION = '0.011';

use Term::termios;

use Term::Choose::Constants :linux;



sub ReadKey ( $timeout ) {    # latin1: fixed length 8 bit
    return $*IN.read( 1 ).decode( 'latin1' ); 
}


has Term::termios $!saved_termios;
#has Int $!abs_cursor_x;
has Int $!abs_cursor_y;


method _get_key_OS ( $mouse ) {
    my $c_1 = ReadKey( 0 );
    return if ! $c_1.defined;
    if $c_1 eq "\e" {
        my $c_2 = ReadKey( 0.10 );
        if    ! $c_2.defined { return KEY_ESC; } # unused
        #elsif $c_2 eq 'A' { return VK_UP; }     vt 52
        #elsif $c_2 eq 'B' { return VK_DOWN; }
        #elsif $c_2 eq 'C' { return VK_RIGHT; }
        #elsif $c_2 eq 'D' { return VK_LEFT; }
        #elsif $c_2 eq 'H' { return VK_HOME; }
        elsif $c_2 eq 'O' {
            my $c_3 = ReadKey( 0 );
            if    $c_3 eq 'A' { return VK_UP; }
            elsif $c_3 eq 'B' { return VK_DOWN; }
            elsif $c_3 eq 'C' { return VK_RIGHT; }
            elsif $c_3 eq 'D' { return VK_LEFT; }
            elsif $c_3 eq 'F' { return VK_END; }
            elsif $c_3 eq 'H' { return VK_HOME; }
            elsif $c_3 eq 'Z' { return KEY_BTAB; }
            else {
                return NEXT_get_key;
            }
        }
        elsif $c_2 eq '[' {
            my $c_3 = ReadKey( 0 );
            if    $c_3 eq 'A' { return VK_UP; }
            elsif $c_3 eq 'B' { return VK_DOWN; }
            elsif $c_3 eq 'C' { return VK_RIGHT; }
            elsif $c_3 eq 'D' { return VK_LEFT; }
            elsif $c_3 eq 'F' { return VK_END; }
            elsif $c_3 eq 'H' { return VK_HOME; }
            elsif $c_3 eq 'Z' { return KEY_BTAB; }
            elsif $c_3 ~~ /^<[0..9]>$/ {
                my $c_4 = ReadKey( 0 );
                if $c_4 eq '~' {
                    if    $c_3 eq '2' { return VK_INSERT; } # unused
                    elsif $c_3 eq '3' { return VK_DELETE; } # unused
                    elsif $c_3 eq '5' { return VK_PAGE_UP; }
                    elsif $c_3 eq '6' { return VK_PAGE_DOWN; }
                    else {
                        return NEXT_get_key;
                    }
                }
                elsif $c_4 ~~ /^<[;0..9]>$/ { # response to "\e[6n"
                    my $abs_curs_y = $c_3;
                    my $ry = $c_4;
                    while $ry ~~ m/^<[0..9]>$/ {
                        $abs_curs_y ~= $ry;
                        $ry = ReadKey( 0 );
                    }
                    return NEXT_get_key if $ry ne ';';
                    my $abs_curs_x = '';
                    my $rx = ReadKey( 0 );
                    while $rx ~~ /^<[0..9]>$/ {
                        $abs_curs_x ~= $rx;
                        $rx = ReadKey( 0 );
                    }
                    if $rx eq 'R' {
                        #$!abs_cursor_x = $abs_curs_x.Int; # unused
                        $!abs_cursor_y = $abs_curs_y.Int;
                    }
                    return NEXT_get_key;
                }
                else {
                    return NEXT_get_key;
                }
            }
            # http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
            elsif $c_3 eq 'M' && $mouse {
                my $event_type = ReadKey( 0 ).ord - 32;
                my $x          = ReadKey( 0 ).ord - 32;
                my $y          = ReadKey( 0 ).ord - 32;
                my Int $button = self!_mouse_event_to_button( $event_type );
                return NEXT_get_key if $button == NEXT_get_key;
                return [ $!abs_cursor_y, $button, $x.Int, $y.Int ];
            }
            elsif $c_3 eq '<' && $mouse {  # SGR 1006
                my $event_type = '';
                my $m1;
                while ( $m1 = ReadKey( 0 ) ) ~~ /^<[0..9]>$/ { #
                    $event_type ~= $m1;
                }
                return NEXT_get_key if $m1 ne ';';
                my $x = '';
                my $m2;
                while ( $m2 = ReadKey( 0 ) ) ~~ /^<[0..9]>$/ { #
                    $x ~= $m2;
                }
                return NEXT_get_key if $m2 ne ';';
                my $y = '';
                my $m3;
                while ( $m3 = ReadKey( 0 ) ) ~~ /^<[0..9]>$/ { #
                    $y ~= $m3;
                }
                return NEXT_get_key if $m3 !~~ /^<[mM]>$/;
                my $button_released = $m3 eq 'm' ?? 1 !! 0;
                return NEXT_get_key if $button_released;
                my $button = self!_mouse_event_to_button( $event_type );
                return NEXT_get_key if $button == NEXT_get_key;
                return [ $!abs_cursor_y, $button, $x.Int, $y.Int ];
            }
            else {
                return NEXT_get_key;
            }
        }
        else {
            return NEXT_get_key;
        }
    }
    else {
        return $c_1.ord;
    }
}


method !_mouse_event_to_button ( $event_type ) {
    my Int $button_drag = ( $event_type +& 0x20 ) +> 5;
    return NEXT_get_key if $button_drag;
    my Int $button;
    my Int $low_2_bits = $event_type +& 0x03;
    if $low_2_bits == 3 {
        $button = 0;
    }
    else {
        if $event_type +& 0x40 {
            $button = $low_2_bits + 4; # 4,5
        }
        else {
            $button = $low_2_bits + 1; # 1,2,3
        }
    }
    return $button;
}


method _set_mode ( Int $mouse, Int $hide_cursor ) {
    if $mouse {
        print SET_ANY_EVENT_MOUSE_1003;
        print SET_SGR_EXT_MODE_MOUSE_1006 if $mouse == 1;
    }
    $!saved_termios := Term::termios.new(fd => 1).getattr;
    my $termios := Term::termios.new(fd => 1).getattr;
    $termios.makeraw;
    $termios.setattr(:DRAIN);
    print HIDE_CURSOR if $hide_cursor;
}


method _reset_mode ( Int $mouse, Int $hide_cursor ) {
    print SHOW_CURSOR if $hide_cursor;
    if $mouse {
        print UNSET_SGR_EXT_MODE_MOUSE_1006 if $mouse == 1;
        print UNSET_ANY_EVENT_MOUSE_1003;
    }
    self._reset;
    $!saved_termios.setattr(:DRAIN);
}


                 # qx[stty -a </dev/tty 2>&1];
method _term_size {
    my Str $stty = qx[stty -a];
    my Int $term_h = $stty.match( / 'rows '    <( \d+ )>/ ).Int;
    my Int $term_w = $stty.match( / 'columns ' <( \d+ )>/ ).Int;
    return $term_w - WIDTH_CURSOR, $term_h;
    # $width - WIDTH_CURSOR: don't let items reach the right edge of the terminal;
    #                        selecting an item which reaches the right edge of the terminal
    #                        messes up the output - maybe because the (hidden) terminal-cursor needs a space
}

method _get_cursor_position {
    #$!abs_cursor_x = 0; # unused
    $!abs_cursor_y = 0;
    print GET_CURSOR_POSITION;
}

method _clear_screen           { print CLEAR_SCREEN; }
method _clear_to_end_of_screen { print CLEAR_TO_END_OF_SCREEN; }
method _bold_underline         { print BOLD_UNDERLINE; }
method _reverse                { print REVERSE; }
method _reset                  { print RESET; }
method _up         ( Int $nr ) { print "\e[{$nr}A"; }
method _left       ( Int $nr ) { print "\e[{$nr}D"; }
method _right      ( Int $nr ) { print "\e[{$nr}C"; }





