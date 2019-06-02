use v6;
unit module Term::Choose::ReadKey;


my Int $abs_cursor_Y;


sub read-key( Int $mouse ) is export( :DEFAULT, :read-key ) {
    my $buf = Buf.new;
    my $c1;
    while ! try $c1 = $buf.decode {
        # Terminal::Print::RawInput
        my $b = $*IN.read(1) or return;
        $buf.push: $b;
    }
    if $c1 eq "\e" {
        my $c2 = $*IN.read(1).decode;
        if ! $c2.defined { return 'Escape' }
        elsif $c2 eq "A" { return 'CursorUp' }
        elsif $c2 eq "B" { return 'CursorDown' }
        elsif $c2 eq "C" { return 'CursorRight' }
        elsif $c2 eq "D" { return 'CursorLeft' }
        elsif $c2 eq "H" { return 'CursorHome' }
        elsif $c2 eq "O" {
            my $c3 = $*IN.read(1).decode;
            if    $c3 eq "A" { return 'CursorUp' }
            elsif $c3 eq "B" { return 'CursorDown' }
            elsif $c3 eq "C" { return 'CursorRight' }
            elsif $c3 eq "D" { return 'CursorLeft' }
            elsif $c3 eq "F" { return 'CursorEnd' }
            elsif $c3 eq "H" { return 'CursorHome' }
            #elsif $c3 eq "P" { return 'F1' }
            #elsif $c3 eq "Q" { return 'F2' }
            #elsif $c3 eq "R" { return 'F3' }
            #elsif $c3 eq "S" { return 'F4' }
            elsif $c3 eq "Z" { return 'BackTab' }
            else { return }
        }
        #elsif $c2 eq "P" { return 'F1' }
        #elsif $c2 eq "Q" { return 'F2' }
        #elsif $c2 eq "R" { return 'F3' }
        #elsif $c2 eq "S" { return 'F4' }
        elsif $c2 eq "[" {
            my $c3 = $*IN.read(1).decode;
            if    $c3 eq "A" { return 'CursorUp' }
            elsif $c3 eq "B" { return 'CursorDown' }
            elsif $c3 eq "C" { return 'CursorRight' }
            elsif $c3 eq "D" { return 'CursorLeft' }
            elsif $c3 eq "F" { return 'CursorEnd' }
            elsif $c3 eq "H" { return 'CursorHome' }
            elsif $c3 eq "Z" { return 'BackTab' }
            elsif $c3 ~~ / ^ <[ 0..9 ]> $ / {
                my $digits = $c3;
                my $next_c = $*IN.read(1).decode;
                while $next_c ~~ / ^ <[ 0..9 ]> $ / {
                    $digits ~= $next_c;
                    $next_c = $*IN.read(1).decode;
                }
                if $next_c eq ";" {
                    my $abs_curs_y = $digits;
                    my $abs_curs_x = '';
                    my $rx = $*IN.read(1).decode;
                    while $rx ~~ / ^ <[ 0..9 ]> $ / {
                        $abs_curs_x ~= $rx;
                        $rx = $*IN.read(1).decode;
                    }
                    if $rx eq "R" {
                        #$!abs_cursor_x = $abs_curs_x; # unused
                        $abs_cursor_Y = $abs_curs_y.Int;
                    }
                    return;
                }
                elsif $next_c eq "~" {
                    if    $digits eq "2" { return 'Insert' }
                    elsif $digits eq "3" { return 'Delete' }
                    elsif $digits eq "5" { return 'PageUp' }
                    elsif $digits eq "6" { return 'PageDown' }
                    #elsif $digits eq "11" { return 'F1' }
                    #elsif $digits eq "12" { return 'F2' }
                    #elsif $digits eq "13" { return 'F3' }
                    #elsif $digits eq "14" { return 'F4' }
                    #elsif $digits eq "15" { return 'F5' }
                    #elsif $digits eq "17" { return 'F6' }
                    #elsif $digits eq "18" { return 'F7' }
                    #elsif $digits eq "19" { return 'F8' }
                    #elsif $digits eq "20" { return 'F9' }
                    #elsif $digits eq "21" { return 'F10' }
                    #elsif $digits eq "23" { return 'F11' }
                    #elsif $digits eq "24" { return 'F12' }
                    #elsif $digits eq "25" { return 'F13' }
                    #elsif $digits eq "26" { return 'F14' }
                    #elsif $digits eq "28" { return 'F15' }
                    #elsif $digits eq "29" { return 'F16' }
                    #elsif $digits eq "31" { return 'F17' }
                    #elsif $digits eq "32" { return 'F18' }
                    #elsif $digits eq "33" { return 'F19' }
                    #elsif $digits eq "34" { return 'F20' }
                    else { return };
                }
                else { return }
            }
            elsif $c3 eq "<" && $mouse { return _mouse_tracking_SRG_1006() }
            else { return }
        }
        else { return }
    }
    else {
        if    $c1.ord == 127 { return 'Backspace'                }
        elsif $c1.ord < 32   { return '^' ~ ( $c1.ord + 64 ).chr }
        else                 { return $c1                        }
    }
}



# http://invisible-island.net/xterm/ctlseqs/ctlseqs.html

sub _mouse_tracking_SRG_1006 {
    my $event_type = '';
    my $m1;
    while ( $m1 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $event_type ~= $m1;
    }
    if $m1 ne ";" {
        return;
    }
    my $x = '';
    my $m2;
    while ( $m2 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $x ~= $m2;
    }
    if $m2 ne ";" {
        return;
    }
    my $y = '';
    my $m3;
    while ( $m3 = $*IN.read(1).decode ) ~~ / ^ <[ 0..9 ]> $ / {
        $y ~= $m3;
    }
    if $m3 !~~ / ^ <[ mM ]> $ / {
        return;
    }
    my $button_released = $m3 eq "m" ?? 1 !! 0;
    if $button_released {
        return;
    }
    my $button = _mouse_event_to_button( $event_type );
    if ! $button.defined {
        return;
    }
    return [ $abs_cursor_Y, $button, $x.Int, $y.Int ];
}


sub _mouse_event_to_button( $event_type ) {
    my $button_drag = ( $event_type +& 0x20 ) +> 5;
    if $button_drag {
        return;
    }
    my $button;
    my $low_2_bits = $event_type +& 0x03;
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


