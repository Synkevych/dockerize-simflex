! evaluates correlation coefficient of vectors a,b
       subroutine corcoef(a,b,n,res)
       implicit none
       integer n
       real a(n),b(n),res

       integer i
       real am,bm,siga,sigb

       res=0
       if(maxval(a(1:n))-minval(a(1:n)).eq.0.)return

       if(maxval(b(1:n))-minval(b(1:n)).eq.0.)return

       am=0
       bm=0
       do i=1,n
         am=am+a(i)
         bm=bm+b(i)
       enddo

       am=am/real(n)
       bm=bm/real(n)

       siga=0
       sigb=0
       res=0
       do i=1,n
         siga=siga+(a(i)-am)**2
         sigb=sigb+(b(i)-bm)**2
         res=res+(a(i)-am)*(b(i)-bm)
       enddo

       siga=siga/real(n)
       sigb=sigb/real(n)
       res=res/real(n)
       res=res/sqrt(siga*sigb)

       end subroutine
