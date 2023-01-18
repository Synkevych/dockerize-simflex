       subroutine eval_srctimes
       use SIMFLEX,only:Nselect,n_dur_sol,indback_ts_sol,
     &                  Jmax_sol,start_time,duration,loutstep,
     &                  i_select,j_select,lon,lat,grid_select,
     &                  Isolut
       implicit none
       
       integer i
       real Jcur,Jmax,start_sol,dur_sol,lon_sol,lat_sol

       integer ndursol,indbacksol,isol
       
       allocate(n_dur_sol(Nselect))
       allocate(indback_ts_sol(Nselect))
       allocate(Jmax_sol(Nselect))
       allocate(start_time(Nselect))
       allocate(duration(Nselect))
       
       write(6,*)'Evaluating start times and durations of release'
       
       Jmax=0
       do i=1,Nselect
        call eval_Jtime_innode(i,Jcur,ndursol,indbacksol)
        n_dur_sol(i)=ndursol
        indback_ts_sol(i)=indbacksol
        Jmax_sol(i)=Jcur
        
      
        start_time(i)=real(loutstep*indback_ts_sol(i))/3600.
        duration(i)=real(loutstep*n_dur_sol(i))/3600.

        if(Jcur.gt.Jmax)then
           Jmax=Jcur
           start_sol=start_time(i)
           dur_sol=duration(i)
           lon_sol=lon(i_select(i))
           lat_sol=lat(j_select(i))
           Isolut=i
        endif
        
       enddo
       write(6,*)'Maximum cor. coef. with respect to time parameters'
       write(6,*)'is reached in point: lon=',lon_sol,'lat=',lat_sol
       write(6,*)'start time=',start_sol,'hrs, duration=',dur_sol 
       write(6,*)'cell_id=grid_select(',Isolut,')=',grid_select(Isolut) 
       write(6,*)' '
       

       
       end subroutine eval_srctimes
