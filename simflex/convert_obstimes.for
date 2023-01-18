! Calculates start and end times of obs in hours from start date_time 
! of This simulation run represented by year,smon,sday,shr,sminut
       subroutine convert_obstimes
       use SIMFLEX,only: Nobs,id_obs,AllSRS,Obs_datestart,Obs_dateend,
     &                   Obs_utctstart,Obs_utctend,syear,smon,sday,shr,
     &                   sminut,AllSRS,Obs_tstart,Obs_tend
       implicit none
       integer julian_date
       
       integer i,year_s,mon_s,day_s,hr_s,minut_s,sec_s,year_e,mon_e,
     &         day_e,hr_e,minut_e,sec_e
       double precision JStart_datetime,tmp_start,tmp_end
       
       character(2) buf
       character(4) buf2       
       
       JStart_datetime=dble(julian_date (syear,smon,sday))+dble(shr)/24
     &                 +dble(sminut)/24/60
! doubles are needed because julian day is large value and appending hour, minutes and seconds 
! converted to day lead to loss of accuracy; therefore doubles are used before substraction
! of JStart_datetime (conversion to time frame related to start of simulation period, not to World Creation))
! after subtraction accuracy of real is sufficient

      allocate(Obs_tstart(Nobs))
      allocate(Obs_tend(Nobs))
      Obs_tstart=0
      Obs_tend=0
      
       do i=1,Nobs
         buf=Obs_datestart(i)(1:2)
         read (buf,'(I2)'),day_s
         buf=Obs_datestart(i)(4:5)
         read (buf,'(I2)'),mon_s
         buf2=Obs_datestart(i)(7:10)
         read (buf2,'(I4)'),year_s

         buf=Obs_utctstart(i)(1:2)
         read (buf,'(I2)'),hr_s
         buf=Obs_utctstart(i)(4:5)
         read (buf,'(I2)'),minut_s
         buf=Obs_utctstart(i)(7:8)
         read (buf,'(I4)'),sec_s

         buf=Obs_dateend(i)(1:2)
         read (buf,'(I2)'),day_e
         buf=Obs_dateend(i)(4:5)
         read (buf,'(I2)'),mon_e
         buf2=Obs_dateend(i)(7:10)
         read (buf2,'(I4)'),year_e

         buf=Obs_utctend(i)(1:2)
         read (buf,'(I2)'),hr_e
         buf=Obs_utctend(i)(4:5)
         read (buf,'(I2)'),minut_e
         buf=Obs_utctend(i)(7:8)
         read (buf,'(I4)'),sec_e
         
         tmp_start=dble(julian_date(year_s,mon_s,day_s))+
     &        dble(hr_s)/24+dble(minut_s)/24/60+dble(sec_s)/86400
         
         
         
         Obs_tstart(i)=real(tmp_start-JStart_datetime)
         write(*,*)Obs_tstart(i)
         
          tmp_end=dble(julian_date(year_e,mon_e,day_e))+
     &        dble(hr_e)/24+dble(minut_e)/24/60+dble(sec_e)/86400
         
          Obs_tend(i)=real(tmp_end-JStart_datetime)
       enddo
       
       
       
       end subroutine convert_obstimes