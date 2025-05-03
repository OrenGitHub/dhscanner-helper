{-# OPTIONS -w  #-}

module PhpLexer

where

import Prelude hiding (lex)
import Control.Monad ( liftM )
import Data.List
import Location

-- SEPARATOR

setFilePath :: FilePath -> Alex ()
setFilePath fp = do
  alexSetUserState (AlexUserState { filepath = fp })

data AlexTokenTag
   = AlexTokenTag
     {
         tokenRaw :: AlexRawToken,
         tokenLoc :: Location
     }
     deriving ( Show )

data AlexRawToken

     = AlexRawToken_INT Int
     | AlexRawToken_ID String
     | AlexRawToken_FLOAT Int
     | AlexRawToken_STR String
      
     deriving ( Show )

alexEOF :: Alex AlexTokenTag
alexEOF = do
    ((AlexPn _ l c),_,_,_) <- alexGetInput
    alexUserState <- alexGetUserState
    return $
        AlexTokenTag
        {
            tokenRaw = TokenEOF,
            tokenLoc = Location {
                lineStart = fromIntegral l,
                lineEnd = fromIntegral l,
                colStart = fromIntegral c,
                colEnd = fromIntegral c,
                filename = (filepath alexUserState)
            }
        }

lex :: (String -> AlexRawToken) -> AlexInput -> Int -> Alex AlexTokenTag
lex f ((AlexPn _ l c),_,_,str) i = do
    alexUserState <- alexGetUserState
    return $
        AlexTokenTag
        {
            tokenRaw = (f (take i str)),
            tokenLoc = Location {
                lineStart = fromIntegral l,
                lineEnd = fromIntegral l,
                colStart = fromIntegral c,
                colEnd = fromIntegral (c+i),
                filename = (filepath alexUserState)
            }
        }

lex' :: AlexRawToken -> AlexInput -> Int -> Alex AlexTokenTag
lex' = lex . const

lexicalError :: AlexInput -> Int -> Alex AlexTokenTag
lexicalError ((AlexPn _ l c),_,_,str) i = alexEOF 

alexError' :: Location -> Alex a
alexError' location = alexError $ "Error[ " ++ show location ++ " ]"

getFilename :: AlexTokenTag -> String
getFilename = Location.filename . location

location :: AlexTokenTag -> Location
location = tokenLoc

tokIntValue :: AlexTokenTag -> Int
tokIntValue t = case (tokenRaw t) of { AlexRawToken_INT i -> i; _ -> 0; }

normalizeChar :: Char -> String
normalizeChar '\\' = "\\\\"
normalizeChar c = [c]

normalize :: String -> String
normalize = concatMap normalizeChar

tokIDValue :: AlexTokenTag -> String
tokIDValue t = case (tokenRaw t) of { AlexRawToken_ID s -> (normalize s); _ -> ""; }

findString :: String -> String -> Maybe Int
findString needle haystack = Data.List.findIndex (Data.List.isPrefixOf needle) (Data.List.tails haystack)

tokStrLocation' :: AlexTokenTag -> String -> Maybe Location
tokStrLocation' t s = case (findString "[" s) of
    Nothing -> Nothing
    Just i1 -> let s1 = drop (i1 + 1) s in case (findString ":" s1) of
        Nothing -> Nothing
        Just i2 -> let { startLine = read (take i2 s1); s2 = (drop (i2 + 1) s1) } in case (findString " - " s2) of
            Nothing -> Nothing
            Just i3 -> let { startCol = read (take i3 s2); s3 = drop (i3 + 3) s2 } in case (findString ":" s3) of
                Nothing -> Nothing
                Just i4 -> let { endLine = read (take i4 s3); s4 = drop (i4 + 1) s3 } in case (findString "]" s4) of
                    Nothing -> Nothing
                    Just i5 -> let { endCol = read (take i5 s4) } in Just $ Location {
                        Location.filename = Location.filename (tokenLoc t),
                        Location.lineStart = startLine,
                        Location.lineEnd = endLine,
                        Location.colStart = startCol,
                        Location.colEnd = endCol
                    }

tokStrLocation :: AlexTokenTag -> Maybe Location
tokStrLocation t = case (tokenRaw t) of { (AlexRawToken_STR s) -> tokStrLocation' t s; _ -> Nothing }

tokStrValue'' :: AlexTokenTag -> String -> Maybe String
tokStrValue'' t s = case (findString "value: " s) of
    Nothing -> Nothing
    Just i1 -> let s1 = drop (i1 + 7) s in case (findString "\n" s1) of
        Nothing -> Nothing
        Just i2 -> Just (take i2 s1)

tokStrValue' :: AlexTokenTag -> String -> Maybe (String,Location)
tokStrValue' t s = case (tokStrLocation t) of 
    Nothing -> Nothing
    Just location -> case (tokStrValue'' t s) of
        Nothing -> Nothing
        Just constStrValue -> Just (constStrValue,location)

tokStrValue :: AlexTokenTag -> Maybe (String,Location)
tokStrValue t = case (tokenRaw t) of { (AlexRawToken_STR s) -> tokStrValue' t s; _ -> Nothing; }

runAlex' :: Alex a -> FilePath -> String -> Either String a
runAlex' a fp input = runAlex input (setFilePath fp >> a)
