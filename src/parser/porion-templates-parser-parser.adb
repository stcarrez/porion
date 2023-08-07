
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


   procedure YYParse (Repository : in out Repository_Type;
                      Context : in out Parser_Context_Type;
                      Scanner : in out Lexer_IO.Context_Type;
                      Error_Count : out Natural) is

      YYLVal : YYSType renames Scanner.YYLVal;
      YYVal  : YYSType renames Scanner.YYVal;

      procedure yyerror (Message : in String := "syntax error");

      procedure yyerror (Message : in String := "syntax error") is
         pragma Unreferenced (Message);
      begin
         Error_Count := Error_Count + 1;
      end yyerror;

      --  Rename User Defined Packages to Internal Names.
      package yy_goto_tables renames
         Porion.Templates.Parser.Parser_Goto;
      package yy_shift_reduce_tables renames
         Porion.Templates.Parser.Parser_Shift_Reduce;
      package yy_tokens renames
         Porion.Templates.Parser.Parser_Tokens;

      use yy_tokens, yy_goto_tables, yy_shift_reduce_tables;

      procedure yyerrok;
      procedure yyclearin;
      procedure handle_error;

      subtype goto_row is yy_goto_tables.Row;
      subtype reduce_row is yy_shift_reduce_tables.Row;

      package yy is

         --  the size of the value and state stacks
         --  Affects error 'Stack size exceeded on state_stack'
         stack_size : constant Natural :=  256;

         --  subtype rule         is Natural;
         subtype parse_state is Natural;
         --  subtype nonterminal  is Integer;

         --  encryption constants
         default           : constant := -1;
         first_shift_entry : constant := 0;
         accept_code       : constant := -3001;
         error_code        : constant := -3000;

         --  stack data used by the parser
         tos                : Natural := 0;
         value_stack        : array (0 .. stack_size) of yy_tokens.YYSType;
         state_stack        : array (0 .. stack_size) of parse_state;

         --  current input symbol and action the parser is on
         action             : Integer;
         rule_id            : Rule;
         input_symbol       : yy_tokens.Token := ERROR;

         --  error recovery flag
         error_flag : Natural := 0;
         --  indicates  3 - (number of valid shifts after an error occurs)

         look_ahead : Boolean := True;
         index      : reduce_row;

         --  Is Debugging option on or off
         debug : constant Boolean := False;
      end yy;

      procedure shift_debug (state_id : yy.parse_state; lexeme : yy_tokens.Token);
      procedure reduce_debug (rule_id : Rule; state_id : yy.parse_state);

      function goto_state
         (state : yy.parse_state;
          sym   : Nonterminal) return yy.parse_state;

      function parse_action
         (state : yy.parse_state;
          t     : yy_tokens.Token) return Integer;

      pragma Inline (goto_state, parse_action);

      function goto_state (state : yy.parse_state;
                           sym   : Nonterminal) return yy.parse_state is
         index : goto_row;
      begin
         index := Goto_Offset (state);
         while Goto_Matrix (index).Nonterm /= sym loop
            index := index + 1;
         end loop;
         return Integer (Goto_Matrix (index).Newstate);
      end goto_state;


      function parse_action (state : yy.parse_state;
                             t     : yy_tokens.Token) return Integer is
         index   : reduce_row;
         tok_pos : Integer;
         default : constant Integer := -1;
      begin
         tok_pos := yy_tokens.Token'Pos (t);
         index   := Shift_Reduce_Offset (state);
         while Integer (Shift_Reduce_Matrix (index).T) /= tok_pos
           and then Integer (Shift_Reduce_Matrix (index).T) /= default
         loop
            index := index + 1;
         end loop;
         return Integer (Shift_Reduce_Matrix (index).Act);
      end parse_action;

      --  error recovery stuff

      procedure handle_error is
         temp_action : Integer;
      begin

         if yy.error_flag = 3 then --  no shift yet, clobber input.
            if yy.debug then
               Text_IO.Put_Line ("  -- Ayacc.YYParse: Error Recovery Clobbers "
                                 & yy_tokens.Token'Image (yy.input_symbol));
            end if;
            if yy.input_symbol = yy_tokens.END_OF_INPUT then  -- don't discard,
               if yy.debug then
                  Text_IO.Put_Line ("  -- Ayacc.YYParse: Can't discard END_OF_INPUT, quiting...");
               end if;
               raise yy_tokens.Syntax_Error;
            end if;

            yy.look_ahead := True;   --  get next token
            return;                  --  and try again...
         end if;

         if yy.error_flag = 0 then --  brand new error
            yyerror ("Syntax Error");
         end if;

         yy.error_flag := 3;

         --  find state on stack where error is a valid shift --

         if yy.debug then
            Text_IO.Put_Line ("  -- Ayacc.YYParse: Looking for state with error as valid shift");
         end if;

         loop
            if yy.debug then
               Text_IO.Put_Line ("  -- Ayacc.YYParse: Examining State "
                                 & yy.parse_state'Image (yy.state_stack (yy.tos)));
            end if;
            temp_action := parse_action (yy.state_stack (yy.tos), ERROR);

            if temp_action >= yy.first_shift_entry then
               if yy.tos = yy.stack_size then
                  Text_IO.Put_Line ("  -- Ayacc.YYParse: Stack size exceeded on state_stack");
                  raise yy_tokens.Syntax_Error;
               end if;
               yy.tos                  := yy.tos + 1;
               yy.state_stack (yy.tos) := temp_action;
               exit;
            end if;

            if yy.tos /= 0 then
               yy.tos := yy.tos - 1;
            end if;

            if yy.tos = 0 then
               if yy.debug then
                  Text_IO.Put_Line
                     ("  -- Ayacc.YYParse: Error recovery popped entire stack, aborting...");
               end if;
               raise yy_tokens.Syntax_Error;
            end if;
         end loop;

         if yy.debug then
            Text_IO.Put_Line ("  -- Ayacc.YYParse: Shifted error token in state "
                              & yy.parse_state'Image (yy.state_stack (yy.tos)));
         end if;

      end handle_error;

      --  print debugging information for a shift operation
      procedure shift_debug (state_id : yy.parse_state; lexeme : yy_tokens.Token) is
      begin
         Text_IO.Put_Line ("  -- Ayacc.YYParse: Shift "
                           & yy.parse_state'Image (state_id) & " on input symbol "
                           & yy_tokens.Token'Image (lexeme));
      end shift_debug;

      --  print debugging information for a reduce operation
      procedure reduce_debug (rule_id : Rule; state_id : yy.parse_state) is
      begin
         Text_IO.Put_Line ("  -- Ayacc.YYParse: Reduce by rule "
                           & Rule'Image (rule_id) & " goto state "
                           & yy.parse_state'Image (state_id));
      end reduce_debug;

      --  make the parser believe that 3 valid shifts have occured.
      --  used for error recovery.
      procedure yyerrok is
      begin
         yy.error_flag := 0;
      end yyerrok;

      --  called to clear input symbol that caused an error.
      procedure yyclearin is
      begin
         --  yy.input_symbol := YYLex (Scanner, Context);
         yy.look_ahead := True;
      end yyclearin;

   begin
      --  initialize by pushing state 0 and getting the first input symbol
      yy.state_stack (yy.tos) := 0;

      Error_Count := 0;  

      loop
         yy.index := Shift_Reduce_Offset (yy.state_stack (yy.tos));
         if Integer (Shift_Reduce_Matrix (yy.index).T) = yy.default then
            yy.action := Integer (Shift_Reduce_Matrix (yy.index).Act);
         else
            if yy.look_ahead then
               yy.look_ahead := False;
               yy.input_symbol := YYLex (Scanner, Context);
            end if;
            yy.action := parse_action (yy.state_stack (yy.tos), yy.input_symbol);
         end if;


         if yy.action >= yy.first_shift_entry then  --  SHIFT

            if yy.debug then
               shift_debug (yy.action, yy.input_symbol);
            end if;

            --  Enter new state
            if yy.tos = yy.stack_size then
               Text_IO.Put_Line (" Stack size exceeded on state_stack");
               raise yy_tokens.Syntax_Error;
            end if;
            yy.tos                  := yy.tos + 1;
            yy.state_stack (yy.tos) := yy.action;
            yy.value_stack (yy.tos) := YYLVal;

            if yy.error_flag > 0 then  --  indicate a valid shift
               yy.error_flag := yy.error_flag - 1;
            end if;

            --  Advance lookahead
            yy.look_ahead := True;

         elsif yy.action = yy.error_code then       -- ERROR
            handle_error;

         elsif yy.action = yy.accept_code then
            if yy.debug then
               Text_IO.Put_Line ("  --  Ayacc.YYParse: Accepting Grammar...");
            end if;
            exit;

         else --  Reduce Action

            --  Convert action into a rule
            yy.rule_id := Rule (-1 * yy.action);

            --  Execute User Action
            --  user_action(yy.rule_id);
            case yy.rule_id is
               pragma Style_Checks (Off);

when 6 => -- #line 71
 Add_With (Repository, Context, yy.value_stack (yy.tos-1));

when 7 => -- #line 74

         Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid with clause");
         yyerrok;
         yyclearin;


when 8 => -- #line 83
 Finish_Template (Context, yy.value_stack (yy.tos-1));

when 9 => -- #line 86

         Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "invalid build rule");
         yyerrok;
         yyclearin;
         Finish_Template (Context, yy.value_stack (yy.tos-1));


when 11 => -- #line 98

         if not Context.Step.Is_Null then
            Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid step rule");
         elsif not Context.Recipe.Is_Null then
            Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid recipe step rule");
         elsif not Context.Template.Is_Null then
            Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid recipe or step declaration");
         else
            Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid template rule: missing 'template' keyword");
         end if;
         yyerrok;
         yyclearin;


when 12 => -- #line 113
 Error (Context, yy.value_stack (yy.tos), "missing string termination character"); YYVal := EMPTY;

when 13 => -- #line 116
 Error (Context, yy.value_stack (yy.tos), "invalid input"); YYVal := EMPTY;

when 14 => -- #line 121
 Create_Template (Repository, Context, yy.value_stack (yy.tos-1), EMPTY);

when 15 => -- #line 124
 Create_Template (Repository, Context, yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1));

when 16 => -- #line 127
 Error (Context, yy.value_stack (yy.tos), "invalid build rule: missing 'build' keyword");

when 25 => -- #line 152
 Create_Step (Context, yy.value_stack (yy.tos-1), EMPTY);

when 27 => -- #line 156
 Create_Step (Context, yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1));

when 29 => -- #line 160
 Create_Step (Context, yy.value_stack (yy.tos), EMPTY);

when 30 => -- #line 162
 Finish_Step (Context, yy.value_stack (yy.tos-2));

when 31 => -- #line 165
 Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid step rule");

when 32 => -- #line 170
 Finish_Step (Context, yy.value_stack (yy.tos-1));

when 33 => -- #line 173
 Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "expecting step name after 'end' keyword");
         Finish_Step (Context, yy.value_stack (yy.tos-1));

when 35 => -- #line 181
 Create_Recipe (Context, yy.value_stack (yy.tos-5), yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1));
         Finish_Recipe (Context, yy.value_stack (yy.tos-5));

