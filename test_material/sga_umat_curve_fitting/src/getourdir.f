      SUBROUTINE GETOUTDIR(OUTDIR, LENOUTDIR)
C
      INCLUDE 'aba_param.inc'
C 
      CHARACTER*256 OUTDIR
      INTEGER LENOUTDIR
C
      CALL GETCWD(OUTDIR)
C        OUTDIR=OUTDIR(1:SCAN(OUTDIR,'\',BACK=.TRUE.)-1)
      LENOUTDIR=LEN_TRIM(OUTDIR)
C
      RETURN
      END SUBROUTINE GETOUTDIR