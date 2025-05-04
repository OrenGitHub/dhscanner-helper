{- _OPTIONS -Werror=missing-fields #-}

module PhpParser( parseProgram ) where

-- *******************
-- *                 *
-- * project imports *
-- *                 *
-- *******************
import Ast
import PhpLexer
import Location
import qualified Token

-- *******************
-- *                 *
-- * general imports *
-- *                 *
-- *******************
import Data.Maybe
import Data.Either
import Data.List ( map, foldl' )
import Data.Map ( empty, fromList )

-- SEPARATOR

-- ***********************
-- *                     *
-- * API function: parse *
-- *                     *
-- ***********************
%name parse

-- *************
-- * tokentype *
-- *************
%tokentype { AlexTokenTag }

-- *********
-- * monad *
-- *********
%monad { Alex }

-- *********
-- * lexer *
-- *********
%lexer { lexwrap } { AlexTokenTag TokenEOF _ }

-- ***************************************************
-- * Call this function when an error is encountered *
-- ***************************************************
%error { parseError }

%token 

-- ***************
-- *             *
-- * parentheses *
-- *             *
-- ***************

'('    { AlexTokenTag AlexRawToken_LPAREN _ }
')'    { AlexTokenTag AlexRawToken_RPAREN _ }
'['    { AlexTokenTag AlexRawToken_LBRACK _ }
']'    { AlexTokenTag AlexRawToken_RBRACK _ }

-- ***************
-- *             *
-- * punctuation *
-- *             *
-- ***************

':'    { AlexTokenTag AlexRawToken_COLON  _ }
'\\'   { AlexTokenTag AlexRawToken_SLASH  _ }
'-'    { AlexTokenTag AlexRawToken_HYPHEN _ }
'|'    { AlexTokenTag AlexRawToken_OR     _ }

-- *********************
-- *                   *
-- * reserved keywords *
-- *                   *
-- *********************

'Alias' { AlexTokenTag AlexRawToken_Alias _ }
'value' { AlexTokenTag AlexRawToken_value _ }
'Arg' { AlexTokenTag AlexRawToken_Arg _ }
'ArrayItem' { AlexTokenTag AlexRawToken_ArrayItem _ }
'ClosureUse' { AlexTokenTag AlexRawToken_ClosureUse _ }
'Const' { AlexTokenTag AlexRawToken_Const _ }
'Expr_Array' { AlexTokenTag AlexRawToken_Expr_Array _ }
'Expr_ArrayDimFetch' { AlexTokenTag AlexRawToken_Expr_ArrayDimFetch _ }
'Expr_Assign' { AlexTokenTag AlexRawToken_Expr_Assign _ }
'Expr_AssignOp_Concat' { AlexTokenTag AlexRawToken_Expr_AssignOp_Concat _ }
'Expr_AssignOp_Div' { AlexTokenTag AlexRawToken_Expr_AssignOp_Div _ }
'Expr_AssignOp_Minus' { AlexTokenTag AlexRawToken_Expr_AssignOp_Minus _ }
'Expr_AssignOp_Plus' { AlexTokenTag AlexRawToken_Expr_AssignOp_Plus _ }
'Expr_BinaryOp_BitwiseOr' { AlexTokenTag AlexRawToken_Expr_BinaryOp_BitwiseOr _ }
'Expr_BinaryOp_BooleanAnd' { AlexTokenTag AlexRawToken_Expr_BinaryOp_BooleanAnd _ }
'Expr_BinaryOp_BooleanOr' { AlexTokenTag AlexRawToken_Expr_BinaryOp_BooleanOr _ }
'Expr_BinaryOp_Coalesce' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Coalesce _ }
'Expr_BinaryOp_Concat' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Concat _ }
'Expr_BinaryOp_Div' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Div _ }
'Expr_BinaryOp_Equal' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Equal _ }
'Expr_BinaryOp_Greater' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Greater _ }
'Expr_BinaryOp_GreaterOrEqual' { AlexTokenTag AlexRawToken_Expr_BinaryOp_GreaterOrEqual _ }
'Expr_BinaryOp_Identical' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Identical _ }
'Expr_BinaryOp_LogicalOr' { AlexTokenTag AlexRawToken_Expr_BinaryOp_LogicalOr _ }
'Expr_BinaryOp_Minus' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Minus _ }
'Expr_BinaryOp_Mul' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Mul _ }
'Expr_BinaryOp_NotEqual' { AlexTokenTag AlexRawToken_Expr_BinaryOp_NotEqual _ }
'Expr_BinaryOp_NotIdentical' { AlexTokenTag AlexRawToken_Expr_BinaryOp_NotIdentical _ }
'Expr_BinaryOp_Plus' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Plus _ }
'Expr_BinaryOp_Smaller' { AlexTokenTag AlexRawToken_Expr_BinaryOp_Smaller _ }
'Expr_BinaryOp_SmallerOrEqual' { AlexTokenTag AlexRawToken_Expr_BinaryOp_SmallerOrEqual _ }
'Expr_BinaryOp_LogicalAnd' { AlexTokenTag AlexRawToken_Expr_BinaryOp_LogicalAnd _ }
'Expr_NullsafePropertyFetch' { AlexTokenTag AlexRawToken_Expr_NullsafePropertyFetch _ }
'Expr_BooleanNot' { AlexTokenTag AlexRawToken_Expr_BooleanNot _ }
'Expr_Cast_Bool' { AlexTokenTag AlexRawToken_Expr_Cast_Bool _ }
'Expr_Cast_Double' { AlexTokenTag AlexRawToken_Expr_Cast_Double _ }
'Expr_Cast_Int' { AlexTokenTag AlexRawToken_Expr_Cast_Int _ }
'Expr_Cast_Object' { AlexTokenTag AlexRawToken_Expr_Cast_Object _ }
'Expr_Cast_String' { AlexTokenTag AlexRawToken_Expr_Cast_String _ }
'Expr_ClassConstFetch' { AlexTokenTag AlexRawToken_Expr_ClassConstFetch _ }
'Expr_Closure' { AlexTokenTag AlexRawToken_Expr_Closure _ }
'Expr_ConstFetch' { AlexTokenTag AlexRawToken_Expr_ConstFetch _ }
'Expr_Empty' { AlexTokenTag AlexRawToken_Expr_Empty _ }
'Expr_ErrorSuppress' { AlexTokenTag AlexRawToken_Expr_ErrorSuppress _ }
'Expr_Exit' { AlexTokenTag AlexRawToken_Expr_Exit _ }
'Expr_FuncCall' { AlexTokenTag AlexRawToken_Expr_FuncCall _ }
'Expr_Include' { AlexTokenTag AlexRawToken_Expr_Include _ }
'Expr_Instanceof' { AlexTokenTag AlexRawToken_Expr_Instanceof _ }
'Expr_Isset' { AlexTokenTag AlexRawToken_Expr_Isset _ }
'Expr_List' { AlexTokenTag AlexRawToken_Expr_List _ }
'Expr_MethodCall' { AlexTokenTag AlexRawToken_Expr_MethodCall _ }
'Expr_New' { AlexTokenTag AlexRawToken_Expr_New _ }
'Expr_PostDec' { AlexTokenTag AlexRawToken_Expr_PostDec _ }
'Expr_PostInc' { AlexTokenTag AlexRawToken_Expr_PostInc _ }
'Expr_Print' { AlexTokenTag AlexRawToken_Expr_Print _ }
'Expr_PropertyFetch' { AlexTokenTag AlexRawToken_Expr_PropertyFetch _ }
'Expr_StaticCall' { AlexTokenTag AlexRawToken_Expr_StaticCall _ }
'Expr_StaticPropertyFetch' { AlexTokenTag AlexRawToken_Expr_StaticPropertyFetch _ }
'Expr_Ternary' { AlexTokenTag AlexRawToken_Expr_Ternary _ }
'Expr_Throw' { AlexTokenTag AlexRawToken_Expr_Throw _ }
'Expr_UnaryMinus' { AlexTokenTag AlexRawToken_Expr_UnaryMinus _ }
'Expr_Variable' { AlexTokenTag AlexRawToken_Expr_Variable _ }
'Identifier' { AlexTokenTag AlexRawToken_Identifier _ }
'Name' { AlexTokenTag AlexRawToken_Name _ }
'Name_FullyQualified' { AlexTokenTag AlexRawToken_Name_FullyQualified _ }
'Param' { AlexTokenTag AlexRawToken_Param _ }
'Scalar_Float' { AlexTokenTag AlexRawToken_Scalar_Float _ }
'Scalar_Int' { AlexTokenTag AlexRawToken_Scalar_Int _ }
'Scalar_InterpolatedString' { AlexTokenTag AlexRawToken_Scalar_InterpolatedString _ }
'Scalar_MagicConst_Class' { AlexTokenTag AlexRawToken_Scalar_MagicConst_Class _ }
'Scalar_MagicConst_Dir' { AlexTokenTag AlexRawToken_Scalar_MagicConst_Dir _ }
'Scalar_MagicConst_File' { AlexTokenTag AlexRawToken_Scalar_MagicConst_File _ }
'StaticVar' { AlexTokenTag AlexRawToken_StaticVar _ }
'Stmt_Break' { AlexTokenTag AlexRawToken_Stmt_Break _ }
'Stmt_Case' { AlexTokenTag AlexRawToken_Stmt_Case _ }
'Stmt_Catch' { AlexTokenTag AlexRawToken_Stmt_Catch _ }
'Stmt_Class' { AlexTokenTag AlexRawToken_Stmt_Class _ }
'Stmt_ClassConst' { AlexTokenTag AlexRawToken_Stmt_ClassConst _ }
'Stmt_ClassMethod' { AlexTokenTag AlexRawToken_Stmt_ClassMethod _ }
'Stmt_Continue' { AlexTokenTag AlexRawToken_Stmt_Continue _ }
'Stmt_Do' { AlexTokenTag AlexRawToken_Stmt_Do _ }
'Stmt_Echo' { AlexTokenTag AlexRawToken_Stmt_Echo _ }
'Stmt_Else' { AlexTokenTag AlexRawToken_Stmt_Else _ }
'Stmt_ElseIf' { AlexTokenTag AlexRawToken_Stmt_ElseIf _ }
'Stmt_Expression' { AlexTokenTag AlexRawToken_Stmt_Expression _ }
'Stmt_For' { AlexTokenTag AlexRawToken_Stmt_For _ }
'Stmt_Foreach' { AlexTokenTag AlexRawToken_Stmt_Foreach _ }
'Stmt_Function' { AlexTokenTag AlexRawToken_Stmt_Function _ }
'Stmt_Global' { AlexTokenTag AlexRawToken_Stmt_Global _ }
'Stmt_If' { AlexTokenTag AlexRawToken_Stmt_If _ }
'Stmt_Interface' { AlexTokenTag AlexRawToken_Stmt_Interface _ }
'Stmt_Namespace' { AlexTokenTag AlexRawToken_Stmt_Namespace _ }
'Stmt_Nop' { AlexTokenTag AlexRawToken_Stmt_Nop _ }
'Stmt_Property' { AlexTokenTag AlexRawToken_Stmt_Property _ }
'Stmt_Return' { AlexTokenTag AlexRawToken_Stmt_Return _ }
'Stmt_Static' { AlexTokenTag AlexRawToken_Stmt_Static _ }
'Stmt_Switch' { AlexTokenTag AlexRawToken_Stmt_Switch _ }
'Stmt_Trait' { AlexTokenTag AlexRawToken_Stmt_Trait _ }
'Stmt_TraitUse' { AlexTokenTag AlexRawToken_Stmt_TraitUse _ }
'Stmt_TryCatch' { AlexTokenTag AlexRawToken_Stmt_TryCatch _ }
'Stmt_Unset' { AlexTokenTag AlexRawToken_Stmt_Unset _ }
'Stmt_Use' { AlexTokenTag AlexRawToken_Stmt_Use _ }
'Stmt_While' { AlexTokenTag AlexRawToken_Stmt_While _ }
'UseItem' { AlexTokenTag AlexRawToken_UseItem _ }
'alias' { AlexTokenTag AlexRawToken_alias _ }
'args' { AlexTokenTag AlexRawToken_args _ }
'array' { AlexTokenTag AlexRawToken_array _ }
'cond' { AlexTokenTag AlexRawToken_cond _ }
'expr' { AlexTokenTag AlexRawToken_expr _ }
'exprs' { AlexTokenTag AlexRawToken_exprs _ }
'init' { AlexTokenTag AlexRawToken_init _ }
'left' { AlexTokenTag AlexRawToken_left _ }
'loop' { AlexTokenTag AlexRawToken_loop _ }
'name' { AlexTokenTag AlexRawToken_name _ }
'null' { AlexTokenTag AlexRawToken_null _ }
'returnType' { AlexTokenTag AlexRawToken_returnType _ }
'right' { AlexTokenTag AlexRawToken_right _ }
'stmts' { AlexTokenTag AlexRawToken_stmts _ }
'type' { AlexTokenTag AlexRawToken_type _ }
'uses' { AlexTokenTag AlexRawToken_uses _ }
'regex' { AlexTokenTag AlexRawToken_regex _ }
'var' { AlexTokenTag AlexRawToken_var _ }

