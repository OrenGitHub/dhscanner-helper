from __future__ import annotations

import os
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

    content: pathlib.Path
    haskell_filename: pathlib.Path
    alex_output_filename: str

    @staticmethod
    def run() -> typing.Optional[Argparse]:

        logging.info('checking required args 👀')

        parser = argparse.ArgumentParser(
            description=ARGPARSE_PROG_DESC
        )

        parser.add_argument(
            '--content',
            required=True,
            type=str,
            metavar="<lexer>.json",
            help=ARGPARSE_CONTENT_HELP
        )

        parser.add_argument(
            '--haskell_filename',
            required=True,
            type=str,
            metavar="<Lexer>.in.hs",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        parser.add_argument(
            '--alex_output_filename',
            required=True,
            type=str,
            metavar="<Lexer>.x",
            help=ARGPARSE_HASKELL_IN_FILENAME_HELP
        )

        args = parser.parse_args()

        logging.info('received required args 😊')
        if os.path.isfile(args.content):

            logging.info('json content file exists 😊')
            if os.path.isfile(args.haskell_filename):
                logging.info('haskell file exists 😊')
                return Argparse(
                    content=pathlib.Path(args.content),
                    haskell_filename=pathlib.Path(args.haskell_filename),
                    alex_output_filename=args.alex_output_filename
                )
            else:
                logging.info('haskell file does not exist 😬')
        else:
            logging.info('json content file does not exist 😬')

        return None

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

@dataclasses.dataclass(frozen=True, kw_only=True)
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
        return Lexer(data=[NameRegex(name=entry['name'], regex=entry['regex']) for entry in data[keywords]])

def main() -> None:
    if args := Argparse.run():
        content_filename = args.content
        haskell_filename = args.haskell_filename
        alex_output_filename = args.alex_output_filename
        if lexer := Lexer.from_json(content_filename):
            if alex_file := lexer.build(haskell_filename):
                alex_file.store(alex_output_filename)

if __name__ == "__main__":
    main()
