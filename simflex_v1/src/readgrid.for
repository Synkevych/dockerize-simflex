!this is stub read subroutine(!)
      subroutine readlonlat
      use SIMFLEX,only:lon,lat,nlon,nlat,dlon,dlat,outlon0,outlat0,
     &                 id_obs,srsfiles,locobsid,full_output_path,
     &                 output_dirname
      implicit none
      include 'netcdf.inc'
      
      integer nlon_,nlat_
      real outlon_,outlat_
      integer state,ncid,J,x_id,y_id,nstr,cvar_id
      character*(nf_max_name) recname
      character(len=100) :: nuclide_name ! Attribute name

       J=locobsid(id_obs(1))
 
       write(6,*)'J=',J

       nstr=len_trim(adjustl(srsfiles(J)))

       write(6,*)'srsfile name:',srsfiles(J)(1:nstr)
       write(6,*)'srsfiles name:',adjustl(srsfiles(J))
       write(6,*)'nstr ',nstr

       state = nf_open(adjustl(srsfiles(J)),nf_nowrite,ncid)
       if(state.ne.nf_noerr) call handle_err(state)

       write(6,*)'Flexpart srs file=',adjustl(srsfiles(J))

       if(state.ne.nf_noerr) call handle_err(state)
       
       state = nf_inq_dim(ncid,2,recname,nlon_)
       if(state.ne.nf_noerr) call handle_err(state)
       
       state = nf_inq_dim(ncid,3,recname,nlat_)
       if(state.ne.nf_noerr) call handle_err(state)

       state=nf_get_att_real(ncid,NF_GLOBAL,'outlon0',
     &                           outlon_)
        if(state.ne.nf_noerr) call handle_err(state)
         
       state=nf_get_att_real(ncid,NF_GLOBAL,'outlat0',
     &                           outlat_)
        if(state.ne.nf_noerr) call handle_err(state)
        write(*,*)'outlat_=',outlat_

        if(abs(outlon0-outlon_).gt.0.00001)goto 2224
        if(abs(outlat0-outlat_).gt.0.00001)goto 2224
       
       if(nlon.ne.nlon_.or.nlat.ne.nlat)then
        goto 2223
       endif
       
       write(*,*)'allocating lonlat'
       allocate(lon(nlon))
       allocate(lat(nlat))
       write(*,*)'lonlat allocated'

       state = nf_inq_varid(ncid,'longitude',x_id)
       state = nf_get_var_real(ncid,x_id,lon)
       if (state .ne. nf_noerr) call handle_err(state)

       state = nf_inq_varid(ncid,'latitude',y_id)
       state = nf_get_var_real(ncid,y_id,lat)
       if (state .ne. nf_noerr) call handle_err(state)
      
       if(abs(lon(2)-lon(1)-dlon).gt.0.00001)then
         goto 2222
       endif
       if(abs(lat(2)-lat(1)-dlat).gt.0.00001)then
         goto 2222
       endif

! Retreive nuclide name
       state = nf_inq_varid(ncid,'spec001_mr',cvar_id)
       if(state.ne.nf_noerr) call handle_err(state)

       state=nf_get_att_text(ncid,cvar_id,'long_name',nuclide_name)
       if(state.ne.nf_noerr) call handle_err(state)
       full_output_path = output_dirname//trim(nuclide_name)//"/"

       state = nf_close(ncid)
       if(state.ne.nf_noerr) call handle_err(state)

       return

 2222  write(6,*)'Error from readlonlat_stub: '
       write(6,*)'Flexpart srs file=',adjustl(srsfiles(J))
       write(6,*)'dlon should be equal ',dlon
       write(6,*)'dlat should be equal ',dlat
       write(6,*)'while lon(2)-lon(1)= ',lon(2)-lon(1)
       write(6,*)'while lat(2)-lat(1)= ',lat(2)-lat(1)
       write(6,*)'Grids in srs files should be consistent with'
       write(6,*)'input settings'
       stop
       
 2223  write(6,*)'Error from readlonlat_stub:'
       write(6,*)'Flexpart srs file=',adjustl(srsfiles(J))
       write(6,*)'Grid sizes nlon_=',nlon_,'nlat_=',nlat_
       write(6,*)'are incompatible with respective sizes'
       write(6,*)'initially set by user:'
       write(6,*)'nlon=',nlon,'nlat=',nlat
       write(6,*)'Grids in srs files should be consistent with'
       write(6,*)'input settings'
       stop

 2224  write(6,*)'Error from readlonlat_stub:'
       write(6,*)'Corner coords read from file outlon_=',outlon_,
     &            'outlat_=',outlat_
       write(6,*)'Flexpart srs file=',adjustl(srsfiles(J))
       write(6,*)'are incompatible with respective coordinates'
       write(6,*)'initially set by user:'
       write(6,*)'outlon0=',outlon0,'outlat0=',outlat0
       write(6,*)'Grids in srs files should be consistent with'
       write(6,*)'input settings'
       stop
      end subroutine readlonlat
