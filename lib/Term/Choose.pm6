use v6;

unit class Term::Choose:ver<1.9.1>;

use Term::termios;

use Term::Choose::ReadKey;
use Term::Choose::Screen;
use Term::Choose::LineFold;
use Term::Choose::SetTerm;

#END {
#    if $*EXIT {    # 2023.02
#        run 'stty', 'sane';
#        print "\n", clear-to-end-of-screen;
#        print show-cursor;
#        print restore-screen;
#    }
#}

constant R  = 0;
constant C  = 1;
constant WIDTH_CURSOR = 1;

subset Positive_Int of Int where * > 0;
subset Int_0_to_2   of Int where * == 0|1|2;
subset Int_0_or_1   of Int where * == 0|1;

has Int_0_or_1   $.beep                 = 0;
has Int_0_or_1   $.clear-screen         = 1;
has Int_0_or_1   $.hide-cursor          = 1;
has Int_0_or_1   $.index                = 0;
has Int_0_or_1   $.loop                 = 0; # privat
has Int_0_or_1   $.mouse                = 0;
has Int_0_or_1   $.order                = 1;
has Int_0_or_1   $.save-screen          = 0;
has Int_0_to_2   $.alignment            = 0;
has Int_0_to_2   $.color                = 0;
has Int_0_to_2   $.include-highlighted  = 0;
has Int_0_to_2   $.layout               = 1;
has Int_0_to_2   $.page                 = 1;
has Int_0_to_2   $.search               = 1;
has Positive_Int $.keep                 = 5;
has Positive_Int $.ll;                       # privat
has Positive_Int $.max-cols;
has Positive_Int $.max-height;
has Positive_Int $.max-width;
has UInt         $.default              = 0;
has UInt         $.pad                  = 2;
has List         $.margin;
has List         $.mark;
has List         $.meta-items;
has List         $.no-spacebar;
has List         $.tabs-info;
has List         $.tabs-prompt;
has Str          $.empty                = '<empty>';
has Str          $.footer               = '';
has Str          $.info                 = '';
has Str          $.prompt;              # undefined because: undef => default prompt-line, '' => no prompt-line
has Str          $.undef                = '<undef>';

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
has Int   @!w_list_items;
has Int   $!single_column;
has Int   $!all_in_one_row;
has Int   $!idx_of_last_col_in_last_row;
has Int   $!page_count;
has Str   $!pp_row_fmt;
has Str   @!prompt_lines;
has Str   $!spare_prompt_line;
has Int   $!first_page_row;
has Int   $!last_page_row;
has Array $!rc2idx;
has Array $!p;
has Array $!marked;
has Int   $!page_step;
has Int   $!cursor_row;

has Str   $!filter_string = '';
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
        while $threads > @!orig_list.elems { ##
            last if $threads < 2;
            $threads = $threads div 2;
        }
        my Int $size = @!orig_list.elems div $threads;
        my Array @portions = ( ^$threads ).map: { [ $size * $_, $size * ( $_ + 1 ) ] }; ##
        @portions[*-1][1] = @!orig_list.elems;
        my Promise @promise;
        for @portions -> $range {
            @promise.push: start {
                my Int %cache;
                do for $range[0] ..^ $range[1] -> $i {
                    if %!o<color> {
                        if ! @!orig_list[$i].defined {
                            my ( $str, $len ) = to-printwidth(
                                %!o<undef>.subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                %cache
                            );
                            $i, $str, $len;
                        }
                        elsif @!orig_list[$i] eq '' {
                            my ( $str, $len ) = to-printwidth(
                                %!o<empty>.subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                %cache
                            );
                            $i, $str, $len;
                        }
                        else {
                                my ( $str, $len ) = to-printwidth(
                                @!orig_list[$i].subst( / \x[feff] /,  '', :g ).subst( / \e \[ <[\d;]>* m /, "\x[feff]", :g ).subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                %cache
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
                                %cache
                            );
                            $i, $str, $len;
                        }
                        elsif @!orig_list[$i] eq '' {
                            my ( $str, $len ) = to-printwidth(
                                %!o<empty>.subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                %cache
                            );
                            $i, $str, $len;
                        }
                        else {
                            my ( $str, $len ) = to-printwidth(
                                @!orig_list[$i].subst( / \t /,  ' ', :g ).subst( / \v+ /,  '  ', :g ).subst( / <:Cc+:Noncharacter_Code_Point+:Cs> /, '', :g ),
                                $!avail_w,
                                True,
                                %cache
                            );
                            $i, $str, $len;
                        }
                    }
                }
            };
        }
        @!list = ();
        @!w_list_items = ();
        for await @promise -> @portion {
            for @portion {
                @!list[.[0]] = .[1];
                @!w_list_items[.[0]] = .[2];
            }
        }
        $!col_w = @!w_list_items.max;
    }
}


