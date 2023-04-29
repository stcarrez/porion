%unit Porion.Templates.Parser.Parser
%lex YYLex (Scanner, Context)
%define parse.params "Repository : in out Repository_Type; Context : in out Parser_Context_Type; Scanner : in out Lexer_IO.Context_Type; Error_Count : out Natural"
%define api.pure true
%token T_AS
%token T_ASSIGN
%token T_BADINPUT
%token T_BADSTR
%token T_DELETE
%token T_END
%token T_EXTENDS
%token T_IDENT
%token T_IGNORE
%token T_IS
%token T_METRIC
%token T_NAME
%token T_NUM
%token T_RECIPE
%token T_RENAMES
%token T_SECRET
%token T_SET
%token T_STEP
%token T_STRING
%token T_ON
%token T_RUN
%token T_BUILD
%token T_XUNIT
%token T_WITH
%token ':'
%token '='
%token ';'
%token '&'

%code decl {
      YYLVal : YYSType renames Scanner.YYLVal;
      YYVal  : YYSType renames Scanner.YYVal;

      procedure yyerror (Message : in String := "syntax error");

      procedure yyerror (Message : in String := "syntax error") is
         pragma Unreferenced (Message);
      begin
         Error_Count := Error_Count + 1;
      end yyerror;

}
%code init {
      Error_Count := 0;  
}
{
   subtype YYSType is Porion.Templates.Parser.YYSType;
}

%%

root :
    with_clauses build_clause
  |
    build_clause
  ;

with_clauses :
    with_clauses with_clause
  |
    with_clause
  |
  ;

with_clause :
    T_WITH name ';'
       { Add_With (Repository, Context, $2); }
  |
    T_WITH error ';'
       {
         Error (Context, $3.Line, $3.Column, "invalid with clause");
         yyerrok;
         yyclearin;
       }
  ;

build_clause :
    build_name build_rules T_END name ';'
       { Finish_Template (Context, $4); }
  |
    build_name error T_END name ';'
       {
         Error (Context, $3.Line, $3.Column, "invalid build rule");
         yyerrok;
         yyclearin;
         Finish_Template (Context, $4);
       }
  |
    error_rule
  ;

error_rule :
    error ';'
       {
         if not Context.Step.Is_Null then
            Error (Context, $2.Line, $2.Column, "invalid step rule");
         elsif not Context.Recipe.Is_Null then
            Error (Context, $2.Line, $2.Column, "invalid recipe step rule");
         elsif not Context.Template.Is_Null then
            Error (Context, $2.Line, $2.Column, "invalid recipe or step declaration");
         else
            Error (Context, $2.Line, $2.Column, "invalid template rule: missing 'template' keyword");
         end if;
         yyerrok;
         yyclearin;
       }
  |
    error T_BADSTR
       { Error (Context, $2, "missing string termination character"); $$ := EMPTY; }
  |
    error T_BADINPUT
       { Error (Context, $2, "invalid input"); $$ := EMPTY; }
  ;

build_name :
    T_BUILD name T_IS
       { Create_Template (Repository, Context, $2, EMPTY); }
  |
    T_BUILD name T_EXTENDS name T_IS
       { Create_Template (Repository, Context, $2, $4); }
  |
    error T_IS
       { Error (Context, $2, "invalid build rule: missing 'build' keyword"); }
  ;

build_rules :
    build_rules build_rule
  |
    build_rule
  ;

build_rule :
    step_rule
  |
    recipe_rule
  |
    var_rule
  |
    set_rule
  |
    delete_rule
  |
    error_rule
  ;

step_rule :
    T_STEP name T_IS
       { Create_Step (Context, $2, EMPTY); }
    recipe_steps step_rule_end
  |
    T_STEP name T_EXTENDS name T_IS
       { Create_Step (Context, $2, $4); }
    recipe_steps step_rule_end
  |
    T_STEP name step_simple_action
  |
    T_STEP error ';'
      { Error (Context, $3.Line, $3.Column, "invalid step rule"); }
  ;

step_rule_end :
    T_END name ';'
       { Finish_Step (Context, $2); }
  |
    T_END error ';'
       { Error (Context, $1.Line, $1.Column, "expecting step name after 'end' keyword"); 
         Finish_Step (Context, $2); }
  ;

recipe_rule :
    recipe_rule_start recipe_steps recipe_rule_end
  |
    T_RECIPE name T_EXTENDS name T_ON name ';'
       { Create_Recipe (Context, $2, $4);
         Finish_Recipe (Context, $2); }
  |
    T_RECIPE error ';'
      { Error (Context, $3.Line, $3.Column, "invalid recipe rule"); }
  ;

recipe_rule_start :
    T_RECIPE name T_ON name T_IS
       { Create_Recipe (Context, $2, $3); }
  |
    T_RECIPE name T_IS
       { Create_Recipe (Context, $2, EMPTY); }
  |
    T_RECIPE name T_EXTENDS name T_ON name T_IS
       { Create_Recipe (Context, $2, $4); }
  |
    T_RECIPE name T_EXTENDS name T_IS
       { Create_Recipe (Context, $2, $4); }
  ;

recipe_rule_end :
    T_END name ';'
       { Finish_Recipe (Context, $2); }
  |
    T_END error ';'
       { Error (Context, $1.Line, $1.Column, "expecting recipe name after 'end' keyword"); 
         Finish_Step (Context, $2); }
  ;

recipe_steps :
    recipe_steps recipe_step
  |
    recipe_step
  ;

recipe_step :
    run_action
  |
    metric_action
  |
    xunit_action
  |
    delete_rule
  |
    var_rule
  |
    set_rule
  |
    error_rule
  ;

