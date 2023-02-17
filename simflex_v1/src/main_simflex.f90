!  simflex.f90 
!
!  FUNCTIONS:
!  simflex - Source Inversion Module - FLEXPART
!

!****************************************************************************
!
!  PROGRAM: simflex
!
!  PURPOSE:  Solves inverse problem using results of backward runs of FLEXPART! 
! 
!
!****************************************************************************
! Author: Ivan Kovalets

    program main_simflex
    use SIMFLEX,only:lat,lon,nlon,nlat,Nobs,AllSRS,id_obs,&
     Obs_Correct,nhgt,create_grid,PassInpSettings,&
     syear,smon,sday,shr,sminut,loutstep,min_duration,tstart_max, &
     thresh_start,dlon,dlat, DHgt,outlon0,outlat0,&
     def_maxtsrcind,def_ndur_min,def_tstartmax,& ! - these are subroutines
     input_dirname,output_dirname

    implicit none
    integer,parameter:: MaxIsolines=100
!Inputs    
    integer nhgt_,Niso_,loutstep_
    real Isolines_(MaxIsolines)
    real ThreshProb_,min_duration_,tstart_max_,thresh_start_,DHgt_
    logical redirect_console
    integer syear_,smon_,sday_,shr_,sminut_,nlon_,nlat_
    
    integer nt,i,ierr1,ierr2
    real dlon_,dlat_
    real outlon_,outlat_
    
    namelist /simflexinp/nhgt_,Niso_,loutstep_,&
     Isolines_,ThreshProb_,min_duration_,tstart_max_,thresh_start_,DHgt_,&
     redirect_console,syear_,smon_,sday_,shr_,sminut_,nlon_,nlat_,&
      dlon_,dlat_,outlon_,outlat_
    
    write(6,*) 'Starting SIMFLEX'
    write(6,*)' '
    
    Isolines_=10

    open(10,file=trim(input_dirname)//'simflexinp.nml',form='formatted',IOSTAT=ierr1)
    if(ierr1.ne.0)then
      write(6,*)'Error opening namelist file simflexinp.nml'
      stop
    endif
    read(10,simflexinp,IOSTAT=ierr2)
    if(ierr2.ne.0)then
      write(6,*)'Error reading namelist file simflexinp.nml'
      stop
    endif
    close(10)    

     write(6,*)'Parameters, read from namelist simflexinp.nml:'
     write(6,*)'redirect_console=',redirect_console
     write(6,*)'nhgt_=',nhgt_,'Niso_=',Niso_
     write(6,*)'Isolines_=',Isolines_(1:Niso_)
     write(6,*)'syear_=',syear_,'smon_=',smon_,'sday_=',sday_
     write(6,*)'shr_=',shr_,'sminut_=',sminut_
     write(6,*)'loutstep_=',loutstep_
     write(6,*)'tstart_max_=',tstart_max_,'min_duration_=',min_duration_
     write(6,*)'thresh_start_=',thresh_start_
     write(6,*)'dlon_=',dlon_,'dlat_=',dlat_
     write(6,*)'outlon_=',outlon_,'outlat_=',outlat_
     write(6,*)'nlon_=',nlon_,'nlat_=',nlat_
     write(6,*)'DHgt_=',DHgt_
     
     call Check_Iso(Isolines_,Niso_)

!Inputs init (to be replaced by reading from file):
!     redirect_console=.false.
!     nhgt_=1
!     Niso_=11
!     do i=1,9
!       Isolines_(i)=0.1*real(i)
!     enddo
!     Isolines_(10)=0.95
!     Isolines_(11)=0.99
!     Threshprob_=0.9
!     syear_=2020
!     smon_=4
!     sday_=18
!     shr_=0
!     sminut_=0
!     loutstep_=360 !sec
!     tstart_max_=-9999.0 !hrs
!     min_duration_=360 !sec
!     thresh_start_=1.0 !factor
!     dlon_=0.1
!     dlat_=0.1
!     outlon_=0.
!     outlat_=37.8
!     nlon_=400
!     nlat_=322
!     DHgt_=200
     
!Pass inputs to module     
     call PassInpSettings(nhgt_,Niso_,Isolines_,Threshprob_)
     syear=syear_
     smon=smon_
     sday=sday_
     shr=shr_
     sminut=sminut_
     loutstep=loutstep_
     min_duration=min_duration_
     tstart_max=tstart_max_
     thresh_start=thresh_start_
     
     dlon=dlon_
     dlat=dlat_
     outlon0=outlon_
     outlat0=outlat_
     nlon=nlon_
     nlat=nlat_
     DHgt=DHgt_
     
    ! Body of simflex
    if(redirect_console)then
       open(6,FILE=trim(output_dirname)//'console.dat')
    endif

    call read_measurements(trim(input_dirname)//'measurem.csv',27)
    
    call convert_obstimes ! convert to time frame relevant to start time of simulation (in days)
    
    call Obs_Correct !subtract background
    
    call def_tstartmax ! maximum start time of release
    
    call def_maxtsrcind ! maximum time and time index of src
    
    call def_ndur_min ! minimum release duration and index

    call read_srs_paths(trim(input_dirname)//'table_srs_paths.txt',34)
    
    call check_init_locobs_id
    
    
    
    write(6,*)'Reading Grid-related parameters'
    write(6,*)' '
    
    call readlonlat
    
    call create_grid
    
    allocate(AllSRS(Nobs))
    call read_tintegr_srs
    
    call convert_check_srs_times !convert srs times to same time frame as observations
    
    call eval_srcloc
    
    call isoselect
    
    call select_subgrid
    
    call readsave_srs_in_selected_nodes
    
    call eval_srctimes
    
    call eval_src_mass
    
    call save_times_mass


    if(redirect_console)then
       close(6)
    endif
    
    stop
! This section is to be deleted; previously used for testing only
    Nobs=31
    
    allocate(id_obs(Nobs))
    do i=1,Nobs
       id_obs(i)=Nobs-i+1
    enddo
    write(6,*)minloc(abs(id_obs-1))
    allocate(AllSRS(Nobs))
    !call readbin_4d('srs_1.bin',9,AllSRS(1)%srs,nlon_,nlat_,nhgt,nt)

    end program main_simflex
    subroutine Check_Iso(Isolines,Niso)
    implicit none
    integer Niso
    real Isolines(Niso)
    integer i
     do i=1,Niso
      if(Isolines(i).le.0.or.Isolines(i).ge.1)then
         write(6,*)'Error in input array Isolines_:'
         write(6,*)'All elements within entered size of array Niso_=',Niso
         write(6,*)'Should be >0 and <1'
         stop
      endif
      if(i.eq.1)cycle
      if(Isolines(i).le.Isolines(i-1))then
         write(6,*)'Error in input array Isolines_:'
         write(6,*)'Isolines_(',i,')=',Isolines(i)
         write(6,*)'is less or equal than the previous value'
         write(6,*)'Isolines_(',i-1,')=',Isolines(i-1)
         write(6,*)'Please, correct your input data'
         stop
      endif
     enddo
    
    end subroutine Check_Iso
