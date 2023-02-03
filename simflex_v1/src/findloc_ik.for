! Implements findloc  for 1d array; restricted for size 1000
      subroutine findloc1(array,Nsz,val,findloc)
      implicit none

      integer,intent(in) :: Nsz
      integer,dimension(Nsz),intent(in) :: array
      integer,intent(in) :: val
      integer,intent(out) :: findloc

!      integer,intent(in) :: array(*)
      integer i

!      Nsz=size(array)
!      write(*,*)'Nsz=',Nsz
      findloc=0
      do i=1,Nsz
!         write(*,*)'In findloc i=',i
         if(array(i).eq.val)then
            findloc=i
            exit
         endif
      enddo
      end subroutine findloc1
