! evaluates correlation coefficient of vectors a,b
       subroutine corcoef(a,b,n,res)
       implicit none
       integer n
       real a(n),b(n),res
       
       integer i
       real ab,am,bm,a2,b2
       
       res=0
       if(maxval(a(1:n))-minval(a(1:n)).eq.0.)return
       
       if(maxval(b(1:n))-minval(b(1:n)).eq.0.)return

       ab=0
       am=0
       bm=0
       a2=0
       b2=0
       do i=1,n
         ab=ab+a(i)*b(i)
         am=am+a(i)
         bm=bm+b(i)
         a2=a2+a(i)**2
         b2=b2+b(i)**2
       enddo
       ab=ab/real(n)
       am=am/real(n)
       bm=bm/real(n)
       a2=a2/real(n)
       b2=b2/real(n)

       res=(ab-am*bm)/((a2-am**2)*(b2-bm**2))**0.5

       end subroutine