when 36 => -- #line 185
 Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid recipe rule");

when 37 => -- #line 190
 Create_Recipe (Context, yy.value_stack (yy.tos-3), EMPTY, yy.value_stack (yy.tos-1));

when 38 => -- #line 193
 Create_Recipe (Context, yy.value_stack (yy.tos-1), EMPTY, EMPTY);

when 39 => -- #line 196
 Create_Recipe (Context, yy.value_stack (yy.tos-5), yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1));

when 40 => -- #line 199
 Create_Recipe (Context, yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1), EMPTY);

when 41 => -- #line 204
 Finish_Recipe (Context, yy.value_stack (yy.tos-1));

when 42 => -- #line 207
 Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "expecting recipe name after 'end' keyword");
         Finish_Step (Context, yy.value_stack (yy.tos-1));

when 52 => -- #line 235
 Add_Step (Context, Porion.Builds.STEP_METRIC, yy.value_stack (yy.tos-1));

when 53 => -- #line 238
 Add_Step (Context, yy.value_stack (yy.tos-3), yy.value_stack (yy.tos-1));

when 54 => -- #line 241
 Add_Step (Context, Porion.Builds.STEP_MAKE, yy.value_stack (yy.tos-1));

when 55 => -- #line 244
 Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "invalid run step"); yyerrok;

