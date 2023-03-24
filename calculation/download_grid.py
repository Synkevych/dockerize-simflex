#!/usr/bin/env python3

from datetime import datetime, timedelta
import os
from urllib.request import urlopen
import shutil
from helper import parse_messages, write_to_file, create_folder

# 2 month equal to 44 Gb / calc speed and time needed to downloads this data


HHMMSS = ['030000', '060000', '090000', '120000',
          '150000', '180000', '210000', '000000']
FILE_HOURS = ['0000', '0000', '0600', '0600', '1200', '1200', '1800', '1800']
FILE_SUFFIX = ['003', '006']
DATA_FOLDER = 'grid_data/'
start_loading_time = datetime.now()
available_template_header = """XXXXXX EMPTY LINES XXXXXXXXX
XXXXXX EMPTY LINES XXXXXXXX
YYYYMMDD HHMMSS      name of the file(up to 80 characters)
"""

def parse_available_file(date=None, file_name=None):
  available_template_body = """{yyyymmdd} {hhmmss}      {file_name}      ON DISC
""".format(yyyymmdd=date.strftime('%Y%m%d'),
          hhmmss=date.strftime('%H%M%S'),
          file_name=file_name)
  write_to_file('','AVAILABLE', available_template_body, 'a')

# dry the function and make ability to provide different degrre or type if fine is not found
def download_grid(date_start=None, date_end=None, grid_degree='1.0', grid_type="analysis"):  # '0.5' or 1.0
  parse_messages('Started loading grid data.')

  if type(date_start) is not datetime:
    parse_messages("Start Date is incorrect",True)
  elif type(date_end) is not datetime:
   parse_messages("End Date is incorrect",True)
  else:
    # dates should ends with hours that divides to 3
    start_date = date_start - timedelta(hours = date_start.hour % 3)
    end_date = date_end + timedelta(hours=3)

    # end date must be divisible by three
    if end_date.hour % 3 == 1:
      end_date = date_end + timedelta(hours=2)
    elif end_date.hour% 3 == 2:
      end_date = date_end + timedelta(hours=1)
    else:
      end_date = date_end + timedelta(hours=3)

    # days, seconds = (
    #     end_date - start_date).days, (end_date - start_date).seconds
    # hours = (days * 24 + seconds / 3600) // 8

    create_folder(DATA_FOLDER)
    write_to_file('', 'AVAILABLE', available_template_header)

    end_forecast_date = start_forecast_date = start_date

    NCEI_URL = "https://www.ncei.noaa.gov/data/global-forecast-system/access/"
    FILE_TYPE = ".grb2"
    PREFIX_BY_DEGREE = {'0.5': '4', '1.0': '3'}
    GRID = "grid-00" + \
        PREFIX_BY_DEGREE[grid_degree] + '-' + grid_degree + "-degree/"

    if start_date < datetime(2005, 1, 2) or start_date > (datetime.now() - timedelta(days=2)):
      parse_messages("Error, grid data is not exist for provided datetime.", True)
      return
    elif start_date < datetime.now() - timedelta(days=1013):
      # historical available from 2019/08/01 - 2020/05/01-15
      if grid_type == "forecast":
      # from 2019/05/16-31 - 2020/05/01-15
        DOMAIN = NCEI_URL + "historical/forecast/" + GRID
      elif grid_type == "analysis":
        # from 2004/03/01 - 2020/05/01-15
        FILE_PREFIX = "gfsanl_" + PREFIX_BY_DEGREE[grid_degree] + "_"
        DOMAIN = NCEI_URL + "historical/analysis/"

      if start_date < datetime(2017, 4, 5):
        FILE_TYPE = ".grb"
    else:
      FILE_PREFIX = "gfs_" + PREFIX_BY_DEGREE[grid_degree] + "_"
      DOMAIN = NCEI_URL + GRID + grid_type + '/'

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
              '%Y%m%d_%H%M_') + forecast_suffix + FILE_TYPE
      path_to_file = os.path.join(DATA_FOLDER, file_name)

      URL = DOMAIN + start_forecast_date.strftime('%Y%m/%Y%m%d/') + file_name
      parse_messages('File URL: ' + URL)
      response = None
      try:
        response = urlopen(URL)
      except Exception as ex:
        parse_messages('Error, while loading file ' + file_name + ' ' + str(ex))
      else:
        if os.path.isfile(path_to_file) and os.stat(path_to_file).st_size == response.length:
          parse_messages("File "+file_name+" " +str(int(os.stat(path_to_file).st_size/1024/1024))+"M exist, skip loading.\n")
          parse_available_file(end_forecast_date, file_name)
          end_forecast_date = start_forecast_date = end_forecast_date + \
              timedelta(hours=3)
          continue
        else:
          if response.status == 200 and response.length > 1024:
              parse_messages('Loading file ' + file_name + ' with size ' + str(int(
                  response.length/1024/1024))+'M from remote host.')
              outfile = open(path_to_file, 'wb')
              try:
                  shutil.copyfileobj(response, outfile)
                  parse_available_file(end_forecast_date, file_name)
                  parse_messages('File ' + file_name + ' uploaded successfully.\n')
              finally:
                  outfile.close()
          else:
             parse_messages('Error, while loading file ' + file_name + ' file name or url is not correct.\n')
      finally:
        if response is not None:
            response.close()
      end_forecast_date = start_forecast_date = end_forecast_date + \
          timedelta(hours=3)

  parse_messages('Finished loading grid data and filling AVAILABLE file, it took ' +
             str(datetime.now()-start_loading_time)+'.\n')
