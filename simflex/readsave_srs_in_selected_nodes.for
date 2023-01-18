! reads srs for all measurements, and stores 
! and stores result in selected nodes in AllSRS(:)%srsred
! also brings times of srs  to uniform time frame with 0 time - at the beginning of simulation
! period, stores the result in AllSRS(:)%times 

       subroutine readsave_srs_in_selected_nodes
       use SIMFLEX,only:Nobs,locobsid,id_obs,AllSRS,srsfiles,
     &                  srs_ind_all,nlon,nlat,nhgt,Nselect,
     &                   i_select,j_select
     
       implicit none
       include 'netcdf.inc'

       integer i,nlon_,nlat_,nhgt_,nstr,J,nt
       integer k,ierr,ii,jj
       real,allocatable::srs(:,:,:,:,:,:),times_(:)
       integer corner(6),edgelen(6),cvar_id,ncid,state
       character*(nf_max_name) recname
       
      write(6,*)'From readsave_srs_in_selected_nodes:'
      write(6,*)'Reading SRS-s for all measurements and '
      write(6,*)'stores the results in selected nodes '
      write(6,*)' '       
      
!       if(not(allocated(AllSRS)))allocate(AllSRS(Nobs))
       
       do i=1,Nobs

           J=locobsid(id_obs(i))
           
           if(AllSRS(i)%id_obs.ne.id_obs(i))then
             write(6,*)'Error from readsave_srs_in_selected_nodes:'
             write(6,*)'AllSRS(i)%id_obs.ne.id_obs(i) for i=',i
             write(6,*)'AllSRS(i)%id_obs=',AllSRS(i)%id_obs
             write(6,*)'id_obs(i)=',id_obs(i)
             write(6,*)'AllSRS had to be initialized correctly before '
             write(6,*)'call of this subroutine; check the code'
             stop
           endif
           
           nstr=len_trim(srsfiles(J))
           write(6,*)srsfiles(J)(1:nstr)

           nt=AllSRS(i)%nt
           allocate(srs(nlon,nlat,nhgt,nt,1,1),stat=ierr)
           srs=0

           state = nf_open(srsfiles(J)(1:nstr),nf_nowrite,ncid)
           if(state.ne.nf_noerr) call handle_err(state)


           if(ierr.ne.0)then
                 goto 71
           endif
             corner=1
             corner(5)=srs_ind_all(J)

             edgelen=1
             edgelen(1)=nlon
             edgelen(2)=nlat
             edgelen(3)=nhgt ! presently nhgt should be 1
             edgelen(4)=nt

            state = nf_inq_varid(ncid,'spec001_mr',cvar_id)
            if(state.ne.nf_noerr) call handle_err(state)

            state=nf_get_vara_real(ncid,cvar_id,corner,edgelen,srs)
            if(state.ne.nf_noerr) call handle_err(state)

           
!           call readbin_4d(srsfiles(J)(1:nstr),nstr,AllSRS(i)%srs,
!     &                     nlon_,nlat_,nhgt_,nt)
            
            allocate(AllSRS(i)%srsred(nt,nhgt,Nselect),stat=ierr)      
             
   71        if ( ierr.ne.0 ) then
               write(6,*) 'Error from readsave_srs_in_selected_nodes:'
               write(6,*) 'Memory allocation failed when processing srs'
               write(6,*) 'for id_obs(',i,')=',id_obs(i)
               write(6,*)'out of total Nobs=',Nobs
               write(6,*) 'Srs file: ',srsfiles(J)(1:nstr)
               write(6,*) 'Please try to reduce threschold probability'
               write(6,*) 'represented by parameter Threshprob,'
               write(6,*) 'or do other optimizations of minimization'
              write(6,*)'problem e.g. increasing time step in srs files'
               stop
             endif           
             
            do k=1,Nselect
              do jj=1,nhgt
                do ii=1,nt
                  AllSRS(i)%srsred(ii,jj,k)=srs(i_select(k),
     &                               j_select(k),jj,ii,1,1)
                enddo
              enddo
            enddo
            
            deallocate(srs) 
            
            
            
            state = nf_close(ncid)
            if(state.ne.nf_noerr) call handle_err(state)       
          
       enddo
       
       
       end subroutine readsave_srs_in_selected_nodes
