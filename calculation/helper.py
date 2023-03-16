#!/usr/bin/env python3

import os
from subprocess import run
import logging
import sys

logging.basicConfig(filename="parsing.log", level=logging.INFO,
                    format="%(asctime)s %(message)s")

def parse_messages(msg, exit=False):

  if exit:
    logging.error(msg)
    sys.exit(msg)
  else:
    logging.info(msg)
    rc = run("""echo \"{message}\" """.format(message=msg), shell=True)


def write_to_file(full_path, file_name, contents, mode='w'):

  file = open(full_path + file_name, mode)
  file.write(contents)
  file.close()
  # for test purpose only could be removed
  logging.info('Parsing {0} file compleated.'.format(file_name))


def create_folder(directory=None):

   if not os.path.exists(directory):
     os.makedirs(directory)
