!Adapted from example code in
! community.intel.com/t5/Intel-Fortran-Compiler/Trouble-reading-a-csv-file/m-p/1034133#M111406
      module parse
      integer, parameter :: MAX_LINE = 1024    ! you determine the size of line
      character(MAX_LINE) :: line
      contains
      function getArg(n) result(arg)
        implicit none
        character(MAX_LINE) :: arg
        integer :: n,i,j,count
        j = 0
        do count=1,n
            i = j + 1
            j = INDEX(line(i:),';')
            if(j == 0) exit
            j = j + i - 1
        end do
        if(j == 0) then
            if(count == n) then
                arg = line(i:)
            else
                arg = ' '
            endif
        else
            arg = line(i:j-1)
        endif
       end function getArg
      end module parse
    
!program lineParse
!    use parse
!    implicit none

    ! Variables
!    CHARACTER(20) :: str1; str2; str3; str4; str5
    ! Body of lineParse
!    line = 'value-a; value-bcd; value ef; value-ghi'    ! simulate read of line
!    str1 = getArg(1)
!    str2 = getArg(2)
!    str3 = getArg(3)
!    str4 = getArg(4)
!    str5 = getArg(5)
!   print *, str1, str2, str3, str4, str5

! end program lineParse