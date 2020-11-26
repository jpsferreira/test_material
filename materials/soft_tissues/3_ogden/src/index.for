      SUBROUTINE INDEXX(STRESS,DDSDDE,SIG,TNG,NTENS,NDI)
C>    INDEXATION: FULL SIMMETRY  IN STRESSES AND ELASTICITY TENSORS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER II1(6),II2(6),NTENS,NDI,I1,J1
      DOUBLE PRECISION STRESS(NTENS),DDSDDE(NTENS,NTENS)
      DOUBLE PRECISION SIG(NDI,NDI),TNG(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION PP1,PP2
C
      II1(1)=1
      II1(2)=2
      II1(3)=3
      II1(4)=1
      II1(5)=1
      II1(6)=2
C
      II2(1)=1
      II2(2)=2
      II2(3)=3
      II2(4)=2
      II2(5)=3
      II2(6)=3
C
      DO I1=1,NTENS
C       STRESS VECTOR
         STRESS(I1)=SIG(II1(I1),II2(I1))
         DO J1=1,NTENS
C       DDSDDE - FULLY SIMMETRY IMPOSED
            PP1=TNG(II1(I1),II2(I1),II1(J1),II2(J1))
            PP2=TNG(II1(I1),II2(I1),II2(J1),II1(J1))
            DDSDDE(I1,J1)=(ONE/TWO)*(PP1+PP2)
         END DO
      END DO
C
      RETURN
C
      END SUBROUTINE INDEXX
