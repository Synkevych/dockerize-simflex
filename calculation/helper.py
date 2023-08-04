#!/usr/bin/env python3

import os
from subprocess import run
import logging
import sys
from settings import LOGS_PATH, COMPLETE_CALCULATION_FILE

logging.basicConfig(filename=LOGS_PATH, level=logging.INFO,
                    format="%(asctime)s %(message)s")

def parse_messages(msg, exit=False):
  run(f"""echo \"{msg}\" """, shell=True)

  if exit:
    logging.error(msg)

    # Optional write an error to a new file
    # file = open("/data/calculations_server.error", "a")
    # file.write(msg)
    # file.close()
    # create a file to indicate that the calculation is done
    open(COMPLETE_CALCULATION_FILE, 'a').close()

    sys.exit(msg)
  else:
    logging.info(msg)


def write_to_file(path, file_name, contents, mode='w'):
  file_path = os.path.join(path, file_name)

  file = open(file_path, mode)
  file.write(contents)
  file.close()
  logging.info(f'Parsing {file_name} file compleated.')


def create_folder(dir_name=None):
  os.makedirs(dir_name, exist_ok=True)
