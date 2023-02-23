#!/usr/bin/env python3

from datetime import datetime, timedelta
import logging, os
from subprocess import run
import sys
from urllib.request import urlopen
import shutil

# 2 month equal to 44 Gb / calc speed and time needed to downloads this data

# logging.basicConfig(filename="parsing.log", level=logging.INFO,
#                     format="%(asctime)s %(message)s")

HHMMSS = ['030000', '060000', '090000', '120000',
          '150000', '180000', '210000', '000000']
FILE_HOURS = ['0000', '0000', '0600', '0600', '1200', '1200', '1800', '1800']
FILE_SUFFIX = ['003', '006']
DATA_FOLDER = '/data/grib_data/'
start_loading_time = datetime.now()
available_template_header = """XXXXXX EMPTY LINES XXXXXXXXX
XXXXXX EMPTY LINES XXXXXXXX
YYYYMMDD HHMMSS      name of the file(up to 80 characters)
"""

def write_to_file(file_name, contents, mode='w'):
  basename = os.getcwd()
  file = open(basename + '/' + file_name, mode)
  file.write(contents)
  file.close()

def create_folder(directory=None):
   if not os.path.exists(directory):
     os.makedirs(directory)

def parse_available_file(date=None, file_name=None):
  # if date is not None and file_name is not None:
  available_template_body = """{yyyymmdd} {hhmmss}      {file_name}      ON DISC
""".format(yyyymmdd=date.strftime('%Y%m%d'),
          hhmmss=date.strftime('%H%M%S'),
          file_name=file_name)
  write_to_file('AVAILABLE', available_template_body, 'a')


def download_grib(date_start=None, date_end=None, angle='1.0'):  # degree = '0.5' or 1
  logging.info('Started loading grib data.')

  if type(date_start) is not datetime:
    sys.exit("Start Date is incorrect")
  elif type(date_end) is not datetime:
    sys.exit("End Date is incorrect")
  else:
    # dates should ends with hours that divides to 3
    start_date = date_start - timedelta(hours = date_start.hour % 3)
    end_date = date_end

    # download last dataset using end date
    if end_date.hour % 3 == 1:
      end_date = date_end + timedelta(hours=2)
    elif end_date.hour% 3 == 2:
      end_date = date_end + timedelta(hours=1)
    else:
      end_date = date_end + timedelta(hours=3)

    days, seconds = (
        end_date - start_date).days, (end_date - start_date).seconds
    hours = (days * 24 + seconds / 3600) // 8

    # print('amount of datasets: ',  hours)
    if hours <= 0:
      sys.exit('Error, invalid START or END date, between the date is no short interval')
      return

    create_folder(DATA_FOLDER)
    write_to_file('AVAILABLE', available_template_header)

    end_forecast_date = start_forecast_date = start_date

    if angle == '0.5':
      FILE_PREFIX = "gfs_4_"
      GRID = "grid-004-0.5-degree/"
    elif angle == '1.0':
      FILE_PREFIX = "gfs_3_"
      GRID = "grid-003-1.0-degree/"

    NCEI_URL = "https://www.ncei.noaa.gov/data/global-forecast-system/access/"
    FILE_SUFIX = ".grb2"

    if start_date < datetime(2017, 4, 5):
      FILE_SUFIX = ".grb"

    # build the link
    if start_date < datetime(2005, 1, 2) or start_date > (datetime.now() - timedelta(days=2)):
      sys.exit("Error can\'t find grib data for provided datetime.")
    elif start_date < datetime.now() - timedelta(days=1013): #1011
      # available from grib file from 2005/01/01 grib2 file from 2017/04/06 to 2020/05/15
      # FILE_PREFIX = "gfsanl_3_"
      TYPE_1 = "historical/"
      TYPE_2 = "forecast/" # or "analysis/" add GRID if you use forecast
      DOMAIN = NCEI_URL + TYPE_1 + TYPE_2 + GRID
    else:
      # available from 2020/05/15 to today -2 days
      TYPE_1 = "forecast/" # or "analysis/"
      DOMAIN = NCEI_URL + GRID + TYPE_1

    # test if file exist

    while(end_forecast_date < end_date):
      forecast_suffix = ''
      if end_forecast_date.hour % 6 == 0:
        # start_forecast_date - in Available
        start_forecast_date = end_forecast_date - timedelta(hours = 6)
        forecast_suffix = FILE_SUFFIX[1]
      elif end_forecast_date.hour % 6 == 3:
        start_forecast_date = end_forecast_date - timedelta(hours = 3)
        forecast_suffix = FILE_SUFFIX[0]
      file_name = FILE_PREFIX + \
          start_forecast_date.strftime(
              '%Y%m%d_%H%M_') + forecast_suffix + FILE_SUFIX
      path_to_file = os.path.join(DATA_FOLDER + '/', file_name)
      # test if file exist
      if os.path.isfile(path_to_file):
        print("File", file_name, "exist, skip loading.")
        parse_available_file(end_forecast_date, file_name)
        end_forecast_date = start_forecast_date = end_forecast_date + timedelta(hours=3)
        continue
      else:
        URL = DOMAIN + start_forecast_date.strftime('%Y%m/%Y%m%d/') + file_name
        print('File URL: ' + URL)
        # urllib.request.urlretrieve(URL, path_to_file)
        with urlopen(URL) as response, open(path_to_file, 'wb') as outfile:
          print('Loading file', file_name, 'with size', int(response.length/1024/1024), 'M from remote host.')
          if response.status == 200 and response.length > 10:
            shutil.copyfileobj(response, outfile)
          else:
            sys.exit('Error file not found!')

        message = 'File URL: ' + URL
        # rc = run("""echo \"{message}\" """.format(message=message), shell=True)
        parse_available_file(end_forecast_date, file_name)
      end_forecast_date = start_forecast_date = end_forecast_date + \
          timedelta(hours=3)


logging.info('Finished loading grib data and filling AVAILABLE file, it took ' +
             str(datetime.now()-start_loading_time)+'.\n')
