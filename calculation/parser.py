#!/usr/bin/env python3

import os
import csv
import xml.etree.ElementTree as ET
from subprocess import run
from download_prognose import download_prognose
from datetime import datetime, timedelta
from helper import parse_messages, write_to_file, create_folder

basename = os.getcwd()
simflex_dir_path = basename + '/simflex_input/'
template_header = """***************************************************************************************************************
*                                                                                                             *
*   Input file for the Lagrangian particle dispersion model FLEXPART                                           *
*                        Please select your options                                                           *
*                                                                                                             *
***************************************************************************************************************
"""
options_file_path = '/data/input/options.xml'
measurements_file_path = '/data/input/measurements.txt'


def parse_datetime(date_string, time_string):
    return datetime.strptime(date_string + time_string, '%Y-%m-%d%H:%M:%S')

def get_xml_params(file=options_file_path):
  xml_tree = ET.parse(file)
  xml_root = xml_tree.getroot()
  start_date_time_str = xml_root.find('imin').text
  end_date_time_str = xml_root.find('imax').text
  start_date_time = datetime.strptime(start_date_time_str, '%Y-%m-%d %H:%M:%S')
  end_date_time = datetime.strptime(end_date_time_str, '%Y-%m-%d %H:%M:%S')
  nx = (xml_root.find('nx').text).split('.')[0]
  ny = (xml_root.find('ny').text).split('.')[0]
  loutstep = xml_root.find('loutstep').text if xml_root.find(
      'loutstep') is not None else '3600'
  min_height = xml_root.find('minheight').text if float(xml_root.find('minheight').text) > 1 else '1'
  return {
      'start_date_time': start_date_time,
      'end_date_time': end_date_time,
      'out_longitude': xml_root.find('se_lon').text,
      'out_latitude': xml_root.find('se_lat').text,
      'num_x_grid': nx,
      'num_y_grid': ny,
      'dx_out': xml_root.find('dlat').text,
      'dy_out': xml_root.find('dlon').text,
      'minheight': min_height,
      'maxheight': xml_root.find('maxheight').text,
      'loutstep': loutstep,
      'series_id': xml_root.find('id_series').text,
      'calc_id': xml_root.find('id_calc').text
  }


def parse_measurements(file=measurements_file_path):
  with open(file, newline='') as csvfile:
    csv_reader = csv.reader(csvfile, delimiter=';')
    csv_header = next(csv_reader)
    simflex_params = "#Use?;Id;Station_id;Lat;Lon;Start_date;Start_time;End_date;End_time;Mass;Sigma_or_ldl;Backgr\n"
    releases_params = []

    for row in csv_reader:
        # name of params in row and it's order:
        # calc_id(0), use(1), m_id(2), s_id(3), station(4), country(5), s_lat(6),s_lng(7),
        # id_nuclide(8), name_nuclide(9), date_start(10), time_start(11), date_end(12), time_end(13), val(14), sigma

        measurement_id = row[2]
        start_date_time = parse_datetime(row[10], row[11])
        end_date_time = parse_datetime(row[12], row[13])
        species_mass = float(row[14])

        # Adjust latitude and longitude values
        latitude_1 = float(row[6]) - 0.001
        latitude_2 = float(row[6]) + 0.001
        longitude_1 = float(row[7]) - 0.001
        longitude_2 = float(row[7]) + 0.001

        # Format species mass
        if species_mass <= 0:
          species_mass = 1.000000e+01

        simflex_params += ";".join([
          row[1], row[2], row[3], row[6], row[7],
          start_date_time.strftime('%d.%m.%Y;%H:%M:%S'),
          end_date_time.strftime('%d.%m.%Y;%H:%M:%S'),
          row[14], row[15], row[16]
        ]) + "\n"

        # Append data to the releases parameters
        releases_params.append({
            'id': measurement_id,
            'latitude_1': round(latitude_1, 3),
            'longitude_1': round(longitude_1, 3),
            'latitude_2': round(latitude_2, 3),
            'longitude_2': round(longitude_2, 3),
            'species_name': row[9],
            'start_date_time': start_date_time,
            'end_date_time': end_date_time,
            'mass': "{:e}".formats(species_mass),
            'comment': "RELEASE " + measurement_id
        })
    return simflex_params, releases_params

