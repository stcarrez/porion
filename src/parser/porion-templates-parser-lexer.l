%unit Porion.Templates.Parser.Lexer
%option bufsize=4096
%option case-insensitive
%option nounput
%option nooutput
%option noinput
%option noyywrap
%option yylineno
%option reentrant

%s START
%yyvar Ctx
%yydecl function YYLex (Ctx : in out Lexer_IO.Context_Type; Context : in out Parser_Context_Type) return Token
%yyinit {
   ENTER(START);
}

h               [0-9a-f]
nonascii        [\240-\377]
unicode         \\{h}{1,6}(\r\n|[ \t\r\n\f])?
escape          {unicode}|\\[^\r\n\f0-9a-f]
nmstart         [_a-z]|{nonascii}|{escape}
nmchar          [_a-z0-9-]|{nonascii}|{escape}|"."
nmany           [!-9@-Z_-~]|{nonascii}|{escape}
num             [0-9]+

string1         \"([^\n\r\f\\"]|\\{nl}|{escape})*\"
string2         \'([^\n\r\f\\']|\\{nl}|{escape})*\'
badstring1      \"([^\n\r\f\\"]|\\{nl}|{escape})*\\?
badstring2      \'([^\n\r\f\\']|\\{nl}|{escape})*\\?
comment         \-\-.*{nl}
name            {nmstart}{nmchar}+
ident           -?{nmstart}{nmany}*
string          {string1}|{string2}
badstring       {badstring1}|{badstring2}
s               [ \t\r\n\f]+
w               {s}?
nl              \n|\r\n|\r|\f

%%

\:                      return ':';
\;                      return ';';
\&                      return '&';

as                      { return T_AS; }
delete                  { return T_DELETE; }
end                     { return T_END; }
extends                 { return T_EXTENDS; }
ignore                  { Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_IGNORE; }
is                      { return T_IS; }
metric                  { return T_METRIC; }
on                      { Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_ON; }
recipe                  { return T_RECIPE; }
renames                 { return T_RENAMES; }
secret                  { return T_SECRET; }
set                     { return T_SET; }
step                    { return T_STEP; }
run                     { return T_RUN; }
<START>build            { ENTER (INITIAL); return T_BUILD; }
xunit                   { return T_XUNIT; }
with                    { return T_WITH; }
\:\=                    { return T_ASSIGN; }
{badstring}		{ Set_String (YYLVal, YYText, yylineno, yylinecol); return T_BADSTR; }
{string}		{ Set_String (YYLVal, YYText, yylineno, yylinecol); return T_STRING; }
{name}			{ Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_NAME; }
{ident}			{ Set_Ident (YYLVal, YYText, yylineno, yylinecol); return T_IDENT; }

{num}ms		        { Set_Number (YYLVal, YYText, UNIT_MS, yylineno, yylinecol); return T_NUM; }
{num}s		        { Set_Number (YYLVal, YYText, UNIT_SEC, yylineno, yylinecol); return T_NUM; }
{num}mn		        { Set_Number (YYLVal, YYText, UNIT_MINUTE, yylineno, yylinecol); return T_NUM; }
{num}h		        { Set_Number (YYLVal, YYText, UNIT_HOUR, yylineno, yylinecol); return T_NUM; }
{num}		        { Set_Number (YYLVal, YYText, UNIT_SEC, yylineno, yylinecol); return T_NUM; }

{comment}       { Current_Comment := To_UString (YYText); }
{s}             { null; }
.               { Error (Context, yylineno, yylinecol, "illegal character '" & YYText & "'"); }

%%
with Porion.Templates.Parser.Parser_Tokens;
with Porion.Templates.Parser.Lexer_IO;
private package Porion.Templates.Parser.Lexer is

   use Porion.Templates.Parser.Parser_Tokens;

   function YYLex (Ctx : in out Lexer_IO.Context_Type; Context : in out Parser_Context_Type) return Token;

   Current_Comment : UString;

end Porion.Templates.Parser.Lexer;

with Ada.Text_IO;
with Porion.Templates.Parser.Lexer_DFA;
package body Porion.Templates.Parser.Lexer is

   use Ada.Text_IO;
   use Ada;
   use Porion.Templates.Parser.Lexer_DFA;
   use Porion.Templates.Parser.Lexer_IO;

   pragma Style_Checks (Off);
   pragma Warnings (Off);
##
   pragma Style_Checks (On);

end Porion.Templates.Parser.Lexer;
