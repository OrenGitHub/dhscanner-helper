from __future__ import annotations

import os
import abc
import sys
import json
import typing
import pathlib
import logging
import argparse
import dataclasses

ARGPARSE_PROG_DESC: typing.Final[str] = """
Generate Lexer.x from lexer.json and Lexer.in.hs
"""

ARGPARSE_CONTENT_HELP: typing.Final[str] = """
Path to input lexer.json
"""

ARGPARSE_HASKELL_IN_FILENAME_HELP: typing.Final[str] = """
Path to output Lexer.in.hs file
"""

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s]: %(message)s",
    datefmt="%d/%m/%Y ( %H:%M:%S )",
    stream=sys.stdout
)

@dataclasses.dataclass(frozen=True, kw_only=True)
class Argparse:

    tokens_json_filename: pathlib.Path
    lexer_haskell_filename: pathlib.Path
    parser_haskell_filename: pathlib.Path
    alex_output_filename: str
    happy_output_filename: str

    @staticmethod
    def run() -> typing.Optional[Argparse]:

        logging.info('checking required args 👀')

        parser = argparse.ArgumentParser(
            description=ARGPARSE_PROG_DESC
        )

        parser.add_argument(
            '--tokens_json',
            required=True,
            type=str,
            metavar="<tokens>.json",
            help=ARGPARSE_CONTENT_HELP
        )

        parser.add_argument(
            '--lexer_haskell',
            required=True,
            type=str,
            metavar="<Lexer>.in.hs",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        parser.add_argument(
            '--parser_haskell',
            required=True,
            type=str,
            metavar="<Parser>.in.hs",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        parser.add_argument(
            '--alex_output_filename',
            required=True,
            type=str,
            metavar="<Lexer>.x",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        parser.add_argument(
            '--happy_output_filename',
            required=True,
            type=str,
            metavar="<Parser>.y",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        args = parser.parse_args()

        logging.info('received required args 😊')
        logging.info('start checking validity of args')
        if not os.path.isfile(args.tokens_json):
            logging.info('tokens json file does not exist 😬')
            return None

        logging.info('tokens json file exists 😊')
        if not os.path.isfile(args.lexer_haskell):
            logging.info('lexer haskell file does not exist 😬')
            return None

        logging.info('rules json file exists 😊')
        if not os.path.isfile(args.parser_haskell):
            logging.info('parser haskell file does not exist 😬')
            return None

        logging.info('parser haskell file exists 😊')
        logging.info('finished checking validity of args: perfect 😊')
        return Argparse(
            tokens_json_filename=pathlib.Path(args.tokens_json),
            lexer_haskell_filename=pathlib.Path(args.lexer_haskell),
            parser_haskell_filename=pathlib.Path(args.parser_haskell),
            alex_output_filename=args.alex_output_filename,
            happy_output_filename=args.happy_output_filename
        )

def extract_parts(haskell_filename: pathlib.Path) -> typing.Optional[tuple[str, str]]:

    if not haskell_filename.is_file():
        return None

    with haskell_filename.open() as fl:
        content = fl.read()

    parts = content.split("-- SEPARATOR", 1)
    if len(parts) != 2:
        return None

    return (parts[0].rstrip() + "\n", parts[1].lstrip())

ALEX_TOKEN_TAG: typing.Final[str] = """
-- *********
-- *       *
-- * Token *
-- *       *
-- *********
data AlexTokenTag
   = AlexTokenTag
     {
         tokenRaw :: AlexRawToken,
         tokenLoc :: Location
     }
     deriving ( Show )
"""

ALEX_RAW_TOKEN: typing.Final[str] = """
-- *************
-- *           *
-- * Raw Token *
-- *           *
-- *************
data AlexRawToken
   = AlexRawToken_ID String
   | AlexRawToken_INT Int
   | AlexRawToken_STR String
   | AlexRawToken_FLOAT Int
"""

WHITE_SPACE: typing.Final[str] = """
-- ***************
-- *             *
-- * white space *
-- *             *
-- ***************
@WHITE_SPACE = $white+
"""

IGNORE_WHITE_SPACE: typing.Final[str] = """
-- ***************************
-- *                         *
-- * whitespace ? do nothing *
-- *                         *
-- ***************************

@WHITE_SPACE ;
"""

VALUED_TOKENS: typing.Final[str] = """
-- ****************************
-- *                          *
-- * integers and identifiers *
-- *                          *
-- ****************************

@KW_ID    { lex  AlexRawToken_ID                    }
@KW_INT   { lex (AlexRawToken_INT . round . read)   }
@KW_STR   { lex AlexRawToken_STR                    }
@KW_FLOAT { lex (AlexRawToken_FLOAT . round . read) }
.         { lexicalError                            }

"""

TOKENS: typing.Final[str] = """
-- **********
-- *        *
-- * tokens *
-- *        *
-- **********
tokens :-

"""

PARSER_API: typing.Final[str] = """
-- ***********************
-- *                     *
-- * API function: parse *
-- *                     *
-- ***********************
%name parse
"""

HAPPY_TOKEN_TYPE: typing.Final[str] = """
-- **************
-- *            *
-- * token type *
-- *            *
-- **************
%tokentype { AlexTokenTag }
"""

MONAD: typing.Final[str] = """
-- *********
-- *       *
-- * monad *
-- *       *
-- *********
%monad { Alex }
"""

THE_LEXER: typing.Final[str] = """
-- *********
-- *       *
-- * lexer *
-- *       *
-- *********
%lexer { lexwrap } { AlexTokenTag TokenEOF _ }
"""

ERROR_HANDLER: typing.Final[str] = """
-- ***************************************************
-- *                                                 *
-- * Call this function when an error is encountered *
-- *                                                 *
-- ***************************************************
%error { parseError }
"""

VALUED_HAPPY_TOKENS: typing.Final[str] = """
-- ****************************
-- *                          *
-- * integers and identifiers *
-- *                          *
-- ****************************

ID     { AlexTokenTag (AlexRawToken_ID    id) _ }
STR    { AlexTokenTag (AlexRawToken_STR    s) _ }
INT    { AlexTokenTag (AlexRawToken_INT    i) _ }
FLOAT  { AlexTokenTag (AlexRawToken_FLOAT  f) _ }
"""

GRAMMAR_START: typing.Final[str] = """
-- *************************
-- *                       *
-- * grammar specification *
-- *                       *
-- *************************
%%
"""

PARAMETRIZED_RULES: typing.Final[str] = """
-- **********************
-- *                    *
-- * parametrized rules *
-- *                    *
-- **********************

optional(a): { Nothing } | a { Just $1 }
listof(a): a { [$1] } | a listof(a) { $1:$2 }
ornull(a): 'null' { Nothing } | a { Just $1 }
possibly_empty_arrayof(a): 'array' '(' ')' { [] } | 'array' '(' listof(a) ')' { $3 }
"""

PROGRAM_STARTS: typing.Final[str] = """
-- ***********
-- *         *
-- * program *
-- *         *
-- ***********
"""

def from_tokens_json(filename: pathlib.Path) -> typing.Optional[list[NameRegex]]:
    try:
        with filename.open() as fl:
            data = json.load(fl)
    except OSError:
        logging.error('Fatal error reading %s', filename)
        return None
    except json.JSONDecodeError:
        logging.error('Invalid json file: %s', filename)
        return None

    keywords = 'keywords'
    if keywords not in data:
        logging.error('Invalid schema: %s ( missing: %s )', filename, keywords)
        return None
    if not isinstance(data[keywords], list):
        logging.error('Invalid json schema: %s ( %s is not a list ) ', filename, keywords)
        return None
    if not all(
        isinstance(k, dict) and
        isinstance(k.get('name'), str) and
        isinstance(k.get('regex'), str)
        for k in data[keywords]
    ):
        logging.error(
            'Invalid json schema: %s (not all %s have name and regex value ) ',
            filename,
            keywords
        )
        return None

    logging.info('json has correct schema 😊')
    return [NameRegex(name=entry['name'], regex=entry['regex']) for entry in data[keywords]]

@dataclasses.dataclass(frozen=True, kw_only=True)
class NameRegex:

    name: str
    regex: str

@dataclasses.dataclass(frozen=True, kw_only=True)
class AlexFile:

    haskell_prologue: str
    haskell_epilogue: str
    content: str

    def __str__(self) -> str:
        return (
            '{\n' + self.haskell_prologue + '\n}\n\n' +
            self.content + '\n\n' +
            self.haskell_epilogue + '}\n'
        )

    def store(self, filename: str) -> None:
        with open(filename, 'w', encoding='utf-8') as fl:
            fl.write(str(self))

@dataclasses.dataclass(frozen=True)
class Lexer:

    data: list[NameRegex]

    def build(self, haskell_filename: pathlib.Path) -> typing.Optional[AlexFile]:

        parts = extract_parts(haskell_filename)
        if parts is None:
            return None

        if content := self._alexify_content():
            return AlexFile(
                haskell_prologue=parts[0],
                haskell_epilogue=parts[1],
                content=str(content)
            )

        return None

    def _alexify_content(self) -> typing.Optional[str]:

        def rulify(name: str) -> str:
            return f'{name} {{ lex\' AlexRawToken_{name} }}'

        def variantify(name: str) -> str:
            return f'   | AlexRawToken_{name}'

        valued_tokens = ['ID', 'STR', 'INT', 'FLOAT']
        data = { entry.name: entry.regex for entry in self.data }
        macros = [f'@KW_{name} = {regex}' for name, regex in data.items()]
        rules = [rulify(name) for name in data.keys() if name not in valued_tokens]
        variants = [variantify(name) for name in data.keys() if name not in valued_tokens]

        output = ""
        output += "%wrapper \"monadUserState\"\n\n"
        output += '\n'.join(macros) + '\n'
        output += WHITE_SPACE
        output += TOKENS
        output += '\n'.join(rules) + '\n'
        output += IGNORE_WHITE_SPACE
        output += VALUED_TOKENS
        output += '{\n'
        output += ALEX_TOKEN_TAG
        output += ALEX_RAW_TOKEN
        output += '\n'.join(variants) + '\n'
        output += '   | TokenEOF\n'
        output += '   deriving ( Show )\n'

        return output

    @staticmethod
    def from_json(filename: pathlib.Path) -> typing.Optional[Lexer]:
        if data := from_tokens_json(filename):
            return Lexer(data=data)

        return None

@dataclasses.dataclass(frozen=True)
class HappyFile:

    haskell_prologue: str
    haskell_epilogue: str
    content: str

    def __str__(self) -> str:
        return (
            '{\n' + self.haskell_prologue + '\n}\n\n' +
            self.content + '\n\n' +
            '{\n' + self.haskell_epilogue + '}\n'
        )

    def store(self, filename: str) -> None:
        with open(filename, 'w', encoding='utf-8') as fl:
            fl.write(str(self))

@dataclasses.dataclass(frozen=True)
class Parser:

    tokens: list[NameRegex]
    rules: list[Rule]

    def build(self, haskell_filename: pathlib.Path) -> typing.Optional[HappyFile]:

        parts = extract_parts(haskell_filename)
        if parts is None:
            return None

        if content := self._happify_the_content():
            return HappyFile(
                haskell_prologue=parts[0],
                haskell_epilogue=parts[1],
                content=str(content)
            )

        return None

    def _happify_the_content(self) -> typing.Optional[str]:

        def clean(value: str) -> str:
            return value.replace('"', '')

        def tokenify(name: str, value: str):
            if name != 'SLASH':
                return f'\'{clean(value)}\' {lbrack} {tag} {raw}_{name} _ {rbrack}'
            
            return f'\'\\\\\' {lbrack} {tag} {raw}_{name} _ {rbrack}'

        lbrack = '{'
        rbrack = '}'
        tag = 'AlexTokenTag'
        raw = 'AlexRawToken'
        valued = ['ID', 'STR', 'INT', 'FLOAT']
        data = { entry.name: entry.regex for entry in self.tokens }
        macros = [f'{tokenify(name, value)}' for name, value in data.items() if name not in valued]

        output = ""
        output += PARSER_API
        output += HAPPY_TOKEN_TYPE
        output += MONAD
        output += THE_LEXER
        output += ERROR_HANDLER
        output += "\n%token\n\n"
        output += '\n'.join(macros) + '\n'
        output += VALUED_HAPPY_TOKENS
        output += GRAMMAR_START
        output += PARAMETRIZED_RULES
        output += PROGRAM_STARTS
        output += '\n'.join([str(rule) for rule in self.rules])

        return output

@dataclasses.dataclass(frozen=True)
class Derived(abc.ABC):
    @abc.abstractmethod
    def __str__(self) -> str:
        ...

@dataclasses.dataclass(frozen=True)
class Variable(Derived):

    variable: str

    @typing.override
    def __str__(self) -> str:
        return self.variable

@dataclasses.dataclass(frozen=True)
class Token(Derived):

    token: str

    @typing.override
    def __str__(self) -> str:
        valued_tokens = ['INT', 'ID', 'STR', 'FLOAT']
        if self.token in valued_tokens:
            return self.token
        
        return f'\'{self.token}\''

@dataclasses.dataclass(frozen=True)
class Parametrized(Derived):

    kind: str
    variable: Variable

    @typing.override
    def __str__(self) -> str:
        return f'{self.kind}({self.variable})'

@dataclasses.dataclass(frozen=True)
class Action:

    action: str

    def __str__(self) -> str:
        return self.action

@dataclasses.dataclass(frozen=True)
class Lhs:

    lhs: str

    def __str__(self) -> str:
        return self.lhs

@dataclasses.dataclass(frozen=True)
class Rule(abc.ABC):
    @abc.abstractmethod
    def __str__(self) -> str:
        ...

@dataclasses.dataclass(frozen=True)
class RuleChoice(Rule):

    lhs: Lhs
    content: list[Variable]

    @typing.override
    def __str__(self) -> str:
        lbrack = '{'
        rbrack = '}'
        choices = ' |\n'.join([f'{element} {lbrack} $1 {rbrack}' for element in self.content])
        return f'{self.lhs}:\n{choices}\n'

@dataclasses.dataclass(frozen=True)
class RuleSequence(Rule):

    lhs: Lhs
    derived: list[Derived]
    action: Action

    @typing.override
    def __str__(self) -> str:
        lbrack = '{'
        rbrack = '}'
        derived = ' '.join([f'{element}' for element in self.derived])
        return f'{self.lhs}: {derived}\n{lbrack}\n{self.action}\n{rbrack}\n'

RULES: list[Rule] = [
    RuleSequence(
        Lhs('program'),
        [
            Variable('stmts')
        ],
        Action("Ast.Root { Ast.filename = \"DDD\", Ast.stmts = $1 }")
    ),
    RuleSequence(
        Lhs('stmts'),
        [
            Parametrized(
                'possibly_empty_arrayof',
                Variable('numbered_stmt')
            )
        ],
        Action('$1')
    ),
    RuleSequence(
        Lhs('numbered_stmt'),
        [
            Token('INT'),
            Token(':'),
            Variable('stmt')
        ],
        Action('$3')
    ),
    RuleSequence(
        Lhs('stmt_namespace'),
        [
            Token('Stmt_Namespace'),
            Variable('loc'),
            Token('('),
            Token('name'),
            Token(':'),
            Variable('Name'),
            Token('stmts'),
            Token(':'),
            Variable('stmts')
        ],
        Action('\n'.join([
            '    Ast.StmtBlock $ Ast.StmtBlockContent',
            '    {',
            '        Ast.stmtBlockContent = $9,',
            '        Ast.stmtBlockLocation = $2',
            '    }'
        ]))
    ),
    RuleChoice(
        Lhs('stmt'),
        [
            Variable('stmt_namespace')
        ],
    ),
    RuleSequence(
        Lhs('Name'),
        [
            Token('Name'),
            Variable('loc'),
            Token('('),
            Token('name'),
            Token(':'),
            Variable('TokenID'),
            Token(')')
        ],
        Action('$6')
    ),
    RuleSequence(
        Lhs('TokenID'),
        [
            Token('ID')
        ],
        Action('tokIDValue $1')
    ),
    RuleSequence(
        Lhs('loc'),
        [
            Token('['),
            Token('INT'),
            Token(':'),
            Token('INT'),
            Token('-'),
            Token('INT'),
            Token(':'),
            Token('INT'),
            Token(']')
        ],
        Action('Location { Location.filename = getFilename $1, lineStart = fromIntegral (tokIntValue $2), colStart = fromIntegral (tokIntValue $4), lineEnd = fromIntegral (tokIntValue $6), colEnd = fromIntegral (tokIntValue $8)}')
    )
]

def generate_parser(args: Argparse) -> None:

    tokens_json_filename = args.tokens_json_filename
    lexer_haskell_filename = args.lexer_haskell_filename
    parser_haskell_filename = args.parser_haskell_filename
    alex_output_filename = args.alex_output_filename
    happy_output_filename = args.happy_output_filename
    tokens = from_tokens_json(tokens_json_filename)
    if tokens is None:
        return

    lexer = Lexer(tokens)
    if alex_file := lexer.build(lexer_haskell_filename):
        alex_file.store(alex_output_filename)

    parser = Parser(tokens, RULES)
    if happy_file := parser.build(parser_haskell_filename):
        happy_file.store(happy_output_filename)

if __name__ == "__main__":
    if args := Argparse.run():
        generate_parser(args)