when 56 => -- #line 249
 Add_Step (Context, Porion.Builds.STEP_METRIC, yy.value_stack (yy.tos-1));

when 57 => -- #line 252
 Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "invalid metric step"); yyerrok;

when 58 => -- #line 257
 Add_Step (Context, Porion.Builds.STEP_TEST, yy.value_stack (yy.tos-3));

when 59 => -- #line 260
 Add_Step (Context, Porion.Builds.STEP_TEST, yy.value_stack (yy.tos-1));

when 60 => -- #line 263
 Error (Context, yy.value_stack (yy.tos-2).Line, yy.value_stack (yy.tos-2).Column, "invalid xunit step"); yyerrok;

when 61 => -- #line 268
 YYVal := yy.value_stack (yy.tos-1); YYVal.Kind := TYPE_RENAMES;

when 62 => -- #line 271
 YYVal := yy.value_stack (yy.tos-1); YYVal.Kind := TYPE_RENAMES;

when 63 => -- #line 274
 YYVal := yy.value_stack (yy.tos-1); YYVal.Kind := TYPE_RENAMES;

when 67 => -- #line 285
 Add_Variable (Context, Name => yy.value_stack (yy.tos-4), Of_Type => yy.value_stack (yy.tos-1), Secret => True, Value => EMPTY);

