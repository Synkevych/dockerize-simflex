! Reads measurements
! Format of read line (\t is separator):
! Use?;id_calc;No;Country;Lat;Lon;
! Date_start;HH:MM:SS_start;Date_end;HH:MM:SS_end;
! Val[Bq/m3];Sigma_OR_LDL[Bq/m3];Backgr[Bq/m3]
       subroutine read_measurements(fname)
       use parse
       use SIMFLEX,only:Nobs,id_obs,Obs_lon,Obs_lat,
     &                   Obs_sig,Obs_bckgr,Obs_datestart,Obs_dateend,
     &                   Obs_utctstart,Obs_utctend,Station_id,
     &                   Obs_val,MAXOBS

       implicit none
       character(1024) fname

       integer id_obs_(MAXOBS),Station_id_(MAXOBS)
       real Obs_lon_(MAXOBS),Obs_lat_(MAXOBS),Obs_val_(MAXOBS),
     &                   Obs_sig_(MAXOBS),Obs_bckgr_(MAXOBS)
       character(10),dimension(MAXOBS)::Obs_datestart_,Obs_dateend_
       character(8),dimension(MAXOBS)::Obs_utctstart_,Obs_utctend_

      character(50) str1
      integer useno
      integer i,L,Reason,nstr

      write(6,*)'From read_measurements:'
      write(6,*)'Reading measurements'
      write(6,*)' '

      OPEN(1024,FILE=fname(1:len(fname)))

      read(1024,"(A)")line
      L=0
      do i=1,MAXOBS
        read(1024,"(A)",IOSTAT=Reason)line
        if(Reason.eq.0)then
           str1=getArg(1)
           read(str1,*)useno
           str1(1:50)=' '

           if(useno.eq.0)then
              cycle
           endif

           L=L+1

           str1=getArg(2)
           read(str1,*)id_obs_(L)
           str1(1:50)=' '

           str1=getArg(3)
           read(str1,*)Station_id_(L)
           str1(1:50)=' '

           str1=getArg(4)
           read(str1,*)Obs_lat_(L)
           str1(1:50)=' '

           str1=getArg(5)
           read(str1,*)Obs_lon_(L)
           str1(1:50)=' '

           str1=getArg(6)
           nstr=len_trim(str1)
           if(nstr.ne.10)then
              call read_meas_err_message(1,nstr)
           endif
           Obs_datestart_(L)=str1(1:10)
           str1(1:50)=' '

           str1=getArg(7)
           nstr=len_trim(str1)
           if(nstr.ne.8)then
              call read_meas_err_message(2,nstr)
           endif
           Obs_utctstart_(L)=str1(1:8)
           str1(1:50)=' '

           str1=getArg(8)
           nstr=len_trim(str1)
           if(nstr.ne.10)then
              call read_meas_err_message(1,nstr)
           endif
           Obs_dateend_(L)=str1(1:10)
           str1(1:50)=' '

           str1=getArg(9)
           nstr=len_trim(str1)
           if(nstr.ne.8)then
              call read_meas_err_message(2,nstr)
           endif
           Obs_utctend_(L)=str1(1:8)
           str1(1:50)=' '

           str1=getArg(10)
           read(str1,*)Obs_val_(L)
           str1(1:50)=' '

           str1=getArg(11)
           read(str1,*)Obs_sig_(L)
           str1(1:50)=' '

           str1=getArg(12)
           read(str1,*)Obs_bckgr_(L)
           str1(1:50)=' '


           if(Obs_bckgr_(L).lt.0.or.Obs_val_(L).lt.0.or.
     &        Obs_sig_(L).lt.0)then
             write(6,*)'Error from read_measurements: all observations,'
             write(6,*)'respective background values and sigmas/LDLs'
             write(6,*)'should have physical values, while for L=',L
             write(6,*)'Obs_val_(L)=',Obs_val_(L)
             write(6,*)'Obs_bckgr_(L)=',Obs_bckgr_(L)
             write(6,*)'Obs_sig_(L)=',Obs_sig_(L)
             stop

           endif

        else
           exit;
        endif

      enddo
      CLOSE(1024)

      Nobs=L
      if(Nobs.eq.MAXOBS)then
        write(6,*)'Error from read_measurements: number of'
        write(6,*)'measurements read from file ',fname(1:len(fname))
        write(6,*)'reached value=',MAXOBS,'while maximum allowable'
        write(6,*)'value is:',MAXOBS-1
        write(6,*)'Please, input file'
        stop
      endif
      
      write(6,*)'Number of measurements Nobs=',Nobs
      write(6,*)' '
      
      allocate(id_obs(Nobs))
      allocate(Station_id(Nobs))
      allocate(Obs_lon(Nobs))
      allocate(Obs_lat(Nobs))
      allocate(Obs_val(Nobs))
      allocate(Obs_sig(Nobs))
      allocate(Obs_bckgr(Nobs))
      allocate(Obs_datestart(Nobs))
      allocate(Obs_dateend(Nobs))
      allocate(Obs_utctstart(Nobs))
      allocate(Obs_utctend(Nobs))

       id_obs=id_obs_(1:Nobs)
       Station_id=Station_id_(Nobs)
       Obs_lon=Obs_lon_(1:Nobs)
       Obs_lat=Obs_lat_(1:Nobs)
       Obs_val=Obs_val_(1:Nobs)
       Obs_sig=Obs_sig_(1:Nobs)
       Obs_bckgr=Obs_bckgr_(1:Nobs)
       Obs_datestart=Obs_datestart_(1:Nobs)
       Obs_dateend=Obs_dateend_(1:Nobs)
       Obs_utctstart=Obs_utctstart_(1:Nobs)
       Obs_utctend=Obs_utctend_(1:Nobs)
      end subroutine read_measurements

       subroutine read_meas_err_message(flag,sizestr)
       implicit none
       integer flag,sizestr
       if(flag.eq.1)then
         write(6,*)'Error from read_measurements: length of '
         write(6,*)'date string dd.mm.yyyy should be 10, while '
         write(6,*)'it is ',sizestr
         write(6,*)'Please, check file with measurements'
         stop
       elseif(flag.eq.2)then
         write(6,*)'Error from read_measurements: length of '
         write(6,*)'time string hh.mm.ss should be 8, while '
         write(6,*)'it is ',sizestr
         write(6,*)'Please, check file with measurements'
         stop
       else
         write(6,*)'Error from read_meas_err_message: flag=',flag
         write(6,*)'is not defined'
         stop
       endif
       end subroutine read_meas_err_message
