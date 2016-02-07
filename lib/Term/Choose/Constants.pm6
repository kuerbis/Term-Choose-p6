use v6;

unit module Term::Choose::Constants;

my $VERSION = '0.006';



constant R is export(:choose) = 0;
constant C is export(:choose) = 1;

constant LF is export(:choose) = "\n";
constant CR is export(:choose) = "\r";

constant BEEP                   is export(:choose) = "\a";
constant CLEAR_SCREEN           is export(:linux)  = "\e[H\e[J";
constant CLEAR_TO_END_OF_SCREEN is export(:linux)  = "\e[0J";
constant RESET                  is export(:linux)  = "\e[0m";
constant BOLD_UNDERLINE         is export(:linux)  = "\e[1m\e[4m";
constant REVERSE                is export(:linux)  = "\e[7m";

constant HIDE_CURSOR  is export(:linux) = "\e[?25l";
constant SHOW_CURSOR  is export(:linux) = "\e[?25h";
constant WIDTH_CURSOR is export(:choose, :linux) = 1;

constant GET_CURSOR_POSITION     is export(:linux) = "\e[6n";

constant SET_ANY_EVENT_MOUSE_1003      is export(:linux) = "\e[?1003h";
constant SET_EXT_MODE_MOUSE_1005       is export(:linux) = "\e[?1005h";
constant SET_SGR_EXT_MODE_MOUSE_1006   is export(:linux) = "\e[?1006h";
constant UNSET_ANY_EVENT_MOUSE_1003    is export(:linux) = "\e[?1003l";
constant UNSET_EXT_MODE_MOUSE_1005     is export(:linux) = "\e[?1005l";
constant UNSET_SGR_EXT_MODE_MOUSE_1006 is export(:linux) = "\e[?1006l";

constant MOUSE_WHEELED                 is export(:win32) = 0x0004;

constant LEFTMOST_BUTTON_PRESSED       is export(:win32) = 0x0001;
constant RIGHTMOST_BUTTON_PRESSED      is export(:win32) = 0x0002;
constant FROM_LEFT_2ND_BUTTON_PRESSED  is export(:win32) = 0x0004;


constant NEXT_get_key   is export(:choose, :linux, :win32) = -1;

constant CONTROL_SPACE  is export(:choose,         :win32) = 0x00;
constant CONTROL_A      is export(:choose                ) = 0x01;
constant CONTROL_B      is export(:choose                ) = 0x02;
constant CONTROL_C      is export(:choose                ) = 0x03;
constant CONTROL_D      is export(:choose                ) = 0x04;
constant CONTROL_E      is export(:choose                ) = 0x05;
constant CONTROL_F      is export(:choose                ) = 0x06;
constant CONTROL_H      is export(:choose                ) = 0x08;
constant KEY_BTAB       is export(:choose, :linux        ) = 0x08;
constant CONTROL_I      is export(:choose                ) = 0x09;
constant KEY_TAB        is export(:choose                ) = 0x09;
constant KEY_ENTER      is export(:choose, :linux        ) = 0x0d;
constant KEY_ESC        is export(         :linux        ) = 0x1b;
constant KEY_SPACE      is export(:choose                ) = 0x20;
constant KEY_h          is export(:choose                ) = 0x68;
constant KEY_j          is export(:choose                ) = 0x6a;
constant KEY_k          is export(:choose                ) = 0x6b;
constant KEY_l          is export(:choose                ) = 0x6c;
constant KEY_q          is export(:choose                ) = 0x71;
constant KEY_Tilde      is export(:choose                ) = 0x7e;
constant KEY_BSPACE     is export(:choose                ) = 0x7f;
 
constant VK_PAGE_UP     is export(:choose, :linux, :win32) = 33;
constant VK_PAGE_DOWN   is export(:choose, :linux, :win32) = 34;
constant VK_END         is export(:choose, :linux, :win32) = 35;
constant VK_HOME        is export(:choose, :linux, :win32) = 36;
constant VK_LEFT        is export(:choose, :linux, :win32) = 37;
constant VK_UP          is export(:choose, :linux, :win32) = 38;
constant VK_RIGHT       is export(:choose, :linux, :win32) = 39;
constant VK_DOWN        is export(:choose, :linux, :win32) = 40;
constant VK_INSERT      is export(:choose, :linux, :win32) = 45;
constant VK_DELETE      is export(:choose, :linux, :win32) = 46;