method !_beep {
    print beep if %!o<beep>;
}


method !_prepare_prompt_and_info {
    @!prompt_lines = ();
    if %!o<margin>[0] {
        @!prompt_lines.append: '' xx %!o<margin>[0];
    }
    my Int $info_w = $!term_w;
    #if $*KERNEL ne any 'MSWin32', 'cygwin' {
        $info_w += WIDTH_CURSOR;
    #}
    if %!o<max-width> && $info_w > %!o<max-width> { #
        $info_w = %!o<max-width>;
    }
    if %!o<info>.chars {
        my Int $init     = %!o<tabs-info>[0] // 0;
        my Int $subseq   = %!o<tabs-info>[1] // 0;
        my Int $r_margin = %!o<tabs-info>[2] // 0;
        @!prompt_lines.push: |line-fold(
            %!o<info>,
            $info_w - $r_margin,
            :init-tab( ' ' x $init ), :subseq-tab( ' ' x $subseq ), :color( %!o<color> ) );
    }
    if %!o<prompt>.chars {
        my Int $init     = %!o<tabs-prompt>[0] // 0;
        my Int $subseq   = %!o<tabs-prompt>[1] // 0;
        my Int $r_margin = %!o<tabs-prompt>[2] // 0;
        @!prompt_lines.push: |line-fold(
            %!o<prompt>,
            $info_w - $r_margin,
            :init-tab( ' ' x $init ), :subseq-tab( ' ' x $subseq ), :color( %!o<color> ) );
    }
    if $!filter_string.chars {
        my Int $init     = %!o<margin>[3] // 0;
        my Int $subseq   = %!o<margin>[3] // 0;
        my Int $r_margin = %!o<margin>[1] // 0;
        @!prompt_lines.push: |line-fold(
            ( %!o<search> == 1 ?? 'Filter: i/' !! 'Filter: /' ) ~ $!filter_string ~ '/',
            $info_w - $r_margin,
            :init-tab( ' ' x $init ), :subseq-tab( ' ' x $subseq ), :color( %!o<color> ) );
    }
    if ! @!prompt_lines.elems {
        return;
    }
    my Int $keep = %!o<keep>;
    $keep += 1; # page row
    if $keep > $!term_h {
        $keep = $!term_h;
    }
    my Int $limit_prompt_lines = $!avail_h - $keep;
    if @!prompt_lines.elems > $limit_prompt_lines {
        $!spare_prompt_line = @!prompt_lines[$limit_prompt_lines];
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


method !_set_pp_row_fmt {
    $!page_count = $!rc2idx.end div $!avail_h + 1;
    if  ! %!o<page> {
        $!pp_row_fmt = Str;
    }
    elsif %!o<page> == 1 && $!page_count == 1 {
        if $!spare_prompt_line {
            @!prompt_lines.push: $!spare_prompt_line;
        }
        else {
            $!avail_h++;
        }
        $!pp_row_fmt = Str;
    }
    else {
        my Int $page_count_w = $!page_count.chars;
        $!pp_row_fmt = '--- %0' ~ $page_count_w ~ 'd/' ~ $!page_count ~ ' ---'; ##
        if %!o<footer>.chars {
            $!pp_row_fmt ~= %!o<footer>;
        }
        if sprintf( $!pp_row_fmt, $!page_count ).chars > $!avail_w { # color
            $!pp_row_fmt = '%0' ~ $page_count_w ~ 'd/' ~ $!page_count;
            if sprintf( $!pp_row_fmt, $!page_count ).chars > $!avail_w {
                $page_count_w = $!avail_w if $page_count_w > $!avail_w;
                $!pp_row_fmt = '%0' ~ $page_count_w ~ '.' ~ $page_count_w ~ 's';
            }
        }
    }
}


method !_pad_str_to_colwidth ( Int $i ) {
    if %!o<ll> || $!all_in_one_row { # if 'll' is set, all list elements must be defined and have the same length
        return @!list[$i];
    }
    my Int $str_w = @!w_list_items[$i];
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
    my Int $matched_col;
    my Int $end_prev_col = 0;
    my Int $row = $mouse_Y + $!first_page_row;

    COL: for ^$!rc2idx[$row] -> $col {
        my Int $end_this_col;
        if $!all_in_one_row {
            $end_this_col = $end_prev_col + @!w_list_items[ $!rc2idx[$row][$col] ] + %!o<pad>;
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
        my Array $tmp_p = $!p;
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


method !_modify_options ( $multiselect ) {
    if %!o<save-screen> {
        %!o<clear-screen> = 1;
    }
    if %!o<max-cols>.defined && %!o<max-cols> == 1 {
        %!o<layout> = 2;
    }
    if %!o<footer>.chars && %!o<page> != 2 {
        %!o<page> = 2;
    }
    if %!o<page> == 2 && ! %!o<clear-screen> {
        %!o<clear-screen> = 1;
    }
    if %!o<max-cols> && %!o<layout> != 0 && %!o<layout> != 2 { ##
        %!o<layout> = 0;
    }
    if %!o<ll> && ! %!o<index> {
        %!o<index> = 1;
    }
    if ! %!o<prompt>.defined {
        %!o<prompt> = $multiselect.defined ?? 'Your choice' !! 'Continue with ENTER';
    }
    if %!o<margin> {
        if ! %!o<tabs-prompt>.defined {
            %!o<tabs-prompt> = %!o<margin>[3,3,1];
        }
        if ! %!o<tabs-info>.defined {
            %!o<tabs-info> = %!o<margin>[3,3,1];
        }
    }
}


sub choose       ( @list, *%opt ) is export( :DEFAULT, :choose )       { Term::Choose.new().choose(       @list, |%opt ) }
sub choose-multi ( @list, *%opt ) is export( :DEFAULT, :choose-multi ) { Term::Choose.new().choose-multi( @list, |%opt ) }
sub pause        ( @list, *%opt ) is export( :DEFAULT, :pause )        { Term::Choose.new().pause(        @list, |%opt ) }

method choose       ( @list, *%opt ) { self!_choose( 0,   @list, |%opt ) }
method choose-multi ( @list, *%opt ) { self!_choose( 1,   @list, |%opt ) }
method pause        ( @list, *%opt ) { self!_choose( Int, @list, |%opt ) }

method !_choose ( Int $multiselect, @!orig_list,
        Int_0_or_1   :$beep                 = $!beep,
        Int_0_or_1   :$clear-screen         = $!clear-screen,
        Int_0_or_1   :$hide-cursor          = $!hide-cursor,
        Int_0_or_1   :$index                = $!index,
        Int_0_or_1   :$mouse                = $!mouse,
        Int_0_or_1   :$order                = $!order,
        Int_0_or_1   :$save-screen          = $!save-screen,
        Int_0_to_2   :$alignment            = $!alignment,
        Int_0_to_2   :$color                = $!color,
        Int_0_to_2   :$include-highlighted  = $!include-highlighted,
        Int_0_to_2   :$layout               = $!layout,
        Int_0_to_2   :$page                 = $!page,
        Int_0_to_2   :$search               = $!search,
        Positive_Int :$keep                 = $!keep,
        Positive_Int :$ll                   = $!ll,
        Positive_Int :$max-cols             = $!max-cols,
        Positive_Int :$max-height           = $!max-height,
        Positive_Int :$max-width            = $!max-width,
        UInt         :$default              = $!default,
        UInt         :$pad                  = $!pad,
        List         :$margin               = $!margin,
        List         :$mark                 = $!mark,
        List         :$meta-items           = $!meta-items,
        List         :$no-spacebar          = $!no-spacebar,
        List         :$tabs-info            = $!tabs-info,
        List         :$tabs-prompt          = $!tabs-prompt,
        Str          :$empty                = $!empty,
        Str          :$footer               = $!footer,
        Str          :$info                 = $!info,
        Str          :$prompt               = $!prompt,
        Str          :$undef                = $!undef,
    ) {
    # %!o -> make options available in methods
    %!o = :$alignment, :$beep, :$clear-screen, :$color, :$default, :$empty, :$footer, :$hide-cursor,
          :$include-highlighted, :$index, :$info, :$keep, :$layout, :$ll, :$margin, :$mark, :$max-cols, :$max-height,
          :$max-width, :$meta-items, :$mouse, :$no-spacebar, :$order, :$pad, :$page, :$prompt, :$save-screen, :$search,
          :$tabs-info, :$tabs-prompt, :$undef;
    self!_modify_options( $multiselect );
    if ! @!orig_list.elems {
        if ! $multiselect.defined {
            return;
        }
        elsif ( ! $multiselect ) {
            return %!o<index> ?? Int !! Str;
        }
        else {
            return %!o<index> ?? Array[Int].new() !! Array.new();
        }
    }
    if %*ENV<TC_RESET_AUTO_UP>:exists {
        %*ENV<TC_RESET_AUTO_UP> = 0;
    }
    $!setterm = Term::Choose::SetTerm.new( :$mouse :$hide-cursor, :$save-screen );
    $!setterm.init-term();
    self!_avail_screen_size();
    self!_prepare_new_copy_of_list();
    self!_wr_first_screen( $multiselect );
    my Int $fast_page = 10;
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
                    $return = -1;
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
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
                when 'PageUp' | '^P' {
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
                when 'PageDown' | '^N' {
                    if $!last_page_row >= $!rc2idx.end {
                        self!_beep();
                    }
                    else {
                        my Int $backup_row_top = $!first_page_row;
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
                when '^C' {
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
                    if $!loop {
                        print clear-to-end-of-screen;
                        print show-cursor;
                    }
                    "^C".note;
                    exit 1;
                }
                when 'q' | '^Q' {
                    $!setterm.restore-term( $!i_row + @!prompt_lines );
                    if ! $multiselect.defined {
                        $return = Any;
                    }
                    elsif ( ! $multiselect ) {
                        $return = %!o<index> ?? Int !! Str;
                    }
                    else {
                        $return = %!o<index> ?? Array[Int].new() !! Array.new();
                    }
                    done();
                }
                when '^M' { # Enter/Return
                    if $!filter_string.chars {
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
                        $return = %!o<index> ?? $i !! @!orig_list[$i];
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
                        my Array[Int] $indexes = self!_marked_rc2idx();
                        $return = %!o<index> ?? $indexes !! [ @!orig_list[|$indexes] ];
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
                when '^F' {
                    if %!o<search> {
                        if %!o<ll> {
                            %*ENV<TC_POS_AT_SEARCH> = $!rc2idx[ $!p[R] ][ $!p[C] ];
                            $!setterm.restore-term( $!i_row + @!prompt_lines );
                            $return = -13;
                            done();
                        }
                        if $!filter_string.chars {
                            self!_search_end( $multiselect );
                            # loop up to read-key before a new _search_begin because get-cursor-position in
                            # _wr_first_screen in _search_end fills the input puffer with the cursor position
                        }
                        else {
                            self!_search_begin( $multiselect );
                        }
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
    # No `return` inside the `react`-block!
    if $multiselect {
        return @$return;
    }
    else {
        return $return;
    }
}

method !_avail_screen_size {
    ( $!term_w, $!term_h ) = get-term-size();
    ( $!avail_w, $!avail_h ) = ( $!term_w, $!term_h );
    if %!o<margin>[1] {
        $!avail_w -= %!o<margin>[1];
    }
    if %!o<margin>[3] {
        $!avail_w -= %!o<margin>[3];
    }
    if  %!o<margin>[1] || ( %!o<ll>.defined && %!o<ll> > $!avail_w ) {
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
    self!_prepare_prompt_and_info();
    if @!prompt_lines.elems {
        $!avail_h -= @!prompt_lines.elems;
    }
    if %!o<margin>[2] {
        $!avail_h -= %!o<margin>[2];
    }
    if %!o<page> {
        $!avail_h--;
    }
    if %!o<max-height> && %!o<max-height> < $!avail_h {
        $!avail_h = %!o<max-height>;
    }
}


method !_wr_first_screen ( Int $multiselect ) {
    $!col_w_plus = $!col_w + %!o<pad>;
    self!_prepare_layout();
    self!_list_idx2rc();
    self!_set_pp_row_fmt;
    $!first_page_row = 0;
    $!last_page_row = $!avail_h - 1;
    if $!last_page_row > $!rc2idx.end {
        $!last_page_row = $!rc2idx.end;
    }
    $!p = [ 0, 0 ];
    $!marked = [];
    if %!o<mark> && $multiselect {
        self!_marked_idx2rc( %!o<mark>, True );
    }
    if %!o<default>.defined && %!o<default> <= @!list.end {
        self!_pos_to_default();
    }
    if %!o<clear-screen> || $!page_count > 1 {
        print clear-screen();
    }
    else {
        print clear-to-end-of-screen;
    }
    if @!prompt_lines.elems {
        print @!prompt_lines.join( "\n\r" ) ~ "\n\r";
    }
    if %!o<margin>[3] {
        print right( %!o<margin>[3] );
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
    my Str @lines;
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
    if %!o<margin>[2] {
        @lines.append: '' xx %!o<margin>[2];
    }
    if %!o<margin>[3] {
        print self!_goto( $!first_page_row, 0 ) ~ @lines.join( "\n\r" ~ right( %!o<margin>[3] ) ) ~ "\r" ~ right( %!o<margin>[3] );
    }
    else {
        print self!_goto( $!first_page_row, 0 ) ~ @lines.join( "\n\r" ) ~ "\r";
    }
    $!i_row += @lines.end;
    $!i_col = 0;
    self!_wr_cell( $!p[R], $!p[C] );
}


method !_wr_cell ( Int $row, Int $col ) {
    print self!_goto( $row, $col ) ~ self!_cell( $row, $col );
    $!i_col += $!all_in_one_row ?? @!w_list_items[ $!rc2idx[$row][$col] ] !! $!col_w;
}


method !_cell ( Int $row, Int $col ) {
    my Bool \is_current_pos = $row == $!p[R] && $col == $!p[C];
    my Str $emphasised = is_current_pos ?? reverse() !! '';
    if $!marked[$row][$col] {
        $emphasised = bold() ~ underline() ~ $emphasised;
    }
    my Int $i = $!rc2idx[$row][$col];
    if %!o<ll> {
        if %!o<color> {
            my $str = @!list[$i];
            if $emphasised {
                if is_current_pos && %!o<color> == 1 {
                    # no color for the selected cell if color == 1
                    $str.=subst( / \e \[ <[\d;]>* m /, '', :g );
                }
                else {
                    # keep marked cells marked after color escapes
                    $str.=subst( / <?after \e \[ <[\d;]>* m > /, $emphasised, :g );
                }
                $str = $emphasised ~ $str;
            }
            return $str ~ normal(); # if \e[
        }
        else {
            if $emphasised {
                return $emphasised ~ @!list[$i] ~ normal();
            }
            else {
                return @!list[$i];
            }
        }
    }
    else {
        my Str $str = self!_pad_str_to_colwidth( $i );
        if %!o<color> {
            my Str @color;
            if ! @!orig_list[$i].defined {
                @color = %!o<undef>.comb( / \e \[ <[\d;]>* m / );
            }
            elsif ! @!orig_list[$i].chars {
                @color = %!o<empty>.comb( / \e \[ <[\d;]>* m / );
            }
            else {
                @color = @!orig_list[$i].comb( / \e \[ <[\d;]>* m / );
            }
            if $emphasised {
                for @color {
                    # keep cell marked after color escapes
                    $_ ~= $emphasised;
                }
                $str = $emphasised ~ $str ~ normal();
                if is_current_pos && %!o<color> == 1 { ## ^ 
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
}


method !_goto( $row, $col ) {
    my Str $escape = '';

    # Row
    my \new_i_row = $row - $!first_page_row;
    if new_i_row > $!i_row {
        $escape = $escape ~ down( new_i_row - $!i_row );
    }
    elsif new_i_row < $!i_row {
        $escape = $escape ~ up( $!i_row - new_i_row );
    }
    $!i_row = new_i_row;

    # Col
    my \new_i_col = $!all_in_one_row ?? [+] @!w_list_items[$!rc2idx[$row][ ^$col ]].map: { $_ + %!o<pad> } !! $!col_w_plus * $col;
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
    if %!o<layout> <= 1 && ! %!o<ll> {
        for ^@!list -> $idx {
            $!all_in_one_row += @!w_list_items[$idx] + %!o<pad>;
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
        my Int $col_count_last_row = $!idx_of_last_col_in_last_row + 1;
        my Int $last_list_idx_in_cols_full = $rows_per_col * $col_count_last_row - 1;
        my Int $first_list_idx_in_cols_short = $last_list_idx_in_cols_full + 1;
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
    my Int $backup_loop = $!setterm.loop;
    my Int $backup_save_screen = $!setterm.save-screen;
    $!setterm.loop = 1;
    $!setterm.save-screen = 0;
    $!setterm.restore-term( 0 );
    print clear-screen();
    if @!prompt_lines.elems {
        print @!prompt_lines.join( "\n\r" ) ~ "\n\r";
    }
    print show-cursor() if %!o<hide-cursor>;
    my Str $string;
    if ( try require Readline ) === Nil {
        $string = prompt( $prompt );
    }
    else {
        require Readline;
        my $rl = ::('Readline').new;
        $string = $rl.readline( $prompt );
    }
    print hide-cursor() if %!o<hide-cursor>;
    $!setterm.loop = $backup_loop;
    $!setterm.save-screen = $backup_save_screen;
    $!setterm.init-term();
    return $string;
}


method !_search_begin ( $multiselect is copy ) {
    $!map_search_list_index = [];
    $!search_backup_opt = {};
    $!search_backup_data = {};
    my Str $search_str = self!_search_user_input( '> search-pattern: ' );
    if ! $search_str.chars {
        self!_search_end( $multiselect );
        return;
    }
    $!filter_string = $search_str;
    my Regex $regex;
    if %!o<search> == 1 {
        $regex = rx:i/<$search_str>/;
    }
    else {
        $regex = rx/<$search_str>/;
    }
    my Array $filtered_list = [];
    my Array[Int] $filtered_w_list_items = Array[Int].new();
    try { 'Teststring' ~~ $regex }
    if $! {
        my Str @lines = $!.Str.split( "\n" ).map: { |line-fold( $_, $!avail_w ) };
         for @lines -> $line is rw {
            $line = $line ~ ( ' ' x ( $!avail_w - print-columns( $line ) ) );
        }
        $filtered_list = [ @lines ];
        $filtered_w_list_items = Array[Int].new( $!avail_w xx @lines.elems );
        $multiselect = 0;
    }
    else {
        for ^@!list -> $i {
            if @!list[$i] ~~ $regex {
                $!map_search_list_index.push: $i;
                $filtered_list.push: @!list[$i];
                $filtered_w_list_items.push: @!w_list_items[$i];
            }
        }
        if ! $filtered_list.elems {
            my Str $message = 'No matches found.';
            $filtered_list = [ $message ];
            $filtered_w_list_items = Array[Int].new( print-columns( $message ) );
            $multiselect = 0;
        }
        else {
            %!o<mark> = self!_marked_rc2idx();
            for <meta-items no-spacebar mark> -> $opt {
                if %!o{$opt}.defined {
                    $!search_backup_opt{$opt} = [ |%!o{$opt} ];
                    my Array $tmp = [];
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
    $!search_backup_data<w_list_items> = [ @!w_list_items ];
    @!w_list_items = |$filtered_w_list_items;
    $!search_backup_data<col_w> = $!col_w;
    $!col_w = $filtered_w_list_items.max;
    %!o<default> = 0;
    my Int $up = $!i_row + @!prompt_lines + 1; # + 1 => readline
    print up( $up ) if $up;
    self!_avail_screen_size();
    self!_wr_first_screen( $multiselect );
}


method !_search_end ( $multiselect ) {
    if $!map_search_list_index.elems {
        %!o<default> = $!map_search_list_index[ $!rc2idx[ $!p[R] ][ $!p[C] ] ];
        my Int @tmp_mark;
        for |self!_marked_rc2idx() -> $i {
            @tmp_mark.push: $!map_search_list_index[$i];
        }
        if $!search_backup_opt<mark>.defined {
            @tmp_mark.push: |$!search_backup_opt<mark>;
        }
        %!o<mark> = [ |@tmp_mark.unique ]; ##
        for <meta-items no-spacebar> -> $key {
            if $!search_backup_opt{$key}.defined {
                %!o{$key} = $!search_backup_opt{$key};
            }
        }
    }
    if $!search_backup_data.keys { # backed up data to avoid a _prepare_new_copy_of_list after each search
        @!list = |$!search_backup_data<list>;
        @!w_list_items = |$!search_backup_data<w_list_items>;
        $!col_w  = $!search_backup_data<col_w>;
    }
    $!filter_string = '';
    my Int $up = $!i_row + @!prompt_lines;
    print up( $up ) if $up;
    print "\r" ~ clear-to-end-of-screen;
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
 
    my $chosen = choose( @list, :2layout );


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

=item the K<Arrow> keys (or K<h>,K<j>,K<k>,K<l>) to move up and down or to move to the right and to the left,

=item the K<Tab> key (or K<Ctrl-I>) to move forward, the K<BackSpace> key (or K<Ctrl-H>) to move backward,

=item the K<PageUp> key (or K<Ctrl-P>) to go to the previous page, the K<PageDown> key (or K<Ctrl-N>) to go to the next
page,

=item the K<Insert> key to go back 10 pages, the K<Delete> key to go forward 10 pages,

=item the K<Home> key (or K<Ctrl-A>) to jump to the beginning of the list, the K<End> key (or K<Ctrl-E>) to jump to the
end of the list.

For the usage of K<SpaceBar>, K<Ctrl-SpaceBar>, K<Return> and the K<q>-key see L<#choose>, L<#choose-multi> and
L<#pause>.

With I<mouse> enabled use the the left mouse key instead the K<Return> key and the right mouse key instead of the
K<SpaceBar> key. Instead of K<PageUp> and K<PageDown> it can be used the mouse wheel. See L<#mouse>

Pressing the K<Ctrl-F> allows one to enter a regular expression so that only the items that match the regular expression
are displayed. When going back to the unfiltered menu (K<Return>) the item highlighted in the filtered menu keeps the
highlighting. Also (in I<list context>) marked items retain there markings. The Raku function C<prompt> is used to
read the regular expression if L<Readline> is not available. See option L<#search>.

=head1 CONSTRUCTOR

The constructor method C<new> can be called with named arguments. For the valid options see L<#OPTIONS>. Setting the
options in C<new> overwrites the default values for the instance.

=head1 ROUTINES

=head2 choose

C<choose> allows the user to choose one item from a list: the highlighted item is returned when K<Return> is pressed.

C<choose> returns nothing if the K<q> or K<Ctrl-Q> is pressed.

=head2 choose-multi

The user can choose many items.

To choose an item mark the item with the K<SpaceBar>. When K<Return> is pressed C<choose-multi> then returns the marked
items as an Array. If the option I<include-highlighted> is set to C<1>, the highlighted item is also returned.

If K<Return> is pressed with no marked items and L<#include-highlighted> is set to C<2>, the highlighted item is
returned.

K<Ctrl-SpaceBar> (or K<Ctrl-@>) inverts the choices: marked items are unmarked and unmarked items are marked.

C<choose-multi> returns nothing if the K<q> or K<Ctrl-Q> is pressed.

=head2 pause

Nothing can be chosen, nothing is returned but the user can move around and read the output until closed with K<Return>,
K<q> or K<Ctrl-Q>.

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

0 - off

1 - clears the screen before printing the choices (default)

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

If a footer string is passed with this option, the option page is automatically set to C<2>.

(default: undefined)

=head3 hide-cursor

0 - keep the terminals highlighting of the cursor position

1 - hide the terminals highlighting of the cursor position (default)

=head3 index

0 - off (default)

1 - return the indices of the chosen elements instead of the chosen elements.

This option has no meaning for C<pause>.

=head3 info

Expects as its value a string. The string is printed above the prompt string.

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

=head3 margin

The option I<margin> allows one to set a margin on all four sides.

I<margin> expects a list of four elements in the following order:

- top margin (number of terminal lines)

- right margin (number of terminal columns)

- botton margin (number of terminal lines)

- left margin (number of terminal columns)

I<margin> does not affect the I<info> and I<prompt> string. To add margins to the I<info> and I<prompt> string see
I<tabs-info> and I<tabs-prompt>.

Allowed values: 0 or greater. Elements beyond the fourth are ignored.

(default: undefined)

=head3 max-cols

Limit the number of item columns to I<max-cols>.

Allowed values: 1 or greater

(default: undefined)

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

=head3 page

0 - off

1 - print the page number on the bottom of the screen. If all the choices fit into one page, the page number is not
displayed. (default)

2 - the page number is always displayed even with only one page. Setting page to 2 automatically enables the option
clear-screen.

=head3 prompt

If I<prompt> is undefined, a default prompt-string will be shown.

If the I<prompt> value is an empty string (""), no prompt-line will be shown.

(default: undefined)

=head3 save-screen

0 - off (default)

1 - use the alternate screen

=head3 search

Set the behavior of K<Ctrl-F>.

0 - off

1 - case-insensitive search (default)

2 - case-sensitive search

=head3 tabs-info

The option I<tabs-info> allows one to insert spaces at beginning  and the end of I<info> lines.

I<tabs-info> expects a list with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from
the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If I<margin> is set, the initial-tab and the subsequent-tab are set to left-I<margin> and the right margin is
set to right-I<margin>. If I<margin> is not defined, the default is undefined.

=head3 tabs-prompt

The option I<tabs-prompt> allows one to insert spaces at beginning  and the end of I<prompt> lines.

I<tabs-prompt> expects a list with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from
the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If I<margin> is set, the initial-tab and the subsequent-tab are set to left-I<margin> and the right margin is
set to right-I<margin>. If I<margin> is not defined, the default is undefined.

=head3 undef

Sets the string displayed on the screen instead of an undefined element.

(default: "E<lt>undefE<gt>")

=head2 options choose-multi

=head3 include-highlighted

0 - C<choose-multi> returns the items marked with the K<SpaceBar>. (default)

1 - C<choose-multi> returns the items marked with the K<SpaceBar> plus the highlighted item.

2 - C<choose-multi> returns the items marked with the K<SpaceBar>. If no items are marked with the K<SpaceBar>, the
highlighted item is returned.

=head3 mark

I<mark> expects as its value a list of indexes (integers). C<choose-multi> preselects the list-elements correlating to
these indexes.

(default: undefined)

=head3 meta-items

I<meta-items> expects as its value a list of indexes (integers). List-elements correlating to these indexes can not be
marked with the K<SpaceBar> or with the right mouse key but if one of these elements is the highlighted item it is added
to the chosen items when K<Return> is pressed.

Elements greater than the last index of the list are ignored.

(default: undefined)

=head3 no-spacebar

I<no-spacebar> expects as its value an list. The elements of the list are indexes of choices which should not be
markable with the K<SpaceBar> or with the right mouse key. If an element is preselected with the option I<mark> and also
marked as not selectable with the option I<no-spacebar>, the user can not remove the preselection of this element.

(default: undefined)

=head1 MULTITHREADING

C<Term::Choose> uses multithreading when preparing the list for the output; the number of threads to use can be set with
the environment variable C<TC_NUM_THREADS>.

=head1 REQUIREMENTS

=head2 Escape sequences

The control of the cursor location, the highlighting of the cursor position and the marked elements and other options on
the terminal is done via escape sequences.

By default C<Term::Choose> uses C<tput> to get the appropriate escape sequences. If the environment variable
C<TC_ANSI_ESCAPES> is set to a true value, hardcoded ANSI escape sequences are used directly without calling C<tput>.

The escape sequences to enable the I<mouse> mode and the escape sequence to get the cursor position are always
hardcoded.

If the environment variable C<TERM> is not set to a true value, C<vt100> is used instead as the terminal type for
C<tput>.

=head2 Monospaced font

It is required a terminal that uses a monospaced font which supports the printed characters.

=head2 Ambiguous width characters

By default ambiguous width characters are treated as half width. If the environment variable TC_AMBIGUOUS_WIDE is set to
a true value, ambiguous width characters are treated as full width.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on the C<choose> function from the L<Term::Clui|https://metacpan.org/pod/Term::Clui> module.

Thanks to the people from L<Perl-Community.de|http://www.perl-community.de>, from
L<stackoverflow|http://stackoverflow.com> and from L<#perl6 on irc.freenode.net|irc://irc.freenode.net/#perl6> for the
help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2023 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
