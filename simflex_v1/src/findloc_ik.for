! Implements findloc  for 1d array; restricted for size 1000
      subroutine findloc1(array,Nsz,val,findloc)
      implicit none

      integer,intent(in) :: Nsz
      integer,dimension(Nsz),intent(in) :: array
      integer,intent(in) :: val
      integer,intent(out) :: findloc
      integer i

      findloc=0
      do i=1,Nsz
         if(array(i).eq.val)then
            findloc=i
            exit
         endif
      enddo
      end subroutine findloc1
