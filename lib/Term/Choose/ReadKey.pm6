use v6;
unit module Term::Choose::ReadKey;


my Int $abs_cursor_Y;

sub read-key( Int $mouse ) is export( :DEFAULT, :read-key ) {
    my $s = Supplier::Preserving.new;
    my Bool $done = False;
    start {
        LOOP: until $done {
            my Buf $buf = Buf.new;
            my Str $c1;
            while ! try $c1 = $buf.decode {
                # Terminal::Print::RawInput
                my Buf $b = $*IN.read(1) or return;
                $buf.push: $b;
            }
            my $pressed_key; # Str or Array
            if $c1 eq "\e" {
                my Str $c2 = $*IN.read(1).decode;
                if ! $c2.defined { $pressed_key = 'Escape' }
                elsif $c2 eq "A" { $pressed_key = 'CursorUp' }
                elsif $c2 eq "B" { $pressed_key = 'CursorDown' }
                elsif $c2 eq "C" { $pressed_key = 'CursorRight' }
                elsif $c2 eq "D" { $pressed_key = 'CursorLeft' }
                elsif $c2 eq "H" { $pressed_key = 'CursorHome' }
                elsif $c2 eq "O" {
                    my Str $c3 = $*IN.read(1).decode;
                    if    $c3 eq "A" { $pressed_key = 'CursorUp' }
                    elsif $c3 eq "B" { $pressed_key = 'CursorDown' }
                    elsif $c3 eq "C" { $pressed_key = 'CursorRight' }
                    elsif $c3 eq "D" { $pressed_key = 'CursorLeft' }
                    elsif $c3 eq "F" { $pressed_key = 'CursorEnd' }
                    elsif $c3 eq "H" { $pressed_key = 'CursorHome' }
                    #elsif $c3 eq "P" { $pressed_key = 'F1' }
                    #elsif $c3 eq "Q" { $pressed_key = 'F2' }
                    elsif $c3 eq "R" { $pressed_key = 'F3' }
                    #elsif $c3 eq "S" { $pressed_key = 'F4' }
                    elsif $c3 eq "Z" { $pressed_key = 'BackTab' }
                    else {}
                }
                #elsif $c2 eq "P" { $pressed_key = 'F1' }
                #elsif $c2 eq "Q" { $pressed_key = 'F2' }
                elsif $c2 eq "R" { $pressed_key = 'F3' }
                #elsif $c2 eq "S" { $pressed_key = 'F4' }
                elsif $c2 eq "[" {
                    my Str $c3 = $*IN.read(1).decode;
                    if    $c3 eq "A" { $pressed_key = 'CursorUp' }
                    elsif $c3 eq "B" { $pressed_key = 'CursorDown' }
                    elsif $c3 eq "C" { $pressed_key = 'CursorRight' }
                    elsif $c3 eq "D" { $pressed_key = 'CursorLeft' }
                    elsif $c3 eq "F" { $pressed_key = 'CursorEnd' }
                    elsif $c3 eq "H" { $pressed_key = 'CursorHome' }
                    elsif $c3 eq "Z" { $pressed_key = 'BackTab' }
                    elsif $c3 ~~ / ^ <[ 0..9 ]> $ / {
                        my Str $digits = $c3;
                        my Str $next_c = $*IN.read(1).decode;
                        while $next_c ~~ / ^ <[ 0..9 ]> $ / {
                            $digits ~= $next_c;
                            $next_c = $*IN.read(1).decode;
                        }
                        if $next_c eq ";" {
                            my Str $abs_curs_y = $digits;
                            my Str $abs_curs_x = '';
                            my Str $rx = $*IN.read(1).decode;
                            while $rx ~~ / ^ <[ 0..9 ]> $ / {
                                $abs_curs_x ~= $rx;
                                $rx = $*IN.read(1).decode;
                            }
                            if $rx eq "R" {
                                #$!abs_cursor_x = $abs_curs_x; # unused
                                $abs_cursor_Y = $abs_curs_y.Int;
                            }
                            # ...;
                        }
                        elsif $next_c eq "~" {
                            if    $digits eq "2"  { $pressed_key = 'Insert' }
                            elsif $digits eq "3"  { $pressed_key = 'Delete' }
                            elsif $digits eq "5"  { $pressed_key = 'PageUp' }
                            elsif $digits eq "6"  { $pressed_key = 'PageDown' }
                            #elsif $digits eq "11" { $pressed_key = 'F1' }
                            #elsif $digits eq "12" { $pressed_key = 'F2' }
                            elsif $digits eq "13" { $pressed_key = 'F3' }
                            #elsif $digits eq "14" { $pressed_key = 'F4' }
                            #elsif $digits eq "15" { $pressed_key = 'F5' }
                            #elsif $digits eq "17" { $pressed_key = 'F6' }
                            #elsif $digits eq "18" { $pressed_key = 'F7' }
                            #elsif $digits eq "19" { $pressed_key = 'F8' }
                            #elsif $digits eq "20" { $pressed_key = 'F9' }
                            #elsif $digits eq "21" { $pressed_key = 'F10' }
                            #elsif $digits eq "23" { $pressed_key = 'F11' }
                            #elsif $digits eq "24" { $pressed_key = 'F12' }
                            #elsif $digits eq "25" { $pressed_key = 'F13' }
                            #elsif $digits eq "26" { $pressed_key = 'F14' }
                            #elsif $digits eq "28" { $pressed_key = 'F15' }
                            #elsif $digits eq "29" { $pressed_key = 'F16' }
                            #elsif $digits eq "31" { $pressed_key = 'F17' }
                            #elsif $digits eq "32" { $pressed_key = 'F18' }
                            #elsif $digits eq "33" { $pressed_key = 'F19' }
                            #elsif $digits eq "34" { $pressed_key = 'F20' }
                            else {};
                        }
                        else {}
                    }
                    elsif $c3 eq "<" && $mouse { $pressed_key = _mouse_tracking_SRG_1006() }
                    else {}
                }
                else {}
            }
            else {
                if    $c1.ord == 127 { $pressed_key = 'Backspace'                }
                elsif $c1.ord < 32   { $pressed_key = '^' ~ ( $c1.ord + 64 ).chr }
                else                 { $pressed_key = $c1                        }
            }
            $s.emit( $pressed_key ) unless $done;
        }
    }
    $s.Supply.on-close: {
        $done = True;
    }
}


# http://invisible-island.net/xterm/ctlseqs/ctlseqs.html

sub _mouse_tracking_SRG_1006 {
    my Str $event_type = '';
    my Str $m1;
    while ( $m1 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $event_type ~= $m1;
    }
    if $m1 ne ";" {
        return;
    }
    my Str $x = '';
    my Str $m2;
    while ( $m2 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $x ~= $m2;
    }
    if $m2 ne ";" {
        return;
    }
    my Str $y = '';
    my Str $m3;
    while ( $m3 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $y ~= $m3;
    }
    if $m3 !~~ / ^ <[ mM ]> $ / {
        return;
    }
    my Int $button_released = $m3 eq "m" ?? 1 !! 0;
    if $button_released {
        return;
    }
    my Int $button = _mouse_event_to_button( $event_type );
    if ! $button.defined {
        return;
    }
    return [ $abs_cursor_Y, $button, $x.Int, $y.Int ];
}


sub _mouse_event_to_button( Str $event_type ) {
    my Int $button_drag = ( $event_type +& 0x20 ) +> 5;
    if $button_drag {
        return;
    }
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