-- ****************************
-- *                          *
-- * integers and identifiers *
-- *                          *
-- ****************************

ID     { AlexTokenTag (AlexRawToken_ID    id) _ }
STR    { AlexTokenTag (AlexRawToken_STR    s) _ }
INT    { AlexTokenTag (AlexRawToken_INT    i) _ }
FLOAT  { AlexTokenTag (AlexRawToken_FLOAT  f) _ }

-- *************************
-- *                       *
-- * grammar specification *
-- *                       *
-- *************************
%%

-- *********************
-- *                   *
-- * Ast root: program *
-- *                   *
-- *********************
program: stmts
{
    Ast.Root
    {
        Ast.filename = "DDD",
        Ast.stmts = $1
    }
}

tokenID:
ID      { tokIDValue $1 } |
'array' { "array"       } |
'value' { "value"       } |
'Name'  { "Name"        } |
'name'  { "name"        } |
'type'  { "type"        } |
'args'  { "args"        } |
'null'  { "null"        }


-- **********************
-- *                    *
-- * parametrized lists *
-- *                    *
-- **********************
optional(a): { Nothing } | a { Just $1 }
listof(a): a { [$1] } | a listof(a) { $1:$2 }
ornull(a): 'null' { Nothing } | a { Just $1 }
possibly_empty_arrayof(a): 'array' '(' ')' { [] } | 'array' '(' listof(a) ')' { $3 }

