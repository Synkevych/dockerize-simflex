! This module contains main arrays use to solve inverse problem based on flexpart
! backward runs
      Module SIMFLEX
      implicit none
      include 'types.fi'
      
      integer,parameter::MAXOBS=10001
      integer locobsid(MAXOBS)
      logical,parameter::ifdebug_out=.TRUE.
      
      character(15),parameter::output_dirname="simflex_output/"
      character(14),parameter::input_dirname="simflex_input/"

      character(1024),parameter::normcorname='normcor.dat'
      character(1024),parameter::timesmassname='times_mass.dat'
      character(1024),parameter::gridname='grid.dat'
      
      character(1024),parameter::normcor_debug='normcor_debug.dat'
      character(1024),parameter::timesmass_debug='times_mass_debug.dat'
      
!USER INPUTS      
!Date-time parameters of the simulation run
      integer syear,smon,sday,shr,sminut ! start year,month,day,hour (minutes/seconds are zero)  
       integer loutstep ! abs value of time step in seconds of output in flexpart files; to be provided by user and consistent with available flexpart files
        real Threshprob ! threschold probability: times of release and mass are calculated only within region of probability of source location > Threschprob
         real min_duration ! minimum duration of release in seconds; input by user
         real tstart_max ! maximum time start in hours from the start of minimization run; if tstart_max<0 then it will be calculated from 'time of arrival'
         real thresh_start ! factor determining of how much background is to be exceeded to define tstart_max; used only when tstart_max provided by user <0
         real dlon,dlat ! size steps of output data in flexpart (dxout, dyout)\
         real outlon0,outlat0 ! coordinates of south-west (lower left)
corner of the grid
         integer nlon,nlat,nhgt ! sizes of flexpart grid; to be consistent with respective fields in flexpart files
         real DHgt ! depth of FLEXPART output vertical layer; to be consistent with respective values in flexpart files
         

! Measurements section:
      integer Nobs ! number of observations used in source inversion
      
! Sizes of all the arrays up to End_Nobs mark are Nobs:
       integer,allocatable::id_obs(:),Station_id(:) ! respective obs id-s and station id-s; size=Nobs
!       character(50),allocatable::St_name(:),St_country(:) ! station name and country (given for each obs)
       real,allocatable::Obs_lon(:),Obs_lat(:),
     &                   Obs_val(:),Obs_val1(:),! Obs_val is observed concentration in air (Bq/m3), Obs_val1 = observed-background
     &                   Obs_sig(:), !Obs_sig is meas. error for non-zero measurements and Lower Detection Limit for zeros
     &                   Obs_bckgr(:) ! Background concentration at the respective station(Bq/m3), provided for all observed values
       character(10),allocatable::Obs_datestart(:),Obs_dateend(:) !dd.mm.yyyy of start and end days of the respective observation
       character(10),allocatable::Obs_utctstart(:),Obs_utctend(:) !HH:MM:SS of the respective start and end times of observation
       real,allocatable::Obs_tstart(:),Obs_tend(:) ! start and end times of obs in hours from start date_time of simulation represented by year,smon,sday,shr,sminut

! End_Nobs       
      
! Section of grid paremeters and srs-s from flexpart backward runs:
!       integer nlon,nlat,nhgt ! sizes of flexpart grid
       integer ntmax ! maximum number of time layers in flexpart files
       
       real,allocatable::lon(:),lat(:)  !size(lon)=nlon,size(lat)=nlat
       integer,allocatable::gridcells(:,:),cell_ilon(:),cell_jlat(:) !array sizes:nlon*nlat; id-s of grid cells
       
       Type(SrcRecptFun),allocatable::AllSRS(:) ! size Nobs - srs-s read from flexpart files for observations to be used in calculation
       
       
       character(1024),allocatable::srsfiles(:) ! paths to srs files;!NO SPACES!
       integer Nobs_all !number of srs files and number of all obs (both used and not used in source inversion)
       integer,allocatable::id_obs_all(:) ! size Nobs_all: id-s of observations represented by srsfiles ;size=Nfiles
       integer,allocatable::srs_ind_all(:) !size Nobs_all: index of 5-th dimension of array in srs file corresponding to respective measurement
       real,allocatable::cmod(:)

! Subgrid parameters for the part of grid where masses of release, start times and durations will be calculated
        real iso1 ! isoline of normcorcoef respective to Threschprob
        integer Nselect ! number of selected grid nodes to store full time-variable srs
        integer,allocatable::ind_select(:,:) !size nlon x nlat , equals index (from 1 to Nselect) of node it it is selected or 0
        integer,allocatable::grid_select(:) !size - Nselect, contains id-s of grid cells where masses of release will be calculated
        integer,allocatable::i_select(:),j_select(:) ! i and j indices of selected nodes; i - for lon, j - for lat
        
