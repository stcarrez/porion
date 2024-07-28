
with Ada.Text_IO;
with Porion.Templates.Parser.Lexer_DFA;
package body Porion.Templates.Parser.Lexer is

   use Ada.Text_IO;
   use Ada;
   use Porion.Templates.Parser.Lexer_DFA;
   use Porion.Templates.Parser.Lexer_IO;

   pragma Style_Checks (Off);
   pragma Warnings (Off);

   function YYLex (Ctx : in out Lexer_IO.Context_Type;
                   Context : in out Parser_Context_Type) return Token is
      subtype Short is Integer range -32768 .. 32767;
      yy_act : Integer;
      yy_c   : Short;

      --  returned upon end-of-file
      YY_END_TOK : constant Integer := 0;
      subtype yy_state_type is Integer;
      yy_current_state : yy_state_type;

      yylinecol : Integer renames Ctx.dfa.yylinecol;
      yylineno  : Line_Number renames Ctx.dfa.yylineno;
      yy_last_yylinecol : Integer renames Ctx.dfa.yy_last_yylinecol;
      yy_last_yylineno  : Line_Number renames Ctx.dfa.yy_last_yylineno;
      yy_eof_has_been_seen : Boolean renames Ctx.yy_eof_has_been_seen;
      aflex_debug : Boolean renames Ctx.dfa.aflex_debug;
      yy_init  : Boolean renames Ctx.dfa.yy_init;
      yy_c_buf_p  : Index renames Ctx.dfa.yy_c_buf_p;
      yy_start : yy_state_type renames Ctx.dfa.yy_start;
      yy_cp    : Index renames Ctx.dfa.yy_cp;
      yy_bp    : Index renames Ctx.dfa.yy_bp;
      yytext_ptr   : Index renames Ctx.dfa.yytext_ptr;
      yy_last_accepting_state : Lexer_DFA.yy_state_type renames Ctx.dfa.yy_last_accepting_state;
      yy_last_accepting_cpos  : Index renames Ctx.dfa.yy_last_accepting_cpos;
      yy_hold_char  : Character renames Ctx.dfa.yy_hold_char;
      yy_ch_buf     : Lexer_DFA.ch_buf_type renames Ctx.dfa.yy_ch_buf;
      yy_n_chars    : Index renames Ctx.yy_n_chars;
      YYLVal : YYSType renames Ctx.YYLVal;
      YYVal  : YYSType renames Ctx.YYVal;

      function yy_get_next_buffer return Lexer_IO.eob_action_type
        is (Lexer_IO.yy_get_next_buffer (Ctx));

      function YYText return String
        is (Lexer_DFA.YYText (Ctx.dfa));

      procedure YY_DO_BEFORE_ACTION is
      begin
        Lexer_DFA.YY_DO_BEFORE_ACTION (Ctx.dfa);
      end YY_DO_BEFORE_ACTION;

      YY_END_OF_BUFFER : constant := 35;
      INITIAL : constant := 0;
      START : constant := 1;
      yy_accept : constant array (0 .. 176) of Short :=
          (0,
        0,    0,    0,    0,   35,   33,   32,   32,   22,    3,
       22,   33,   30,    1,    2,   33,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   32,   22,
       23,   22,   22,   22,    0,    0,   25,   30,   29,    0,
       27,   21,   25,   25,   25,   24,   25,    4,   24,   24,
       24,   24,    9,   24,   11,   24,   24,   24,   24,   24,
       24,   24,   22,   22,   22,   22,   22,   22,    0,   31,
       31,   31,   25,   25,   25,   28,   26,   25,   24,   24,
       24,   24,   24,   24,    6,   24,   24,   24,   24,   24,
       17,   24,   15,   24,   24,   24,   24,   22,   22,   22,

       22,   22,   22,   31,   25,   25,   25,   25,   25,   25,
       24,   24,   24,   24,   24,   25,   24,   24,   24,   24,
       24,   24,   24,   16,   20,   24,   24,   22,   22,   25,
       25,   25,   24,   24,   24,   24,   24,   24,   24,   24,
       24,   24,   19,   18,   22,   22,   25,   25,   24,   24,
       24,    5,   24,    8,   10,   12,   24,   14,   22,   22,
       25,   25,   24,   24,   24,    7,   13,   22,   22,   25,
       25,   24,   24,   25,   24,    0
       );

      yy_ec : constant array (ASCII.NUL .. Character'Last) of Short := (0,
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    4,    5,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    2,    6,    7,    6,    6,    6,    8,    9,    6,
        6,    6,    6,    6,   10,   11,    6,   12,   12,   12,
       12,   12,   12,   12,   12,   12,   12,   13,   14,    1,
       15,    1,    1,    6,   18,   19,   20,   21,   22,   23,
       24,   25,   26,   17,   17,   27,   28,   29,   30,   31,
       17,   32,   33,   34,   35,   17,   36,   37,   17,   17,
        6,   16,    6,    6,   17,    6,   18,   19,   20,   21,

       22,   23,   24,   25,   26,   17,   17,   27,   28,   29,
       30,   31,   17,   32,   33,   34,   35,   17,   36,   37,
       17,   17,    6,    6,    6,    6,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,

       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38,   38,   38,   38,   38,   38,
       38,   38,   38,   38,   38, others => 1

       );

      yy_meta : constant array (0 .. 38) of Short :=
          (0,
        1,    1,    2,    2,    2,    3,    3,    3,    3,    4,
        3,    3,    1,    1,    1,    4,    4,    4,    4,    4,
        4,    4,    4,    4,    4,    4,    4,    4,    4,    4,
        4,    4,    4,    4,    4,    4,    4,    4
       );

      yy_base : constant array (0 .. 188) of Short :=
          (0,
        0,    0,  466,  454,  467,  883,   37,   41,   40,  883,
       39,   41,   37,  451,  883,   59,   52,   77,   30,   58,
       40,   66,   21,   67,   70,   41,   61,   72,  109,   59,
      883,  112,   60,  133,  115,  145,  445,  114,  883,   68,
      883,  883,  426,  167,  434,  411,  200,  410,   94,  107,
       75,   96,  409,   89,  408,  129,  115,  126,  128,  140,
      147,  149,  176,  188,  222,  168,  190,  244,  193,  883,
      204,  227,  424,  266,  289,  883,  883,  178,  301,  381,
      379,  323,  346,  172,  376,  195,  203,  218,  177,  219,
      375,  222,  374,  110,   65,  246,  247,  276,  290,  373,

      320,  394,  399,  883,  278,  411,  390,  388,  433,  456,
      468,  297,  480,  357,  502,  525,  224,  206,  243,  305,
      228,  304,  317,  316,  301,  262,  365,  537,  549,  561,
      384,  573,  585,  597,  609,  318,  368,  366,  382,  383,
      391,  265,  300,  285,  621,  633,  645,  657,  669,  681,
      693,  284,  283,  282,  281,  244,  240,  145,  705,  717,
      729,  741,  460,  753,  765,   73,   39,  787,  802,  423,
      807,  479,  819,  444,  529,  883,  842,  846,   49,  850,
      852,  856,  860,  864,  868,  870,  874,  878
       );

      yy_def : constant array (0 .. 188) of Short :=
          (0,
      176,    1,    1,    1,  176,  176,  176,  176,  177,  176,
      178,  179,  176,  176,  176,  180,  181,  181,   18,   18,
       18,   18,   18,   18,   18,   18,   18,   18,  176,  177,
      176,  182,  178,  183,  184,  185,  186,  176,  176,  176,
      176,  176,   18,   18,  186,   18,  187,   18,   18,   18,
       18,   18,   18,   18,   18,   18,   18,   18,   18,   18,
       18,   18,  177,  177,  177,  178,  178,  178,  184,  176,
      184,  184,  186,  186,  188,  176,  176,   18,   44,   18,
       18,   44,  176,   18,   18,   18,   18,   18,   18,   18,
       18,   18,   18,   18,   18,   18,   18,  177,  177,   65,

      178,  178,   68,  176,  186,   74,  186,  186,   74,  188,
       44,   18,   82,   18,   82,  187,   18,   18,   18,   18,
       18,   18,   18,   18,   18,   18,   18,   65,   68,   74,
      186,  109,   44,   82,  115,   18,   18,   18,   18,   18,
       18,   18,   18,   18,   65,   68,   74,  109,   44,   82,
      115,   18,   18,   18,   18,   18,   18,   18,   65,   68,
       74,  109,   18,   82,  115,   18,   18,  177,  178,  186,
      109,   18,  115,  186,   18,    0,  176,  176,  176,  176,
      176,  176,  176,  176,  176,  176,  176,  176
       );

      yy_nxt : constant array (0 .. 921) of Short :=
          (0,
        6,    7,    8,    7,    7,    6,    9,   10,   11,   12,
        6,   13,   14,   15,    6,   16,   17,   18,   17,   17,
       19,   20,   17,   17,   17,   21,   17,   22,   17,   23,
       17,   24,   25,   17,   17,   26,   27,   17,   29,   29,
       29,   29,   29,   29,   29,   29,   31,   31,   38,   55,
       35,   49,   37,   46,   34,   32,   36,   45,   45,   45,
       45,   39,   46,   52,   40,   31,   60,   47,   31,   41,
       44,   46,   53,   46,   32,   34,   44,   44,   44,   44,
       44,   44,   45,   45,   45,   45,   50,   54,   56,  125,
       46,   58,   47,   46,   51,   61,   76,   46,   46,   46,

       77,   57,   46,   59,   46,   46,   62,   46,   86,   48,
       29,   29,   29,   29,   30,   30,   64,   70,   71,   72,
       84,   46,   88,   65,   87,   38,   46,   85,   46,   65,
       65,   65,   65,   65,   65,   33,   33,   67,   39,   46,
      124,   40,   46,   91,   68,   92,   41,   46,   89,   94,
       68,   68,   68,   68,   68,   68,   74,   90,   46,   93,
       46,   46,   74,   74,   74,   74,   74,   74,   43,   43,
       43,   78,   46,   95,   97,   96,   31,   46,   79,   46,
       43,   46,   31,   34,   79,   79,   79,   79,   79,   79,
       30,   32,   33,  117,   31,   70,   71,   72,   31,   46,

       80,   80,  121,   32,   46,   34,   70,   71,   72,   46,
       46,   82,   80,   80,   80,   83,  118,   82,   82,   82,
       82,   82,   82,   98,   63,   63,   99,   46,   31,  104,
       71,   72,  119,  100,  137,   46,  122,   32,   46,  100,
      100,  100,  100,  100,  100,  101,   66,   66,  102,  120,
       46,   46,   31,  123,   46,  103,   46,  136,  140,   34,
       46,  103,  103,  103,  103,  103,  103,   73,   73,   73,
      105,  126,  167,  127,  138,   46,   46,  106,   46,   46,
       73,   75,   31,  106,  106,  106,  106,  106,  106,  107,
      107,   32,   63,   75,   46,  143,   31,   46,  158,   80,

      109,  107,  107,  107,  110,   32,  109,  109,  109,  109,
      109,  109,  111,   46,   46,  166,   46,   46,  111,  111,
      111,  111,  111,  111,   80,   80,   80,  112,   31,   46,
      139,  141,   46,   46,  113,   34,   46,   46,  142,  152,
      113,  113,  113,  113,  113,  113,  107,  107,   46,   46,
       46,  108,  108,  108,  108,  114,  114,  115,  107,  107,
      107,  116,  114,  115,  115,  115,  115,  115,  115,  114,
      114,  114,  114,  114,  114,  114,  114,  114,  114,  114,
      114,  114,  114,  114,  128,  144,  107,  154,  153,   46,
      128,  128,  128,  128,  128,  128,   66,   46,   46,   75,

       46,  155,   31,   75,  156,   75,   46,   46,   46,   34,
      129,   46,  157,   46,   46,   46,  129,  129,  129,  129,
      129,  129,  130,   46,   73,   73,   73,  105,  130,  130,
      130,  130,  130,  130,  107,  107,  107,  131,   75,   75,
       46,   46,   46,   46,  132,  107,  107,  107,  131,   75,
      132,  132,  132,  132,  132,  132,  107,  107,   46,   75,
       75,   43,   43,   43,   78,   42,  176,  109,  107,  107,
      107,  110,   28,  109,  109,  109,  109,  109,  109,  133,
       80,   80,   80,  112,   28,  133,  133,  133,  133,  133,
      133,  134,   46,  176,  176,  176,  176,  134,  134,  134,

      134,  134,  134,  107,  107,  107,  131,  176,  176,  176,
      176,   46,  176,  135,  176,  176,  176,  176,  176,  135,
      135,  135,  135,  135,  135,   80,   80,  176,  176,  176,
      107,  107,  107,  131,  176,  176,   82,   80,   80,   80,
       83,  176,   82,   82,   82,   82,   82,   82,  145,  176,
      176,  176,  176,  176,  145,  145,  145,  145,  145,  145,
      146,   46,  176,  176,  176,  176,  146,  146,  146,  146,
      146,  146,  147,  176,  176,  176,  176,  176,  147,  147,
      147,  147,  147,  147,  148,  176,  176,  176,  176,  176,
      148,  148,  148,  148,  148,  148,  149,  176,  176,  176,

      176,  176,  149,  149,  149,  149,  149,  149,  150,  176,
      176,  176,  176,  176,  150,  150,  150,  150,  150,  150,
      151,  176,  176,  176,  176,  176,  151,  151,  151,  151,
      151,  151,  159,  176,  176,  176,  176,  176,  159,  159,
      159,  159,  159,  159,  160,  176,  176,  176,  176,  176,
      160,  160,  160,  160,  160,  160,  161,  176,  176,  176,
      176,  176,  161,  161,  161,  161,  161,  161,  162,  176,
      176,  176,  176,  176,  162,  162,  162,  162,  162,  162,
      163,  176,  176,  176,  176,  176,  163,  163,  163,  163,
      163,  163,  164,  176,  176,  176,  176,  176,  164,  164,

      164,  164,  164,  164,  165,  176,  176,  176,  176,  176,
      165,  165,  165,  165,  165,  165,  168,  176,  176,  176,
      176,  176,  168,  168,  168,  168,  168,  168,  169,  176,
      176,  176,  176,  176,  169,  169,  169,  169,  169,  169,
      170,  176,  176,  176,  176,  176,  170,  170,  170,  170,
      170,  170,  171,  176,  176,  176,  176,  176,  171,  171,
      171,  171,  171,  171,  172,  176,  176,  176,  176,  176,
      172,  172,  172,  172,  172,  172,  173,  176,  176,  176,
      176,  176,  173,  173,  173,  173,  173,  173,   98,   63,
       63,   99,  176,   31,  176,  176,  176,  176,  176,  176,

      176,  176,   32,  101,   66,   66,  102,  176,  176,  176,
       31,  176,  176,  176,  176,  176,  176,   34,  174,  176,
      176,  176,  176,  176,  174,  174,  174,  174,  174,  174,
      175,  176,  176,  176,  176,  176,  175,  175,  175,  175,
      175,  175,   30,  176,   30,   30,   33,  176,   33,   33,
       43,  176,   43,   43,   46,   46,   63,   63,   63,   63,
       66,   66,   66,   66,   69,   69,   69,   69,   73,  176,
       73,   73,   45,   45,   81,  176,   81,   81,  108,  176,
      108,  108,    5,  176,  176,  176,  176,  176,  176,  176,
      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,

      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,
      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,
      176
       );

      yy_chk : constant array (0 .. 921) of Short :=
          (0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    7,    7,
        7,    7,    8,    8,    8,    8,    9,   11,   13,   23,
       12,   19,  179,   23,   11,    9,   12,   17,   17,   17,
       17,   13,   19,   21,   13,   30,   26,   17,   33,   13,
       16,  167,   21,   26,   30,   33,   16,   16,   16,   16,
       16,   16,   18,   18,   18,   18,   20,   22,   24,   95,
       20,   25,   18,   27,   20,   27,   40,   95,   22,   24,

       40,   24,   25,   25,   28,  166,   28,   51,   51,   18,
       29,   29,   29,   29,   32,   32,   32,   35,   35,   35,
       49,   54,   54,   32,   52,   38,   49,   50,   52,   32,
       32,   32,   32,   32,   32,   34,   34,   34,   38,   50,
       94,   38,   94,   57,   34,   58,   38,   57,   56,   59,
       34,   34,   34,   34,   34,   34,   36,   56,   58,   58,
       59,   56,   36,   36,   36,   36,   36,   36,   44,   44,
       44,   44,   60,   60,   62,   61,   66,  158,   44,   61,
       78,   62,   63,   66,   44,   44,   44,   44,   44,   44,
       64,   63,   67,   84,   64,   69,   69,   69,   67,   44,

       47,   47,   89,   64,   84,   67,   71,   71,   71,   89,
       78,   47,   47,   47,   47,   47,   86,   47,   47,   47,
       47,   47,   47,   65,   65,   65,   65,   86,   65,   72,
       72,   72,   87,   65,  118,   87,   90,   65,  118,   65,
       65,   65,   65,   65,   65,   68,   68,   68,   68,   88,
       88,   90,   68,   92,   92,   68,  117,  117,  121,   68,
      121,   68,   68,   68,   68,   68,   68,   74,   74,   74,
       74,   96,  157,   97,  119,  119,  156,   74,   96,   97,
      105,   74,   98,   74,   74,   74,   74,   74,   74,   75,
       75,   98,   99,  105,  126,  126,   99,  142,  142,  112,

       75,   75,   75,   75,   75,   99,   75,   75,   75,   75,
       75,   75,   79,  155,  154,  153,  152,  144,   79,   79,
       79,   79,   79,   79,   82,   82,   82,   82,  101,  112,
      120,  122,  143,  125,   82,  101,  122,  120,  123,  136,
       82,   82,   82,   82,   82,   82,   83,   83,  124,  123,
      136,   83,   83,   83,   83,   83,   83,   83,   83,   83,
       83,   83,   83,   83,   83,   83,   83,   83,   83,   83,
       83,   83,   83,   83,   83,   83,   83,   83,   83,   83,
       83,   83,   83,   83,  100,  127,  131,  138,  137,  114,
      100,  100,  100,  100,  100,  100,  102,  127,  138,  131,

      137,  139,  102,  108,  140,  107,   93,   91,   85,  102,
      103,   81,  141,   80,  139,  140,  103,  103,  103,  103,
      103,  103,  106,  141,  170,  170,  170,  170,  106,  106,
      106,  106,  106,  106,  109,  109,  109,  109,  170,   73,
       55,   53,   48,   46,  109,  174,  174,  174,  174,   45,
      109,  109,  109,  109,  109,  109,  110,  110,   43,  174,
       37,  163,  163,  163,  163,   14,    5,  110,  110,  110,
      110,  110,    4,  110,  110,  110,  110,  110,  110,  111,
      172,  172,  172,  172,    3,  111,  111,  111,  111,  111,
      111,  113,  163,    0,    0,    0,    0,  113,  113,  113,

      113,  113,  113,  115,  115,  115,  115,    0,    0,    0,
        0,  172,    0,  115,    0,    0,    0,    0,    0,  115,
      115,  115,  115,  115,  115,  116,  116,    0,    0,    0,
      175,  175,  175,  175,    0,    0,  116,  116,  116,  116,
      116,    0,  116,  116,  116,  116,  116,  116,  128,    0,
        0,    0,    0,    0,  128,  128,  128,  128,  128,  128,
      129,  175,    0,    0,    0,    0,  129,  129,  129,  129,
      129,  129,  130,    0,    0,    0,    0,    0,  130,  130,
      130,  130,  130,  130,  132,    0,    0,    0,    0,    0,
      132,  132,  132,  132,  132,  132,  133,    0,    0,    0,

        0,    0,  133,  133,  133,  133,  133,  133,  134,    0,
        0,    0,    0,    0,  134,  134,  134,  134,  134,  134,
      135,    0,    0,    0,    0,    0,  135,  135,  135,  135,
      135,  135,  145,    0,    0,    0,    0,    0,  145,  145,
      145,  145,  145,  145,  146,    0,    0,    0,    0,    0,
      146,  146,  146,  146,  146,  146,  147,    0,    0,    0,
        0,    0,  147,  147,  147,  147,  147,  147,  148,    0,
        0,    0,    0,    0,  148,  148,  148,  148,  148,  148,
      149,    0,    0,    0,    0,    0,  149,  149,  149,  149,
      149,  149,  150,    0,    0,    0,    0,    0,  150,  150,

      150,  150,  150,  150,  151,    0,    0,    0,    0,    0,
      151,  151,  151,  151,  151,  151,  159,    0,    0,    0,
        0,    0,  159,  159,  159,  159,  159,  159,  160,    0,
        0,    0,    0,    0,  160,  160,  160,  160,  160,  160,
      161,    0,    0,    0,    0,    0,  161,  161,  161,  161,
      161,  161,  162,    0,    0,    0,    0,    0,  162,  162,
      162,  162,  162,  162,  164,    0,    0,    0,    0,    0,
      164,  164,  164,  164,  164,  164,  165,    0,    0,    0,
        0,    0,  165,  165,  165,  165,  165,  165,  168,  168,
      168,  168,    0,  168,    0,    0,    0,    0,    0,    0,

        0,    0,  168,  169,  169,  169,  169,    0,    0,    0,
      169,    0,    0,    0,    0,    0,    0,  169,  171,    0,
        0,    0,    0,    0,  171,  171,  171,  171,  171,  171,
      173,    0,    0,    0,    0,    0,  173,  173,  173,  173,
      173,  173,  177,    0,  177,  177,  178,    0,  178,  178,
      180,    0,  180,  180,  181,  181,  182,  182,  182,  182,
      183,  183,  183,  183,  184,  184,  184,  184,  185,    0,
      185,  185,  186,  186,  187,    0,  187,  187,  188,    0,
      188,  188,  176,  176,  176,  176,  176,  176,  176,  176,
      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,

      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,
      176,  176,  176,  176,  176,  176,  176,  176,  176,  176,
      176
       );


      --  copy whatever the last rule matched to the standard output

      --  enter a start condition.
      --  Using procedure requires a () after the ENTER, but makes everything
      --  much neater.

      procedure ENTER (state : Integer) is
      begin
         yy_start := 1 + 2 * state;
      end ENTER;

      --  action number for EOF rule of a given start state
      function YY_STATE_EOF (state : Integer) return Integer is
      begin
         return YY_END_OF_BUFFER + state + 1;
      end YY_STATE_EOF;

      --  return all but the first 'n' matched characters back to the input stream
      procedure yyless (n : Integer) is
      begin
         yy_ch_buf (yy_cp) := yy_hold_char; --  undo effects of setting up yytext
         yy_cp := yy_bp + n;
         yy_c_buf_p := yy_cp;
         YY_DO_BEFORE_ACTION; -- set up yytext again
      end yyless;
      --  yy_get_previous_state - get the state just before the EOB char was reached

      function yy_get_previous_state return yy_state_type is
         yy_current_state : yy_state_type;
         yy_c : Short;
         --  yy_bp : constant Integer := yytext_ptr;
      begin
         yy_current_state := yy_start;

         for yy_cp in yytext_ptr .. yy_c_buf_p - 1 loop
            yy_c := yy_ec (yy_ch_buf (yy_cp));
            if yy_accept (yy_current_state) /= 0 then
               yy_last_accepting_state := yy_current_state;
               yy_last_accepting_cpos := yy_cp;
               yy_last_yylineno := yylineno;
               yy_last_yylinecol := yylinecol;
            end if;
            while yy_chk (yy_base (yy_current_state) + yy_c) /= yy_current_state loop
               yy_current_state := yy_def (yy_current_state);
               if yy_current_state >= 177 then
                  yy_c := yy_meta (yy_c);
               end if;
            end loop;
            yy_current_state := yy_nxt (yy_base (yy_current_state) + yy_c);
         end loop;

         return yy_current_state;
      end yy_get_previous_state;

      procedure yyrestart (input_file : File_Type) is
      begin
         Open_Input (Ctx, Ada.Text_IO.Name (input_file));
      end yyrestart;

   begin -- of YYLex

      if yy_init then

   ENTER(START);
         if yy_start = 0 then
            yy_start := 1;      -- first start state
         end if;

         --  we put in the '\n' and start reading from [1] so that an
         --  initial match-at-newline will be true.

         yy_ch_buf (0) := ASCII.LF;
         yy_n_chars := 1;

         --  we always need two end-of-buffer characters. The first causes
         --  a transition to the end-of-buffer state. The second causes
         --  a jam in that state.

         yy_ch_buf (yy_n_chars) := YY_END_OF_BUFFER_CHAR;
         yy_ch_buf (yy_n_chars + 1) := YY_END_OF_BUFFER_CHAR;

         yy_eof_has_been_seen := False;

         yytext_ptr := 1;
         yy_c_buf_p := yytext_ptr;
         yy_hold_char := yy_ch_buf (yy_c_buf_p);
         yy_init := False;
      end if; -- yy_init

      loop                -- loops until end-of-file is reached

         yy_cp := yy_c_buf_p;

         --  support of yytext
         yy_ch_buf (yy_cp) := yy_hold_char;

         --  yy_bp points to the position in yy_ch_buf of the start of the
         --  current run.
         yy_bp := yy_cp;
         yy_current_state := yy_start;
         loop
               yy_c := yy_ec (yy_ch_buf (yy_cp));
               if yy_accept (yy_current_state) /= 0 then
                  yy_last_accepting_state := yy_current_state;
                  yy_last_accepting_cpos := yy_cp;
                  yy_last_yylineno := yylineno;
                  yy_last_yylinecol := yylinecol;
               end if;
               while yy_chk (yy_base (yy_current_state) + yy_c) /= yy_current_state loop
                  yy_current_state := yy_def (yy_current_state);
                  if yy_current_state >= 177 then
                     yy_c := yy_meta (yy_c);
                  end if;
               end loop;
               yy_current_state := yy_nxt (yy_base (yy_current_state) + yy_c);
            if yy_ch_buf (yy_cp) = ASCII.LF then
               yylineno := yylineno + 1;
               yylinecol := 0;
            else
               yylinecol := yylinecol + 1;
            end if;
            yy_cp := yy_cp + 1;
            if yy_current_state = 176 then
                exit;
            end if;
         end loop;
         yy_cp := yy_last_accepting_cpos;
         yy_current_state := yy_last_accepting_state;
         yylineno := yy_last_yylineno;
         yylinecol := yy_last_yylinecol;

   <<next_action>>
         yy_act := yy_accept (yy_current_state);
         YY_DO_BEFORE_ACTION;

         if aflex_debug then  -- output acceptance info. for (-d) debug mode
            Ada.Text_IO.Put (Standard_Error, "  -- Aflex.YYLex accept rule #");
            Ada.Text_IO.Put (Standard_Error, Integer'Image (yy_act));
            Ada.Text_IO.Put_Line (Standard_Error, "(""" & YYText & """)");
         end if;

   <<do_action>>   -- this label is used only to access EOF actions
         case yy_act is

            when 0 => -- must backtrack
            -- undo the effects of YY_DO_BEFORE_ACTION
            yy_ch_buf (yy_cp) := yy_hold_char;
            yy_cp := yy_last_accepting_cpos;
            yylineno := yy_last_yylineno;
            yylinecol := yy_last_yylinecol;
            yy_current_state := yy_last_accepting_state;
            goto next_action;



         when 1 =>
            return ':';

         when 2 =>
            return ';';

         when 3 =>
            return '&';

         when 4 =>
             return T_AS; 

         when 5 =>
             return T_DELETE; 

         when 6 =>
             return T_END; 

         when 7 =>
             return T_EXTENDS; 

         when 8 =>
             Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_IGNORE; 

         when 9 =>
             return T_IS; 

         when 10 =>
             return T_METRIC; 

         when 11 =>
             Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_ON; 

         when 12 =>
             return T_RECIPE; 

         when 13 =>
             return T_RENAMES; 

         when 14 =>
             return T_SECRET; 

         when 15 =>
             return T_SET; 

         when 16 =>
             return T_STEP; 

         when 17 =>
             return T_RUN; 

         when 18 =>
             ENTER (INITIAL); return T_BUILD; 

         when 19 =>
             return T_XUNIT; 

         when 20 =>
             return T_WITH; 

         when 21 =>
             return T_ASSIGN; 

         when 22 =>
             Set_String (YYLVal, YYText, yylineno, yylinecol); return T_BADSTR; 

         when 23 =>
             Set_String (YYLVal, YYText, yylineno, yylinecol); return T_STRING; 

         when 24 =>
             Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_NAME; 

         when 25 =>
             Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_IDENT; 

         when 26 =>
             Set_Number (YYLVal, YYText, UNIT_MS, yylineno, yylinecol); return T_NUM; 

         when 27 =>
             Set_Number (YYLVal, YYText, UNIT_SEC, yylineno, yylinecol); return T_NUM; 

         when 28 =>
             Set_Number (YYLVal, YYText, UNIT_MINUTE, yylineno, yylinecol); return T_NUM; 

         when 29 =>
             Set_Number (YYLVal, YYText, UNIT_HOUR, yylineno, yylinecol); return T_NUM; 

         when 30 =>
             Set_Number (YYLVal, YYText, UNIT_SEC, yylineno, yylinecol); return T_NUM; 

         when 31 =>
             Current_Comment := To_UString (YYText); 

         when 32 =>
             null; 

         when 33 =>
             Error (Context, yylineno, yylinecol, "illegal character '" & YYText & "'"); 

         when 34 =>
            raise AFLEX_SCANNER_JAMMED;
         when YY_END_OF_BUFFER + INITIAL + 1 |
              YY_END_OF_BUFFER + START + 1 =>
            return End_Of_Input;

         when YY_END_OF_BUFFER =>
            --  undo the effects of YY_DO_BEFORE_ACTION
            yy_ch_buf (yy_cp) := yy_hold_char;

            yytext_ptr := yy_bp;

            case yy_get_next_buffer is
               when EOB_ACT_END_OF_FILE =>
                  --  note: because we've taken care in
                  --  yy_get_next_buffer() to have set up yytext,
                  --  we can now set up yy_c_buf_p so that if some
                  --  total hoser (like aflex itself) wants
                  --  to call the scanner after we return the
                  --  End_Of_Input, it'll still work - another
                  --  End_Of_Input will get returned.

                  yy_c_buf_p := yytext_ptr;

                  yy_act := YY_STATE_EOF ((yy_start - 1) / 2);

                  goto do_action;

               when EOB_ACT_RESTART_SCAN =>
                  yy_c_buf_p := yytext_ptr;
                  yy_hold_char := yy_ch_buf (yy_c_buf_p);

               when EOB_ACT_LAST_MATCH =>
                  yy_c_buf_p := yy_n_chars;
                  yy_current_state := yy_get_previous_state;
                  yy_cp := yy_c_buf_p;
                  yy_bp := yytext_ptr;
                  goto next_action;

            end case; --  case yy_get_next_buffer()

         when others =>
            Ada.Text_IO.Put ("action # ");
            Ada.Text_IO.Put (Integer'Image (yy_act));
            Ada.Text_IO.New_Line;
            raise AFLEX_INTERNAL_ERROR;

         end case; --  case (yy_act)
      end loop; --  end of loop waiting for end of file
   end YYLex;

   pragma Style_Checks (On);

end Porion.Templates.Parser.Lexer;