-- *********
-- *       *
-- * stmts *
-- *       *
-- *********
stmts:
'array' '('                       ')' { [] } |
'array' '(' listof(numbered_stmt) ')' { $3 }

-- *****************
-- *               *
-- * numbered_stmt *
-- *               *
-- *****************
numbered_stmt: INT ':' stmt { $3 }

-- *****************
-- *               *
-- * stmt_function *
-- *               *
-- *****************
stmt_function:
'Stmt_Function' loc
'('
    ID ':' 'array' '(' ')'
    ID ':' ID
    'name' ':' identifier
    ID ':' params
    'returnType' ':' type
    'stmts' ':' stmts
')'
{
    Ast.StmtFunc $ Ast.StmtFuncContent
    {
        Ast.stmtFuncReturnType = Token.NominalTy (Token.Named "any" $2),
        Ast.stmtFuncName = Token.FuncName $14,
        Ast.stmtFuncParams = $17,
        Ast.stmtFuncBody = $23,
        Ast.stmtFuncAnnotations = [],
        Ast.stmtFuncLocation = $2
    }
}

-- *************
-- *           *
-- * stmt_cont *
-- *           *
-- *************
stmt_cont:
'Stmt_Continue' loc
'('
    ID ':' 'null'
')'
{
    Ast.StmtContinue (Ast.StmtContinueContent $2)
}

case:
'Stmt_Case' loc
'('
    'cond' ':' ornull(exp)
    'stmts' ':' stmts
')'
{
    Nothing
}

numbered_case: INT ':' case { Nothing }
cases: 'array' '(' listof(numbered_case) ')' { Nothing }

-- ***************
-- *             *
-- * stmt_switch *
-- *             *
-- ***************
stmt_switch:
'Stmt_Switch' loc
'('
    'cond' ':' exp
    ID ':' cases
')'
{
    Ast.StmtExp $6
}

-- *************
-- *           *
-- * stmt_cont *
-- *           *
-- *************
stmt_break:
'Stmt_Break' loc
'('
    ID ':' 'null'
')'
{
    Ast.StmtBreak (Ast.StmtBreakContent $2)
}

-- ************
-- *          *
-- * stmt_nop *
-- *          *
-- ************
stmt_nop: 'Stmt_Nop' loc '(' ')'
{
    Ast.StmtBreak (Ast.StmtBreakContent $2)
}

-- ***************
-- *             *
-- * stmt_global *
-- *             *
-- ***************
stmt_global:
'Stmt_Global' loc
'('
    ID ':' exps
')'
{
    Ast.StmtBreak (Ast.StmtBreakContent $2)
}

-- *****************
-- *               *
-- * stmt_trycatch *
-- *               *
-- *****************
stmt_trycatch:
'Stmt_TryCatch' loc
'('
    'stmts' ':' stmts
    ID ':' stmts
    ID ':' 'null'
')'
{
    Ast.StmtIf $ Ast.StmtIfContent
    {
        Ast.stmtIfCond = Ast.ExpInt $ Ast.ExpIntContent $ Token.ConstInt
        {
            Token.constIntValue = 1,
            Token.constIntLocation = $2
        },
        Ast.stmtIfBody = $6,
        Ast.stmtElseBody = [],
        Ast.stmtIfLocation = $2
    }
}

-- **************
-- *            *
-- * stmt_while *
-- *            *
-- **************
stmt_while:
'Stmt_While' loc
'('
    'cond' ':' exp
    'stmts' ':' stmts
')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = $6,
        Ast.stmtWhileBody = $9,
        Ast.stmtWhileLocation = $2
    }
}

-- ***********
-- *         *
-- * stmt_do *
-- *         *
-- ***********
stmt_do:
'Stmt_Do' loc
'('
    'stmts' ':' stmts
    'cond' ':' exp
')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = $9,
        Ast.stmtWhileBody = $6,
        Ast.stmtWhileLocation = $2
    }
}


catch_type_1:
'Name' loc
'('
    'name' ':' tokenID
')'
{
    Nothing
}

catch_type_2:
'Name_FullyQualified' loc
'('
    'name' ':' tokenID
')'
{
    Nothing
}


catch_type:
catch_type_1 { $1 } |
catch_type_2 { $1 }

numbered_catch_type: INT ':' catch_type { Nothing }

catch_types: 'array' '(' listof(numbered_catch_type) ')' { Nothing }

-- **************
-- *            *
-- * stmt_catch *
-- *            *
-- **************
stmt_catch:
'Stmt_Catch' loc
'('
    ID ':' catch_types
    'var' ':' exp
    'stmts' ':' stmts
')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = $9,
        Ast.stmtWhileBody = $12,
        Ast.stmtWhileLocation = $2
    }
}

static_vardec:
'StaticVar' loc
'('
    'var' ':' var
    ID ':' ornull(exp)
')'
{
    Ast.StmtAssign $ Ast.StmtAssignContent
    {
        Ast.stmtAssignLhs = $6,
        Ast.stmtAssignRhs = case $9 of {
            Nothing -> Ast.ExpInt $ Ast.ExpIntContent $ Token.ConstInt 0 $2;
            Just exp -> exp
        }
    }
}

stmt_static_single:
static_vardec { $1 }

numbered_stmt_static:
INT ':' stmt_static_single { $3 }

-- ***************
-- *             *
-- * stmt_static *
-- *             *
-- ***************
stmt_static:
'Stmt_Static' loc
'('
    ID ':' 'array' '(' listof(numbered_stmt_static) ')'
')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = Ast.ExpInt $ Ast.ExpIntContent $ Token.ConstInt
        {
            Token.constIntValue = 1,
            Token.constIntLocation = $2
        },
        Ast.stmtWhileBody = [],
        Ast.stmtWhileLocation = $2
    }
}

-- ******************
-- *                *
-- * stmt_namespace *
-- *                *
-- ******************
stmt_namespace:
'Stmt_Namespace' loc
'('
    'name' ':' 'Name' loc '(' 'name' ':' tokenID ')'
    'stmts' ':' stmts 
')'
{
    Ast.StmtIf $ Ast.StmtIfContent
    {
        Ast.stmtIfCond = Ast.ExpBool $ Ast.ExpBoolContent $ Token.ConstBool True $2,
        Ast.stmtIfBody = $15,
        Ast.stmtElseBody = [],
        Ast.stmtIfLocation = $2
    }
}

