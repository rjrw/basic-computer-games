  10 PRINT TAB(30);"TIC-TAC-TOE"
  20 PRINT TAB(15);"CREATIVE COMPUTING  MORRISTOWN, NEW JERSEY"
  30 PRINT:PRINT:PRINT
  40 PRINT "THE BOARD IS NUMBERED:"
  50 PRINT " 1  2  3"
  60 PRINT " 4  5  6"
  70 PRINT " 7  8  9"
  80 PRINT:PRINT:PRINT
  90 DIM S(9)
 100 INPUT"DO YOU WANT 'X' OR 'O'";C$
 110 IF C$="X"THEN 530
 120 P$="O":Q$="X"
 130 G=-1:H=1:IF S(5)<>0 THEN 150
 140 S(5)=-1:GOTO 500
 150 IF S(5)<>1 THEN 180
 160 IF S(1)<>0 THEN 220
 170 S(1)=-1:GOTO 500
 180 IF S(2)=1 AND S(1)=0 THEN 450
 190 IF S(4)=1 AND S(1)=0 THEN 450
 200 IF S(6)=1 AND S(9)=0 THEN 490
 210 IF S(8)=1 AND S(9)=0 THEN 490
 220 IF G<>1 THEN 280
 230 J=3*INT((M-1)/3)+1
 240 IF 3*INT((M-1)/3)+1=M THEN K=1
 250 IF 3*INT((M-1)/3)+2=M THEN K=2
 260 IF 3*INT((M-1)/3)+3=M THEN K=3
 270 GOTO 290
 280 FOR J=1 TO 7 STEP 3:FOR K=1 TO 3
 290 GOSUB 620
 300 GOTO 310
 310 IF X=1 THEN 500
 320 IF G=1 THEN 340
 330 NEXT K,J
 340 IF S(5)=G THEN 360
 350 GOTO 400
 360 IF S(3)=G AND S(7)=0 THEN 480
 370 IF S(9)=G AND S(1)=0 THEN 450
 380 IF S(7)=G AND S(3)=0 THEN 470
 390 IF S(9)=0 AND S(1)=G THEN 490
 400 IF G=-1 THEN G=1:H=-1:GOTO 220
 410 IF S(9)=1 AND S(3)=0 THEN 460
 420 FOR I=2 TO 9:IF S(I)<>0 THEN 440
 430 S(I)=-1:GOTO 500
 440 NEXT I
 450 S(1)=-1:GOTO 500
 460 IF S(1)=1 THEN 420
 470 S(3)=-1:GOTO 500
 480 S(7)=-1:GOTO 500
 490 S(9)=-1
 500 PRINT:PRINT"THE COMPUTER MOVES TO..."
 510 GOSUB 860
 520 GOTO 540
 530 P$="X":Q$="O"
 540 PRINT:INPUT"WHERE DO YOU MOVE";M
 550 IF M=0 THEN PRINT"THANKS FOR THE GAME.":GOTO 1160
 560 IF M>9 THEN 580
 570 IF S(M)=0 THEN 590
 580 PRINT"THAT SQUARE IS OCCUPIED.":PRINT:PRINT:GOTO 540
 590 G=1:S(M)=1
 600 GOSUB 860
 610 GOTO 130
 620 X=0
 630 IF S(J)<>G THEN 670
 640 IF S(J+2)<>G THEN 710
 650 IF S(J+1)<>0 THEN 740
 660 S(J+1)=-1:X=1:GOTO 850
 670 IF S(J)=H THEN 740
 680 IF S(J+2)<>G THEN 740
 690 IF S(J+1)<>G THEN 740
 700 S(J)=-1:X=1:GOTO 850
 710 IF S(J+2)<>0 THEN 740
 720 IF S(J+1)<>G THEN 740
 730 S(J+2)=-1:X=1:GOTO 850
 740 IF S(K)<>G THEN 780
 750 IF S(K+6)<>G THEN 820
 760 IF S(K+3)<>0 THEN 850
 770 S(K+3)=-1:X=1:GOTO 850
 780 IF S(K)=H THEN 850
 790 IF S(K+6)<>G THEN 850
 800 IF S(K+3)<>G THEN 850
 810 S(K)=-1:X=1:GOTO 850
 820 IF S(K+6)<>0 THEN 850
 830 IF S(K+3)<>G THEN 850
 840 S(K+6)=-1:X=1:GOTO 850
 850 RETURN
 860 PRINT:FOR I=1 TO 9:PRINT" ";:IF S(I)<>-1 THEN 880
 870 PRINT Q$" ";:GOTO 910
 880 IF S(I)<>0 THEN 900
 890 PRINT"  ";:GOTO 910
 900 PRINT P$" ";
 910 IF I<>3 AND I<>6 THEN 940
 920 PRINT:PRINT"---+---+---"
 930 GOTO 960
 940 IF I=9 THEN 960
 950 PRINT"!";
 960 NEXT I:PRINT:PRINT:PRINT
 970 FOR I=1 TO 7 STEP 3
 980 IF S(I)<>S(I+1)THEN 1020
 990 IF S(I)<>S(I+2)THEN 1020
1000 IF S(I)=-1 THEN 1140
1010 IF S(I)=1 THEN 1130
1020 NEXT I:FOR I=1 TO 3:IF S(I)<>S(I+3)THEN 1060
1030 IF S(I)<>S(I+6)THEN 1060
1040 IF S(I)=-1 THEN 1140
1050 IF S(I)=1 THEN 1130
1060 NEXT I:FOR I=1 TO 9:IF S(I)=0 THEN 1080
1070 NEXT I:GOTO 1150
1080 IF S(5)<>G THEN 1110
1090 IF S(1)=G AND S(9)=G THEN 1120
1100 IF S(3)=G AND S(7)=G THEN 1120
1110 RETURN
1120 IF G=-1 THEN 1140
1130 PRINT"YOU BEAT ME!! GOOD GAME.":GOTO 1160
1140 PRINT"I WIN, TURKEY!!!":GOTO 1160
1150 PRINT"IT'S A DRAW. THANK YOU."
1160 END