run_action :
    T_AS T_METRIC T_RUN names ';'
      { Add_Step (Context, Porion.Builds.STEP_METRIC, $4); }
  |
    T_AS name T_RUN names ';'
      { Add_Step (Context, $2, $4); }
  |
    T_RUN names ';'
      { Add_Step (Context, Porion.Builds.STEP_MAKE, $2); }
  |
    T_RUN error ';'
      { Error (Context, $1.Line, $1.Column, "invalid run step"); yyerrok; }
  ;

metric_action :
    T_METRIC names ';'
      { Add_Step (Context, Porion.Builds.STEP_METRIC, $2); }
  |
    T_METRIC error ';'
      { Error (Context, $1.Line, $1.Column, "invalid metric step"); yyerrok; }
  ;

xunit_action :
    T_XUNIT names T_IGNORE names ';'
      { Add_Step (Context, Porion.Builds.STEP_TEST, $2); }
  |
    T_XUNIT names ';'
      { Add_Step (Context, Porion.Builds.STEP_TEST, $2); }
  |
    T_XUNIT error ';'
      { Error (Context, $1.Line, $1.Column, "invalid xunit step"); yyerrok; }
  ;

step_simple_action :
    T_AS name T_RENAMES name ';'
      { $$ := $4; $$.Kind := TYPE_RENAMES; }
  |
    T_AS T_METRIC T_RENAMES name ';'
      { $$ := $4; $$.Kind := TYPE_RENAMES; }
  |
    T_RENAMES name ';'
      { $$ := $2; $$.Kind := TYPE_RENAMES; }
  |
    run_action
  |
    metric_action
  |
    xunit_action
  ;

var_rule :
    T_NAME ':' T_SECRET T_NAME ';'
      { Add_Variable (Context, Name => $1, Of_Type => $4, Secret => True, Value => EMPTY); }
  |
    T_NAME ':' T_NAME T_ASSIGN string ';'
      { Add_Variable (Context, Name => $1, Of_Type => $3, Secret => False, Value => $5); }
  |
    T_NAME T_ASSIGN string ';'
      { Add_Variable (Context, Name => $1, Of_Type => EMPTY, Secret => False, Value => $3); }
  |
    T_NAME ':' T_NAME ';'
      { Add_Variable (Context, Name => $1, Of_Type => $3, Secret => False, Value => EMPTY); }
  |
    T_NAME ':' error ';'
      { Error (Context, $2, "invalid variable declaration"); }
  ;

set_rule :
    T_SET T_IGNORE T_ON ';'
      { Set_Config (Context, $2, $3); }
  |
    T_SET T_IGNORE name ';'
      { Set_Config (Context, $2, $3); }
  |
    T_SET T_NAME T_NUM ';'
      { Set_Config (Context, $2, $3); }
  |
    T_SET T_NAME name ';'
      { Set_Config (Context, $2, $3); }
  |
    T_SET error ';'
      { Error (Context, $3.Line, $3.Column, "invalid set declaration"); }
  ;

delete_rule :
    T_DELETE T_RECIPE name ';'
      { Delete_Recipe (Context, $3); }
  |
    T_DELETE T_STEP name ';'
      { Delete_Recipe (Context, $3); }
  |
    T_DELETE error ';'
      { Error (Context, $3.Line, $3.Column, "invalid delete rule"); }
  ;

names :
    names name_or_ident
      { Set_Names ($$, $1, $2); }
  |
    name_or_ident
      { $$ := $1; }
  ;

name_or_ident :
    T_NAME
      { $$ := $1; }
  |
    T_IDENT
      { $$ := $1; }
  |
    string
      { $$ := $1; }
  ;

name :
    T_NAME
      { $$ := $1; }
  |
    string
      { $$ := $1; }
  ;

string :
    string '&' T_STRING
      { $$ := $1; Append_String ($$, $3); }
  |
    T_STRING
      { $$ := $1; }
  |
    T_BADSTR
      { Error (Context, $1, "missing string termination character"); $$ := $1; }
  ;

%%
private package Porion.Templates.Parser.Parser is

   procedure Parse (Path       : in String;
                    Repository : in out Repository_Type;
                    Context    : in out Parser_Context_Type;
                    Status     : out Integer);

   --  Set or clear the parser debug flag.
   --  procedure Set_Debug (Flag : in Boolean);

end Porion.Templates.Parser.Parser;

with Porion.Templates.Parser.Parser_Goto;
with Porion.Templates.Parser.Parser_Tokens;
with Porion.Templates.Parser.Parser_Shift_Reduce;
with Porion.Templates.Parser.Lexer_IO;
with Porion.Templates.Parser.Lexer;
with Ada.Text_IO;
package body Porion.Templates.Parser.Parser is

   use Ada;
   use Porion.Templates.Parser.Lexer;

   procedure YYParse (Repository  : in out Repository_Type;
                      Context     : in out Parser_Context_Type;
                      Scanner     : in out Lexer_IO.Context_Type;
                      Error_Count : out Natural);

##

   procedure Parse (Path       : in String;
                    Repository : in out Repository_Type;
                    Context    : in out Parser_Context_Type;
                    Status     : out Integer) is
      Lexer : Porion.Templates.Parser.Lexer_IO.Context_Type;
      Error_Count : Natural := 0;
   begin
      Porion.Templates.Parser.Lexer_IO.Open_Input (Lexer, Path);
      YYParse (Repository, Context, Lexer, Error_Count);
      Porion.Templates.Parser.Lexer_IO.Close_Input (Lexer);
      Status := Error_Count;

   exception
      when others =>
         Porion.Templates.Parser.Lexer_IO.Close_Input (Lexer);
         raise;

   end Parse;

end Porion.Templates.Parser.Parser;
