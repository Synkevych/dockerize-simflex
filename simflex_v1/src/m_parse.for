! Adapted from example code in
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
