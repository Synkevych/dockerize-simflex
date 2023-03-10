#!/usr/bin/env python3

import os
import sys
import logging
import csv
import xml.etree.ElementTree as ET
from subprocess import run
from download_grib import *
from datetime import datetime, timedelta

logging.basicConfig(filename="parsing.log", level=logging.INFO,
                    format="%(asctime)s %(message)s")

basename = os.getcwd()
simflex_input_path = '/simflex_input/'
template_header = """***************************************************************************************************************
*                                                                                                             *
*   Input file for the Lagrangian particle dispersion model FLEXPART                                           *
*                        Please select your options                                                           *
*                                                                                                             *
***************************************************************************************************************
"""
user_params = {}
releases_params = []
measurem_csv_params = "#Use?;Id;Station_id;Lat;Lon;Start_date;Start_time;End_date;End_time;Mass;Sigma_or_ldl;Backgr\n"

if not os.path.exists(basename + simflex_input_path):
  os.makedirs(basename + simflex_input_path)

if not os.path.exists('output'):
    os.makedirs('output')

def parse_messages(message, exit=False):
  message = message + "\n"

  if exit:
    logging.error(message)
    sys.exit(message)
  else:
    logging.info(message)
    rc = run("""echo \"{message}\" """.format(message=message), shell=True)

def write_to_file(folder_name, file_name, contents, mode='w'):
  full_file_path = basename + folder_name + file_name

  file = open(full_file_path, mode)
  file.write(contents)
  file.close()
  logging.info('Parsing {0} file compleated.'.format(file_name))

def get_xml_params():
  xml_tree = ET.parse(os.path.basename(basename) + '.xml')
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
      'loutstep': loutstep
  }

with open(os.path.basename(basename) + '.txt', newline='') as csvfile:
  csv_reader = csv.reader(csvfile, delimiter='\t')
  csv_header = next(csv_reader)
  for row in csv_reader:
      # name of params in row and it's order:
      # calc_id(0), use(1), m_id(2), s_id(3), station(4), country(5), s_lat(6),s_lng(7),
      # id_nuclide(8), name_nuclide(9), date_start(10), time_start(11), date_end(12), time_end(13), val(14), sigma

      measurement_id = row[2]
      latitude_1 = float(row[6]) - 0.001
      latitude_2 = float(row[6]) + 0.001
      longitude_1 = float(row[7]) - 0.001
      longitude_2 = float(row[7]) + 0.001
      start_date_time = datetime.strptime(
          row[10] + row[11], '%Y-%m-%d%H:%M:%S')
      end_date_time = datetime.strptime(
          row[12] + row[13], '%Y-%m-%d%H:%M:%S')
      species_mass = "{:e}".format(float(row[14]))

      if float(row[14]) <= 0:
        species_mass = 1.000000e+01

      measurem_csv_params += ";".join([row[1], row[2], row[3], row[6], row[7],
                         start_date_time.strftime('%d.%m.%Y;%H:%M:%S'),
                         end_date_time.strftime('%d.%m.%Y;%H:%M:%S'),
                         row[14], row[15], row[16]]) + "\n"

      releases_params.append({
          'id': measurement_id,
          'latitude_1': round(latitude_1,3),
          'longitude_1': round(longitude_1,3),
          'latitude_2': round(latitude_2, 3),
          'longitude_2': round(longitude_2, 3),
          'species_name': row[9],
          'start_date_time': start_date_time,
          'end_date_time': end_date_time,
          'mass': species_mass,
          'comment': "RELEASE " + measurement_id
      })

def parse_command_file():
  start_date_time = user_params['start_date_time']
  end_date_time = releases_params[-1]['end_date_time'] + timedelta(hours=1)
  command_body = """&COMMAND
 LDIRECT=              -1, ! Simulation direction in time   ; 1 (forward) or -1 (backward)
 IBDATE=         {date_1}, ! Start date of the simulation   ; YYYYMMDD: YYYY=year, MM=month, DD=day
 IBTIME=           {time_1}, ! Start time of the simulation   ; HHMISS: HH=hours, MI=min, SS=sec; UTC
 IEDATE=         {date_2}, ! End date of the simulation     ; same format as IBDATE
 IETIME=           {time_2}, ! End  time of the simulation    ; same format as IBTIME
 LOUTSTEP=        {loutstep}, ! Interval of model output; average concentrations calculated every LOUTSTEP (s)
 LOUTAVER=        {loutstep}, ! Interval of output averaging (s)
 LOUTSAMPLE=      {loutstep}, ! Interval of output sampling  (s), higher stat. accuracy with shorter intervals
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
""".format(date_1=start_date_time.strftime('%Y%m%d'),
           time_1=start_date_time.strftime('%H%M%S'),
           date_2=end_date_time.strftime('%Y%m%d'),
           time_2=end_date_time.strftime('%H%M%S'),
           loutstep=user_params['loutstep'])
  write_to_file('/options/', 'COMMAND', template_header + command_body)

def parse_outgrid_file():
  outgrid_template = """!*******************************************************************************
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
 OUTLON0=      {out_lon},
 OUTLAT0=     {out_lat},
 NUMXGRID=      {x_grid},
 NUMYGRID=      {y_grid},
 DXOUT=        {dx_out},
 DYOUT=        {dy_out},
 OUTHEIGHTS=   {maxheight},
 /
""".format(out_lon=user_params['out_longitude'],
          out_lat=user_params['out_latitude'],
          x_grid=user_params['num_x_grid'],
          y_grid=user_params['num_y_grid'],
          dx_out=user_params['dx_out'],
          dy_out=user_params['dy_out'],
          maxheight=user_params['maxheight'])
  write_to_file('/options/', 'OUTGRID', outgrid_template)


