       subroutine save_times_mass
       use SIMFLEX,only:Nselect,Jmax_sol,start_time,duration,gridcells,
     &                  grid_select,lon,lat,nlon,nlat,
     &                  ifdebug_out,timesmassname,timesmass_debug,Mass,
     &                  ind_select,calc_output_path
      implicit none
      integer i,ii,j

      write(6,*)'Saving calculated times and masses of release'

       open(1024, FILE = calc_output_path // timesmassname)

       do i=1,Nselect

          write(1024,*)grid_select(i),';',duration(i),';',
     &                 start_time(i),';',Mass(i),';',Jmax_sol(i)

       enddo
       close(1024)

       if(.not.ifdebug_out)return

       open(1025, FILE = calc_output_path // timesmass_debug)
       do j=1,nlat
       do i=1,nlon
         if(ind_select(i,j).ne.0)then
         ii=ind_select(i,j)
         write(1025,'(1I6,1X,4F8.4,1X,1E8.2,1X,1F8.4)')grid_select(ii),
     &                lon(i),lat(j),duration(ii),start_time(ii),
     &                Mass(ii),Jmax_sol(ii)
         else
          write(1025,'(1I6,1X,4F8.4,1X,1E8.2,1X,1F8.4)')gridcells(i,j),
     &                lon(i),lat(j),0.0,-1.0,
     &                0.0,0.0
         endif
      enddo
      enddo
       close(1025)

       end subroutine save_times_mass
