! reads srs for all measurements from flexpart output netcdf files,
! summarizes them in time
! and stores result in AllSRS(:)%srsti
! This is stub; to be replaced by reading netcdf files
       subroutine read_tintegr_srs
       use SIMFLEX,only:Nobs,locobsid,id_obs,AllSRS,srsfiles,
     &                  srs_ind_all,nlon,nlat,nhgt,series_id,
     &                  readbin_4d,nuclide_name,
     &                  loutstep,ntmax,maxtsrcind,Indback_tsmax

       implicit none
       include 'netcdf.inc'

       integer i,k,nlon_,nlat_,nhgt_,nstr,J,nt,loutstep_infile
       integer state,ncid,x_id,cvar_id
       character*8 ibdate,iedate
       character*6 ibtime,ietime
       real,allocatable::srs(:,:,:,:,:,:),times_(:)
       real,allocatable::srsred(:,:)
       integer corner(6),edgelen(6)
       character*(nf_max_name) recname

       character*200 fsrsname
       CHARACTER(len=3),PARAMETER::fsrspattern='srs'
       character(len=:), allocatable :: series_dirpath
      integer curlen

      write(6,*)'From read_tintegr_srs:'
      write(6,*)'Reading and time integrating SRS-s'


      if(.not.allocated(AllSRS))allocate(AllSRS(Nobs))


       ntmax=0
       do i=1,Nobs
      ! do i=1,1 !for test only
           J=locobsid(id_obs(i))
           nstr=len_trim(srsfiles(J))
           write(6,*)adjustl(srsfiles(J))

           state = nf_open(adjustl(srsfiles(J)),nf_nowrite,ncid)
           if(state.ne.nf_noerr) call handle_err(state)

           state = nf_inq_dim(ncid,1,recname,nt)
           if(state.ne.nf_noerr) call handle_err(state)
           AllSRS(i)%nt=nt

           state = nf_inq_dim(ncid,2,recname,nlon_)
           if(state.ne.nf_noerr) call handle_err(state)


           state = nf_inq_dim(ncid,3,recname,nlat_)
           if(state.ne.nf_noerr) call handle_err(state)

           state = nf_inq_dim(ncid,4,recname,nhgt_)
           if(state.ne.nf_noerr) call handle_err(state)

!           call readbin_4d(srsfiles(J)(1:nstr),nstr,AllSRS(i)%srs,
!     &                     nlon_,nlat_,nhgt_,nt)

            if(nlon_.ne.nlon.or.nlat.ne.nlat_)then
              write(6,*)'Error from read_tintegr_srs:'
              write(6,*)'Grid sizes in file=',adjustl(srsfiles(J))
              write(6,*)'nlon_=',nlon,'nlat_=',nlat
              write(6,*)'are incompatible with respective sizes'
              write(6,*)'initially specified by user:'
              write(6,*)'nlon=',nlon,'nlat=',nlat
              write(6,*)'Grids in all srs files should be the same!'
              stop
            endif

            if(nhgt_.ne.nhgt)then
              write(6,*)'Error from read_tintegr_srs:'
              write(6,*)'Number of vertical levels in file=',
     &                   adjustl(srsfiles(J))
              write(6,*)'is incompatible with respective size'
              write(6,*)'initially read from input nml file:'
              write(6,*)'in srs file nhgt=',nhgt_
              write(6,*)'in simflexinp.nml file nhgt=',nhgt
              stop
            endif

          !  allocate(AllSRS(i)%srs(nlon,nlat,nhgt,nt))
             allocate(srs(nlon,nlat,nhgt,nt,1,1))
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

            allocate(AllSRS(i)%srstsum(nlon,nlat,nhgt))

            if(.not.allocated(srsred))allocate(srsred(nlon,nlat))

            !AllSRS(i)%srstsum=SUM(AllSRS(i)%srs,4) ! 4 is assummed to be time dimension
            AllSRS(i)%srstsum=SUM(srs(:,:,:,:,1,1),4)
            AllSRS(i)%id_obs=id_obs(i)

            srsred=REAL(loutstep)*AllSRS(i)%srstsum(:,:,1)
             call fname_srs(fsrspattern,id_obs(i),fsrsname,200)
             curlen=len_trim(fsrsname)
             series_dirpath = '/series/'//
     &                        trim(adjustl(int2str(series_id)))//
     &                        '/'//trim(nuclide_name)//'/'
              open(1022,FILE=series_dirpath//fsrsname(1:curlen),
     &                  FORM='UNFORMATTED')
              write(1022)nlon,nlat
              write(1022)srsred
              close(1022)
          !  deallocate(AllSRS(i)%srs)
            deallocate(srs)

