use v6;
unit module Term::Choose::Constant;


my regex rx-color        is export( :DEFAULT, :rx-color )        { \e \[ <[\d;]>* m };
my regex rx-invalid-char is export( :DEFAULT, :rx-invalid-char ) { <:Cc+:Noncharacter_Code_Point+:Cs> };
my regex rx-is-binary    is export( :DEFAULT, :rx-is-binary )    { <[\x00..\x08\x0B..\x0C\x0E..\x1F]> };


constant cursor-width is export( :DEFAULT, :cursor-width ) = 1;
#constant extra-w is export( :DEFAULT, :extra-w ) = $*DISTRO.is-win ?? 0 !! cursor-width;     # Term::TablePrint not installable on Windows
constant extra-w is export( :DEFAULT, :extra-w ) = cursor-width; # ### 

# zero width placeholder charcter:
constant ph-char is export( :DEFAULT, :ph-char ) = "\x[feff]";


subset Positive_Int is export( :DEFAULT, :Positive_Int ) of Int where * > 0;
subset Int_0_to_2   is export( :DEFAULT, :Int_0_to_2   ) of Int where * == 0|1|2;
subset Int_0_or_1   is export( :DEFAULT, :Int_0_or_1   ) of Int where * == 0|1;
