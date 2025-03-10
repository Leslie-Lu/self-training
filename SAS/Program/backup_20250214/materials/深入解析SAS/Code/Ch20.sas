/*ex 20.3*/
proc optmodel;
	/*declare variables*/
	var x1>=0, x2>=0, x3>=0,x4>=0,s1>=0,s2>=0;
	/*declare constraints*/
	con con1: 3*x1+x2+x3=3;
	con con2:4*x1+3*x2-s1+x4=6;
	con con3: x1+2*x2+s2=4;
	/*declare objective*/
	min w=x3+x4;
	solve with lp/solver=ps;
	print x1 x2 x3 x4 s1 s2;
	print x1.rc x2.rc x3.rc x4.rc s1.rc s2.rc; 
	con con4: x3+x4=0;
	min z=4*x1+x2;
	solve obj z with lp/solver=ps /*basis=warmstart*/;
	print x1 x2 x3 x4 s1 s2;
	print x1.rc x2.rc x3.rc x4.rc s1.rc s2.rc; 
quit;

proc optmodel;
	var x1>=0, x2>=0;
	con con1: 3*x1+x2=3;
	con con2:4*x1+3*x2>=6;
	con con3: x1+2*x2<=4;
	min z=4*x1+x2;
	solve with lp/solver=ps;
	print x1 x2;
quit;

***ex20.4****;

proc optmodel;
	var x1>=0, x2>=0;
	con time: 2*x1+x2<=40;
	con resource: x1+1.5*x2<=50;
	con demand1: x1>=6;
	con demand2: x1<=10;
	con demand3: x2<=30;
	max z=160*x1+120*x2;
	solve with lp/solver=ds;
	print x1 x2;
	print time.dual resource.dual demand1.dual demand2.dual demand3.dual;
quit;

proc optmodel;
	var x1>=0, x2>=0;
	con time: 2*x1+x2<=40;
	con resource: x1+1.5*x2<=50;
	con demand1: x1>=6;
	con demand2: x1<=10;
	con demand3: x2<=30;
	max z=160*x1+120*x2;
	solve with lp/solver=ii;
	print x1 x2;
	print time.dual resource.dual demand1.dual demand2.dual demand3.dual;
quit;