stmt_traituse:
'Stmt_TraitUse' loc
'('
    ID ':' possibly_empty_arrayof(numbered_exp) 
    ID ':' possibly_empty_arrayof(exp) 
')'
{
    case $6 of {
        [] -> Ast.StmtContinue $ Ast.StmtContinueContent $2;
        (head:_) -> Ast.StmtExp head
    }
}

stmt_trait:
'Stmt_Trait' loc
'('
    ID ':' possibly_empty_arrayof(exp) 
    'name' ':' type
    'stmts' ':' stmts 
')'
{
    Ast.StmtClass $ Ast.StmtClassContent
    {
        Ast.stmtClassName = Token.ClassName $9,
        Ast.stmtClassSupers = [],
        Ast.stmtClassDataMembers = Ast.DataMembers Data.Map.empty,
        Ast.stmtClassMethods = Ast.Methods $ Data.Map.fromList $ methodify (Token.ClassName $9) $12
    }
}

stmt_class_const:
'Stmt_ClassConst' loc
'('
    ID ':' possibly_empty_arrayof(exp)
    ID ':' INT
    'type' ':' type
    ID ':' stmts 
')'
{
    Ast.StmtIf $ Ast.StmtIfContent
    {
        Ast.stmtIfCond = Ast.ExpBool $ Ast.ExpBoolContent $ Token.ConstBool True $2,
        Ast.stmtIfBody = $15,
        Ast.stmtElseBody = [],
        Ast.stmtIfLocation = $2
    }
}

stmt_dec_const:
'Const' loc
'('
    'name' ':' identifier
    'value' ':' exp
')'
{
    Ast.StmtAssign $ Ast.StmtAssignContent
    {
        Ast.stmtAssignLhs = Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $6,
        Ast.stmtAssignRhs = $9
    }
}

-- ********
-- *      *
-- * stmt *
-- *      *
-- ********
stmt:
stmt_if        { $1 } | 
stmt_use       { $1 } |
stmt_for       { $1 } |
stmt_while     { $1 } |
stmt_do        { $1 } |
stmt_nop       { $1 } |
stmt_foreach   { $1 } |
stmt_exp       { $1 } |
stmt_echo      { $1 } |
stmt_unset     { $1 } |
stmt_trait     { $1 } |
stmt_traituse  { $1 } |
stmt_catch     { $1 } |
stmt_global    { $1 } |
stmt_switch    { $1 } |
stmt_class     { $1 } |
stmt_method    { $1 } |
stmt_data_member { $1 } |
stmt_interface { $1 } |
stmt_namespace { $1 } |
stmt_cont      { $1 } |
stmt_dec_const { $1 } |
stmt_class_const { $1 } |
stmt_break     { $1 } |
stmt_static    { $1 } |
stmt_trycatch  { $1 } |
stmt_function  { $1 } |
stmt_return    { $1 }

importee: tokenID { [$1] } | tokenID '\\' importee { $1:$3 }

name: 'Name' loc '(' 'name' ':' importee ')' { $6 }

alias:
'alias' ':' type { Nothing }

use_item:
'UseItem' loc '(' 'type' ':' stmt_use_type 'name' ':' name alias ')' { $9 }

numbered_use_item: INT ':' use_item { $3 }

use_items: listof(numbered_use_item) { head $1 }

stmt_use_type: tokenID '(' INT ')' { Nothing }

-- ************
-- *          *
-- * stmt_use *
-- *          *
-- ************
stmt_use:
'Stmt_Use' loc '(' 'type' ':' stmt_use_type 'uses' ':' 'array' '(' use_items ')' ')'
{
    Ast.StmtImport $ Ast.StmtImportContent
    {
        Ast.stmtImportSource = (Data.List.foldl' (\x y -> x ++ "." ++ y) "" $11),
        Ast.stmtImportFromSource = Just (last $11),
        Ast.stmtImportAlias = Just (last $11),
        Ast.stmtImportLocation = $2
    }
} 

-- **************
-- *            *
-- * identifier *
-- *            *
-- **************
identifier: 'Identifier' loc '(' 'name' ':' tokenID ')'
{
    Token.Named
    {
        Token.content = $6,
        Token.location = $2
    }
}

dec_var:
tokenID loc
'('
    'name' ':' ID loc '(' 'name' ':' tokenID ')'
    ID ':' ornull(exp)
')'
{
    Token.Named
    {
        Token.content = $11,
        Token.location = $2
    }
}

flag:
ID             { Nothing } |
INT            { Nothing } |
ID '(' INT ')' { Nothing }

flags:
flag { Nothing } |
flag '|' flags { Nothing }

stmt_data_member:
'Stmt_Property' loc
'('
    ID ':' 'array' '(' ')'
    ID ':' flags
    'type' ':' type
    ID ':' 'array' '(' INT ':' dec_var ')'
    optional(hooks)
')'
{
    Ast.StmtVardec $ Ast.StmtVardecContent
    {
        Ast.stmtVardecName = Token.VarName $21,
        Ast.stmtVardecNominalType = Token.NominalTy (Token.Named "any" $2),
        Ast.stmtVardecInitValue = Nothing,
        Ast.stmtVardecLocation = $2
    }
}

type:
tokenID { Token.Named $1 dummyLoc } |
identifier { $1 } |
'Name_FullyQualified' loc '(' 'name' ':' tokenID ')' { Token.Named $6 $2 } |
'Name' loc '(' 'name' ':' ID ')' { Token.Named (tokIDValue $6) $2 }

param_default_value:
tokenID { Nothing } |
exp     { Nothing }

hooks:
ID ':' 'array' '(' ')' { Nothing }

param:
'Param' loc
'('
    ID ':' 'array' '(' ')'
    ID ':' INT
    'type' ':' type
    ID ':' ID
    ID ':' ID
    'var' ':' 'Expr_Variable' loc '(' 'name' ':' tokenID ')'
    ID ':' param_default_value
    optional(hooks)
')'
{
    Ast.Param
    {
        Ast.paramName = Token.ParamName $ Token.Named $28 $24,
        Ast.paramNominalType = Token.NominalTy $ Token.Named "any" $24,
        Ast.paramNominalTypeV2 = Nothing,
        paramSerialIdx = 15555
    }
}

numbered_param: INT ':' param { $3 }

params: 'array' '(' ')' { [] } | 'array' '(' listof(numbered_param) ')' { $3 }

stmt_method:
'Stmt_ClassMethod' loc
'('
    ID ':' 'array' '(' ')'
    ID ':' flags
    ID ':' ID
    'name' ':' identifier
    ID ':' params
    'returnType' ':' tokenID
    'stmts' ':' ornull(stmts)
')'
{
    Ast.StmtMethod $ Ast.StmtMethodContent
    {
        Ast.stmtMethodReturnType = Token.NominalTy (Token.Named "any" $2),
        Ast.stmtMethodName = Token.MethdName $17,
        Ast.stmtMethodParams = [],
        Ast.stmtMethodBody = case $26 of { Nothing -> []; Just _stmts -> _stmts },
        Ast.stmtMethodLocation = $2,
        Ast.hostingClassName = Token.ClassName (Token.Named "not_a_real_class_name" $2),
        Ast.hostingClassSupers = []
    }
}

stmt_interface:
'Stmt_Interface' loc
'('
    tokenID ':' 'array' '(' ')'
    'name' ':' identifier
    ID ':' 'array' '(' ')'
    'stmts' ':' stmts
')'
{
    Ast.StmtClass $ Ast.StmtClassContent
    {
        Ast.stmtClassName = Token.ClassName $11,
        Ast.stmtClassSupers = [],
        Ast.stmtClassDataMembers = Ast.DataMembers Data.Map.empty,
        Ast.stmtClassMethods = Ast.Methods $ Data.Map.fromList $ methodify (Token.ClassName $11) $19
    }
} 

implements:
'Name' loc '(' 'name' ':' tokenID ')' { Nothing }

numbered_implements:
INT ':' implements { Nothing }

stmt_class:
'Stmt_Class' loc
'('
    tokenID ':' 'array' '(' ')'
    ID ':' INT
    'name' ':' identifier
    ID ':' type
    ID ':' possibly_empty_arrayof(numbered_implements)
    'stmts' ':' stmts 
')'
{
    Ast.StmtClass $ Ast.StmtClassContent
    {
        Ast.stmtClassName = Token.ClassName $14,
        Ast.stmtClassSupers = [],
        Ast.stmtClassDataMembers = Ast.DataMembers Data.Map.empty,
        Ast.stmtClassMethods = Ast.Methods $ Data.Map.fromList $ methodify (Token.ClassName $14) $23
    }
} 

-- *************
-- *           *
-- * stmt_call *
-- *           *
-- *************
stmt_exp:
'Stmt_Expression' loc '(' 'expr' ':' exp ')' { Ast.StmtExp $6 } |
'Stmt_Expression' loc '(' 'expr' ':' assign ')' { $6 } |
exp { Ast.StmtExp $1 }

-- *************
-- *           *
-- * stmt_else *
-- *           *
-- *************
stmt_else:
'Stmt_Else' loc
'('
    'stmts' ':' stmts
')'
{
    $6
}

elseif:
'Stmt_ElseIf' loc
'('
    'cond' ':' exp
    'stmts' ':' stmts
')'
{
    $9
}

numbered_elseif: INT ':' elseif { $3 }

elseifs:
'array' '(' ')' { [] } | 'array' '(' listof(numbered_elseif) ')' { [] }

-- ***********
-- *         *
-- * stmt_if *
-- *         *
-- ***********
stmt_if:
'Stmt_If' loc
'('
    'cond' ':' exp
    'stmts' ':' stmts
    ID ':' elseifs
    ID ':' ornull(stmt_else)
')'
{
    Ast.StmtIf $ Ast.StmtIfContent
    {
        Ast.stmtIfCond = $6,
        Ast.stmtIfBody = $9,
        Ast.stmtElseBody = [],
        Ast.stmtIfLocation = $2
    }
}

-- **************
-- *            *
-- * var_simple *
-- *            *
-- **************
var_simple:
'Expr_Variable' loc '(' 'name' ':' tokenID ')'
{
    Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = $6,
        Token.location = $2
    }
} |
'Name' loc '(' 'name' ':' tokenID ')'
{
    Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = $6,
        Token.location = $2
    }
} |
'Name_FullyQualified' loc '(' 'name' ':' tokenID ')'
{
    Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = $6,
        Token.location = $2
    }
}




