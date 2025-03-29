use v6;
unit module Term::Choose::LineFold:ver<1.9.6>;

use Term::Choose::Constant;
use Term::Choose::Screen;


my $table;
if %*ENV<TC_AMBIGUOUS_WIDTH_IS_WIDE>:exists {                                       # 29.03.2025
    if %*ENV<TC_AMBIGUOUS_WIDTH_IS_WIDE> {
        require Term::Choose::LineFold::CharWidthAmbiguousWide <&table_char_width>;
        $table = table_char_width();
    }
    else {
        require Term::Choose::LineFold::CharWidthDefault <&table_char_width>;
        $table = table_char_width();
    }
}                                                                                   #
else {                                                                              #
    if %*ENV<TC_AMBIGUOUS_WIDE> {                                                   #
        require Term::Choose::LineFold::CharWidthAmbiguousWide <&table_char_width>; #
        $table = table_char_width();                                                #
    }                                                                               #
    else {                                                                          #
        require Term::Choose::LineFold::CharWidthDefault <&table_char_width>;       #
        $table = table_char_width();                                                #
    }                                                                               #
}                                                                                   #



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


multi sub line-fold( $str, Int $width, Str :$init-tab is copy = '', Str :$subseq-tab is copy = '', Int :$color = 0, Int :$join = 1, Int :$binary-filter = 0 ) is export( :DEFAULT, :line-fold ) {   # 29.03.2025
    return line-fold( $str, :$width, :$init-tab, :$subseq-tab, :$color, :$join, :$binary-filter );                                                                                                  #
}                                                                                                                                                                                                   #
multi sub line-fold(                                                                                                                                                                                #

#sub line-fold(
        $str,
        Positive_Int :$width = get-term-size().[0] + extra-w,
        :$init-tab is copy = '',
        :$subseq-tab is copy = '',
        Int_0_to_2 :$color = 0,
        Int_0_or_1 :$join = 1,
        Int_0_to_2 :$binary-filter = 0
    ) is export( :DEFAULT, :line-fold ) {

    if ! $str.defined || ! $str.chars {
        return $str;
    }
    for $init-tab, $subseq-tab {
        if $_.chars {
            if / ^ <[0..9]>+ $ / {
                $_ = ' ' x $_;
            }
            else {
                $_ = to-printwidth(
                        $_.=subst( / \t /,  ' ', :g ).=subst( / \v+ /,  '  ', :g ).=subst( &rx-invalid-char, '', :g ),
                        $width div 2,
                        False
                ).[0];
            }
        }
    }
    my $str_copy = $str;
    if $str_copy ~~ Buf {
        $str_copy = $str_copy.gist; # perl
    }
    my Str @colors;
    if $color { # 1 or 2 # elsif 
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
    if $str_copy !~~ / \R / && print-columns( $init-tab ~ $str_copy ) <= $width {
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
            if print-columns( $line ~ @words[$i] ) <= $width {
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
                $line = to-printwidth( $tmp, $width, False ).[0];
                my Str $remainder = $tmp.substr( $line.chars );
                while $remainder.chars {
                    @lines.push( $line );
                    $tmp = $subseq-tab ~ $remainder;
                    $line = to-printwidth( $tmp, $width, False ).[0];
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
                my Int $count = $line.comb( $(ph-char) ).elems;
                if $count {
                    $last_color = @colors[$count - 1];
                }
            }
            $line.=subst( / $(ph-char) /, { @colors.shift }, :g );
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



=begin pod

=head1 NAME

Term::Choose::LineFold - print-columns and line-fold

=head1 DESCRIPTION

I<Width> in this context refers to the number of occupied columns of a character string on a terminal with a monospaced
font.

=head1 EXPORT

Nothing by default.

    use Term::Choose::LineFold qw( print-columns );

=head1 FUNCTIONS

=head2 print-columns

Get the number of occupied columns of a character string on a terminal.

    $print-width = print-columns( $string );

    $print-width = print-columns( $string, %cache );

The string passed to this function is free of control characters, non-characters, and surrogates.

Passing a hash (C<%cache>) to cache the character widths is optional.

=head2 line-fold

Fold a string.

    $folded-string = line-fold( $string );

    $folded-string = line-fold( $string, :120width, :1color );

Control characters (excluding vertical spaces), non-characters, and surrogates are removed before the string is folded.
Changes are applied to a copy; the passed string is unchanged.

=head3 Options

=item width

If not set, defaults to the terminal width.

I<width> is C<1> or greater.

=item init-tab

Sets the initial tab inserted at the beginning of paragraphs. If a value consisting of C< <[0..9]>+> is provided,
the tab will be that number of spaces. Otherwise, the provided value is used directly as the tab. By default, no initial
tab is inserted. If the initial tab is longer than half the available width, it will be cut to half the available width.

=item subseq-tab

Sets the subsequent tab inserted at the beginning of all broken lines (excluding paragraph beginnings). If a value
consisting of C< <[0..9]>+> is provided, the tab will be that number of spaces. Otherwise, the provided value is
used directly as the tab. By default, no subsequent tab is inserted. If the subsequent tab is longer than half the
available width, it will be cut to half the available width

=item color

Enables support for ANSI SGR escape sequences. If enabled, all zero-width no-break spaces (C<0xfeff>) are removed.

I<color> is C<0> or C<1>.

=head1 Ambiguous width characters

By default ambiguous width characters are treated as half width. If the environment variable
C<TC_AMBIGUOUS_WIDTH_IS_WIDE> is set to a true value, ambiguous width characters are treated as full width.

=head1 Restrictions

Term::Choose::LineFold is not installable on Windows.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod









