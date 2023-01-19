      subroutine select_subgrid
      use SIMFLEX,only:nlon,nlat,gridcells,normcor0,
     &                iso1,Nselect,grid_select,i_select,
     &                      j_select,ind_select
      implicit none
      integer i,j,k,LL
      integer,allocatable::grid_select_tmp(:),i_select_tmp(:),
     &                     j_select_tmp(:)
      
      
      write(6,*)'From select_subgrid:'
      write(6,*)'Selecting grid cells where release inventories,'
      write(6,*)'start times, durations will be evaluated'
      
      allocate(grid_select_tmp(nlon*nlat))
      allocate(i_select_tmp(nlon*nlat))
      allocate(j_select_tmp(nlon*nlat))
      allocate(ind_select(nlon,nlat))
      
      ind_select=0
      grid_select_tmp=0

      
      LL=0
      k=0
      do j=1,nlat
       do i=1,nlon
         k=k+1
         if(normcor0(i,j).ge.iso1)then
          LL=LL+1
          grid_select_tmp(LL)=gridcells(i,j)
          i_select_tmp(LL)=i
          j_select_tmp(LL)=j
          ind_select(i,j)=LL
         endif
       enddo
      enddo
      
      Nselect=LL
      
      allocate(grid_select(Nselect))
      allocate(i_select(Nselect))
      allocate(j_select(Nselect))
      grid_select(1:Nselect)=grid_select_tmp(1:Nselect)
      i_select(1:Nselect)=i_select_tmp(1:Nselect)
      j_select(1:Nselect)=j_select_tmp(1:Nselect)
      
      deallocate(grid_select_tmp)
      deallocate(i_select_tmp)
      deallocate(j_select_tmp)
      
      write(6,*)'Number of selected grid nodes Nselect=',Nselect
      write(6,*)' '
      
      end subroutine select_subgrid