def parse_command_file(user_params):
  start_date_time = user_params['start_date_time']
  end_date_time = releases_params[-1]['end_date_time'] + timedelta(hours=1)
  command_body = f"""&COMMAND
 LDIRECT=              -1, ! Simulation direction in time   ; 1 (forward) or -1 (backward)
 IBDATE=         {start_date_time.strftime('%Y%m%d')}, ! Start date of the simulation   ; YYYYMMDD: YYYY=year, MM=month, DD=day
 IBTIME=           {start_date_time.strftime('%H%M%S')}, ! Start time of the simulation   ; HHMISS: HH=hours, MI=min, SS=sec; UTC
 IEDATE=         {end_date_time.strftime('%Y%m%d')}, ! End date of the simulation     ; same format as IBDATE
 IETIME=           {end_date_time.strftime('%H%M%S')}, ! End  time of the simulation    ; same format as IBTIME
 LOUTSTEP=        {user_params['loutstep']}, ! Interval of model output; average concentrations calculated every LOUTSTEP (s)
 LOUTAVER=        {user_params['loutstep']}, ! Interval of output averaging (s)
 LOUTSAMPLE=      {user_params['loutstep']}, ! Interval of output sampling  (s), higher stat. accuracy with shorter intervals
 ITSPLIT=        99999999, ! Interval of particle splitting (s)
 LSYNCTIME=            60, ! All processes are synchronized to this time interval (s)
 CTL=          -5.0000000, ! CTL>1, ABL time step = (Lagrangian timescale (TL))/CTL, uses LSYNCTIME if CTL<0
 IFINE=                 4, ! Reduction for time step in vertical transport, used only if CTL>1
 IOUT=                  9, ! Output type: [1]mass 2]pptv 3]1&2 4]plume 5]1&4, +8 for NetCDF output
 IPOUT=                 0, ! Particle position output: 0]no 1]every output 2]only at end 3]time averaged
 LSUBGRID=              1, ! Increase of ABL heights due to sub-grid scale orographic variations;[0]off 1]on
 LCONVECTION=           1, ! Switch for convection parameterization;0]off [1]on
 LAGESPECTRA=           0, ! Switch for calculation of age spectra (needs AGECLASSES);[0]off 1]on
 IPIN=                  0, ! Warm start from particle dump (needs previous partposit_end file); [0]no 1]yes
 IOUTPUTFOREACHRELEASE= 1, ! Separate output fields for each location in the RELEASE file; [0]no 1]yes
 IFLUX=                 0, ! Output of mass fluxes through output grid box boundaries
 MDOMAINFILL=           0, ! Switch for domain-filling, if limited-area particles generated at boundary
 IND_SOURCE=            1, ! Unit to be used at the source   ;  [1]mass 2]mass mixing ratio
 IND_RECEPTOR=          1, ! Unit to be used at the receptor; [1]mass 2]mass mixing ratio 3]wet depo. 4]dry depo.
 MQUASILAG=             0, ! Quasi-Lagrangian mode to track individual numbered particles
 NESTED_OUTPUT=         0, ! Output also for a nested domain
 LINIT_COND=            0, ! Output sensitivity to initial conditions (bkw mode only) [0]off 1]conc 2]mmr
 SURF_ONLY=             0, ! Output only for the lowest model layer, used w/ LINIT_COND=1 or 2
 CBLFLAG=               0, ! Skewed, not Gaussian turbulence in the convective ABL, need large CTL and IFINE
 OHFIELDS_PATH= "../../flexin/", ! Default path for OH file
 /
"""
  write_to_file(basename + '/options/', 'COMMAND', template_header + command_body)

