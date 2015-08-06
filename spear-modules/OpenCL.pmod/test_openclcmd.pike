int main(int argc,array argv)
{
	array res;
	res=Octave.feval("openclcmd",1);
	res=Octave.feval("openclcmd",0,"initialize",0,0);
	res=Octave.feval("openclcmd",0,"addfile","spear-modules/Octave.pmod/opencl-toolbox/cl/simple_add.cl");
	res=Octave.feval("openclcmd",0,"build");
	res=Octave.feval("openclcmd",1,"create_buffer","ro",4*9);
	float buffA=res[0];
	write("%O\n",res);
	res=Octave.feval("openclcmd",1,"create_buffer","ro",4*9);
	float buffB=res[0];
	write("%O\n",res);
	res=Octave.feval("openclcmd",1,"create_buffer","rw",4*9);
	float buffC=res[0];
	write("%O\n",res);
	res=Octave.feval("openclcmd",0,"set_buffer",0,buffA,Octave.FloatRowVector(({1,2,3,4,5,6,7,8,9})));
	res=Octave.feval("openclcmd",0,"set_buffer",0,buffB,Octave.FloatRowVector(({1,2,3,4,5,6,7,8,9})));
	res=Octave.feval("openclcmd",1,"get_buffer",0,buffA,9,"single");
	write("%O\n",res);
	res=Octave.feval("openclcmd",1,"get_buffer",0,buffB,9,"single");
	write("%O\n",res);
	//res=Octave.feval("uint32",1,Octave.RowVector(({9,0,0})));
	//object arg1=res[0];
	//write("%O\n",arg1);
	//res=Octave.feval("uint32",1,Octave.RowVector(({9,0,0})));
	//object arg2=res[0];
	//write("%O\n",arg2);
	res=Octave.feval("openclcmd",1,"create_kernel",Octave.convert(Octave.RowVector(({9,0,0})),"uint32"),Octave.convert(Octave.RowVector(({9,0,0})),"uint32"),"add");
	write("%O\n",res);
	float kid=res[0];

	res=Octave.feval("openclcmd",1,"set_kernel_args",kid,0,buffA,Octave.RowVector(({})),0);
	res=Octave.feval("openclcmd",1,"set_kernel_args",kid,1,buffB,Octave.RowVector(({})),0);
	res=Octave.feval("openclcmd",1,"set_kernel_args",kid,2,buffC,Octave.RowVector(({})),0);
	//res=Octave.feval("uint32",1,9);
	//object arg3=res[0];
	//write("%O\n",arg3);
	res=Octave.feval("openclcmd",1,"set_kernel_args",kid,3,-1,Octave.convert(9,"uint32"),0);
	res=Octave.feval("openclcmd",1,"execute_kernel",0,kid);
	res=Octave.feval("openclcmd",1,"wait_queue",0);
	res=Octave.feval("openclcmd",1,"get_buffer",0,buffC,9,"single");
	write("%O\n",res);

	Octave.exit();
}