!Section of intermediate results relevant to start time
         integer Indback_tsmax !is maximum index from start of minimization run (and the same - end of srs backward run)
         integer ndur_min ! number of time steps representing minimum time duration; should be floor(min_duration/loutstep)+1 - nearest upper integer
         integer maxtsrcind ! maximum time index for simulation of release duration

         integer,allocatable::n_dur_sol(:),indback_ts_sol(:) ! size- Nselect indices for solution of release duration and release start index calculated from the start time of minimization run (end time of srs run)
         
! representing maximum start time of release        

! Results section
        real MaxCor0 !maximum correlation coefficient obtained assuming constant release
        integer Imax0,Jmax0 ! node in which MaxCor0 is reached

        real,allocatable::normcor0(:,:) !size: nlon x nlat; normalized corr. coef
        ! as function of grid node, obtained assuming constant release
        
        integer Niso ! number of Isolines of ncorr0 within which probabilities of source location to be calculated
        real,allocatable::Isolines(:) ! size: Niso; entered user through input file
        real,allocatable::Prob_iso(:) ! size: Niso; probability of source location within respective Isoline

         real,allocatable::Jmax_sol(:),start_time(:),duration(:),Mass(:) ! size - Nselect maximum corr. coeff., start time  from the start of release and duration in hours, Mass of release in Bq (if input con where in Bq/m3)
         integer Isolut ! index of selected subgrid where maximum cor. coef with respect to time is reached

!       real,allocatable::Arr(:,:,:,:) !temporary

        contains
        
        subroutine def_tstartmax
        implicit none
        integer i
        real tendhrs
        
        write(6,*)'From def_tstart: evaluating maximum start time'
        write(6,*)'of release'
        if(tstart_max.ge.0)then
           Indback_tsmax=int(tstart_max*3600/real(loutstep))+1
           return ! this subroutine is used only when tstart_max is not provided by user (i.e. <0)
        endif
        
        if(thresh_start.lt.0)then
           write(6,*)'Error from def_tstart: when tstart_max'
           write(6,*)'provided by user is <=0 then thresh_start'
           write(6,*)'should be >=0, while presently'
           write(6,*)'thresh_start=',thresh_start
           stop
        endif
        
        tstart_max=1E14
        do i=1,Nobs ! select observation that exceeds threschold and has minimum end time that is set to tstart_max
          if(Obs_val1(i).gt.thresh_start*Obs_bckgr(i))then
              tendhrs=Obs_tend(i)*24.0 ! convert days to hours
             if(tendhrs.lt.tstart_max)then
               tstart_max=tendhrs
             endif
          endif
        enddo
        
        if(tstart_max.eq.1E14)then
          write(6,*)'Error from def_tstart: no measurements'
          write(6,*)'found, exceeding background by given threschold'
          write(6,*)'thresh_start=(obs-bckgr)/bckgr=',thresh_start
          write(6,*)'no release is assumed'
          stop
        endif
        
        
        
        Indback_tsmax=int(tstart_max*3600/real(loutstep))+1 ! time index representing tstart_max
        write(6,*)'tstart_max=',tstart_max,'hrs'
        write(6,*)'Indback_tsmax=',Indback_tsmax
        
        
        end subroutine def_tstartmax
        
        subroutine def_ndur_min
        implicit none
! defines ndur_min by using input from user parameter minduration and loutstep
        ndur_min=max(nint(min_duration/real(loutstep)),1)
           
        write(6,*)'From def_ndur_min: number of time steps '
         write(6,*)'representing minimum release duration is ndur_min=',
     &              ndur_min
        end subroutine def_ndur_min
        
        subroutine def_maxtsrcind ! defines maximum index for release duration based on maximum end time of observation