-- **************
-- *            *
-- * var_field1 *
-- *            *
-- **************
var_field1:
'Expr_PropertyFetch' loc
'('
    'var' ':' exp
    'name' ':' identifier
')'
{
    Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = $6,
        Ast.varFieldName = Token.FieldName $9,
        Ast.varFieldLocation = $2
    }
}

-- **************
-- *            *
-- * var_field2 *
-- *            *
-- **************
var_field2:
'Expr_StaticPropertyFetch' loc
'('
    tokenID ':' tokenID loc '(' 'name' ':' tokenID ')'
    tokenID ':' tokenID loc '(' 'name' ':' tokenID ')'
')'
{
    Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = $11,
            Token.location = $7
        },
        Ast.varFieldName = Token.FieldName $ Token.Named
        {
            Token.content = $20,
            Token.location = $16
        },
        Ast.varFieldLocation = $2
    }
}

-- **************
-- *            *
-- * var_field3 *
-- *            *
-- **************
var_field3:
'Expr_PropertyFetch' loc
'('
    'var' ':' exp
    'name' ':' exp
')'
{
    Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = $6,
        Ast.varFieldName = Token.FieldName (Token.Named "popo" $2),
        Ast.varFieldLocation = $2
    }
}

-- **************
-- *            *
-- * var_field4 *
-- *            *
-- **************
var_field4:
'Expr_ClassConstFetch' loc
'('
    ID ':' exp
    'name' ':' identifier 
')'
{
    Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = $6,
        Ast.varFieldName = Token.FieldName $9,
        Ast.varFieldLocation = $2
    }
}

-- *************
-- *           *
-- * var_field *
-- *           *
-- *************
var_field:
var_field1 { $1 } |
var_field2 { $1 } |
var_field3 { $1 } |
var_field4 { $1 }

-- *****************
-- *               *
-- * var_subscript *
-- *               *
-- *****************
var_subscript:
'Expr_ArrayDimFetch' loc
'('
    'var' ':' exp
    ID ':' ornull(exp)
')'
{
    Ast.VarSubscript $ Ast.VarSubscriptContent
    {
        Ast.varSubscriptLhs = $6,
        Ast.varSubscriptIdx = $6,
        Ast.varSubscriptLocation = $2
    }
}

-- *******
-- *     *
-- * var *
-- *     *
-- *******
var:
var_simple    { $1 } |
var_list      { $1 } |
var_field     { $1 } |
var_subscript { $1 }

assign_op:
'Expr_Assign'          { Nothing } |
'Expr_AssignOp_Div'    { Nothing } |
'Expr_AssignOp_Plus'   { Nothing } |
'Expr_AssignOp_Minus'  { Nothing } |
'Expr_AssignOp_Concat' { Nothing }

-- *************
-- *           *
-- * stmt_echo *
-- *           *
-- *************
stmt_echo:
'Stmt_Echo' loc
'('
    'exprs' ':' exps
')'
{
    Ast.StmtExp $ Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "echo",
            Token.location = $2
        },
        Ast.args = $6,
        Ast.expCallLocation = $2
    }
}

-- *************
-- *           *
-- * stmt_echo *
-- *           *
-- *************
stmt_unset:
'Stmt_Unset' loc
'('
    ID ':' exps
')'
{
    Ast.StmtExp $ Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "unset",
            Token.location = $2
        },
        Ast.args = $6,
        Ast.expCallLocation = $2
    }
}

exp_or_null:
'null' { Nothing } |
exp { Just $1 }

-- ***************
-- *             *
-- * stmt_return *
-- *             *
-- ***************
stmt_return: 'Stmt_Return' loc '(' 'expr' ':' exp_or_null ')'
{
    Ast.StmtReturn $ Ast.StmtReturnContent
    {
        Ast.stmtReturnValue = $6,
        Ast.stmtReturnLocation = $2
    }
}

