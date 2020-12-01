      SUBROUTINE CONTRACTION24(S,LT,RT,NDI)
C>       DOUBLE CONTRACTION BETWEEN 4TH ORDER AND 2ND ORDER  TENSOR
C>      INPUT:
C>       LT - RIGHT 2ND ORDER TENSOR
C>       RT - LEFT  4TH ODER TENSOR
C>      OUTPUT:
C>       S - DOUBLE CONTRACTED TENSOR (2ND ORDER)
       IMPLICIT NONE
       INCLUDE 'PARAM_UMAT.INC'
C
       INTEGER I1,J1,K1,L1,NDI
C
       DOUBLE PRECISION LT(NDI,NDI),RT(NDI,NDI,NDI,NDI)
       DOUBLE PRECISION S(NDI,NDI)
       DOUBLE PRECISION AUX
C
      DO K1=1,NDI
       DO L1=1,NDI
         AUX=ZERO
        DO I1=1,NDI
         DO J1=1,NDI
           AUX=AUX+LT(K1,L1)*RT(I1,J1,K1,L1)
        END DO
       END DO
          S(K1,L1)=AUX
      END DO
      END DO
       RETURN
      END SUBROUTINE CONTRACTION24