! note that if later appears that maxtsrcind > ntmax (even though this should not happen) then maxtsrcind=ntmax        
        implicit none
        integer i
        real tcur
        write(6,*)'From def_maxtsrcind: defining maximum time index for'
          write(6,*)'for simulation, based Nobs=',Nobs,'observations'
          write(6,*)'loutstep=',loutstep
          write(6,*)'maxt=',maxval(Obs_tend),'days'
          
          maxtsrcind=int(maxval(Obs_tend)*86400./real(loutstep))
          
          write(6,*)'maxtsrcind=',maxtsrcind
          write(6,*)' '
          
        end subroutine def_maxtsrcind
        
        subroutine Obs_Correct
        implicit none
        integer i
        
        write(6,*)'From Obs_Correct:'
       write(6,*)'Subtracting background from measurements'
       write(6,*)' '        
       
        if(allocated(Obs_val).and.allocated(Obs_bckgr))then
          if(size(Obs_val).eq.Nobs.and.size(Obs_bckgr).eq.Nobs)then
          else
            write(6,*)'Error from Obs_Correct: sizes of arrys are'
            write(6,*)'incompatible: size(Obs_val)=',size(Obs_val)
            write(6,*)'incompatible: size(Obs_bckgr)=',size(Obs_bckgr)
            write(6,*)'incompatible: Nobs=',Nobs
            stop
          endif
          allocate(Obs_val1(Nobs))
          Obs_val1=Obs_val-Obs_bckgr
          do i=1,Nobs
             if(Obs_val1(i).lt.0)Obs_val1(i)=0.
          enddo
        else
          write(6,*)'Error from Obs_Correct, arrays Obs_val'
          write(6,*)'or not Obs_bckgr not allocated'
          stop
        endif
         continue
        end subroutine Obs_Correct
        
        subroutine create_grid
        implicit none
        integer i,j,k
        
         write(6,*)'From create_grid:'
        write(6,*)'defining grid '
        write(6,*)' '

        if(.not.allocated(lon).or..not.allocated(lat))then
          write(6,*)'Error from create_grid: lon and lat not yet ready'
          stop
        endif
        if(size(lon,1).ne.nlon.or.size(lat,1).ne.nlat)then
           write(6,*)'Error from create_grid: size of lon=',size(lon,1)
           write(6,*)'or size of lat=',size(lat,1)
           write(6,*)'are incompatible with nlon=',nlon
           write(6,*)'or nlat=',nlat
           stop
        endif
        allocate(gridcells(nlon,nlat))
        allocate(cell_ilon(nlon*nlat))
        allocate(cell_jlat(nlon*nlat))

        CALL system("mkdir -p "//output_dirname)

        open(1024,FILE=trim(output_dirname)//gridname)
        k=0
        do j=1,nlat
           do i=1,nlon
              k=k+1
              gridcells(i,j)=k
              cell_ilon(k)=i
              cell_jlat(k)=j
              write(1024,*)k,lon(i),lat(j)
           enddo
        enddo
        close(1024)
        
        end subroutine create_grid
        
        subroutine PassInpSettings(nhgt_,Niso_,Isolines_,Threshprob_)
        implicit none
! Passes user-input settings        
         integer nhgt_,Niso_
         real Isolines_(Niso_),Threshprob_        
        
         nhgt=nhgt_
         Niso=Niso_
         allocate(Isolines(Niso))
         Isolines(1:Niso)=Isolines_(1:Niso_)
         allocate(Prob_iso(Niso))
         Prob_iso=0;
         
         Threshprob=Threshprob_
        
        end subroutine PassInpSettings
      
      subroutine readbin_1d(fname,nfname,Arr,n1)
      implicit none
      integer nfname
      character(nfname) fname
      real,allocatable,intent(out)::Arr(:)
      integer n1,ierr,readerr
      

      open(1111,FILE=fname(1:nfname),FORM='UNFORMATTED',iostat=ierr)
      if(ierr.ne.0)goto 1111
      read(1111,iostat=readerr)n1
      if(readerr.ne.0)goto 1111
      allocate(Arr(n1))
      read(1111,iostat=readerr)Arr
      if(readerr.ne.0)goto 1111
      close(1111)
      return

1111  write(6,*)'Error opening or reading file: ',fname(1:nfname)   
      write(6,*)'Ierr=',ierr,'readerr=',readerr
      stop
      end subroutine readbin_1d      
      
      subroutine readbin_4d(fname,nfname,Arr,n1,n2,n3,n4)
      implicit none
      integer nfname
      character(nfname) fname
      real,allocatable,intent(out)::Arr(:,:,:,:)
      integer n1,n2,n3,n4,ierr,readerr
      

      open(1111,FILE=fname(1:nfname),FORM='UNFORMATTED',iostat=ierr)
      if(ierr.ne.0)goto 1112
      read(1111,iostat=readerr)n1,n2,n3,n4
      if(readerr.ne.0)goto 1112
      allocate(Arr(n1,n2,n3,n4))
      read(1111,iostat=readerr)Arr
      if(readerr.ne.0)goto 1112
      close(1111)
     
      return
      
 1112  write(6,*)'Error opening or reading file: ',fname(1:nfname) 
       write(6,*)'Ierr=',ierr,'readerr=',readerr
       stop     
      
      end subroutine readbin_4d
      
      end module SIMFLEX
      
     
