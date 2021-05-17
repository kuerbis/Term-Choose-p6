use v6;

unit class Term::Choose:ver<1.7.1>;

use Term::termios;

use Term::Choose::ReadKey;
use Term::Choose::Screen;
use Term::Choose::LineFold;
use Term::Choose::SetTerm;


constant R  = 0;
constant C  = 1;

subset Positive_Int     of Int where * > 0;
subset Int_2_or_greater of Int where * > 1;
subset Int_0_to_2       of Int where * == 0|1|2;
subset Int_0_or_1       of Int where * == 0|1;

has Int_0_or_1       $.page                 = 0; # removed 26.03.2019
has Int_0_or_1       $.beep                 = 0;
has Int_0_or_1       $.index                = 0;
has Int_0_or_1       $.mouse                = 0;
has Int_0_or_1       $.order                = 1;
has Int_0_or_1       $.loop                 = 0; # privat
has Int_0_or_1       $.hide-cursor          = 1;
has Int_0_to_2       $.alignment            = 0;
has Int_0_to_2       $.clear-screen         = 0;
has Int_0_to_2       $.color                = 0;
has Int_0_to_2       $.f3                   = 1;
has Int_0_to_2       $.include-highlighted  = 0;
has Int_0_to_2       $.layout               = 1;
has Positive_Int     $.keep                 = 5;
has Positive_Int     $.ll;                       # privat
has Positive_Int     $.max-height;
has Int_2_or_greater $.max-width;
has UInt             $.default              = 0;
has UInt             $.pad                  = 2;
has List             $.mark;
has List             $.meta-items;
has List             $.no-spacebar;
has List             $.tabs-prompt;
has List             $.tabs-info;
has Str              $.footer               = '';
has Str              $.info                 = '';
has Str              $.prompt;
has Str              $.empty                = '<empty>';
has Str              $.undef                = '<undef>';

has Int $!i_col;
has Int $!i_row;

has @!orig_list;
has @!list;
has %!o;

has Int   $!term_w;
has Int   $!term_h;
has Int   $!avail_w;
has Int   $!avail_h;
has Int   $!col_w;
has Int   $!col_w_plus;
has Int   @!w_list;
has Int   $!single_column;
has Int   $!all_in_one_row;
has Int   $!idx_of_last_col_in_last_row;
has Int   $!page_count;
has Str   $!pp_row_fmt;
has Str   @!prompt_lines;
has Int   $!first_page_row;
has Int   $!last_page_row;
has Array $!rc2idx;
has Array $!p;
has Array $!marked;
has Int   $!page_step;
has Int   $!cursor_row;

has Int   $!search;
has Array $!map_search_list_index;
has Hash  $!search_backup_data;
has Hash  $!search_backup_opt;




has Term::Choose::SetTerm $!setterm;