-- ********
-- *      *
-- * exps *
-- *      *
-- ********
exps: 'array' '(' numbered_exps ')' { $3 }

-- *****************
-- *               *
-- * numbered_exps *
-- *               *
-- *****************
numbered_exps: numbered_exp numbered_exps { $1:$2 } | numbered_exp { [$1] }

-- ****************
-- *              *
-- * numbered_exp *
-- *              *
-- ****************
numbered_exp: INT ':' exp { $3 }

-- ***********
-- *         *
-- * exp_not *
-- *         *
-- ***********
exp_not:
'Expr_BooleanNot' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_exit *
-- *          *
-- ************
exp_exit:
'Expr_Exit' loc
'('
    'expr' ':' ornull(exp)
')'
{
    Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "exit",
            Token.location = $2
        },
        Ast.args = [],
        Ast.expCallLocation = $2
    }
}

-- *************
-- *           *
-- * exp_isset *
-- *           *
-- *************
exp_isset:
'Expr_Isset' loc
'('
    ID ':' exps 
')'
{
    Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "isset",
            Token.location = $2
        },
        Ast.args = $6,
        Ast.expCallLocation = $2
    }
}

-- ***************
-- *             *
-- * exp_ternary *
-- *             *
-- ***************
exp_ternary:
'Expr_Ternary' loc
'('
    'cond' ':' exp
    ID ':' ornull(exp)
    ID ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast1:
'Expr_Cast_Double' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast2:
'Expr_Cast_Int' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast3:
'Expr_Cast_String' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast4:
'Expr_Cast_Bool' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast5:
'Expr_Cast_Object' loc
'('
    'expr' ':' exp
')'
{
    $6
}


-- ************
-- *          *
-- * exp_cast *
-- *          *
-- ************
exp_cast:
exp_cast1 { $1 } |
exp_cast2 { $1 } |
exp_cast3 { $1 } |
exp_cast4 { $1 } |
exp_cast5 { $1 }

-- *************
-- *           *
-- * exp_empty *
-- *           *
-- *************
exp_empty:
'Expr_Empty' loc
'('
    'expr' ':' exp
')'
{
    $6
}

interpolated_string_part: exp { $1 }

numbered_interpolated_string_part:
INT ':' interpolated_string_part { $3 }

interpolated_string_parts:
'array' '(' listof(numbered_interpolated_string_part) ')' { $3 }

-- ***************
-- *             *
-- * exp_fstring *
-- *             *
-- ***************
exp_fstring:
'Scalar_InterpolatedString' loc
'('
    ID ':' interpolated_string_parts
')'
{
    Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "fstring",
            Token.location = $2
        },
        Ast.args = $6,
        Ast.expCallLocation = $2
    }
}

unop_operator:
'Expr_UnaryMinus' { Nothing } |
'Expr_PostInc'    { Nothing } |
'Expr_PostDec'    { Nothing }

-- ************
-- *          *
-- * exp_unop *
-- *          *
-- ************
exp_unop1:
unop_operator loc
'('
    'var' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_unop *
-- *          *
-- ************
exp_unop2:
unop_operator loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- ************
-- *          *
-- * exp_unop *
-- *          *
-- ************
exp_unop:
exp_unop1 { $1 } |
exp_unop2 { $1 }

import_type:
ID '(' INT ')' { Nothing }

-- **************
-- *            *
-- * exp_import *
-- *            *
-- **************
exp_import:
'Expr_Include' loc
'('
    'expr' ':' exp
    'type' ':' import_type
')'
{
    $6
}

-- ************
-- *          *
-- * exp_file *
-- *          *
-- ************
exp_file: 'Scalar_MagicConst_File' loc '(' ')'
{
    Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = "__FILE__",
        Token.location = $2
    }
}

-- ************
-- *          *
-- * exp_file *
-- *          *
-- ************
exp_dir: 'Scalar_MagicConst_Dir' loc '(' ')'
{
    Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = "__DIR__",
        Token.location = $2
    }
}

-- ************
-- *          *
-- * exp_inst *
-- *          *
-- ************
exp_instof:
'Expr_Instanceof' loc
'('
    'expr' ':' exp
    ID ':' 'Name' loc '(' 'name' ':' tokenID ')'
')'
{
    $6
}

-- ****************
-- *              *
-- * err_suppress *
-- *              *
-- ****************
err_suppress:
'Expr_ErrorSuppress' loc
'('
    'expr' ':' exp
')'
{
    $6
}

assign:
assign_op loc
'('
    'var' ':' var
    'expr' ':' exp
')'
{
    Ast.StmtAssign $ Ast.StmtAssignContent
    {
        Ast.stmtAssignLhs = $6,
        Ast.stmtAssignRhs = $9
    }
}

-- *************
-- *           *
-- * exp_print *
-- *           *
-- *************
exp_print:
'Expr_Print' loc
'('
    'expr' ':' exp
')'
{
    $6
}

-- *************
-- *           *
-- * exp_throw *
-- *           *
-- *************
exp_throw:
'Expr_Throw' loc
'('
    'expr' ':' exp
')'
{
    $6
}

exp_kwclass:
'Scalar_MagicConst_Class' loc
'('
')'
{
    Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
    {
        Token.content = "class",
        Token.location = $2
    } 
}

exp_null_safe_prop_fetch:
'Expr_NullsafePropertyFetch' loc
'('
    'var' ':' var
    'name' ':' identifier
')'
{
    Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = Ast.ExpVar (Ast.ExpVarContent $6),
        Ast.varFieldName = Token.FieldName $9,
        Ast.varFieldLocation = $2
    }
}

-- *******
-- *     *
-- * exp *
-- *     *
-- *******
exp:
exp_int     { $1 } |
exp_float   { $1 } |
exp_str     { $1 } |
exp_new     { $1 } |
exp_not     { $1 } |
exp_bool    { $1 } |
exp_exit    { $1 } |
exp_cast    { $1 } |
exp_call    { Ast.ExpCall $1 } |
exp_binop   { $1 } |
exp_print   { $1 } |
exp_throw   { $1 } |
exp_dir     { $1 } |
exp_file    { $1 } |
exp_unop    { $1 } |
exp_isset   { $1 } |
exp_empty   { $1 } |
exp_null_safe_prop_fetch { $1 } |
exp_array   { $1 } |
exp_import  { $1 } |
err_suppress  { $1 } |
exp_lambda  { $1 } |
exp_ternary { $1 } |
exp_fstring { $1 } |
exp_instof  { $1 } |
exp_var     { $1 } |
exp_kwclass { $1 }

array_item:
'ArrayItem' loc
'('
    ID ':' ornull(exp)
    'value' ':' exp 
    ID ':' ID
    ID ':' ID
')'
{
    $9
}

numbered_array_item: INT ':' array_item { $3 }

array_items:
'array' '(' ')' { [] } | 'array' '(' listof(numbered_array_item) ')' { $3 }

-- *************
-- *           *
-- * exp_array *
-- *           *
-- *************
exp_array:
'Expr_Array' loc
'('
    ID ':' array_items
