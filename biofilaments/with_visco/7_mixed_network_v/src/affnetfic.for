      SUBROUTINE AFFNETFIC(SFIC,CFIC,F,MF0,RW,FILPROPS,AFFPROPS,
     1                        EFI,NOEL,DET,NDI)
C>    AFFINE NETWORK: 'FICTICIOUS' CAUCHY STRESS AND ELASTICITY TENSOR
C>    MOBILE LINKERS
      IMPLICIT NONE
      INCLUDE 'PARAM_UMAT.INC'
C
      INTEGER NDI,I1,J1,K1,L1,M1,NOEL,IM1
      DOUBLE PRECISION SFIC(NDI,NDI),SFILFIC(NDI,NDI),
     1                  CFIC(NDI,NDI,NDI,NDI),F(NDI,NDI),MF0(NWP,NDI),
     2                 RW(NWP),CFILFIC(NDI,NDI,NDI,NDI)
      DOUBLE PRECISION FILPROPS(8),AFFPROPS(2),MFI(NDI),MF0I(NDI)
      DOUBLE PRECISION DET,AUX,PI,LAMBDAI,DWI,DDWI,RWI,LAMBDAIC
      DOUBLE PRECISION L,R0F,R0,MU0,B0,BETA,LAMBDA0,RHO,N,FI,FFI,DTIME
      DOUBLE PRECISION R0C,ETAC,LAMBDAIF
      DOUBLE PRECISION B,FRIC,FFMAX,ANG,EFI,FRAC(4),RU0(NWP),RU
      DOUBLE PRECISION VARA,AVGA,MAXA,AUX0,FFIC,SUMA,RHO0,DIRMAX(NDI)

C
C     FILAMENT
      L       = FILPROPS(1)
      R0F     = FILPROPS(2)
      R0C     = FILPROPS(3)
      ETAC    = FILPROPS(4)      
      MU0     = FILPROPS(5)
      BETA    = FILPROPS(6)
      B0      = FILPROPS(7)
      LAMBDA0 = FILPROPS(8)
C     NETWORK
      N       = AFFPROPS(1)
      B       = AFFPROPS(2)      
C
      PI=FOUR*ATAN(ONE)
      AUX=N*(DET**(-ONE))*FOUR*PI
      CFIC=ZERO
      SFIC=ZERO
C      
       RHO=ONE
       R0=R0F+R0C
C       
C       CALL DENSITY(RHO0,ZERO,B,EFI)
C        
C             OPEN (UNIT=20,FILE="projfil.out",action="write",
C     1 status="replace")
     
C        LOOP OVER THE INTEGRATION DIRECTIONS
      DO I1=1,NWP
C
       MFI=ZERO
       MF0I=ZERO
       DO J1=1,NDI
        MF0I(J1)=MF0(I1,J1)
       END DO
       RWI=RW(I1)
C
       CALL DEFFIL(LAMBDAI,MFI,MF0I,F,NDI)
C        
       CALL BANGLE(ANG,F,MFI,NOEL,NDI)
C      
       CALL DENSITY(RHO,ANG,B,EFI)
C       
       IF((ETAC.GT.ZERO).AND.(ETAC.LT.ONE))THEN
C
        LAMBDAIF=ETAC*(R0/R0F)*(LAMBDAI-ONE)+ONE
        LAMBDAIC=(LAMBDAI*R0-LAMBDAIF*R0F)/R0C
       ELSE
        LAMBDAIF=LAMBDAI
        LAMBDAIC=ZERO
       ENDIF   
        

C     
       CALL FIL(FI,FFI,DWI,DDWI,LAMBDAIF,LAMBDA0,L,R0,MU0,BETA,B0)          
C       
       CALL SIGFILFIC(SFILFIC,RHO,LAMBDAIF,DWI,MFI,RWI,NDI)
C
       CALL CSFILFIC(CFILFIC,RHO,LAMBDAIF,DWI,DDWI,MFI,RWI,NDI)
C     
C
       DO J1=1,NDI
        DO K1=1,NDI
         SFIC(J1,K1)=SFIC(J1,K1)+AUX*SFILFIC(J1,K1)
         DO L1=1,NDI
          DO M1=1,NDI
           CFIC(J1,K1,L1,M1)=CFIC(J1,K1,L1,M1)+AUX*CFILFIC(J1,K1,L1,M1)
          END DO
         END DO
        END DO
       END DO  
C             
      END DO  
C        
      RETURN
      END SUBROUTINE AFFNETFIC