def parse_outgrid_file(user_params):
  outgrid_template = f"""!*******************************************************************************
!                                                                              *
!      Input file for the Lagrangian particle dispersion model FLEXPART         *
!                       Please specify your output grid                        *
!                                                                              *
! OUTLON0    = GEOGRAPHYICAL LONGITUDE OF LOWER LEFT CORNER OF OUTPUT GRID     *
! OUTLAT0    = GEOGRAPHYICAL LATITUDE OF LOWER LEFT CORNER OF OUTPUT GRID      *
! NUMXGRID   = NUMBER OF GRID POINTS IN X DIRECTION (= No. of cells + 1)       *
! NUMYGRID   = NUMBER OF GRID POINTS IN Y DIRECTION (= No. of cells + 1)       *
! DXOUT      = GRID DISTANCE IN X DIRECTION                                    *
! DYOUN      = GRID DISTANCE IN Y DIRECTION                                    *
! OUTHEIGHTS = HEIGHT OF LEVELS (UPPER BOUNDARY)                               *
!*******************************************************************************
&OUTGRID
 OUTLON0=      {user_params['out_longitude']},
 OUTLAT0=     {user_params['out_latitude']},
 NUMXGRID=      {user_params['num_x_grid']},
 NUMYGRID=      {user_params['num_y_grid']},
 DXOUT=        {user_params['dx_out']},
 DYOUT=        {user_params['dy_out']},
 OUTHEIGHTS=   {user_params['maxheight']},
 /
"""
  write_to_file(basename + '/options/', 'OUTGRID', outgrid_template)


def parse_table_srs_file(id, file_path):
  filename = 'table_srs_paths.txt'
  file_header = """#obs_id;path_to_file;srs_id;\n"""
  file_content = f"""{id};{file_path};1\n"""

  if not os.path.isfile(simflex_dir_path + filename):
    write_to_file(simflex_dir_path, filename, file_header + file_content)
  else:
    write_to_file(simflex_dir_path, filename, file_content, 'a')


def parse_simflex_inputs(series_id, simflex_params, user_params):
  date_time = user_params['start_date_time']

  simflexinp_template = f"""$simflexinp
redirect_console=.true.,
Niso_=11,
Isolines_(1:11) = 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.99,
Threshprob_=0.9,
syear_={date_time:%Y},
smon_={date_time:%m},
sday_={date_time:%d},
shr_={date_time:%H},
sminut_={date_time:%M},
loutstep_={user_params['loutstep']}, ! 3600 default
tstart_max_=-9999.0,
thresh_start_=1.0,
min_duration_={user_params['loutstep']},
dlon_={user_params['dy_out']},
dlat_={user_params['dx_out']},
outlon_={user_params['out_longitude']}, ! 0. default
outlat_={user_params['out_latitude']},
nlon_={user_params['num_x_grid']},
nlat_={user_params['num_y_grid']},
nhgt_={user_params['minheight']}, ! 1 default
DHgt_={user_params['maxheight']},
series_id_={series_id}
$end
"""
  write_to_file(simflex_dir_path, 'simflexinp.nml', simflexinp_template)
  write_to_file(simflex_dir_path, 'measurem.csv', simflex_params)

def parse_releases_file(releases_params):
  SPECIES_BY_ID = {"O3": '002', "NO": '003', "NO2": '004',
                  "HNO3": '005', "HNO2": '006', "H2O2": '007',
                  "NO2": '008', "HCHO": '009', "PAN": '010',
                  "NH3": '011', "SO4-aero": '012', "NO3-aero": '013',
                  "I2-131": '014', "I-131": '015', "Cs-137": '016',
                  "Y-91": '017', "Ru-106": '018', "Kr-85": '019',
                  "Sr-90": '020', "Xe-133": '021', "CO": '022',
                  "SO2": '023', "AIRTRACER": '024', "AERO-TRACE": '025',
                  "CH4": '026', "C2H6": '027', "C3H8": '028',
                  "PCB28": '031', "G-HCH": '034', "BC": '040'}
  species_id = int(SPECIES_BY_ID.get(releases_params['species_name']))
  release_header = f"""&RELEASES_CTRL
 NSPEC      =           1, ! Total number of species
 SPECNUM_REL=          {species_id}, ! Species numbers in directory SPECIES
 /
"""

  release_body = f"""&RELEASE
 IDATE1  =     {releases_params['start_date_time'].strftime('%Y%m%d')},
 ITIME1  =       {releases_params['start_date_time'].strftime('%H%M%S')},
 IDATE2  =     {releases_params['end_date_time'].strftime('%Y%m%d')},
 ITIME2  =       {releases_params['end_date_time'].strftime('%H%M%S')},
 LON1    =        {releases_params['longitude_1']},
 LON2    =        {releases_params['longitude_2']},
 LAT1    =        {releases_params['latitude_1']},
 LAT2    =        {releases_params['latitude_2']},
 Z1      =           {user_params['minheight']},
 Z2      =           {user_params['maxheight']},
 ZKIND   =             1,
 MASS    =     {releases_params['mass']},
 PARTS   =        10000,
 COMMENT =  "{releases_params['comment']}",
 /
"""

  write_to_file(f"{basename}/options/", 'RELEASES', template_header +
                release_header + release_body)


