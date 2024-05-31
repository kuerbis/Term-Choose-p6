use v6;
unit module Term::Choose::LineFold;

use Term::Choose::Constant;
use Term::Choose::Screen;


my $table;
if %*ENV<TC_AMBIGUOUS_WIDE> {
    require Term::Choose::LineFold::CharWidthAmbiguousWide <&table_char_width>;
    $table = table_char_width();
}
else {
    require Term::Choose::LineFold::CharWidthDefault <&table_char_width>;
    $table = table_char_width();
}


sub char-width( Int $ord_char ) returns Int is export( :DEFAULT, :char-width ) {
    my Int $min = 0;
    my Int $mid;
    my Int $max = $table.end;
    if $ord_char < $table[0][0] || $ord_char > $table[$max][1] {
        return 1;
    }
    while $max >= $min {
        $mid = ( $min + $max ) div 2;
        if $ord_char > $table[$mid][1] {
            $min = $mid + 1;
        }
        elsif $ord_char < $table[$mid][0] {
            $max = $mid - 1;
        }
        else {
            return $table[$mid][2];
        }
    }
    return 1;
}


sub to-printwidth( $str, Int $avail_w, Int $dot=0, %cache? ) is export( :DEFAULT, :to-printwidth ) {
    # no check if char-width returns -1 because no invalid characters (s:g/<:C>//)
    my Int $width = 0;
    my Str @graph;
    for $str.NFC {
        my $w;
        if %cache.EXISTS-KEY( $_ ) {
            $w := %cache.AT-KEY( $_ );
        }
        else {
            $w := %cache.BIND-KEY( $_, char-width( $_ ) );
        }
        if $width + $w > $avail_w {
            if $dot && $avail_w > 5 {
                my \tail = '...';
                my \tail_w = 3;
                while $width > $avail_w - tail_w {
                    $width -= %cache.AT-KEY( @graph.pop.ord );
                }
                return @graph.join( '' ) ~ '.' ~ tail, $width + tail_w + 1 if $width < $avail_w - tail_w;
                return @graph.join( '' )       ~ tail, $width + tail_w;
            }
            return @graph.join( '' ) ~ ' ', $width + 1 if $width < $avail_w;
            return @graph.join( '' )      , $width;
        }
        $width = $width + $w;
        @graph.push: .chr;
    }
    return @graph.join( '' ), $width;
}


sub line-fold( $str, Int $avail_w, Str :$init-tab is copy = '', Str :$subseq-tab is copy = '', :$color = 0, :$join = 0, :$binary-filter = 0 ) is export( :DEFAULT, :line-fold ) {
    if ( ! ( $str // '' ).chars ) {
        return $str;
    }

    for $init-tab, $subseq-tab {
        if $_ { # .gist
            $_ = to-printwidth(
                    $_.=subst( / \t /,  ' ', :g ).=subst( / \v+ /,  '  ', :g ).=subst( &rx-invalid-char, '', :g ),
                    $avail_w div 2,
                    False
                ).[0];
        }
    }
    my $str_copy = $str;
    if $str_copy ~~ Buf {
        $str_copy = $str_copy.gist; # perl
    }
    my Str @colors;
    if $color { # elsif
        $str_copy.=subst( / $(ph-char) /, '', :g );
        $str_copy.=subst( / ( <rx-color> ) /, { @colors.push( $0.Str ) && ph-char }, :g );
    }
    if $binary-filter && $str_copy.substr( 0, 100 ).match: &rx-is-binary {
        if $binary-filter == 2 {
            $str_copy = $str.encode>>.fmt('%02X').Str;
        }
        else {
            $str_copy = 'BNRY';
        }
    }
    $str_copy.=subst( / \t /, ' ', :g );
    $str_copy.=subst( / <rx-invalid-char> && \V /, '' , :g ); #
    if $str_copy !~~ / \R / && print-columns( $init-tab ~ $str_copy ) <= $avail_w {
        return $init-tab ~ $str_copy;
    }
    my Str @lines;

    for $str_copy.lines -> $row {
        my Str @words;
        if $row ~~ / \S / {
            @words = $row.trim-trailing.split( / <?after \S > <?before \s > / );
        }
        else {
            @words = $row;
        }
        my Str $line = $init-tab;

        for 0 .. @words.end -> $i {
            if print-columns( $line ~ @words[$i] ) <= $avail_w {
                $line ~= @words[$i];
            }
            else {
                my Str $tmp;
                if $i == 0 {
                    $tmp = $init-tab ~ @words[$i];
                }
                else {
                    @lines.push: $line;
                    $tmp = $subseq-tab ~ @words[$i].subst( / ^ \s+ /, '' );
                }
                $line = to-printwidth( $tmp, $avail_w, False ).[0];
                my Str $remainder = $tmp.substr( $line.chars );
                while $remainder.chars {
                    @lines.push( $line );
                    $tmp = $subseq-tab ~ $remainder;
                    $line = to-printwidth( $tmp, $avail_w, False ).[0];
                    $remainder = $tmp.substr( $line.chars );
                }
            }
            if $i == @words.end {
                @lines.push( $line );
            }
        }
    }
    if @colors.elems {
        my Str $last_color;
        for @lines -> $line is rw {
            if ! $join {
                if $last_color {
                    $line = $last_color ~ $line;
                }
                my Int $count = $line.comb( "\x[feff]" ).elems;
                if $count {
                    $last_color = @colors[$count - 1];
                }
            }
            $line.=subst( / \x[feff] /, { @colors.shift }, :g );
            if ! @colors.elems {
                last;
            }
        }
    }
    @lines.push( '' ) if $str_copy.ends-with( "\n" );
    return @lines.join: "\n" if $join;
    return @lines; #
}


sub print-columns( $str, %cache? ) returns Int is export( :DEFAULT, :print-columns ) {
    # no check if char-width returns -1 because invalid characters removed
    my Int $width = 0;
    for $str.Str.NFC {
        if %cache.EXISTS-KEY( $_ ) {
            $width = $width + %cache.AT-KEY( $_ );
        }
        else {
            $width = $width + %cache.BIND-KEY( $_, char-width( $_ ) );
        }
    }
    $width;
}


