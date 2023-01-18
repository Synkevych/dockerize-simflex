! From intel fortran forum
! https://software.intel.com/en-us/forums/intel-visual-fortran-compiler-for-windows/topic/271933
!Here are functions you need to convert any date into
!a unique integer, which allows easy time interval arithmetic.
      FUNCTION julian_date (yyyy, mm, dd) RESULT (julian)
      IMPLICIT NONE
! converts calendar date to Julian date
! cf Fliegel & Van Flandern, CACM 11(10):657, 1968
! example: julian_date(1970,1,1)=2440588
       INTEGER,INTENT(IN) :: yyyy,mm,dd
      INTEGER :: julian
        julian = dd-32075+1461*(yyyy+4800+(mm-14)/12)/4 + 
     &    367*(mm-2-((mm-14)/12)*12)/12- 
     &    3*((yyyy + 4900 + (mm - 14)/12)/100)/4
      END FUNCTION julian_date

      SUBROUTINE get_ymd (jd, yyyy, mm, dd)
      IMPLICIT NONE
! expands a Julian date into a calendar date
! cf Fliegel & Van Flandern, CACM 11(10):657, 1968
       INTEGER,INTENT(IN) :: jd
       INTEGER,INTENT(OUT) :: yyyy,mm,dd
      INTEGER :: l,n
      l = jd + 68569
      n = 4*l/146097
      l = l - (146097*n + 3)/4
       yyyy = 4000*(l + 1)/1461001
      l = l - 1461*yyyy/4 + 31
       mm = 80*l/2447
      dd = l - 2447*mm/80
      l = mm/11
      mm = mm + 2 - 12*l
        yyyy = 100*(n - 49) + yyyy + l
       END SUBROUTINE get_ymd