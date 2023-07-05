#!/usr/bin/env python3

import os
from subprocess import run
import logging
import sys

logging.basicConfig(filename="/data/calculations_server.log", level=logging.INFO,
                    format="%(asctime)s %(message)s")

def parse_messages(msg, exit=False):

  if exit:
    logging.error(msg)

    file = open("/data/calculation_server.error", "a")
    file.write(msg)
    file.close()

    sys.exit(msg)
  else:
    logging.info(msg)
    rc = run("""echo \"{message}\" """.format(message=msg), shell=True)


def write_to_file(full_path, file_name, contents, mode='w'):

  file = open(full_path + file_name, mode)
  file.write(contents)
  file.close()
  logging.info(f'Parsing {file_name} file compleated.')


def create_folder(directory=None):

   if not os.path.exists(directory):
     os.makedirs(directory)