when 68 => -- #line 288
 Add_Variable (Context, Name => yy.value_stack (yy.tos-5), Of_Type => yy.value_stack (yy.tos-3), Secret => False, Value => yy.value_stack (yy.tos-1));

when 69 => -- #line 291
 Add_Variable (Context, Name => yy.value_stack (yy.tos-3), Of_Type => EMPTY, Secret => False, Value => yy.value_stack (yy.tos-1));

when 70 => -- #line 294
 Add_Variable (Context, Name => yy.value_stack (yy.tos-3), Of_Type => yy.value_stack (yy.tos-1), Secret => False, Value => EMPTY);

when 71 => -- #line 297
 Error (Context, yy.value_stack (yy.tos-2), "invalid variable declaration");

when 72 => -- #line 302
 Set_Config (Context, yy.value_stack (yy.tos-2), yy.value_stack (yy.tos-1));

when 73 => -- #line 305
 Set_Config (Context, yy.value_stack (yy.tos-2), yy.value_stack (yy.tos-1));

when 74 => -- #line 308
 Set_Config (Context, yy.value_stack (yy.tos-2), yy.value_stack (yy.tos-1));

when 75 => -- #line 311
 Set_Config (Context, yy.value_stack (yy.tos-2), yy.value_stack (yy.tos-1));

when 76 => -- #line 314
 Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid set declaration");

when 77 => -- #line 319
 Delete_Recipe (Context, yy.value_stack (yy.tos-1));

when 78 => -- #line 322
 Delete_Recipe (Context, yy.value_stack (yy.tos-1));

when 79 => -- #line 325
 Error (Context, yy.value_stack (yy.tos).Line, yy.value_stack (yy.tos).Column, "invalid delete rule");

when 80 => -- #line 330
 Set_Names (YYVal, yy.value_stack (yy.tos-1), yy.value_stack (yy.tos));

when 81 => -- #line 333
 YYVal := yy.value_stack (yy.tos);

when 82 => -- #line 338
 YYVal := yy.value_stack (yy.tos);

when 83 => -- #line 341
 YYVal := yy.value_stack (yy.tos);

when 84 => -- #line 344
 YYVal := yy.value_stack (yy.tos);

when 85 => -- #line 349
 YYVal := yy.value_stack (yy.tos);

when 86 => -- #line 352
 YYVal := yy.value_stack (yy.tos);

when 87 => -- #line 357
 YYVal := yy.value_stack (yy.tos-2); Append_String (YYVal, yy.value_stack (yy.tos));

when 88 => -- #line 360
 YYVal := yy.value_stack (yy.tos);

when 89 => -- #line 363
 Error (Context, yy.value_stack (yy.tos), "missing string termination character"); YYVal := yy.value_stack (yy.tos);
               pragma Style_Checks (On);

               when others => null;
            end case;

            --  Pop RHS states and goto next state
            yy.tos := yy.tos - Rule_Length (yy.rule_id) + 1;
            if yy.tos > yy.stack_size then
               Text_IO.Put_Line (" Stack size exceeded on state_stack");
               raise yy_tokens.Syntax_Error;
            end if;
            yy.state_stack (yy.tos) := goto_state (yy.state_stack (yy.tos - 1),
                                                   Get_LHS_Rule (yy.rule_id));

            yy.value_stack (yy.tos) := YYVal;
            if yy.debug then
               reduce_debug (yy.rule_id,
                  goto_state (yy.state_stack (yy.tos - 1),
                              Get_LHS_Rule (yy.rule_id)));
            end if;

         end if;
      end loop;

   end YYParse;

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
