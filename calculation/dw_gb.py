import os
import requests
from datetime import datetime, timedelta
import subprocess
from helper import parse_messages, write_to_file, create_folder
from settings import GRIB2_FILES_PATH

# move DATA_FOLDER to a settings file and import it here

start_loading_time = datetime.now()
available_template_header = """XXXXXX EMPTY LINES XXXXXXXXX
XXXXXX EMPTY LINES XXXXXXXX
YYYYMMDD HHMMSS      name of the file(up to 80 characters)
"""


def parse_available_file(date, hour, file_name):
  available_template_body = f"""{date.strftime('%Y%m%d')} {hour}0000      {file_name}      ON DISC\n"""
  write_to_file('', 'AVAILABLE', available_template_body, 'a')


def compress_grib_record(file_path, new_file_path):
    for start, end in [(1, 6), (9, 14), (75, 76), (83, 84), (95, 97), (101, 102), (104, 107), (111, 112), (114, 117), (121, 122), (124, 127), (131, 132), (134, 137), (141, 142), (144, 147), (151, 156), (163, 167), (171, 177), (181, 186), (193, 198), (202, 213), (217, 224), (226, 240), (242, 256), (258, 272), (274, 288), (290, 304), (306, 320), (322, 336), (338, 347), (349, 352), (354, 368), (370, 379), (381, 384), (386, 395), (397, 400), (402, 411), (413, 416), (418, 432), (434, 443), (445, 448), (450, 459), (461, 464), (466, 480), (482, 491), (493, 496), (498, 507), (509, 512), (514, 523), (525, 529), (531, 540), (542, 544), (546, 558), (561, 565), (567, 568), (570, 571), (573, 574), (577, 578), (580, 593), (598, 607), (613, 676), (679, 683), (685, 696)]:
        command = f"wgrib2 {file_path} -for_n {start}:{end} -grib >(cat >> {new_file_path}) > /dev/null 2>&1"
        process = subprocess.Popen(command, shell=True, executable="/bin/bash")
        process.communicate()
    parse_messages(f"File {file_path} updated successfully.\n")


def prepare_file(current_date, hour, file_name, file_compressed=True):
    full_file_path = os.path.join(GRIB2_FILES_PATH, file_name)
    new_name = file_name.split(".")[0] + "_.grib2"
    full_new_path = os.path.join(GRIB2_FILES_PATH, new_name)

    # check is file need to be compressed and compressed it if needed
    if current_date > datetime(2021, 3, 21, 6):
        if not os.path.isfile(full_new_path):
            compress_grib_record(
                full_file_path, full_new_path) if not file_compressed else None

        parse_available_file(current_date, hour, new_name)
    else:
        parse_available_file(current_date, hour, file_name)


def download_data(start, end):
    parse_messages('Started loading grid data.')

    if type(start) is not datetime:
        parse_messages("grib_error: Start Date is incorrect", True)
    elif type(end) is not datetime:
        parse_messages("grib_error: End Date is incorrect", True)
    elif (end - start).days > 61:
        parse_messages("grib_error: Difference between start and end dates should be less than 60 days", True)
    else:
        # dates should ends with hours that divides to 3
        if start.hour % 6 != 0:
            start_date = start - timedelta(hours = start.hour % 6)
        else:
            start_date = start - timedelta(hours = 6)

        if end.hour % 6 != 0:
            end_date = end + timedelta(hours = (end.hour % 6) + 6)
        else:
            end_date = end + timedelta(hours = 6)

    # remove from start_date and end_date minutes and seconds
    start_date = start_date.replace(minute=0, second=0, microsecond=0)
    end_date = end_date.replace(minute=0, second=0, microsecond=0)

    write_to_file('', 'AVAILABLE', available_template_header)

    # URL example: https://data.rda.ucar.edu/ds083.2/grib2/2022/2022.04/fnl_20220419_12_00.grib2
    url_template = "https://data.rda.ucar.edu/ds083.2/grib2/{year}/{year}.{month}/fnl_{date}_{hour}_00.grib2"
    # Create a directory to store the downloaded files
    create_folder(GRIB2_FILES_PATH)

    # Loop through the dates between start_date and end_date (inclusive)
    current_date = start_date
    while current_date <= end_date:
        # create correct hour value with leading zero
        hour = str(current_date.hour).zfill(2)
        # Generate the URL for the current date and hour
        url = url_template.format(year=current_date.year, month=current_date.strftime("%m"),
                                    date=current_date.strftime("%Y%m%d"), hour=hour)

        # Generate the output file name
        file_name = f"fnl_{current_date.strftime('%Y%m%d')}_{hour}_00.grib2"
        file_path = os.path.join(GRIB2_FILES_PATH, file_name)
        new_name = file_name.split(".")[0] + "_.grib2"
        new_path = os.path.join(GRIB2_FILES_PATH, new_name)
        # check if file already exists or already compressed
        if current_date > datetime(2021, 3, 21, 6) and os.path.isfile(new_path):
            parse_messages(
                f"File {new_path} already exists. Skipping download.")
            parse_available_file(current_date, hour, new_name)
            current_date += timedelta(hours=6)
            continue
        elif os.path.isfile(file_path):
            parse_messages(
                f"File {file_path} already exists. Skipping download.")
            prepare_file(current_date, hour, file_name, False)
            current_date += timedelta(hours=6)
            continue
        else:
            # Download the grib data and parse AVAILABLE file
            response = None
            try:
                parse_messages(f"Trying to download the file {file_path} ")
                response = requests.get(url)
            except Exception as ex:
                parse_messages(
                    f"grib_error: Problem with the connection to the URL {url}", True)
            else:
                if response.status_code == 200:
                    file = open(file_path, "wb")
                    try:
                        file.write(response.content)
                        parse_messages(f"File {file_path} downloaded successfully.\n")
                        prepare_file(current_date, hour, file_name, False)
                    finally:
                        file.close()
                else:
                    parse_messages(f"grib_error: Failed to download file {file_name} from {url}", True)

        # Move to the next date
        current_date += timedelta(hours=6)
    parse_messages(
        f"Finished loading grid data and filling AVAILABLE file, it took {datetime.now()-start_loading_time}.\n")