method !_prepare_new_copy_of_list {
    if %!o<ll> {
        @!list = @!orig_list;
        $!col_w = %!o<ll>;
    }
    else {
        my Int $threads = num-threads();
        while $threads > @!orig_list.elems {
            last if $threads < 2;
            $threads = $threads div 2;
        }
        my $size = @!orig_list.elems div $threads;
        my @portions = ( ^$threads ).map: { [ $size * $_, $size * ( $_ + 1 ) ] };
        @portions[*-1][1] = @!orig_list.elems;
        my @promise;
        for @portions -> $range {
            my @cache;
            @promise.push: start {
                do for $range[0] ..^ $range[1] -> $i {
                    if %!o<color> {
                        if ! @!orig_list[$i].defined {
                            my ( $str, $len ) = to-printwidth(
                                %!o<undef>.subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                        elsif @!orig_list[$i] eq '' {
                            my ( $str, $len ) = to-printwidth(
                                %!o<empty>.subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                        elsif %!o<color> {
                                my ( $str, $len ) = to-printwidth(
                                @!orig_list[$i].subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                    }
                    else {
                        if ! @!orig_list[$i].defined {
                            my ( $str, $len ) = to-printwidth(
                                %!o<undef>.subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                        elsif @!orig_list[$i] eq '' {
                            my ( $str, $len ) = to-printwidth(
                                %!o<empty>.subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                        else {
                            my ( $str, $len ) = to-printwidth(
                                @!orig_list[$i].subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                @cache
                            );
                            $i, $str, $len;
                        }
                    }
                }
            };
        }
        @!list = ();
        @!w_list = ();
        for await @promise -> @portion {
            for @portion {
                @!list[.[0]] := .[1];
                @!w_list[.[0]] := .[2];
            }
        }
        $!col_w = @!w_list.max;
    }
}

method !_beep {
    print beep if %!o<beep>;
}


method !_prepare_prompt {
    my @tmp;
    @!prompt_lines = ();
    if %!o<info>.chars {
        my Int $init   = %!o<tabs-info>[0] // 0;
        my Int $subseq = %!o<tabs-info>[1] // 0;
        @!prompt_lines.push: |line-fold( %!o<info>, $!avail_w, :init-tab( ' ' x $init ), :subseq-tab( ' ' x $subseq ), :color( %!o<color> ) );
    }
    if %!o<prompt>.chars {
        my Int $init   = %!o<tabs-prompt>[0] // 0;
        my Int $subseq = %!o<tabs-prompt>[1] // 0;
        @!prompt_lines.push: |line-fold( %!o<prompt>, $!avail_w, :init-tab( ' ' x $init ), :subseq-tab( ' ' x $subseq ), :color( %!o<color> ) );
    }
    if ! @!prompt_lines.elems {
        return;
    }
    my Int $keep = %!o<keep>;
    $keep += 1; # page row
    if $keep > $!term_h {
        $keep = $!term_h;
    }
    my $limit_prompt_lines = $!avail_h - $keep;
    if @!prompt_lines.elems > $limit_prompt_lines {
        @!prompt_lines.splice( 0, $limit_prompt_lines );
    }
}


method !_pos_to_default {
    ROW: for ^$!rc2idx -> $row {
        COL: for ^$!rc2idx[$row] -> $col {
            if %!o<default> == $!rc2idx[$row][$col] {
                $!p = [ $row, $col ];
                last ROW;
            }
        }
    }
    $!first_page_row = $!avail_h * ( $!p[R] div $!avail_h );
    $!last_page_row  = $!first_page_row + $!avail_h - 1;
    $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
}

method !_set_pp_print_fmt {
    if $!rc2idx.elems / $!avail_h > 1 || %!o<footer>.chars {
        $!avail_h -= 1; #
        $!page_count = $!rc2idx.end div $!avail_h + 1;
        my $page_count_w = $!page_count.chars;
        if %!o<footer>.chars {
            $!pp_row_fmt = "\%0{$page_count_w}d/{$!page_count} %!o<footer>";
        }
        else {
            $!pp_row_fmt = "--- Page \%0{$page_count_w}d/{$!page_count} ---";
        }
        if sprintf( $!pp_row_fmt, $!page_count ).chars > $!avail_w {
            $!pp_row_fmt = "\%0{$page_count_w}d/{$!page_count}";
            if sprintf( $!pp_row_fmt, $!page_count ).chars > $!avail_w {
                $page_count_w = $!avail_w if $page_count_w > $!avail_w;
                $!pp_row_fmt = "\%0{$page_count_w}.{$page_count_w}s";
            }
        }
    }
    else {
        $!pp_row_fmt = Str;
        $!page_count = 1;
    }
}


method !_pad_str_to_colwidth ( Int $i ) {
    if %!o<ll> || $!all_in_one_row { # if 'll' is set, all list elements must have the same length
        return @!list[$i];
    }
    my Int $str_w = @!w_list[$i];
    if $str_w < $!col_w {
        if %!o<alignment> == 0 {
            return @!list[$i] ~ " " x ( $!col_w - $str_w );
        }
        elsif %!o<alignment> == 1 {
            return " " x ( $!col_w - $str_w ) ~ @!list[$i];
        }
        elsif %!o<alignment> == 2 {
            my Int $fill = $!col_w - $str_w;
            my Int $half_fill = $fill div 2;
            return " " x $half_fill ~ @!list[$i] ~ " " x ( $fill - $half_fill );
        }
    }
    else {
        return @!list[$i];
    }
}


method !_mouse_info_to_key ( Int $abs_cursor_Y, Int $button, Int $abs_mouse_X, Int $abs_mouse_Y ) {
    if $button == 4 {
        return 'PageUp';
    }
    elsif $button == 5 {
        return 'PageDown';
    }
    # $abs_cursor_Y, $abs_mouse_X, $abs_mouse_Y, $abs_Y_top_row: base index = 1
    my Int $abs_Y_top_row = $abs_cursor_Y - $!cursor_row;
    if $abs_mouse_Y < $abs_Y_top_row {
        return;
    }
    my Int $mouse_Y = $abs_mouse_Y - $abs_Y_top_row;
    my Int $mouse_X = $abs_mouse_X;
    if $mouse_Y > $!rc2idx.end {
        return;
    }
    my $matched_col;
    my $end_prev_col = 0;
    my $row = $mouse_Y + $!first_page_row;

    COL: for ^$!rc2idx[$row] -> $col {
        my Int $end_this_col;
        if $!all_in_one_row {
            $end_this_col = $end_prev_col + @!w_list[ $!rc2idx[$row][$col] ] + %!o<pad>;
        }
        else { #
            $end_this_col = $end_prev_col + $!col_w_plus;
        }
        if $col == 0 {
            $end_this_col -= %!o<pad> div 2;
        }
        if $col == $!rc2idx[$row].end && $end_this_col > $!avail_w {
            $end_this_col = $!avail_w;
        }
        if $end_prev_col < $mouse_X && $end_this_col >= $mouse_X {
            $matched_col = $col;
            last COL;
        }
        $end_prev_col = $end_this_col;
    }
    if ! $matched_col.defined {
        return;
    }
    if $button == 1 {
        $!p[R] = $row;
        $!p[C] = $matched_col;
        return '^M';
    }
    if $row != $!p[R] || $matched_col != $!p[C] {
        my $tmp_p = $!p;
        $!p = [ $row, $matched_col ];
        self!_wr_cell( $tmp_p[R], $tmp_p[C] );
        self!_wr_cell( $!p[R], $!p[C] );
    }
    if $button == 3 {
        return ' ';
    }
    else {
        return;
    }
}


sub choose       ( @list, *%opt ) is export( :DEFAULT, :choose )       { Term::Choose.new().choose(       @list, |%opt ) }
sub choose-multi ( @list, *%opt ) is export( :DEFAULT, :choose-multi ) { Term::Choose.new().choose-multi( @list, |%opt ) }
sub pause        ( @list, *%opt ) is export( :DEFAULT, :pause )        { Term::Choose.new().pause(        @list, |%opt ) }

method choose       ( @list, *%opt ) { self!_choose( 0,   @list, |%opt ) }
method choose-multi ( @list, *%opt ) { self!_choose( 1,   @list, |%opt ) }
method pause        ( @list, *%opt ) { self!_choose( Int, @list, |%opt ) }

method !_choose ( Int $multiselect, @!orig_list,
        Int_0_or_1       :$page                 = $!page, # removed 26.03.2019
        Int_0_or_1       :$beep                 = $!beep,
        Int_0_or_1       :$index                = $!index,
        Int_0_or_1       :$mouse                = $!mouse,
        Int_0_or_1       :$order                = $!order,
        Int_0_or_1       :$hide-cursor          = $!hide-cursor,
        Int_0_to_2       :$alignment            = $!alignment,
        Int_0_to_2       :$clear-screen         = $!clear-screen,
        Int_0_to_2       :$color                = $!color,
        Int_0_to_2       :$f3                   = $!f3,
        Int_0_to_2       :$include-highlighted  = $!include-highlighted,
        Int_0_to_2       :$layout               = $!layout,
        Positive_Int     :$keep                 = $!keep,
        Positive_Int     :$ll                   = $!ll,
        Positive_Int     :$max-height           = $!max-height,
        Int_2_or_greater :$max-width            = $!max-width,
        UInt             :$default              = $!default,
        UInt             :$pad                  = $!pad,
        List             :$mark                 = $!mark,
        List             :$meta-items           = $!meta-items,
        List             :$no-spacebar          = $!no-spacebar,
        List             :$tabs-info            = $!tabs-info,
        List             :$tabs-prompt          = $!tabs-prompt,
        Str              :$footer               = $!footer,
        Str              :$info                 = $!info,
        Str              :$prompt               = $!prompt,
        Str              :$empty                = $!empty,
        Str              :$undef                = $!undef,
    ) {
    if ! @!orig_list.elems {
        return;
    }
    # %!o -> make options available in methods
    %!o = :$page, :$beep, :$index, :$mouse, :$order, :$hide-cursor, :$alignment, :$clear-screen, :$color, :$f3,
          :$include-highlighted, :$layout, :$keep, :$ll, :$max-height, :$max-width, :$default, :$pad, :$mark,
          :$meta-items, :$no-spacebar, :$tabs-info, :$tabs-prompt, :$footer, :$info, :$prompt, :$empty, :$undef;
    if ! %!o<prompt>.defined {
        %!o<prompt> = $multiselect.defined ?? 'Your choice' !! 'Continue with ENTER';
    }
    if %*ENV<TC_RESET_AUTO_UP>:exists {
        %*ENV<TC_RESET_AUTO_UP> = 0;
    }
    $!setterm = Term::Choose::SetTerm.new( :$mouse :$hide-cursor, :$clear-screen );
    $!setterm.init-term();
    self!_avail_screen_size();
    self!_prepare_new_copy_of_list();
    self!_wr_first_screen( $multiselect );
    my $fast_page = 10;
    if $!page_count > 10_000 {
        $fast_page = 20;
    }
    my Array $saved_pos;
    my $return;

    react {
        whenever signal(SIGTERM,SIGINT,SIGQUIT,SIGHUP) -> $sig {
            $!setterm.restore-term( $!i_row + @!prompt_lines );
            say "Received signal: $sig";
            exit;
        }
        whenever read-key( %!o<mouse> ) -> $c is rw {
            if $c ~~ Array {
                $c = self!_mouse_info_to_key( |$c );
            }
            #if ! $c.defined {
            #    $!setterm.restore-term( $!i_row + @!prompt_lines );
            #    die "EOT!";
            #}
            next if ! $c.defined;
            next if $c eq '~'; #
            my ( Int $new_term_w, Int $new_term_h ) = get-term-size();
            if $new_term_w != $!term_w || $new_term_h != $!term_h { #
                if %!o<ll> {
                    #return -1;
                    $return = -1;
                    done();
                }
                %!o<default> = $!rc2idx[ $!p[R] ][ $!p[C] ];
                if $!marked.elems {
                    %!o<mark> = self!_marked_rc2idx();
                }
                $!setterm.restore-term( $!i_row + @!prompt_lines );
                $!setterm.init-term();
                self!_avail_screen_size();
                self!_prepare_new_copy_of_list();
                self!_wr_first_screen( $multiselect );
                next;
            }
            $!page_step = 1;
            if $c eq  'Insert' {
                if $!first_page_row - $fast_page * $!avail_h >= 0 {
                    $!page_step = $fast_page;
                }
                $c = 'PageUp';
            }
            elsif $c eq 'Delete' {
                if $!last_page_row + $fast_page * $!avail_h <= $!rc2idx.end {
                    $!page_step = $fast_page;
                }
                $c = 'PageDown';
            }
            if %*ENV<TC_RESET_AUTO_UP>:exists {   # documentation
                if $c ne '^J' | '^M' {
                    %*ENV<TC_RESET_AUTO_UP> = 1;
                }
            }
            if $saved_pos && $c eq none <PageUp ^B PageDown ^F> {
                $saved_pos = Array;
            }

            # $!rc2idx holds the new list (AoA) formatted in "_list_idx2rc" appropriate to the chosen layout.
            # $!rc2idx does not hold the values directly but the respective list indexes from the original list.
            # If the original list would be ( 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ) and the new formatted list should be
            #     a d g
            #     b e h
            #     c f
            # then the $!rc2idx would look like this
            #     0 3 6
            #     1 4 7
            #     2 5
            # So e.g. the second value in the second row of the new list would be @!list[ $!rc2idx[1][1] ].
            # On the other hand the index of the last row of the new list would be $!rc2idx.end
            # or the index of the last column in the first row would be $!rc2idx[0].end.

            given $c {
                when 'CursorDown' | 'j' {
                    if ! $!rc2idx[ $!p[R]+1 ] || ! $!rc2idx[ $!p[R]+1 ][ $!p[C] ] {
                        self!_beep();
                    }
                    else {
                        $!p[R]++;
                        self!_wr_cell( $!p[R] - 1, $!p[C] ); #
                        if $!p[R] <= $!last_page_row {
                            #self!_wr_cell( $!p[R] - 1, $!p[C] );
                            self!_wr_cell( $!p[R]    , $!p[C] );
                        }
                        else {
                            $!first_page_row = $!last_page_row + 1;
                            $!last_page_row  = $!last_page_row + $!avail_h;
                            $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
                            self!_wr_screen();
                        }
                    }
                }
                when 'CursorUp' | 'k' {
                    if $!p[R] == 0 {
                        self!_beep();
                    }
                    else {
                        $!p[R]--;
                        self!_wr_cell( $!p[R] + 1, $!p[C] ); #
                        if $!p[R] >= $!first_page_row {
                            #self!_wr_cell( $!p[R] + 1, $!p[C] );
                            self!_wr_cell( $!p[R]    , $!p[C] );
                        }
                        else {
                            $!last_page_row  = $!first_page_row - 1;
                            $!first_page_row = $!first_page_row - $!avail_h;
                            $!first_page_row = 0 if $!first_page_row < 0;
                            self!_wr_screen();
                        }
                    }
                }
                when 'CursorRight' | 'l' {
                    if $!p[C] == $!rc2idx[ $!p[R] ].end {
                        self!_beep();
                    }
                    else {
                        $!p[C]++;
                        self!_wr_cell( $!p[R], $!p[C] - 1 );
                        self!_wr_cell( $!p[R], $!p[C]     );
                    }
                }
                when 'CursorLeft' | 'h' {
                    if $!p[C] == 0 {
                        self!_beep();
                    }
                    else {
                        $!p[C]--;
                        self!_wr_cell( $!p[R], $!p[C] + 1 );
                        self!_wr_cell( $!p[R], $!p[C]     );
                    }
                }
                when '^I' { # Tab
                    if $!p[R] == $!rc2idx.end && $!p[C] == $!rc2idx[ $!p[R] ].end {
                        self!_beep();
                    }
                    else {
                        if $!p[C] < $!rc2idx[ $!p[R] ].end {
                            $!p[C]++;
                            self!_wr_cell( $!p[R], $!p[C] - 1 );
                            self!_wr_cell( $!p[R], $!p[C]     );
                        }
                        else {
                            $!p[R]++;
                            $!p[C] = 0;
                            self!_wr_cell( $!p[R] - 1, $!rc2idx[ $!p[R]-1 ].end ); #
                            if $!p[R] <= $!last_page_row {
                                #self!_wr_cell( $!p[R] - 1, $!rc2idx[ $!p[R]-1 ].end );
                                self!_wr_cell( $!p[R]    , $!p[C]                   );
                            }
                            else {
                                $!first_page_row = $!last_page_row + 1;
                                $!last_page_row  = $!last_page_row + $!avail_h;
                                $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
                                self!_wr_screen();
                            }
                        }
                    }
                }
                when 'Backspace' | '^H' {
                    if $!p[C] == 0 && $!p[R] == 0 {
                        self!_beep();
                    }
                    else {
                        if $!p[C] > 0 {
                            $!p[C]--;
                            self!_wr_cell( $!p[R], $!p[C] + 1 );
                            self!_wr_cell( $!p[R], $!p[C]     );
                        }
                        else {
                            $!p[R]--;
                            $!p[C] = $!rc2idx[ $!p[R] ].end;
                            self!_wr_cell( $!p[R] + 1, 0      ); #
                            if $!p[R] >= $!first_page_row {
                                #self!_wr_cell( $!p[R] + 1, 0      );
                                self!_wr_cell( $!p[R]    , $!p[C] );
                            }
                            else {
                                $!last_page_row  = $!first_page_row - 1;
                                $!first_page_row = $!first_page_row - $!avail_h; #
                                $!first_page_row = 0 if $!first_page_row < 0;
                                self!_wr_screen();
                            }
                        }
                    }
                }
                when 'PageUp' | '^B' {
                    if $!first_page_row <= 0 {
                        self!_beep();
                    }
                    else {
                        $!first_page_row = $!avail_h * ( $!p[R] div $!avail_h - $!page_step );
                        $!last_page_row  = $!first_page_row + $!avail_h - 1;
                        if $saved_pos {
                            $!p[R] = $saved_pos[R] + $!first_page_row;
                            $!p[C] = $saved_pos[C];
                            $saved_pos = Array;
                        }
                        else {
                            $!p[R] -= $!avail_h * $!page_step; # after $!first_page_row
                        }
                        self!_wr_screen();
                    }
                }
                when 'PageDown' | '^F' {
                    if $!last_page_row >= $!rc2idx.end {
                        self!_beep();
                    }
                    else {
                        my $backup_row_top = $!first_page_row;
                        $!first_page_row = $!avail_h * ( $!p[R] div $!avail_h + $!page_step );
                        $!last_page_row  = $!first_page_row + $!avail_h - 1;
                        $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
                        if $!p[R] + $!avail_h > $!rc2idx.end || $!p[C] > $!rc2idx[$!p[R] + $!avail_h].end {
                            $saved_pos = [ $!p[R] - $backup_row_top, $!p[C] ];
                            $!p[R] = $!rc2idx.end;
                            if $!p[C] > $!rc2idx[$!p[R]].end {
                                $!p[C] = $!rc2idx[$!p[R]].end;
                            }
                        }
                        else {
                            $!p[R] += $!avail_h * $!page_step;
                        }
                        self!_wr_screen();
                    }
                }
                when 'CursorHome' | '^A' {
                    if $!p[C] == 0 && $!p[R] == 0 {
                        self!_beep();
                    }
                    else {
                        $!p[R] = 0;
                        $!p[C] = 0;
                        $!first_page_row = 0;
                        $!last_page_row  = $!first_page_row + $!avail_h - 1;
                        $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
                        self!_wr_screen();
                    }
                }
                when 'CursorEnd' | '^E' {
                    if %!o<order> == 1 && $!idx_of_last_col_in_last_row < $!rc2idx[0].end {
                        if $!p[R] == $!rc2idx.end - 1 && $!p[C] == $!rc2idx[ $!p[R] ].end {
                            self!_beep();
                        }
                        else {
                            $!p[R] = $!rc2idx.end - 1;
                            $!p[C] = $!rc2idx[ $!p[R] ].end;
                            $!first_page_row = $!rc2idx.elems - ( $!rc2idx.elems % $!avail_h || $!avail_h );
                            if $!first_page_row == $!rc2idx.end {
                                $!first_page_row = $!first_page_row - $!avail_h;
                                $!last_page_row  = $!first_page_row + $!avail_h - 1;
                            }
                            else {
                                $!last_page_row = $!rc2idx.end;
                            }
                            self!_wr_screen();
                        }
                    }
                    else {
                        if $!p[R] == $!rc2idx.end && $!p[C] == $!rc2idx[ $!p[R] ].end {
                            self!_beep();
                        }
                        else {
                            $!p[R] = $!rc2idx.end;
                            $!p[C] = $!rc2idx[ $!p[R] ].end;
                            $!first_page_row = $!rc2idx.elems - ( $!rc2idx.elems % $!avail_h || $!avail_h );
                            $!last_page_row  = $!rc2idx.end;
                            self!_wr_screen();
                        }
                    }
                }
                when 'q' | '^Q' {
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
                    done();
                    #return;
                }
                when '^C' {
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
                    if $!loop {
                        print clr-lines-to-bot;
                        print show-cursor;
                    }
                    "^C".note;
                    exit 1;
                }
                when '^M' { # Enter/Return
                    if $!search {
                        self!_search_end( $multiselect );
                        next;
                    }
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
                    if ! $multiselect.defined {
                        done();
                        #return;
                    }
                    elsif $multiselect == 0 {
                        my Int $i = $!rc2idx[ $!p[R] ][ $!p[C] ];
                        $return = %!o<index> || %!o<ll> ?? $i !! @!orig_list[$i];
                        done();
                    }
                    else {
                        if %!o<include-highlighted> == 1 {
                            $!marked[ $!p[R] ][ $!p[C] ] = True;
                        }
                        elsif %!o<include-highlighted> == 2 && ! self!_marked_rc2idx().elems {
                            $!marked[ $!p[R] ][ $!p[C] ] = True;
                        }
                        if %!o<meta-items>.defined && ! $!marked[ $!p[R] ][ $!p[C] ] {
                            for %!o<meta-items>.list -> $meta_item {
                                if $meta_item == $!rc2idx[ $!p[R] ][ $!p[C] ] {
                                    $!marked[ $!p[R] ][ $!p[C] ] = True;
                                    last;
                                }
                            }
                        }
                        my $indexes = self!_marked_rc2idx();
                        $return = %!o<index> || %!o<ll> ?? $indexes.list !! @!orig_list[$indexes.list];
                        done();
                    }
                }
                when ' ' { # Space
                    if $multiselect {
                        my Int $locked = 0;
                        OUTER_FOR:
                        for 'meta-items', 'no-spacebar' -> $key {
                            if %!o{$key} {
                                for |%!o{$key} -> $index {
                                    if $!rc2idx[ $!p[R] ][ $!p[C] ] == $index {
                                        ++$locked;
                                        last OUTER_FOR;
                                    }
                                }
                            }
                        }
                        if $locked {
                            self!_beep();
                        }
                        else {
                            $!marked[ $!p[R] ][ $!p[C] ] = ! $!marked[ $!p[R] ][ $!p[C] ];
                            self!_wr_cell( $!p[R], $!p[C] );
                        }
                    }
                }
                when '^@' { # Control Space
                    if $multiselect {
                        for ^$!rc2idx -> $row {
                            for ^$!rc2idx[$row] -> $col {
                                $!marked[$row][$col] = ! $!marked[$row][$col];
                            }
                        }
                        if %!o<no-spacebar> {
                            self!_marked_idx2rc( %!o<no-spacebar>, False );
                        }
                        if %!o<meta-items> {
                            self!_marked_idx2rc( %!o<meta-items>, False );
                        }
                        self!_wr_screen();
                    }
                    else {
                        self!_beep();
                    }
                }
                when 'F3' {
                    if %!o<f3> {
                        if %!o<ll> {
                            $!setterm.restore-term( $!i_row + @!prompt_lines );
                            return -13;
                        }
                        if $!search {
                            self!_search_end( $multiselect );
                        }
                        self!_search_begin( $multiselect );
                    }
                    else {
                        self!_beep();
                    }
                }
                default {
                    self!_beep();
                }
            }
        }
    }
    return $return;
}

method !_avail_screen_size {
    ( $!term_w, $!term_h ) = get-term-size();
    ( $!avail_w, $!avail_h ) = ( $!term_w, $!term_h );
    if  %!o<ll>.defined &&  %!o<ll> > $!avail_w {
        $!avail_w += 1;
        # with only one print-column the output doesn't get messed up if an item
        # reaches the right edge of the terminal on a non-MSWin32-OS
    }
    if %!o<max-width> && $!avail_w > %!o<max-width> {
        $!avail_w = %!o<max-width>;
    }
    if $!avail_w < 2 {
        die "Terminal width to small!";
    }
    self!_prepare_prompt();
    if @!prompt_lines.elems {
        $!avail_h -= @!prompt_lines.elems;
    }
    if %!o<max-height> && %!o<max-height> < $!avail_h {
        $!avail_h = %!o<max-height>;
    }
}


method !_wr_first_screen ( Int $multiselect ) {
    $!col_w_plus = $!col_w + %!o<pad>;
    self!_prepare_layout();
    self!_list_idx2rc();
    self!_set_pp_print_fmt;
    $!first_page_row = 0;
    $!last_page_row  = $!avail_h - 1;
    $!last_page_row  = $!rc2idx.end if $!last_page_row > $!rc2idx.end;
    $!p = [ 0, 0 ];
    $!marked = [];
    if %!o<mark> && $multiselect {
        self!_marked_idx2rc( %!o<mark>, True );
    }
    if %!o<default>.defined && %!o<default> <= @!list.end {
        self!_pos_to_default();
    }
    if %!o<clear-screen> || $!page_count > 1 {
        print clear;
    }
    else {
        print clr-lines-to-bot;
    }
    if @!prompt_lines.elems {
        print @!prompt_lines.join( "\n\r" ) ~ "\n\r";
    }
    $!i_col = 0;
    $!i_row = 0;
    self!_wr_screen();
    if %!o<mouse> {
      print get-cursor-position;
    }
    $!cursor_row = $!i_row;
}


method !_wr_screen {
    my @lines;
    if %!o<color> || $!all_in_one_row {
        for $!first_page_row .. $!last_page_row -> $row {
            @lines.push: ( 0 .. $!rc2idx[$row].end ).map({
                self!_cell( $row, $_ )
            }).join: ' ' x %!o<pad>;
        }
    }
    elsif $!marked.elems {
        for $!first_page_row .. $!last_page_row -> $row {
            @lines.push: ( 0 .. $!rc2idx[$row].end ).map({
                $!marked[$row][$_]
                ?? bold() ~ underline() ~ self!_pad_str_to_colwidth( $!rc2idx[$row][$_] ) ~ normal()
                !!                        self!_pad_str_to_colwidth( $!rc2idx[$row][$_] )
            }).join: ' ' x %!o<pad>;
        }
    }
    else {
        for $!first_page_row .. $!last_page_row -> $row {
            @lines.push: ( 0 .. $!rc2idx[$row].end ).map({
                self!_pad_str_to_colwidth( $!rc2idx[$row][$_] )
            }).join: ' ' x %!o<pad>;
        }
    }
    if $!last_page_row == $!rc2idx.end && $!first_page_row != 0 {
        if $!rc2idx[$!last_page_row].end < $!rc2idx[0].end {
            @lines[@lines.end] ~= ' ' x $!col_w_plus * ( $!rc2idx[0].end - $!rc2idx[$!last_page_row].end );
        }
        if $!last_page_row - $!first_page_row < $!avail_h {
            for ( $!last_page_row + 1 - $!first_page_row ) ..^ $!avail_h {
                @lines.push: ' ' x $!avail_w;
            }
        }
    }
    if $!pp_row_fmt.defined {
        if @lines.elems < $!avail_h {
            @lines.append: '' xx $!avail_h - @lines.elems;
        }
        @lines.push: sprintf $!pp_row_fmt, $!first_page_row div $!avail_h + 1;
    }
    print self!_goto( $!first_page_row, 0 ) ~ @lines.join( "\n\r" ) ~ "\r";
    $!i_row += @lines.end;
    $!i_col = 0;
    self!_wr_cell( $!p[R], $!p[C] );
}


method !_wr_cell ( Int $row, Int $col ) {
    print self!_goto( $row, $col ) ~ self!_cell( $row, $col );
    $!i_col += $!all_in_one_row ?? @!w_list[ $!rc2idx[$row][$col] ] !! $!col_w;
}


method !_cell ( Int $row, Int $col ) {
    my Bool \is_current_pos = $row == $!p[R] && $col == $!p[C];
    my $emphasised = is_current_pos ?? reverse() !! '';
    if $!marked[$row][$col] {
        $emphasised = bold() ~ underline() ~ $emphasised;
    }
    my $str = self!_pad_str_to_colwidth( $!rc2idx[$row][$col] );
    if %!o<color> {
        my @color;
        if ! @!orig_list[ $!rc2idx[$row][$col] ].defined {
            @color = %!o<undef>.comb( / \e \[ <[\d;]>* m / );
        }
        elsif ! @!orig_list[ $!rc2idx[$row][$col] ].chars {
            @color = %!o<empty>.comb( / \e \[ <[\d;]>* m / );
        }
        else {
            @color = @!orig_list[ $!rc2idx[$row][$col] ].comb( / \e \[ <[\d;]>* m / );
        }
        if $emphasised {
            for @color {
                # keep cell marked after color escapes
                $_ ~= $emphasised;
            }
            $str = $emphasised ~ $str ~ normal();
            if is_current_pos && %!o<color> == 1 {
                # no color for selected cell if color == 1
                @color = ();
                $str.=subst( / \x[feff] /, '', :g );
            }
        }
        if @color.elems {
            $str.=subst( / \x[feff] /, { @color.shift }, :g );
            if ! $emphasised {
                $str ~= normal();
            }
        }
        return $str;
    }
    elsif $emphasised {
        return $emphasised ~ $str ~ normal();
    }
    else {
        return $str;
    }
}


method !_goto( $row, $col ) {
    my $escape = '';

    # Row
    my \new_i_row = $row - $!first_page_row;
    if new_i_row > $!i_row {
        $escape = $escape ~ "\r\n" x ( new_i_row - $!i_row );
        $!i_col = 0; #!
    }
    elsif new_i_row < $!i_row {
        $escape = $escape ~ up( $!i_row - new_i_row );
    }
    $!i_row = new_i_row;

    # Col
    my \new_i_col = $!all_in_one_row ?? [+] @!w_list[$!rc2idx[$row][ ^$col ]].map: { $_ + %!o<pad> } !! $!col_w_plus * $col;
    if new_i_col > $!i_col {
        $escape = $escape ~ right( new_i_col - $!i_col );
    }
    elsif new_i_col < $!i_col {
        $escape = $escape ~ left( $!i_col - new_i_col );
    }
    $!i_col = new_i_col;

    return $escape;
}


method !_prepare_layout {
    $!all_in_one_row = 0;
    $!single_column = 0;
    if %!o<layout> != 2 && ! %!o<ll> {
        for ^@!list -> $idx {
            $!all_in_one_row += @!w_list[$idx] + %!o<pad>;
            if $!all_in_one_row - %!o<pad> > $!avail_w {
                $!all_in_one_row = 0;
                last;
            }
        }
    }
    if ! $!all_in_one_row {
        if %!o<layout> == 2 {
            $!single_column = 1;
        }
        elsif $!col_w * 2 + %!o<pad> > $!avail_w {
            $!single_column = 1;
        }
        # elements longer than $!avail_w are (unlike p5) already
        # cut to $!avail_w in _prepare_new_copy_of_list
    }
}


method !_list_idx2rc {
    $!rc2idx = [];
    if $!all_in_one_row {
        $!rc2idx[0] = [ ^@!list ];
        $!idx_of_last_col_in_last_row = @!list.end;
    }
    elsif $!single_column {
        for ^@!list -> $i {
            $!rc2idx[$i][0] = $i;
        }
        $!idx_of_last_col_in_last_row = 0;
    }
    else {
        my Int $tmp_avail_w = $!avail_w + %!o<pad>;
        # auto_format
        if %!o<layout> == 1 {
            my Int $tmc = @!list.elems div $!avail_h;
            $tmc++ if @!list.elems % $!avail_h;
            $tmc *= $!col_w_plus;
            if $tmc < $tmp_avail_w {
                $tmc += ( ( $tmp_avail_w - $tmc ) / 1.5 ).Int;
                $tmp_avail_w = $tmc;
            }
        }
        # order
        my Int $cols_per_row = $tmp_avail_w div $!col_w_plus || 1;
        $!idx_of_last_col_in_last_row = ( @!list.elems % $cols_per_row || $cols_per_row ) - 1;
        if %!o<order> == 1 {
            my Int $nr_of_rows = ( @!list.elems - 1 + $cols_per_row ) div $cols_per_row; #
            my Array @rearranged_idx;
            my Int $begin = 0;
            my Int $end = $nr_of_rows - 1;
            for ^$cols_per_row -> $col { # idx
                if $col > $!idx_of_last_col_in_last_row {
                    --$end;
                }
                @rearranged_idx[$col] = [ $begin .. $end ];
                $begin = $end + 1;
                $end = $begin + $nr_of_rows - 1;
            }
            for ^$nr_of_rows -> $row {
                my Int @temp_idx;
                for ^$cols_per_row -> $col {
                    if $row == $nr_of_rows - 1 && $col > $!idx_of_last_col_in_last_row {
                        next;
                    }
                    @temp_idx.push( @rearranged_idx[$col][$row] );
                }
                $!rc2idx.push( @temp_idx );
            }
        }
        else {
            my Int $begin = 0;
            my Int $end = $cols_per_row - 1;
            $end = @!list.end if $end > @!list.end;
            $!rc2idx.push( [ $begin .. $end ] );
            while $end < @!list.end {
                $begin += $cols_per_row;
                $end   += $cols_per_row;
                $end = @!list.end if $end > @!list.end;
                $!rc2idx.push( [ $begin .. $end ] );
            }
        }
    }
}


method !_marked_idx2rc ( List $indexes, Bool $yesno ) {
    if $!single_column {
        for $indexes.list -> $list_idx {
            next if $list_idx > @!list.end;
            $!marked[$list_idx][0] = $yesno;
        }
        return;
    }
    my ( Int $row, Int $col );
    my Int $cols_per_row = $!rc2idx[0].elems;
    if %!o<order> == 0 {
        for $indexes.list -> $list_idx {
            next if $list_idx > @!list.end;
            $row = $list_idx div $cols_per_row;
            $col = $list_idx % $cols_per_row;
            $!marked[$row][$col] = $yesno;
        }
    }
    elsif %!o<order> == 1 {
        my Int $rows_per_col = $!rc2idx.elems;
        my $col_count_last_row = $!idx_of_last_col_in_last_row + 1;
        my $last_list_idx_in_cols_full = $rows_per_col * $col_count_last_row - 1;
        my $first_list_idx_in_cols_short = $last_list_idx_in_cols_full + 1;
        for $indexes.list -> $list_idx {
            next if $list_idx > @!list.end;
            if $list_idx < $last_list_idx_in_cols_full {
                $row = $list_idx % $rows_per_col;
                $col = $list_idx div $rows_per_col;
            }
            else {
                my Int $rows_per_short_col = $rows_per_col - 1;
                $row = ( $list_idx - $first_list_idx_in_cols_short ) % $rows_per_short_col;
                $col = ( $list_idx - $col_count_last_row ) div $rows_per_short_col;
            }
            $!marked[$row][$col] = $yesno;
        }
    }
}


method !_marked_rc2idx {
    my Int @idx;
    if %!o<order> == 1 {
        for ^$!rc2idx[0] -> $col {
            for ^$!rc2idx -> $row {
                @idx.push( $!rc2idx[$row][$col] ) if $!marked[$row][$col];
            }
        }
    }
    else {
        for ^$!rc2idx -> $row {
            for ^$!rc2idx[$row] -> $col {
                @idx.push( $!rc2idx[$row][$col] ) if $!marked[$row][$col];
            }
        }
    }
    return @idx;
}



method !_search_user_input ( $prompt ) {
    my $backup_loop = $!setterm.loop;
    $!setterm.loop = 1;
    $!setterm.restore-term( 0 );
    print "\r", clr-to-eol();
    print show-cursor() if ! %!o<hide_cursor>;
    my $string;
    if ( try require Readline ) === Nil {
        $string = prompt( $prompt );
    }
    else {
        require Readline;
        my $rl = ::('Readline').new;
        $string = $rl.readline( $prompt );
    }
    print hide-cursor() if ! %!o<hide_cursor>;
    $!setterm.init-term();
    $!setterm.loop = $backup_loop;
    return $string;
}


method !_search_begin ( $multiselect is copy ) {
    $!map_search_list_index = [];
    $!search_backup_opt = {};
    $!search_backup_data = {};
    my $search_str = self!_search_user_input( '> search-pattern: ' );
    if ! $search_str.chars {
        self!_search_end( $multiselect );
        return;
    }
    my $regex;
    if %!o<f3> == 1 {
        $regex = rx:i/<$search_str>/;
    }
    else {
        $regex = rx/<$search_str>/;
    }
    my $filtered_list = [];
    my $filtered_w_list = [];
    try { 'Teststring' ~~ $regex }
    if $! {
        my @lines = $!.Str.split( "\n" ).map: { |line-fold( $_, $!avail_w ) };
        $filtered_list = [ @lines ];
        $filtered_w_list = [ $!avail_w xx @lines.elems ];
        $multiselect = 0;
    }
    else {
        for ^@!list -> $i {
            if @!list[$i] ~~ $regex {
                $!map_search_list_index.push: $i;
                $filtered_list.push: @!list[$i];
                $filtered_w_list.push: @!w_list[$i];
            }
        }
        if ! $filtered_list.elems {
            my $message = 'No matches found.';
            $filtered_list = [ $message ];
            $filtered_w_list = [ print-columns( $message ) ];
            $multiselect = 0;
        }
        else {
            %!o<mark> = self!_marked_rc2idx();
            for <meta_items no_spacebar mark> -> $opt {
                if %!o{$opt}.defined {
                    $!search_backup_opt{$opt} = [ |%!o{$opt} ];
                    my $tmp = [];
                    for |%!o{$opt} -> $orig_idx {
                        for ^$!map_search_list_index -> $i {
                            if $!map_search_list_index[$i] == $orig_idx {
                                $tmp.push: $i;
                            }
                        }
                    }
                    %!o{$opt} = $tmp;
                }
            }
        }
    }
    $!search_backup_data<list> = [ @!list ];
    @!list = |$filtered_list;
    $!search_backup_data<w_list> = [ @!w_list ];
    @!w_list = |$filtered_w_list;
    $!search_backup_data<col_w> = $!col_w;
    $!col_w = $filtered_w_list.max;
    %!o<default> = 0;
    $!search = 1;
    my $up = $!i_row + @!prompt_lines + 1; # + 1 => readline
    print up( $up ) if $up;
    self!_avail_screen_size();
    self!_wr_first_screen( $multiselect );
}


method !_search_end ( $multiselect ) {
    if $!map_search_list_index.elems {
        %!o<default> = $!map_search_list_index[ $!rc2idx[ $!p[R] ][ $!p[C] ] ];
        my $tmp_mark = [];
        for |self!_marked_rc2idx() -> $i {
            $tmp_mark.push: $!map_search_list_index[$i];
        }
        if $!search_backup_opt<mark>.defined {
            $tmp_mark.push: |$!search_backup_opt<mark>;
        }
        %!o<mark> = [ |$tmp_mark.unique ];
        for <meta_items no_spacebar> -> $key {
            if $!search_backup_opt{$key}.defined {
                %!o{$key} = $!search_backup_opt{$key};
            }
        }
    }
    if $!search_backup_data.keys {
        @!list = |$!search_backup_data<list>;
        @!w_list = |$!search_backup_data<w_list>;
        $!col_w  = $!search_backup_data<col_w>;
    }
    $!search = 0;
    my $up = $!i_row + @!prompt_lines;
    print up( $up ) if $up;
    print "\r" ~ clr-lines-to-bot;
    self!_avail_screen_size();
    self!_wr_first_screen( $multiselect );
}



=begin pod

=head1 NAME

Term::Choose - Choose items from a list interactively.

=head1 SYNOPSIS

    use Term::Choose :choose;

    my @list = <one two three four five>;


    # Functional interface:
 
    my $chosen = choose( @list, :layout(2) );


    # OO interface:
 
    my $tc = Term::Choose.new( :1mouse, :0order );

    $chosen = $tc.choose( @list, :1layout, :2default );

=head1 DESCRIPTION

Choose interactively from a list of items.

For C<choose>, C<choose-multi> and C<pause> the first argument holds the list of the available choices.

The different options can be passed as key-values pairs. See L<#OPTIONS> to find the available options.

The return values are described in L<#Routines>

=head1 USAGE

To browse through the available list-elements use the keys described below.

If the items of the list don't fit on the screen, the user can scroll to the next (previous) page(s).

If the window size is changed, the screen is rewritten as soon as a key is pressed.

How to choose the items is described in L<#ROUTINES>.

=head2 Keys

=item the C<Arrow> keys (or C<h,j,k,l>) to move up and down or to move to the right and to the left,

=item the C<Tab> key (or C<Ctrl-I>) to move forward, the C<BackSpace> key (or C<Ctrl-H>) to move
backward,

=item the C<PageUp> key (or C<Ctrl-B>) to go back one page, the C<PageDown> key (or C<Ctrl-F>) to go forward one page,

=item the C<Insert> key to go back 10 pages, the C<Delete> key to go forward 10 pages,

=item the C<Home> key (or C<Ctrl-A>) to jump to the beginning of the list, the C<End> key (or C<Ctrl-E>) to jump to the
end of the list.

For the usage of C<SpaceBar>, C<Ctrl-SpaceBar>, C<Return> and the C<q>-key see L<#choose>, L<#choose-multi> and
L<#pause>.

With I<mouse> enabled use the the left mouse key instead the C<Return> key and the right mouse key instead of the
C<SpaceBar> key. Instead of C<PageUp> and C<PageDown> it can be used the mouse wheel. See L<#mouse>

Pressing the C<F3> allows one to enter a regular expression so that only the items that match the regular expression
are displayed. When going back to the unfiltered menu (C<Enter>) the item highlighted in the filtered menu keeps the
highlighting. Also (in I<list context>) marked items retain there markings. The Raku function C<prompt> is used to
read the regular expression if L<Readline> is not available. See option L<#f3>.

=head1 CONSTRUCTOR

The constructor method C<new> can be called with named arguments. For the valid options see L<#OPTIONS>. Setting the
options in C<new> overwrites the default values for the instance.

=head1 ROUTINES

=head2 choose

C<choose> allows the user to choose one item from a list: the highlighted item is returned when C<Return>
is pressed.

C<choose> returns nothing if the C<q> or C<Ctrl-Q> is pressed.

=head2 choose-multi

The user can choose many items.

To choose an item mark the item with the C<SpaceBar>. When C<Return> is pressed C<choose-multi> then returns the marked
items as an Array. If the option I<include-highlighted> is set to C<1>, the highlighted item is also returned.

If C<Return> is pressed with no marked items and L<#include-highlighted> is set to C<2>, the highlighted item is
returned.

C<Ctrl-SpaceBar> (or C<Ctrl-@>) inverts the choices: marked items are unmarked and unmarked items are marked.

C<choose-multi> returns nothing if the C<q> or C<Ctrl-Q> is pressed.

=head2 pause

Nothing can be chosen, nothing is returned but the user can move around and read the output until closed with C<Return>,
C<q> or C<Ctrl-Q>.

=head1 OUTPUT

For the output on the screen the elements of the list are copied and then modified. Chosen elements are returned as they
were passed without modifications.

Modifications:

=item If an element is not defined the value from the option I<undef> is assigned to the element.

=item If an element holds an empty string the value from the option I<empty> is assigned to the element.

=item Tab characters in elements are replaces with a space.

    $element =~ s/\t/ /g;

=item Vertical spaces in elements are squashed to two spaces.

    $element =~ s/\v+/\ \ /g;

=item Code points from the ranges of control, surrogate and noncharacter are removed.

    $element =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;

=item If the length (print columns) of an element is greater than the width of the screen the element is cut and three
dots are attached.

=head1 OPTIONS

Options which expect a number as their value expect integers.

=head3 alignment

0 - elements ordered in columns are aligned to the left (default)

1 - elements ordered in columns are aligned to the right

2 - elements ordered in columns are centered

=head3 beep

0 - off (default)

1 - on

=head3 clear-screen

0 - off (default)

1 - clears the screen before printing the choices

2 - use the alternate screen

=head3 color

If enabled, SRG ANSI escape sequences can be used to color the screen output.

0 - off (default)

1 - on (current selected element not colored)

2 - on (current selected element colored)

=head3 default

With the option I<default> it can be selected an element, which will be highlighted as the default instead of the first
element.

I<default> expects a zero indexed value, so e.g. to highlight the third element the value would be I<2>.

If the passed value is greater than the index of the last array element, the first element is highlighted.

Allowed values: 0 or greater

(default: 0)

=head3 empty

Sets the string displayed on the screen instead of an empty string.

(default: "E<lt>emptyE<gt>")

=head3 footer

Add a string in the bottom line.

(default: undefined)

=head3 f3

Set the behavior of the C<F3> key.

0 - off

1 - case-insensitive search (default)

2 - case-sensitive search

=head3 hide-cursor

0 - keep the terminals highlighting of the cursor position

1 - hide the terminals highlighting of the cursor position (default)

=head3 info

Expects as its value a string. The string is printed above the prompt string.

=head3 index

0 - off (default)

1 - return the indices of the chosen elements instead of the chosen elements.

This option has no meaning for C<pause>.

=head3 keep

I<keep> prevents that all the terminal rows are used by the prompt lines.

Setting I<keep> ensures that at least I<keep> terminal rows are available for printing "list"-rows.

If the terminal height is less than I<keep>, I<keep> is set to the terminal height.

Allowed values: 1 or greater

(default: 5)

=head3 layout

From broad to narrow: 0 > 1 > 2

=item 0 - layout off

=begin code

    .-------------------.   .-------------------.   .-------------------.   .-------------------.
    | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |
    |                   |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |   | .. .. .. .. .. .. |
    |                   |   |                   |   | .. .. .. ..       |   | .. .. .. .. .. .. |
    |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
    |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
    |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
    '-------------------'   '--- ---------------'   '-------------------'   '-------------------'

=end code

=item 1 - (default)

=begin code

    .-------------------.   .-------------------.   .-------------------.   .-------------------.
    | .. .. .. .. .. .. |   | .. .. .. ..       |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
    |                   |   | .. .. .. ..       |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
    |                   |   | .. ..             |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
    |                   |   |                   |   | .. .. .. .. ..    |   | .. .. .. .. .. .. |
    |                   |   |                   |   | .. .. ..          |   | .. .. .. .. .. .. |
    |                   |   |                   |   |                   |   | .. .. .. .. .. .. |
    '-------------------'   '-------------------'   '-------------------'   '-------------------'

=end code

=item 2 - all in a single column

=begin code

    .-------------------.   .-------------------.   .-------------------.   .-------------------.
    | ..                |   | ..                |   | ..                |   | ..                |
    | ..                |   | ..                |   | ..                |   | ..                |
    | ..                |   | ..                |   | ..                |   | ..                |
    |                   |   | ..                |   | ..                |   | ..                |
    |                   |   |                   |   | ..                |   | ..                |
    |                   |   |                   |   |                   |   | ..                |
    '-------------------'   '-------------------'   '-------------------'   '-------------------'

=end code

=head3 max-height

If defined sets the maximal number of rows used for printing list items.

If the available height is less than I<max-height>, I<max-height> is set to the available height.

Height in this context means number of print rows.

I<max-height> overwrites I<keep> if I<max-height> is set to a value less than I<keep>.

Allowed values: 1 or greater

(default: undefined)

=head3 max-width

If defined, sets the maximal output width to I<max-width> if the terminal width is greater than I<max-width>.

To prevent the "auto-format" to use a width less than I<max-width> set I<layout> to C<0>.

Width refers here to the number of print columns.

Allowed values: 2 or greater

(default: undefined)

=head3 mouse

0 - no mouse (default)

1 - mouse enabled

=head3 order

If the output has more than one row and more than one column:

0 - elements are ordered horizontally

1 - elements are ordered vertically (default)

=head3 pad

Sets the number of whitespaces between columns. (default: 2)

Allowed values: 0 or greater

=head3 prompt

If I<prompt> is undefined, a default prompt-string will be shown.

If the I<prompt> value is an empty string (""), no prompt-line will be shown.

=head3 tabs-info

If I<info> lines are folded, the option I<tabs-info> allows one to insert spaces at beginning of the folded lines.

The option I<tabs-info> expects a reference to an array with one or two elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- a second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart
from the beginning of paragraphs

Allowed values: 0 or greater. Elements beyond the second are ignored.

(default: undefined)

=head3 tabs-prompt

If I<prompt> lines are folded, the option I<tabs-prompt> allows one to insert spaces at beginning of the folded lines.

The option I<tabs-prompt> expects a reference to an array with one or two elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- a second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart
from the beginning of paragraphs

Allowed values: 0 or greater. Elements beyond the second are ignored.

(default: undefined)

=head3 undef

Sets the string displayed on the screen instead of an undefined element.

default: "E<lt>undefE<gt>"

=head2 options choose-multi

=head3 include-highlighted

0 - C<choose-multi> returns the items marked with the C<SpaceBar>. (default)

1 - C<choose-multi> returns the items marked with the C<SpaceBar> plus the highlighted item.

2 - C<choose-multi> returns the items marked with the C<SpaceBar>. If no items are marked with the C<SpaceBar>, the
highlighted item is returned.

=head3 mark

I<mark> expects as its value a list of indexes (integers). C<choose-multi> preselects the list-elements correlating to
these indexes.

(default: undefined)

=head3 meta-items

I<meta_items> expects as its value a list of indexes (integers). List-elements correlating to these indexes can not be
marked with the C<SpaceBar> or with the right mouse key but if one of these elements is the highlighted item it is added
to the chosen items when C<Return> is pressed.

Elements greater than the last index of the list are ignored.

(default: undefined)

=head3 no-spacebar

I<no-spacebar> expects as its value an list. The elements of the list are indexes of choices which should not be
markable with the C<SpaceBar> or with the right mouse key. If an element is preselected with the option I<mark> and also
marked as not selectable with the option I<no-spacebar>, the user can not remove the preselection of this element.

(default: undefined)

=head1 MULTITHREADING

C<Term::Choose> uses multithreading when preparing the list for the output; the number of threads to use can be set with
the environment variable C<TC_NUM_THREADS>.

=head1 REQUIREMENTS

=head2 tput

The control of the cursor location, the highlighting of the cursor position and the marked elements and other options on
the terminal is done via escape sequences.

C<tput> is used to get the appropriate escape sequences.

If the environment variable C<TERM> is not set to a true value, C<vt100> is used instead as the terminal type for
C<tput>.

Escape sequences to handle mouse input are hardcoded.

=head2 Monospaced font

It is required a terminal that uses a monospaced font which supports the printed characters.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on the C<choose> function from the L<Term::Clui|https://metacpan.org/pod/Term::Clui> module.

Thanks to the people from L<Perl-Community.de|http://www.perl-community.de>, from
L<stackoverflow|http://stackoverflow.com> and from L<#perl6 on irc.freenode.net|irc://irc.freenode.net/#perl6> for the
help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2020 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