')'
{
    Ast.ExpCall $ Ast.ExpCallContent
    { 
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
        {
            Token.content = "arrayify",
            Token.location = $2
        },
        Ast.args = $6,
        Ast.expCallLocation = $2
    }
}

-- ************
-- *          *
-- * exp_list *
-- *          *
-- ************
var_list:
'Expr_List' loc
'('
    ID ':' array_items
')'
{
    Ast.VarField $ Ast.VarFieldContent
    {
        Ast.varFieldLhs = Ast.ExpCall $ Ast.ExpCallContent
        { 
            Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarSimple $ Ast.VarSimpleContent $ Token.VarName $ Token.Named
            {
                Token.content = "arrayify",
                Token.location = $2
            },
            Ast.args = $6,
            Ast.expCallLocation = $2
        },
        Ast.varFieldName = Token.FieldName $ Token.Named
        {
            Token.content = "arrayify",
            Token.location = $2
        },
        Ast.varFieldLocation = $2
    }
}

closure_use:
'ClosureUse' loc
'('
    'var' ':' var
    ID ':' ID
')'
{
    Nothing
}

numbered_closure_use: INT ':' closure_use { Nothing }

-- **************
-- *            *
-- * exp_lambda *
-- *            *
-- **************
exp_lambda:
'Expr_Closure' loc
'('
    ID ':' 'array' '(' ')'
    ID ':' ID
    ID ':' ID
    ID ':' params
    'uses' ':' 'array' '(' optional(listof(numbered_closure_use)) ')'
    'returnType' ':' tokenID
    'stmts' ':' stmts
')'
{
    Ast.ExpLambda $ Ast.ExpLambdaContent
    {
        Ast.expLambdaParams = $17,
        Ast.expLambdaBody = $29,
        Ast.expLambdaLocation = $2
    }
}

-- ***********
-- *         *
-- * exp_int *
-- *         *
-- ***********
exp_int: 'Scalar_Int' loc '(' 'value' ':' INT ')'
{
    Ast.ExpInt $ Ast.ExpIntContent $ Token.ConstInt
    {
        Token.constIntValue = tokIntValue $6,
        Token.constIntLocation = $2
    }
}

float_value:
FLOAT { Nothing } |
INT   { Nothing }

-- *************
-- *           *
-- * exp_float *
-- *           *
-- *************
exp_float: 'Scalar_Float' loc '(' 'value' ':' float_value ')'
{
    Ast.ExpInt $ Ast.ExpIntContent $ Token.ConstInt
    {
        Token.constIntValue = 4444,
        Token.constIntLocation = $2
    }
}

-- ***********
-- *         *
-- * exp_str *
-- *         *
-- ***********
exp_str: STR
{
    Ast.ExpStr $ Ast.ExpStrContent $ Token.ConstStr
    {
        Token.constStrValue = case (tokStrValue $1) of { Nothing -> "LLL"; Just (s,_) -> s },
        Token.constStrLocation = case (tokStrLocation $1) of {
            Nothing -> Location (Location.filename (tokenLoc $1)) 6 6 6 6;
            Just loc -> loc
        }
    }
}

-- ************
-- *          *
-- * exp_bool *
-- *          *
-- ************
exp_bool:
'Expr_ConstFetch' loc '(' 'name' ':' 'Name' loc '(' 'name' ':' tokenID ')' ')'
{
    Ast.ExpBool $ Ast.ExpBoolContent $ Token.ConstBool
    {
        Token.constBoolValue = True,
        Token.constBoolLocation = $2
    }
}
 
-- ***********
-- *         *
-- * exp_var *
-- *         *
-- ***********
exp_var: var { Ast.ExpVar (Ast.ExpVarContent $1) }

operator:
'Expr_BinaryOp_Smaller'      { Nothing } |
'Expr_BinaryOp_SmallerOrEqual' { Nothing } |
'Expr_BinaryOp_Equal'        { Nothing } |
'Expr_BinaryOp_NotEqual'     { Nothing } |
'Expr_BinaryOp_Mul'          { Nothing } |
'Expr_BinaryOp_Div'          { Nothing } |
'Expr_BinaryOp_Plus'         { Nothing } |
'Expr_BinaryOp_Minus'        { Nothing } |
'Expr_BinaryOp_Greater'      { Nothing } |
'Expr_BinaryOp_GreaterOrEqual' { Nothing } |
'Expr_BinaryOp_Coalesce'     { Nothing } |
'Expr_BinaryOp_Concat'       { Nothing } |
'Expr_BinaryOp_Identical'    { Nothing } |
'Expr_BinaryOp_NotIdentical' { Nothing } |
'Expr_BinaryOp_LogicalAnd'   { Nothing } |
'Expr_BinaryOp_BooleanOr'    { Nothing } |
'Expr_BinaryOp_BitwiseOr'    { Nothing } |
'Expr_BinaryOp_LogicalOr'    { Nothing } |
'Expr_BinaryOp_BooleanAnd'   { Nothing }

-- *************
-- *           *
-- * exp_binop *
-- *           *
-- *************
exp_binop_1:
operator loc
'('
    'left' ':' exp
    'right' ':' exp
')'
{
    Ast.ExpBinop $ Ast.ExpBinopContent
    {
        Ast.expBinopLeft = $6,
        Ast.expBinopRight = $9,
        Ast.expBinopOperator = Ast.PLUS,
        Ast.expBinopLocation = $2
    }
} 

-- *************
-- *           *
-- * exp_binop *
-- *           *
-- *************
exp_binop_2:
operator loc
'('
    'left' ':' exp
    'right' ':' assign
')'
{
    Ast.ExpBinop $ Ast.ExpBinopContent
    {
        Ast.expBinopLeft = $6,
        Ast.expBinopRight = case $9 of { (Ast.StmtAssign a) -> Ast.stmtAssignRhs a; _ -> $6 },
        Ast.expBinopOperator = Ast.PLUS,
        Ast.expBinopLocation = $2
    }
} 

exp_binop:
exp_binop_1 { $1 } |
exp_binop_2 { $1 }

-- ***********
-- *         *
-- * exp_new *
-- *         *
-- ***********
exp_new:
'Expr_New' loc
'('
    ID ':' exp
    'args' ':' args
')' 
{
    Ast.ExpCall $ Ast.ExpCallContent
    {
        Ast.callee = $6,
        Ast.args = $9,
        Ast.expCallLocation = $2
    }
}


-- ************
-- *          *
-- * exp_call *
-- *          *
-- ************
exp_call:
exp_func_call          { $1 } |
exp_method_call        { $1 } |
exp_static_method_call { $1 }

-- *****************
-- *               *
-- * exp_func_call *
-- *               *
-- *****************
exp_func_call:
'Expr_FuncCall' loc
'('
    'name' ':' exp
    'args' ':' args
')' 
{
    Ast.ExpCallContent
    {
        Ast.callee = $6,
        Ast.args = $9,
        Ast.expCallLocation = $2
    }
}

