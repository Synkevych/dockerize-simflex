!Evaluates mass of release when start time and duration were evaluated
       subroutine eval_src_mass
       use SIMFLEX,only:Nselect,start_time,duration,loutstep,
     &                  dlon,dlat,lat,j_select,DHgt,
     &                  n_dur_sol,indback_ts_sol,Obs_val1,Mass,
     &                  cmod,Nobs,AllSRS,Isolut
       implicit none
       integer i,j,ii,jj
       real dA,dM,adjsum,tdur_insec,obssum
       integer ndursol,indbacksol,nt,ind1,k
       
       allocate(Mass(Nselect))
       
       write(6,*)'Evaluating masses of release'
       
       obssum=sum(Obs_val1)
       
       write(6,*)'obssum=',obssum

       
       do i=1,Nselect 
       
       !write(*,*)'i=',i

         jj=j_select(i)
         
!         write(6,*)'dlon=',dlon,'dlat=',dlat,'cos=',
!     &             cos(lat(jj)*3.1416/180.)
         
         dA=(111139.**2)*dlon*dlat*cos(lat(jj)*3.1416/180.) ! cell area in meters
         
         ndursol=n_dur_sol(i)
         indbacksol=indback_ts_sol(i)
         
         cmod=0
         do j=1,Nobs
           nt=AllSRS(j)%nt
         
           if(indbacksol.gt.nt)cycle ! respective observation ended earlier than start time of current release
         
           ind1=max(nt-indbacksol-ndursol,1) ! if end of release later than end of obs than the rest are zeros
           do k=ind1,nt-indbacksol+1
             cmod(j)=cmod(j)+AllSRS(j)%srsred(k,1,i);
           enddo
           
         enddo         
         
         adjsum=sum(cmod)

         tdur_insec=duration(i)*3600.
         
  !       write(*,*)'dA=',dA,'DHgt=',DHgt,'tdur_insec=',tdur_insec,
  !   &             'adjsum=',adjsum         
         
         Mass(i)=obssum*dA*DHgt*tdur_insec/adjsum
         
       enddo
       
       write(6,*)'Mass in grid_cell(',Isolut,') is Mass=',Mass(Isolut) 
       write(6,*)' '
       end subroutine eval_src_mass
