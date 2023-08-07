private package Porion.Templates.Parser.Parser_Tokens is


   subtype YYSType is Porion.Templates.Parser.YYSType;

   type Token is
        (END_OF_INPUT, ERROR, T_AS, T_ASSIGN,
         T_BADINPUT, T_BADSTR, T_DELETE,
         T_END, T_EXTENDS, T_IDENT,
         T_IGNORE, T_IS, T_METRIC,
         T_NAME, T_NUM, T_RECIPE,
         T_RENAMES, T_SECRET, T_SET,
         T_STEP, T_STRING, T_ON,
         T_RUN, T_BUILD, T_XUNIT,
         T_WITH, ':', '=',
         ';', '&');

   Syntax_Error : exception;

end Porion.Templates.Parser.Parser_Tokens;