def parse_simflex_input_paths(id, file_path):
  filename = 'table_srs_paths.txt'
  file_header = """#obs_id;path_to_file;srs_id;
"""
  file_content = """{obs_id};{path_to_file};{srs_id}
""".format(obs_id=id, path_to_file=file_path, srs_id=1)

  if not os.path.isfile(basename + simflex_input_path + filename):
    write_to_file(simflex_input_path, filename, file_header + file_content)
  else:
    write_to_file(simflex_input_path, filename, file_content, 'a')

def parse_simflex_inputs():
  start_date_time = user_params['start_date_time']
  simflexinp_template = """$simflexinp
redirect_console=.false.,
Niso_=11,
Isolines_(1:11) = 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.99,
Threshprob_=0.9,
syear_={start_year},
smon_={start_month},
sday_={start_day},
shr_={start_hour},
sminut_={start_min},
loutstep_={loutstep}, ! 3600 default
tstart_max_=-9999.0,
thresh_start_=1.0,
min_duration_={loutstep},
dlon_={dlon},
dlat_={dlat},
outlon_={se_lon}, ! 0. default
outlat_={se_lat},
nlon_={nx},
nlat_={ny},
nhgt_={minheight}, ! 1 default
DHgt_={maxheight}
$end
""".format(start_year=start_date_time.strftime('%Y'),
          start_month=start_date_time.strftime('%m'),
          start_day=start_date_time.strftime('%d'),
          start_hour=start_date_time.strftime('%H'),
          start_min=start_date_time.strftime('%M'),
          loutstep=user_params['loutstep'],
          dlon=user_params['dy_out'],
          dlat=user_params['dx_out'],
          se_lon=user_params['out_longitude'],
          se_lat=user_params['out_latitude'],
          nx=user_params['num_x_grid'],
          ny=user_params['num_y_grid'],
          minheight=user_params['minheight'],
          maxheight=user_params['maxheight'])
  write_to_file(simflex_input_path, 'simflexinp.nml', simflexinp_template)
  write_to_file(simflex_input_path, 'measurem.csv', measurem_csv_params)

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
  release_header = """&RELEASES_CTRL
 NSPEC      =           1, ! Total number of species
 SPECNUM_REL=          {species_number}, ! Species numbers in directory SPECIES
 /
""".format(species_number=species_id)

  release_body = """&RELEASE
 IDATE1  =     {date_1},
 ITIME1  =       {time_1},
 IDATE2  =     {date_2},
 ITIME2  =       {time_2},
 LON1    =        {lon_1},
 LON2    =        {lon_2},
 LAT1    =        {lat_1},
 LAT2    =        {lat_2},
 Z1      =           {minheight},
 Z2      =           {maxheight},
 ZKIND   =             1,
 MASS    =     {mass},
 PARTS   =        10000,
 COMMENT =  "{comment}",
 /
""".format(date_1=releases_params['start_date_time'].strftime('%Y%m%d'),
             time_1=releases_params['start_date_time'].strftime('%H%M%S'),
             date_2=releases_params['end_date_time'].strftime('%Y%m%d'),
             time_2=releases_params['end_date_time'].strftime('%H%M%S'),
             lon_1=releases_params['longitude_1'],
             lon_2=releases_params['longitude_2'],
             lat_1=releases_params['latitude_1'],
             lat_2=releases_params['latitude_2'],
             mass=releases_params['mass'],
             comment=releases_params['comment'],
             minheight=user_params['minheight'],
             maxheight=user_params['maxheight'])

  write_to_file('/options/', 'RELEASES', template_header +
                release_header + release_body)

user_params = get_xml_params()

# First date from user last is the last release date + 1 hour
download_grib(user_params['start_date_time'], releases_params[-1]['end_date_time'])

parse_command_file()
parse_outgrid_file()
parse_simflex_inputs()

end_date_time_str = (
    releases_params[-1]['end_date_time'] + timedelta(hours=1)).strftime('%Y%m%d%H%M%S')
output_filename_prefix = 'grid_time_' + end_date_time_str
start_calc_time = datetime.now()

for param in releases_params:
  # move output prognose to simflex folder and rename it according to the release id
  id = param['id']
  old_output_file_path = basename + '/output/' + output_filename_prefix + '.nc'
  new_output_file_path = basename + simflex_input_path + \
      output_filename_prefix + '_' + id + '.nc'

  # skip calculation if output file exist
  if not os.path.isfile(new_output_file_path):
    parse_releases_file(param)
    message = 'FLEXPART running {i} of {j} releases.'.format(
        i=id, j=len(releases_params))
    parse_messages(message)
    rc = run("time FLEXPART_MPI", shell=True)

    if os.path.isfile(old_output_file_path):
      os.rename(old_output_file_path,  new_output_file_path)
      parse_simflex_input_paths(id, new_output_file_path)
      parse_messages(
          "FLEXPART completed the calculation of {i} release.".format(i=id))
      # for test purpose only, should be removed
      os.rename(basename + '/output/',  basename + '/output_' + id)
      os.makedirs('output')
    else:
      message = "Calculation didn\'t complete successful for {0} release, check the outputs or input parameters.".format(
          id)
      parse_messages(message, True)
  else:
    parse_messages('Skip calculation, output file for {0} release exist.'.format(id))
    continue

messages = 'FLEXPART finished all calculations, it took '+str(datetime.now()-start_calc_time)+".\n"

start_simflex_time = datetime.now()
messages +=  "Starting simflex calculation.\n"
rc = run("simflex", shell=True)

messages += 'SIMFLEX finished calculation, it took '+str(datetime.now()-start_simflex_time)+".\n"
messages += 'All calculation took ' + \
    str(datetime.now()-start_calc_time)
parse_messages(messages)
