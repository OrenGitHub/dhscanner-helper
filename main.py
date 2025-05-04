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

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s]: %(message)s",
    datefmt="%d/%m/%Y ( %H:%M:%S )",
    stream=sys.stdout
)

ARGPARSE_PROG_DESC: typing.Final[str] = """
Generate Lexer.x from lexer.json and Lexer.in.hs
"""

ARGPARSE_CONTENT_HELP: typing.Final[str] = """
Path to input lexer.json
"""

ARGPARSE_HASKELL_IN_FILENAME_HELP: typing.Final[str] = """
Path to output Lexer.in.hs file
"""

@dataclasses.dataclass(frozen=True, kw_only=True)
class Argparse:

    tokens_json_filename: pathlib.Path
    lexer_haskell_filename: pathlib.Path
    rules_json_filename: pathlib.Path
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
            '--rules_json',
            required=True,
            type=str,
            metavar="<rules>.json",
            help=ARGPARSE_CONTENT_HELP
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

        logging.info('lexer haskell file exists 😊')
        if not os.path.isfile(args.rules_json):
            logging.info('rules json file does not exist 😬')
        
        logging.info('rules json file exists 😊')
        if not os.path.isfile(args.parser_haskell):
            logging.info('parser haskell file does not exist 😬')
            return None

        logging.info('parser haskell file exists 😊')
        logging.info('finished checking validity of args: perfect 😊')
        return Argparse(
            tokens_json_filename=pathlib.Path(args.tokens_json),
            lexer_haskell_filename=pathlib.Path(args.lexer_haskell),
            rules_json_filename=pathlib.Path(args.rules_json),
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

def from_tokens_json(filename: pathlib.Path) -> typing.Optional[list[NameRegex]]:
    try:
        with filename.open() as fl:
            data = json.load(fl)
    except OSError:
        logging.error(f"Fatal error reading {filename}")
        return None
    except json.JSONDecodeError:
        logging.error(f"Invalid json file: {filename}")
        return None

    keywords = 'keywords'
    if keywords not in data:
        logging.error(f'Invalid schema: {filename} ( missing: {keywords} )')
        return None
    if not isinstance(data[keywords], list):
        logging.error(f'Invalid json schema: {filename} ({keywords} is not a list ) ')
        return None
    if not all(
        isinstance(k, dict) and
        isinstance(k.get('name'), str) and
        isinstance(k.get('regex'), str)
        for k in data[keywords]
    ):
        logging.error(f'Invalid json schema: {filename} (not all {keywords} have name and regex value ) ')
        return None

    logging.info(f'json has correct schema 😊')
    return [NameRegex(name=entry['name'], regex=entry['regex']) for entry in data[keywords]]


@dataclasses.dataclass(frozen=True)
class HappyFile:

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
        with open(filename, 'w') as fl:
            fl.write(str(self))

@dataclasses.dataclass(frozen=True)
class Derived(abc.ABC):

    @abc.abstractmethod
    def __init__(self) -> None:
        ...

    @staticmethod
    def from_dict(candidate: dict) -> Derived:
        ...

@dataclasses.dataclass(frozen=True)
class VariableOrToken(abc.ABC):

    @abc.abstractmethod
    def __init__(self):
        ...

    @typing.override
    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[VariableOrToken]:
        ...

    @typing.override
    @staticmethod
    def valid_dict_representation(candidate: dict) -> bool:
        ...

@dataclasses.dataclass(frozen=True)
class Variable(VariableOrToken):

    variable: str

    @typing.override
    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[VariableOrToken]:
        if 'variable' not in candidate:
            return None
        
        if not isinstance(candidate['variable'], str):
            return None
        
        return Variable(candidate['variable'])

@dataclasses.dataclass(frozen=True)
class Token(VariableOrToken):

    token: str

    @typing.override
    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[VariableOrToken]:
        if 'token' not in candidate:
            return None
        
        if not isinstance(candidate['token'], str):
            return None
        
        return Token(candidate['token'])

@dataclasses.dataclass(frozen=True)
class Action:

    action: str

    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[Action]:
        if 'action' not in candidate:
            return None
        
        if not isinstance(candidate['action'], str):
            return None
        
        return Action(candidate['action'])

@dataclasses.dataclass(frozen=True)
class VariableAction:

    variable: Variable
    action: Action

    def from_dict(candidate: dict) -> bool:

        if 'variable' not in candidate:
            return False

        if 'action' not in candidate:
            return False
        
        if v := Variable.from_dict(candidate['variable']):
            if action := Action.from_dict(candidate['action']):
                return VariableAction(variable=v, action=action)

        return None

@dataclasses.dataclass(frozen=True)
class DerivedSequence(Derived):

    sequence: list[VariableOrToken]

    @typing.override
    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[Derived]:

        if 'sequence' not in candidate:
            return None

        sequence = candidate['sequence']
        result = [VariableOrToken.from_dict(c) for c in sequence]
        return result

@dataclasses.dataclass(frozen=True)
class DerivedChoice(Derived):

    choice: list[VariableAction]

    @typing.override
    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[Derived]:

        if 'choice' not in candidate:
            return None

        choice = candidate['choice']
        result = [VariableAction.from_dict(c) for c in choice]
        return result


@dataclasses.dataclass(frozen=True)
class Rule:

    LHS: Variable
    derived: Derived
    action: Action

    @staticmethod
    def from_dict(candidate: dict) -> typing.Optional[Rule]:
        
        if 'LHS' not in candidate:
            return None
        
        if 'derived' not in candidate:
            return None
        
        if 'action' not in candidate:
            return None
        
        if lhs := Variable.from_dict(candidate['LHS']):
            if derived := Derived.from_dict(candidate['derived']):
                if action := Action.from_dict(candidate['action']):
                    return Rule(lhs, derived, action)
                
        return None

@dataclasses.dataclass(frozen=True)
class Parser:

    tokens: list[NameRegex]
    rules: list[Rule]

    @staticmethod
    def from_rules_json(filename: pathlib.Path) -> typing.Optional[list[Rule]]:
        try:
            with filename.open() as fl:
                data = json.load(fl)
        except OSError:
            logging.error(f"Fatal error reading {filename}")
            return None
        except json.JSONDecodeError:
            logging.error(f"Invalid json file: {filename}")
            return None

        if not isinstance(data, list):
            logging.error(f'Invalid json schema: {filename} ( not a list ) ')
            return None

        result = [Rule.from_dict(r) for r in data]
        return result if None not in result else None

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

        lbrack = '{'
        rbrack = '}'
        tag = 'AlexTokenTag'
        raw = 'AlexRawToken'
        valued = ['ID', 'STR', 'INT', 'FLOAT'] 
        clean = lambda value: value.replace('\\', '')
        data = { entry.name: entry.regex for entry in self.data }
        tokenify = lambda name, value: f'\'{clean(value)}\' {tag} {raw}_{name} {lbrack} _ {rbrack}'
        macros = [f'{tokenify(name, value)}' for name, value in data.items() if name not in valued]

        output = ""
        output += PARSER_API
        output += HAPPY_TOKEN_TYPE
        output += MONAD
        output += ERROR_HANDLER
        output += "%token\n\n"
        output += '\n'.join(macros)

        return output

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
        with open(filename, 'w') as fl:
            fl.write(str(self))

@dataclasses.dataclass(frozen=True, kw_only=True)
class NameRegex:

    name: str
    regex: str

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

        valued_tokens = ['ID', 'STR', 'INT', 'FLOAT'] 
        data = { entry.name: entry.regex for entry in self.data }
        namify = lambda name: f'@KW_{name}'
        rulify = lambda name: f'{name} {{ lex\' AlexRawToken_{name} }}'
        variantify = lambda name: f'   | AlexRawToken_{name}'
        macros = [f'{namify(name)} = {regex}' for name, regex in data.items()]
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

def main() -> None:
    if args := Argparse.run():
        tokens_json_filename = args.tokens_json_filename
        lexer_haskell_filename = args.lexer_haskell_filename
        rules_json_filename = args.rules_json_filename
        parser_haskell_filename = args.parser_haskell_filename
        alex_output_filename = args.alex_output_filename
        happy_output_filename = args.happy_output_filename
        tokens = from_tokens_json(tokens_json_filename)
        if tokens is None:
            return
        
        lexer = Lexer(tokens)
        if alex_file := lexer.build(lexer_haskell_filename):
            alex_file.store(alex_output_filename)
        
        if rules := Parser.from_rules_json(rules_json_filename):
            parser = Parser(tokens, rules)
            if happy_file := parser.build(parser_haskell_filename):
                happy_file.store(happy_output_filename)

if __name__ == "__main__":
    main()
