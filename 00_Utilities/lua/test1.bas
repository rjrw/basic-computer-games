5 REM INPUT"DO YOU WANT 'X' OR 'O'";C$
7 REM PRINT "READ ";C$
10 A$="AAA":B=128-4*8:C=B*2
20 PRINT "HELLO";10,10,10+10,A$,B,C,-10
30 GOTO 50
40 PRINT "SHOULDN'T COME HERE"
50 IF B=1 THEN PRINT "FAILED":PRINT" AND AGAIN"
60 IF B=B THEN 90
70 PRINT "FAILED"
80 IF B<>B THEN 100
90 PRINT "PASSED"
100 IF B=B THEN PRINT "PASSED"
110 GOSUB 1240
120 PRINT "RETURNED FROM SUB"
130 IF B=B THEN GOSUB 1240 : PRINT "RETURNED FROM IF GOSUB"
140 IF B<>B THEN GOSUB 1240 : PRINT "FAILED"
150 DIM S(9)
160 S(1+1)=2*5:PRINT S(1),S(2)
170 FOR I=1 TO 5:PRINT I:NEXT
180 FOR I=5 TO 1 STEP -1:PRINT I:NEXT
190 FOR I=0 TO 4
200 ON I GOTO 210,220,230
205 PRINT "FALL THROUGH":GOTO 240
210 PRINT 210:GOTO 240
220 PRINT 220:GOTO 240
230 PRINT 230:GOTO 240
240 NEXT
250 PRINT RND(1):PRINT RND(0)
260 END
1240 PRINT "CALLED SUB"
1250 RETURN
1260 STOP
