! checks whether all srs start times coincide with simulation start time 
! and whether all srs end times are greater than respective measurements       
       subroutine convert_check_srs_times
       use SIMFLEX,only:Nobs,id_obs,AllSRS,Obs_dateend,Obs_utctend,
     &                   syear,smon,sday,shr,sminut,
     &                   AllSRS,locobsid,srsfiles
                        
       implicit none
       integer julian_date
       integer year_s,mon_s,day_s,hr_s,minut_s,sec_s,year_e,mon_e,
     &         day_e,hr_e,minut_e,sec_e,nt,year_e1,mon_e1,
     &         day_e1,hr_e1,minut_e1,sec_e1
       
       character(2) buf
       character(4) buf2
       character*8 ibdate,iedate ! end and start dates of flexpart simulation (iedate>ibdate in backward run)
       character*6 ibtime,ietime ! end and start dates of flexpart simulation
       
       integer J,nstr,k,i
       real tsecsince
       
       double precision JStart_datetime,tmpt,tflexmax,
     &                   tobsend
      double precision,parameter::thresch=-1.E-4
      
      write(6,*)'Converting srs times'
      write(6,*)' '
        
       JStart_datetime=dble(julian_date(syear,smon,sday))+dble(shr)/24
     &                 +dble(sminut)/24/60        
       
        
       do i=1,Nobs
       
         ibdate=AllSRS(i)%ibdate
         iedate=AllSRS(i)%iedate
         ibtime=AllSRS(i)%ibtime
         ietime=AllSRS(i)%ietime
         
         buf2=ibdate(1:4)
         read (buf2,'(I4)') year_s
         buf=ibdate(5:6)
         read (buf,'(I2)') mon_s
         buf=ibdate(7:8)
         read (buf,'(I2)') day_s

         buf=ibtime(1:2)
         read (buf,'(I2)') hr_s
         buf=ibtime(3:4)
         read (buf,'(I2)') minut_s
         buf=ibtime(5:6)
         read (buf,'(I4)') sec_s
         
         if(sec_s.ne.0.or.minut_s.ne.sminut.or.hr_s.ne.shr.or.
     &       day_s.ne.sday.or.mon_s.ne.smon.or.year_s.ne.syear)then
            J=locobsid(id_obs(i))
            nstr=len_trim(srsfiles(J))
           write(6,*)'Error from convert_check_srs_times: dat_time of'
           write(6,*)'Flexpart backward srs simulation corresponding to'
           write(6,*)'id_obs(',i,')=',id_obs(i),'as stored insrs file='
           write(6,*)srsfiles(J)(1:nstr)
           write(6,*)'should have the same end date as start date of '
           write(6,*)'this inverse run: year=',syear,'mon=',smon
           write(6,*)'day=',sday,'minut=',sminut,'sec=',0
           write(6,*)'while in srs file end date of backward run is:' 
           write(6,*)'year=',year_s,'mon=',mon_s,'day=',day_s
           write(6,*)'minut=',minut_s,'sec=',sec_s
           write(6,*)'Please, check your input data!'
           stop
                      
         endif 

         buf2=iedate(1:4)
         read (buf2,'(I4)') year_e
         buf=iedate(5:6)
         read (buf,'(I2)') mon_e
         buf=iedate(7:8)
         read (buf,'(I2)') day_e

         buf=ietime(1:2)
         read (buf,'(I2)') hr_e
         buf=ietime(3:4)
         read (buf,'(I2)') minut_e
         buf=ietime(5:6)
         read (buf,'(I4)') sec_e

         tflexmax=dble(julian_date(year_e,mon_e,day_e))+dble(hr_e)/24
     &                 +dble(minut_e)/24/60+dble(sec_e)/86400

         buf=Obs_dateend(i)(1:2)
         read (buf,'(I2)') day_e1
         buf=Obs_dateend(i)(4:5)
         read (buf,'(I2)') mon_e1
         buf2=Obs_dateend(i)(7:10)
         read (buf2,'(I4)') year_e1

         buf=Obs_utctend(i)(1:2)
         read (buf,'(I2)') hr_e1
         buf=Obs_utctend(i)(4:5)
         read (buf,'(I2)') minut_e1
         buf=Obs_utctend(i)(7:8)
         read (buf,'(I4)') sec_e1

         tobsend=dble(julian_date(year_e1,mon_e1,day_e1))+
     &           dble(hr_e1)/24+dble(minut_e1)/24/60+dble(sec_e1)/86400 
     
         if(tflexmax.lt.tobsend)then
            write(6,*)'Error from convert_check_srs_times: maximum '
            write(6,*)'date_time of flexpart backward simulation in '
            write(6,*)srsfiles(J)(1:nstr)
            write(6,*)'is less than end time of the respective '
            write(6,*)'observation, id_obs(',i,')=',id_obs(i)
            write(6,*)'For Flexpart run max date_time:'
            write(6,*)'year=',year_e,'mon=',mon_e,'day=',day_e
            write(6,*)'minut=',minut_e,'sec=',sec_e
            write(6,*)'For observation end date_time:'
            write(6,*)'year=',year_e1,'mon=',mon_e1,'day=',day_e1
            write(6,*)'minut=',minut_e1,'sec=',sec_e1
            write(6,*)'Please, check your input data!'
            stop
         endif
     
         nt=AllSRS(i)%nt
         
         allocate(AllSRS(i)%timed2(nt))
         
         AllSRS(i)%timedmax=real(tflexmax-JStart_datetime)
         
         
         do k=nt,1,-1
            tsecsince=AllSRS(i)%times(k) ! this value should be negative!

            if(tsecsince.gt.0)then 
              write(6,*)'Error from onvert_check_srs_times: times'
              write(6,*)'in output file of backward FLEXPART run'
              write(6,*)srsfiles(J)(1:nstr)
              write(6,*)'should be negative; please, check your data!'
              stop
            endif

            tmpt=tflexmax+tsecsince/86400.
            
            if(tmpt-JStart_datetime.le.thresch)then ! 1E-4 is approx. 10 sec in days
              write(6,*)'Error from onvert_check_srs_times: '
              write(6,*)'negative time happenned when converting times'
              write(6,*)'from Flexpart file:'
              write(6,*)srsfiles(J)(1:nstr)
              write(6,*)'to time frame related to start simulation time'
              write(6,*)'year=',year_s,'mon=',mon_s,'day=',day_s
              write(6,*)'minut=',minut_s,'sec=',sec_s              
              write(6,*)'Negative value happenned at time step k=',k
              write(6,*)'This may be due to round off errors in time '
              write(6,*)'Conversion, however program could not continue'
              write(6,*)'If sure than recompile after increasing '
              write(6,*)'threschold represented by thresch parameter'
              stop

            endif
                                   
            AllSRS(i)%timed2(k)=real(tmpt-JStart_datetime)
         enddo
         

       enddo
       
       
       
       end subroutine convert_check_srs_times
