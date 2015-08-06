class opencl{
	array platforms=({});
	int selected_platform=1;  
	int selected_device=1;
	array files_loaded=({});
	int built=0;        

	void create()
	{
		//platforms=(array)(Octave.feval("openclcmd",1)[0]);//XXX
	}
	void initializes(int platform,int device)
	{
		Octave.feval("openclcmd",0,"initialize",0,0);
		selected_platform = platform;
		selected_device = device;
	}
	void addfile(string filename)
	{
		files_loaded+=({filename});
		Octave.feval("openclcmd",0,"addfile",filename);
	}
	void build()
	{
		Octave.feval("openclcmd",0,"build");
		built=1;
	}
	void wait(int device_id)
	{
		Octave.feval("openclcmd",0,"wait_queue",device_id);
	}
}
class clbuffer{
	int id;
	int device;
	int num_bytes;
	int num_elems;
	array dims;
	string type;
	string mode;

	void create(string _mode, string _type, int nelems, int _device)
	{
		mode=_mode;type=_type;device=_device;
		int unit_size = 1;
		switch(type){
			case "int64": case "uint64": case "double":
				unit_size = 8;
			break;
			case "int32": case "uint32": case "single":
					unit_size = 4;
			break;
			case "int16": case "uint16":
					unit_size = 2;
			break;
			case "int8": case "uint8": case "char": case "logical":
					unit_size = 1;
			break;
			case "local":
				unit_size = 0;
			break;
			default:
				unit_size = 1;
			break;
		}

		id = -1;
		if(unit_size > 0){
				id=Octave.feval("openclcmd",0,"create_buffer",mode,unit_size*nelems)[0]->value();
		}else{
				unit_size = 1; // Set to 1 so that we can properly compute the bytes
		}

		num_elems = nelems;
		num_bytes = unit_size*nelems;
	}
	object get()
	{
		if(id >= 0){
				object res=Octave.feval("openclcmd",1,"get_buffer",device,id,num_elems,type)[0];
				res=Octave.feval("reshape",1,res,Octave.RowVector(dims));
				return res;
		}
	}
	object set(object data)
	{
		if(id >= 0){
			data=Octave.feval(type,1,data)[0];
			dims=Octave.dims(data);
			Octave.feval("openclcmd",0,"set_buffer",device,id,data)[0];
		}
		return this;
	}
	void destroy()
	{
			Octave.feval("openclcmd",0,"destroy_buffer",id)[0];
	}
}
class clkernel
{
	int device=1;
	int id=0;
	void create(string kernelname, array global_dim, array local_dim, int target_device)
	{
		device=target_device;
		id=Octave.feval("openclcmd",1,"create_kernel",Octave.convert(Octave.RowVector(local_dim),"uint32"),Octave.convert(Octave.RowVector(global_dim),"uint32"),kernelname)[0]->value();
	}
	void `()(mixed ... args)
	{
		execute(@args);
	}

	void execute(mixed ... args)
	{
		foreach(args;int argnum;mixed arg){
			int kernelid = id;
			int bufferid = -1;
			mixed data;
			int nbytes = 0;
			if(objectp(arg)){
				if(object_program(arg)==clbuffer){
					bufferid = arg->id;
					if(bufferid < 0){
						//Local variable type:                        
						nbytes = arg->num_bytes;
					}
				}else if(object_program(arg)==clobject){
					bufferid = arg->buffer->id;
					if(bufferid < 0){
						//Local variable type:                        
						nbytes = arg->num_bytes;
					}
				}else{
					data=arg;
				}
			}else{
				data=arg;
			}
			Octave.feval("openclcmd",1,"set_kernel_args",kernelid,argnum,bufferid,data,nbytes);
		}
		Octave.feval("openclcmd",1,"execute_kernel",device,id);
	}
}
class clobject{}//XXX

void main()
{
	object cl=opencl();
	cl->initializes(0,0);
	cl->addfile("spear-modules/Octave.pmod/opencl-toolbox/cl/test.cl");
	cl->build();
	object buffA=clbuffer("ro","single",9,0)->set(Octave.RowVector(({1,2,3,4,5,6,7,8,9})));;
	object buffB=clbuffer("ro","single",9,0)->set(Octave.RowVector(({1,2,3,4,5,6,7,8,9})));;
	object buffC=clbuffer("rw","single",9,0);

	object k=clkernel("test",({9,0,0}),({9,0,0}),0);
	k->execute(buffC,buffA,buffB);
	object rC=buffC->get();
	werror("%O",rC->value());
	Octave.exit();
}