! Dates are read but dates checks made later
            state=nf_get_att_text(ncid,NF_GLOBAL,'ibdate',ibdate)
            if(state.ne.nf_noerr) call handle_err(state)

            state=nf_get_att_text(ncid,NF_GLOBAL,'iedate',iedate)
            if(state.ne.nf_noerr) call handle_err(state)

            state=nf_get_att_text(ncid,NF_GLOBAL,'ibtime',ibtime)
            if(state.ne.nf_noerr) call handle_err(state)

            state=nf_get_att_text(ncid,NF_GLOBAL,'ietime',ietime)
            if(state.ne.nf_noerr) call handle_err(state)

            AllSRS(i)%ibdate=ibdate
            AllSRS(i)%ibtime=ibtime

            AllSRS(i)%iedate=iedate
            AllSRS(i)%ietime=ietime

            state=nf_get_att_int(ncid,NF_GLOBAL,'loutstep',
     &                           loutstep_infile)
            if(state.ne.nf_noerr) call handle_err(state)

            if(abs(loutstep_infile).ne.loutstep)then
              write(6,*)'Error from read_tintegr_srs: abs value of '
              write(6,*)'time step of savings in file:',
     &                    adjustl(srsfiles(J))
              write(6,*)'loutstep=', loutstep_infile
             write(6,*)'is inconsistent with time step provided by user'
              write(6,*)'loutstep=', loutstep
              write(6,*)'Please, check your data and settings!'
              stop
            endif

            write(6,*)'AllSRS(',i,')%iedate%time=',AllSRS(i)%iedate,
     &                AllSRS(i)%ietime
            write(6,*)'file=',trim(adjustl(srsfiles(J))),
     &                ' point_index=',srs_ind_all(J)

             AllSRS(i)%nt=nt
             allocate(AllSRS(i)%times(nt))

             state=nf_inq_varid(ncid,'time',x_id)
             if(state.ne.nf_noerr) call handle_err(state)

             state=nf_get_var_real(ncid,x_id,AllSRS(i)%times)
             if(state.ne.nf_noerr) call handle_err(state)

            if(AllSRS(i)%nt.gt.ntmax)ntmax=AllSRS(i)%nt

            state = nf_close(ncid)
            if(state.ne.nf_noerr) call handle_err(state)

       enddo
       if(allocated(srsred))deallocate(srsred)

       write(6,*)'Maximum number of time layers in srs files ntmax=',
     &            ntmax

!checks of previously calculated time indices that should not exceed ntmax
       if(maxtsrcind.gt.ntmax)then
          write(6,*)'Warning: strange situation: maxtsrcind.gt.ntmax'
          write(6,*)'Resetting maxtsrcind=ntmax'
          maxtsrcind=ntmax
       endif
       if(Indback_tsmax.gt.ntmax)then
          write(6,*)'Warning: strange situation: Indback_tsmax.gt.ntmax'
          write(6,*)'Resetting Indback_tsmax=ntmax'
          Indback_tsmax=ntmax
       endif

       write(6,*)' '


       end subroutine read_tintegr_srs

       subroutine fname_srs(fsrspattern, srsid, fname, Lenf)
       implicit none

       character(*) fsrspattern
       integer srsid, Lenf
       character(Lenf) fname

       fname = fsrspattern // '_'
     &         // trim(adjustl(int2str(srsid)))
     &         // '.bin'

      contains

        function int2str(n) result(str)
          implicit none
          integer, intent(in) :: n
          character(len=10) :: str
          write(str, '(I10)') n
        end function int2str

      end subroutine fname_srs