def process_releases(releases_params, end_date, series_id):
  series_dirpath = f"/series/{series_id}"
  end_date_time_str = (end_date + timedelta(hours=1)).strftime('%Y%m%d%H%M%S')
  output_filename_prefix = f"grid_time_{end_date_time_str}"

  # Create output folder for FLEXPART calculation
  create_folder('output')
  # Create output folder for series
  create_folder(series_dirpath)

  for param in releases_params:
    id = param['id']
    nuclide_name = param['species_name']
    default_flexpart_file_path = f"{basename}/output/{output_filename_prefix}.nc"
    new_flexpart_file_path = f"{series_dirpath}/{nuclide_name}/{output_filename_prefix}_{id}.nc"

    create_folder(f"/data/output/{nuclide_name}")
    create_folder(f"{series_dirpath}/{nuclide_name}")

    if not os.path.isfile(new_flexpart_file_path):
      parse_releases_file(param)
      parse_messages(
          f'FLEXPART running {id} of {len(releases_params)} releases.')
      rc = run("FLEXPART_MPI", shell=True)

      if os.path.isfile(default_flexpart_file_path):
        os.popen(
            f"cp {default_flexpart_file_path} {new_flexpart_file_path}")
        parse_table_srs_file(id, new_flexpart_file_path)
        parse_messages(
            f"FLEXPART completed the calculation of {id} release.")
      else:
        message = f"Calculation didn't complete successfully for {id} release, check the output/input params."
        parse_messages(message, True)
    else:
        parse_table_srs_file(id, new_flexpart_file_path)
        parse_messages(
            f'Skip calculation, output file for {id} release exist.')


def run_simflex_calculation(calc_id, series_id):
    start_simflex_time = datetime.now()
    parse_messages("Starting simflex calculation.")
    rc = run("simflex", shell=True)
    parse_messages(
        f"SIMFLEX finished calculation {calc_id} for series {series_id}, it took {datetime.now()-start_simflex_time}.\n")

# Main function
if __name__ == '__main__':
  user_params = get_xml_params()
  simflex_params, releases_params = parse_measurements()
  calc_id = user_params['calc_id']
  series_id = user_params['series_id']
  last_release_end_date = releases_params[-1]['end_date_time']
  parse_messages(f'Calculation {calc_id} for series {series_id} started.')
  start_calc_time = datetime.now()

  # First date from user last is the last release date + 1 hour
  ### ToDo: do not download prognose if calculation is already done for this series
  download_prognose(user_params['start_date_time'], last_release_end_date)

  parse_command_file(user_params)
  parse_outgrid_file(user_params)

  create_folder(simflex_dir_path)
  parse_simflex_inputs(series_id, simflex_params, user_params)

  process_releases(releases_params,
                   last_release_end_date, series_id)
  parse_messages(
      f"FLEXPART finished all calculations, it took {datetime.now()-start_calc_time}.\n")

  run_simflex_calculation(calc_id, series_id)
  parse_messages(f'All calculation took {datetime.now()-start_calc_time}')
