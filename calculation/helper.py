#!/usr/bin/env python3

import os
from subprocess import run
import logging
import sys
from settings import LOGS_PATH

logging.basicConfig(filename=LOGS_PATH, level=logging.INFO,
                    format="%(asctime)s %(message)s")

def parse_messages(msg, exit=False):
  rc = run("""echo \"{message}\" """.format(message=msg), shell=True)

  if exit:
    logging.error(msg)

    # Optional write an error to a new file
    # file = open("/data/calculations_server.error", "a")
    # file.write(msg)
    # file.close()
    # create a file to indicate that the calculation is done
    open('/data/done.txt', 'a').close()

    sys.exit(msg)
  else:
    logging.info(msg)


def write_to_file(full_path, file_name, contents, mode='w'):

  file = open(full_path + file_name, mode)
  file.write(contents)
  file.close()
  logging.info(f'Parsing {file_name} file compleated.')


def create_folder(directory=None):
  os.makedirs(directory, exist_ok=True)
