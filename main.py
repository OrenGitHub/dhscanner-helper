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
                return Argparse(
                    content=pathlib.Path(args.content),
                    haskell_filename=pathlib.Path(args.haskell_filename),
                    alex_output_filename=args.alex_output_filename
                )
        else:
            logging.info('json content file does not exist 😬')
        return None

def extract_prologue_part(haskell_filename: pathlib.Path) -> typing.Optional[str]:
    return ""

def extract_epilogue_part(haskell_filename: pathlib.Path) -> typing.Optional[str]:
    return ""

@dataclasses.dataclass(frozen=True, kw_only=True)
class AlexFile:

    haskell_prologue: str
    haskell_epilogue: str
    content: str

    def __str__(self) -> str:
        return (
            self.haskell_prologue +
            self.content +
            self.haskell_epilogue
        )

    def store(self, filename: str) -> None:
        with open(filename, 'w') as fl:
            fl.write(str(self))

@dataclasses.dataclass(frozen=True, kw_only=True)
class Lexer:

    keywords: list[str]

    def build(self, haskell_filename: pathlib.Path) -> typing.Optional[AlexFile]:
        if haskell_prologue := extract_prologue_part(haskell_filename):
            if haskell_epilogue := extract_epilogue_part(haskell_filename):
                if content := self.alexify_content():
                    return AlexFile(
                        haskell_prologue=haskell_prologue,
                        haskell_epilogue=haskell_epilogue,
                        content=content
                    )
        return None

    @staticmethod
    def from_json(path: str) -> typing.Optional[Lexer]:
        try:
            with open(path) as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            logging.error(f"JSON decode error in {path}: {e}")
            return None
        except OSError as e:
            logging.error(f"File error when opening {path}: {e}")
            return None

        if "keywords" not in data:
            logging.error(f"Missing 'keywords' field in {path}")
            return None
        if not isinstance(data["keywords"], list):
            logging.error(f"'keywords' must be a list in {path}")
            return None
        if not all(isinstance(k, str) for k in data["keywords"]):
            logging.error(f"All items in 'keywords' must be strings in {path}")
            return None

        logging.info(f"Successfully loaded lexer spec from {path}")
        return Lexer(keywords=data["keywords"])

def generate_tokens_block(keywords: list[str]) -> str:
    lines = ["tokens :-"]
    for kw in keywords:
        token = "KW_" + kw.upper()
        lines.append(f'  "{kw}" {{ \\s -> Token {token} }}')
    lines.append('  . { \\_ -> error "Unknown token" }')
    return "\n".join(lines)

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