-- *******************
-- *                 *
-- * exp_method_call *
-- *                 *
-- *******************
exp_method_call:
'Expr_MethodCall' loc
'('
    'var' ':' exp
    'name' ':' 'Identifier' loc '(' 'name' ':' tokenID ')'
    'args' ':' args
')' 
{
    Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarField $ Ast.VarFieldContent
        {
            Ast.varFieldLhs = $6,
            Ast.varFieldName = Token.FieldName $ Token.Named { Token.content = $14, Token.location = $10 },
            Ast.varFieldLocation = Location {
                Location.filename = getFilename $1,
                lineStart = lineStart $2,
                colStart = colStart $2,
                lineEnd = lineEnd $10,
                colEnd = colEnd $10
            }
        },
        Ast.args = $18,
        Ast.expCallLocation = $2
    }
}

-- **************************
-- *                        *
-- * exp_static_method_call *
-- *                        *
-- **************************
exp_static_method_call:
'Expr_StaticCall' loc
'('
    ID ':' exp
    'name' ':' identifier
    'args' ':' args
')'
{
    Ast.ExpCallContent
    {
        Ast.callee = Ast.ExpVar $ Ast.ExpVarContent $ Ast.VarField $ Ast.VarFieldContent
        {
            Ast.varFieldLhs = $6,
            Ast.varFieldName = Token.FieldName $9,
            Ast.varFieldLocation = $2
        },
        Ast.args = $12,
        Ast.expCallLocation = $2
    }
}

-- ********
-- *      *
-- * args *
-- *      *
-- ********
args:
'array' '('                      ')' { [] } |
'array' '(' listof(numbered_arg) ')' { $3 }

-- ****************
-- *              *
-- * numbered_arg *
-- *              *
-- ****************
numbered_arg: INT ':' arg { $3 }

-- *******
-- *     *
-- * arg *
-- *     *
-- *******
arg: 'Arg' loc
'('
    'name' ':' tokenID
    'value' ':' exp
    ID ':' ID
    ID ':' ID
')'
{
    $9
}

stmt_for_loop:
exp { $1 } |
exps { head $1 } 

-- ************
-- *          *
-- * stmt_for *
-- *          *
-- ************
stmt_for: 'Stmt_For' loc '(' 'init' ':' stmts 'cond' ':' exps 'loop' ':' stmt_for_loop 'stmts' ':' stmts ')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = $12,
        Ast.stmtWhileBody = $15,
        Ast.stmtWhileLocation = $2
    }
}

-- ****************
-- *              *
-- * stmt_foreach *
-- *              *
-- ****************
stmt_foreach:
'Stmt_Foreach' loc
'('
    'expr' ':' exp
    ID ':' ornull(exp)
    ID ':' ID 
    ID ':' exp
    'stmts' ':' stmts
')'
{
    Ast.StmtWhile $ Ast.StmtWhileContent
    {
        Ast.stmtWhileCond = $6,
        Ast.stmtWhileBody = $18,
        Ast.stmtWhileLocation = $2
    }
}


-- *******
-- *     *
-- * loc *
-- *     *
-- *******
loc: '[' INT ':' INT '-' INT ':' INT ']'
{
    Location
    {
        Location.filename = getFilename $1,
        lineStart = fromIntegral (tokIntValue $2),
        colStart = fromIntegral (tokIntValue $4),
        lineEnd = fromIntegral (tokIntValue $6),
        colEnd = fromIntegral (tokIntValue $8)
    }
}

{

extractParamSingleName' :: [ Token.ParamName ] -> Maybe Token.ParamName
extractParamSingleName' ps = case ps of { [p] -> Just p; _ -> Nothing }
 
extractParamSingleName :: [ Either Token.ParamName Token.NominalTy ] -> Maybe Token.ParamName
extractParamSingleName = extractParamSingleName' . lefts  

extractParamNominalType' :: [ Token.NominalTy ] -> Maybe Token.NominalTy
extractParamNominalType' ts = case ts of { [t] -> Just t; _ -> Nothing }
 
extractParamNominalType :: [ Either Token.ParamName Token.NominalTy ] -> Maybe Token.NominalTy
extractParamNominalType = extractParamNominalType' . rights 

paramify :: [ Either Token.ParamName Token.NominalTy ] -> Location -> Maybe Ast.Param
paramify attrs l = let
    name = extractParamSingleName attrs
    nominalType = extractParamNominalType attrs
    in case (name, nominalType) of { (Just n, Just t) -> Just $ Ast.Param n t Nothing 0; _ -> Nothing }

getFuncNameAttr :: [ Either (Either Token.FuncName [ Ast.Param ] ) (Either Token.NominalTy [ Ast.Stmt ] ) ] -> Maybe Token.FuncName
getFuncNameAttr = undefined

getFuncReturnType :: [ Either (Either Token.FuncName [ Ast.Param ] ) (Either Token.NominalTy [ Ast.Stmt ] ) ] -> Maybe Token.NominalTy
getFuncReturnType = undefined

getFuncBody :: [ Either (Either Token.FuncName [ Ast.Param ] ) (Either Token.NominalTy [ Ast.Stmt ] ) ] -> Maybe [ Ast.Stmt ]
getFuncBody = undefined

getFuncParams :: [ Either (Either Token.FuncName [ Ast.Param ] ) (Either Token.NominalTy [ Ast.Stmt ] ) ] -> Maybe [ Ast.Param ]
getFuncParams = undefined

-- add the /real/ serial index of the param
-- the parser just puts an arbitrary value
-- there because it lacks context
enumerateParams :: (Word,[Param]) -> [Param]
enumerateParams (_,[    ]) = []
enumerateParams (i,(p:ps)) =
    let
        n = (paramName        p)
        t = (paramNominalType p)
        head = Param { paramName = n, paramNominalType = t, paramNominalTypeV2 = Nothing, paramSerialIdx = i }
        tail = (enumerateParams (i+1,ps))
    in
        head:tail

dummyLoc :: Location
dummyLoc = Location "" 0 0 0 0

-- *************
-- *           *
-- * methodify *
-- *           *
-- *************
methodify :: Token.ClassName -> [ Ast.Stmt ] -> [(Token.MethdName, Ast.StmtMethodContent)]
methodify c stmts = catMaybes $ Data.List.map (methodify' c) stmts

methodify' :: Token.ClassName -> Ast.Stmt -> Maybe (Token.MethdName, Ast.StmtMethodContent)
methodify' c (Ast.StmtMethod m) = Just (Ast.stmtMethodName m, m { Ast.hostingClassName = c } )
methodify' _ _ = Nothing

-- ***********
-- *         *
-- * lexwrap *
-- *         *
-- ***********
lexwrap :: (AlexTokenTag -> Alex a) -> Alex a
lexwrap = (alexMonadScan >>=)

-- **************
-- *            *
-- * parseError *
-- *            *
-- **************
parseError :: AlexTokenTag -> Alex a
parseError t = alexError' (tokenLoc t)

-- ****************
-- *              *
-- * parseProgram *
-- *              *
-- ****************
parseProgram :: FilePath -> String -> Either String Ast.Root
parseProgram = runAlex' parse
}
