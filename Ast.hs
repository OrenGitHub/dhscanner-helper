{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

module Ast

where

import Data.Aeson
import GHC.Generics
import Data.Map ( Map )

-- project imports
import Location
import qualified Token

data Root
   = Root
     {
         filename :: FilePath,
         stmts :: [ Stmt ]
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Exp
   = ExpInt ExpIntContent
   | ExpStr ExpStrContent
   | ExpVar ExpVarContent
   | ExpBool ExpBoolContent
   | ExpNull ExpNullContent
   | ExpCall ExpCallContent
   | ExpBinop ExpBinopContent
   | ExpLambda ExpLambdaContent
   deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Stmt
   = StmtExp Exp
   | StmtIf StmtIfContent
   | StmtTry StmtTryContent
   | StmtFunc StmtFuncContent
   | StmtBlock StmtBlockContent
   | StmtBreak StmtBreakContent
   | StmtClass StmtClassContent
   | StmtWhile StmtWhileContent
   | StmtImport StmtImportContent
   | StmtMethod StmtMethodContent
   | StmtAssign StmtAssignContent
   | StmtReturn StmtReturnContent
   | StmtVardec StmtVardecContent
   | StmtContinue StmtContinueContent
   deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Param
   = Param
     {
         paramName :: Token.ParamName,
         paramNominalType :: Token.NominalTy, -- ^ ( will be deprecated soon )
         paramNominalTypeV2 :: Maybe Var, -- ^ ( use this instead )
         paramSerialIdx :: Word -- ^ ( /zero/-based )
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data DataMember
   = DataMember
     {
         dataMemberName :: Token.MembrName,
         dataMemberNominalType :: Token.NominalTy,
         dataMemberInitValue :: Maybe Exp
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data DataMembers
   = DataMembers
     {
         actualDataMembers :: Map Token.MembrName DataMember
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtMethodContent
   = StmtMethodContent
     {
         stmtMethodReturnType :: Token.NominalTy,
         stmtMethodName :: Token.MethdName,
         stmtMethodParams :: [ Param ],
         stmtMethodBody :: [ Stmt ],
         stmtMethodLocation :: Location,
         hostingClassName :: Token.ClassName,
         hostingClassSupers :: [ Token.SuperName ]
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Methods
   = Methods
     {
         actualMethods :: Map Token.MethdName StmtMethodContent
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtClassContent
   = StmtClassContent
     {
         stmtClassName :: Token.ClassName,
         stmtClassSupers :: [ Token.SuperName ],
         stmtClassDataMembers :: DataMembers,
         stmtClassMethods :: Methods
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtFuncContent
   = StmtFuncContent
     {
         stmtFuncReturnType :: Token.NominalTy,
         stmtFuncName :: Token.FuncName,
         stmtFuncParams :: [ Param ],
         stmtFuncBody :: [ Stmt ],
         stmtFuncAnnotations :: [ Exp ],
         stmtFuncLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtVardecContent
   = StmtVardecContent
     {
         stmtVardecName :: Token.VarName,
         stmtVardecNominalType :: Token.NominalTy,
         stmtVardecInitValue :: Maybe Exp,
         stmtVardecLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpIntContent
   = ExpIntContent
     {
         expIntValue :: Token.ConstInt
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpStrContent
   = ExpStrContent
     {
         expStrValue :: Token.ConstStr
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpBoolContent
   = ExpBoolContent
     {
         expBoolValue :: Token.ConstBool
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpNullContent
   = ExpNullContent
     {
         expNullValue :: Token.ConstNull
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Operator
   = PLUS
   | MINUS
   | TIMES
   | DIVIDE
   | PERCENT
   deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpLambdaContent
   = ExpLambdaContent
     {
         expLambdaParams :: [ Param ],
         expLambdaBody :: [ Stmt ],
         expLambdaLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpBinopContent
   = ExpBinopContent
     {
         expBinopLeft :: Exp,
         expBinopRight :: Exp,
         expBinopOperator :: Operator,
         expBinopLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpVarContent
   = ExpVarContent
     {
         actualExpVar :: Var
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtAssignContent
   = StmtAssignContent
     {
         stmtAssignLhs :: Var,
         stmtAssignRhs :: Exp
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtTryContent
   = StmtTryContent
     {
         stmtTryPart :: [ Stmt ],
         stmtCatchPart :: [ Stmt ],
         stmtTryLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtBreakContent
   = StmtBreakContent
     {
         stmtBreakLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtBlockContent
   = StmtBlockContent
     {
         stmtBlockContent :: [ Stmt ],
         stmtBlockLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtImportContent
   = StmtImportContent
     {
         stmtImportSource :: String,
         stmtImportFromSource :: Maybe String,
         stmtImportAlias :: Maybe String,
         stmtImportLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtContinueContent
   = StmtContinueContent
     {
         stmtContinueLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtIfContent
   = StmtIfContent
     {
         stmtIfCond :: Exp,
         stmtIfBody :: [ Stmt ],
         stmtElseBody :: [ Stmt ],
         stmtIfLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtWhileContent
   = StmtWhileContent
     {
         stmtWhileCond :: Exp,
         stmtWhileBody :: [ Stmt ],
         stmtWhileLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data StmtReturnContent
   = StmtReturnContent
     {
         stmtReturnValue :: Maybe Exp,
         stmtReturnLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data ExpCallContent
   = ExpCallContent
     {
         callee :: Exp,
         args :: [ Exp ],
         expCallLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data VarFieldContent
   = VarFieldContent
     {
         varFieldLhs :: Exp,
         varFieldName :: Token.FieldName,
         varFieldLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data VarSimpleContent
   = VarSimpleContent
     {
         varName :: Token.VarName
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data VarSubscriptContent
   = VarSubscriptContent
     {
         varSubscriptLhs :: Exp,
         varSubscriptIdx :: Exp,
         varSubscriptLocation :: Location
     }
     deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )

data Var
   = VarSimple VarSimpleContent
   | VarField VarFieldContent
   | VarSubscript VarSubscriptContent
   deriving ( Show, Eq, Ord, Generic, ToJSON, FromJSON )
