from __future__ import annotations

import glob
import os
import sys
import json
import openai
import typing
import pathlib
import logging
import argparse
import subprocess
import dataclasses

import requests

ARGPARSE_PROG_DESC: typing.Final[str] = """

LALR(1) Parser generator builder
"""

ARGPARSE_CONTENT_HELP: typing.Final[str] = """
Path to input lexer.json
"""

MODEL = "gpt-4o"

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s]: %(message)s",
    datefmt="%d/%m/%Y ( %H:%M:%S )",
    stream=sys.stdout
)

@dataclasses.dataclass(frozen=True, kw_only=True)
class Argparse:

    tokens_json_filename: pathlib.Path
    rules_python_filename: pathlib.Path
    haskell_ast_filename: pathlib.Path
    parsing_status_json_filename: pathlib.Path

    @staticmethod
    def run() -> typing.Optional[Argparse]:

        logging.info('>>>>>>>>>>>>>>>>>>>>>> LFG')
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
            '--rules_python',
            required=True,
            type=str,
            metavar="<rules>.py",
            help=ARGPARSE_CONTENT_HELP
        )

        parser.add_argument(
            '--haskell_ast',
            required=True,
            type=str,
            metavar="<Ast>.hs",
            help=ARGPARSE_CONTENT_HELP
        )

        parser.add_argument(
            '--parsing_status',
            required=True,
            type=str,
            metavar="<Ast>.hs",
            help=ARGPARSE_CONTENT_HELP
        )

        args = parser.parse_args()

        logging.info('received required args 😊')
        logging.info('start checking validity of args')
        if not os.path.isfile(args.tokens_json):
            logging.info('tokens json file does not exist 😬')
            return None

        logging.info('tokens json file exists 😊')
        if not os.path.isfile(args.rules_python):
            logging.info('rules python file does not exist 😬')
            return None

        logging.info('rules python file exists 😊')
        if not os.path.isfile(args.haskell_ast):
            logging.info('haskell ast file does not exist 😬')
            return None

        logging.info('rules python file exists 😊')
        if not os.path.isfile(args.parsing_status):
            logging.info('parsing status file does not exist 😬')
            return None

        logging.info('parsing status file exists 😊')
        logging.info('finished checking validity of args: perfect 😊')
        return Argparse(
            tokens_json_filename=pathlib.Path(args.tokens_json),
            rules_python_filename=pathlib.Path(args.rules_python),
            haskell_ast_filename=pathlib.Path(args.haskell_ast),
            parsing_status_json_filename=pathlib.Path(args.parsing_status)
        )

def load_tokens(tokens_json_filename: str) -> str:
    with open(tokens_json_filename) as fl:
        tokens = json.load(fl)

    return tokens

def load_rules(rules_filename: str) -> str:
    with open(rules_filename) as fl:
        rules = fl.read()
    return rules

def load_haskell_ast(haskell_ast_filename: str) -> str:
    with open(haskell_ast_filename) as fl:
        rules = fl.read()
    return rules

def load_parse_status(parse_status_json_filename: str) -> str:
    with open(parse_status_json_filename) as fl:
        parse_status = json.load(fl)
    return parse_status

NUM_ITERATIONS = 1

def get_openai_api_key() -> typing.Optional[str]:
    return os.getenv('OPENAI_API_KEY')

def get_system_prompt_message() -> str:
    with open('system_prompt.txt') as fl:
        system_prompt = fl.read()

    return { 'role': 'system', 'content': system_prompt }

def get_user_prompt_message(tokens, rules, ast, parse_status) -> str:
    pass

def call_llm(tokens, rules, ast, parse_status) -> str:

    api_key = get_openai_api_key()
    if api_key is None: return None

    messages = [
        get_system_prompt_message(),
        get_user_prompt_message(tokens, rules, ast, parse_status)
    ]

    response = openai.ChatCompletion.create(
        model=MODEL,
        api_key=api_key,
        messages=messages
    )

    return response['choices'][0]['message']['content']

def main(args: Argparse) -> None:

    for i in range(NUM_ITERATIONS):

        tokens = load_tokens(args.tokens_json_filename)
        rules = load_rules(args.rules_python_filename)
        ast = load_haskell_ast(args.haskell_ast_filename)
        parse_status = load_parse_status(args.parsing_status_json_filename)

        feedback = "this is the first iteration"

        response = call_llm(tokens, rules, ast, parse_status, feedback)

        if response is None:
            logging.error('Invalid OpenAI token')
            return

        #rule = Rule.extract(response)
        #if not rule:
        #    feedback = invalid_rule_returned(response)
        
        #if not Parser.generated_fine_with_new(rule):
        #    feedback = invalid_parser_generated(rule)

        #improvement = Benchmark.check_improvement_with_new(rule)
        #if not improvement:
        #    feedback = no_improvement_was_achieved(improvement)

        # Yes ! improvement was achieved !
        #accept_suggested_improvement(rule)

def collect(workdir: str) -> None:

    files: list[str] = []
    filenames = glob.glob(f'{workdir}/**/*.php', recursive=True)
    for filename in filenames:
        if os.path.isfile(filename):
            files.append(filename)

    return files

NATIVE_PHP_PARSER_URL: typing.Final[str] = 'http://127.0.0.1:5000/to/php/ast'
DHSCANNER_PARSER_URL: typing.Final[str] = 'http://127.0.0.1:3000/from/php/to/dhscanner/ast'

def read_single_file(filename: str):

    with open(filename, 'r', encoding='utf-8') as fl:
        code = fl.read()

    return { 'source': (filename, code) }

def get_native_ast(filename: str) -> str:
    url = NATIVE_PHP_PARSER_URL
    one_file_at_a_time = read_single_file(filename)
    response = requests.post(url, files=one_file_at_a_time)
    return response.text

def get_dhscanner_status_for(filename: str, native_ast: str) -> dict:

    url = DHSCANNER_PARSER_URL
    content = { 'filename': filename, 'content': native_ast}
    response = requests.post(f'{url}?filename={filename}', json=content)
    return { 'filename': filename, 'status': response.text }

def generate_initial_parse_status(parsing_status_json_filename: str) -> None:

    filenames = collect('benchmark/php')
    status: dict[str, str]
    for filename in filenames:
        native_ast = get_native_ast(filename)
        parse_status = get_dhscanner_status_for(filename, native_ast)
        status[filename] = parse_status

    return status

def launch_services_successfully(docker_compose_yaml_filename: str) -> bool:

    try:
        result = subprocess.run(
            [
                'docker',
                'compose',
                '-f',
                docker_compose_yaml_filename,
                "up",
                "-d"
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        logging.info('docker containers started successfully 😊')
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        logging.info('docker containers failed to start 😬')
        print(e.stderr)
        return False

if __name__ == "__main__":

    if args := Argparse.run():

        if launch_services_successfully('compose.parsers.yaml'):
            generate_initial_parse_status(args.parsing_status_json_filename)
            main(args)
        
        # Arrrggghhhh ...
        logging.error('Failed to launch parsing dockers')
