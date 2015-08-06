#! /bin/env pike
#include <args.h>

class Buffer{
	inherit OpenCL.clbuffer;
	extern string type;
	extern string mode;
	void create(object data)
	{
		::create(mode,type,`*(1.0,@Octave.dims(data)),0);
		set(data);
	}
}
class ReadWriteUInt8{ inherit Buffer; string mode="rw";string type="uint8";}
class ReadWriteUInt16{ inherit Buffer; string mode="rw";string type="uint16";}
class ReadWriteUInt32{ inherit Buffer; string mode="rw";string type="uint32";}
class ReadWriteUInt64{ inherit Buffer; string mode="rw";string type="uint64";}
class ReadWriteInt8{ inherit Buffer; string mode="rw";string type="int8";}
class ReadWriteInt16{ inherit Buffer; string mode="rw";string type="int16";}
class ReadWriteInt32{ inherit Buffer; string mode="rw";string type="int32";}
class ReadWriteInt64{ inherit Buffer; string mode="rw";string type="int64";}
class ReadWriteSingle{ inherit Buffer; string mode="rw";string type="single";}
class ReadWriteDouble{ inherit Buffer; string mode="rw";string type="double";}
class ReadOnlyUInt8{ inherit Buffer; string mode="ro";string type="uint8";}
class ReadOnlyUInt16{ inherit Buffer; string mode="ro";string type="uint16";}
class ReadOnlyUInt32{ inherit Buffer; string mode="ro";string type="uint32";}
class ReadOnlyUInt64{ inherit Buffer; string mode="ro";string type="uint64";}
class ReadOnlyInt8{ inherit Buffer; string mode="ro";string type="int8";}
class ReadOnlyInt16{ inherit Buffer; string mode="ro";string type="int16";}
class ReadOnlyInt32{ inherit Buffer; string mode="ro";string type="int32";}
class ReadOnlyInt64{ inherit Buffer; string mode="ro";string type="int64";}
class ReadOnlySingle{ inherit Buffer; string mode="ro";string type="single";}
class ReadOnlyDouble{ inherit Buffer; string mode="ro";string type="double";}

class MyOpenCL{
	class KernelFunction(string funcname,array|void  gsize,array|void lsize){/*{{{*/
		object k;
		object `()clbuffer res,mixed ... args)
		{
			if(k==0){
				k=OpenCL.clkernel(funcname,gsize||res->dims,lsize||res->dims,0);
			}
			k(res,@args);
			return res;
		}
	};/*}}}*/
	object cl=OpenCL.opencl();
	KernelFunction ifmerge=KernelFunction("ifmerge");
	void create()
	{
		cl->initializes(0,0);
		cl->addfile("spear-modules/OpenCLMergeGraph.pmod/cl/merge-graph.cl");
		cl->build();
	}
}

object my=MyOpenCL();

object merge_graph(object data,float cost)
{
	[int w,int h,int d,int n]=Octave.dims(data);
	array classid_nearbylistidx=allocate(w*h*d);
	array nearbylist=({});
	array nearbypairs=({});
	for(int i=1;i<w-1;i++){/*{{{*/
		for(int j=1;j<h-1;j++){
			for(int t=1;t<d-1;t++){
				int curr=(t*d+j)*h+i;
				classid_nearbylistidx[curr]=sizeof(nearbylist);
				foreach(({({0,0,-1}),({0,0,1}),({0,-1,0}),({0,1,0}),({-1,0,0}),({1,0,0})}),[int di,int dj,int dt]){
					int target=((t+dt)*d+(j+dj))*h+(i+di);
					nearbylist+=({target});
					if(target>curr){
						nearbypairs+=({({curr,target})});
					}
				}
			}
		}
	}
	for(int i=0;i<w;i++){
		for(int j=0;j<h;j++){
			for(int t=0;t<d;t++){
				if(i==0||i==w-1||j==0||j==h-1||t==0||t==d-1){
					int curr=(t*d+j)*h+i;
					classid_nearbylistidx[curr]=sizeof(nearbylist);
					foreach(({({0,0,-1}),({0,0,1}),({0,-1,0}),({0,1,0}),({-1,0,0}),({1,0,0})}),[int di,int dj,int dt]){
						if(i+di>=0&&i+di<w&&j+dj>=0&&j+dj<h&&t+dt>=0&&t+dt<d){
							int target=((t+dt)*d+(j+dj))*h+(i+di);
							nearbylist+=({target});
							if(target>curr){
								nearbypairs+=({({curr,target})});
							}
						}
					}
				}
			}
		}
	}/*}}}*/
	object classid_minvals_o=Octave.feval("reshape",1,data,Octave.RowVector(({w*h*d,n})))[0];
	object classid_maxvals_o=Octave.feval("reshape",1,data,Octave.RowVector(({w*h*d,n})))[0];

	/* 从任何像素应该能够找到这个像素属于的类 id=(t*d+j)*h+i*/
	object pixel_classid_o=ReadOnlyUInt32(Octave.result(sprintf("reshape(uint32([0:%d]),%d,%d,%d)",w*h*d-1,w,h,d)));
	object classid_nearbylistidx_o=ReadOnlyUInt32(Octave.convert(Octave.RowVector(classid_nearbylistidx),"uint32"));
	object classid_entropy_o=ReadOnlySingle(Octave.FloatRowVector(allocate(w*h*d,cost)));
	object classid_count_o=ReadOnlyUInt32(Octave.convert(Octave.FloatRowVector(allocate(w*h*d,1)),"uint32"));
	object nearbylist_o=ReadOnlyUInt32(Octave.convert(Octave.RowVector(nearbylist),"uint32"));
	object nearbypairs_ifmerge_entropy_o=ReadWriteSingle(Octave.FloatRowVector(allocate(sizeof(nearbypairs))));
	object nearbypairs_ifmerge_count_o=ReadWriteUInt32(Octave.convert(Octave.FloatRowVector(allocate(sizeof(nearbypairs),2)),"uint32"));
	object nearbypairs_ifmerge_minvals_o=ReadWriteSingle(Octave.FloatRowVector(allocate(sizeof(nearbypairs,({0.0})*n))));
	object nearbypairs_ifmerge_maxvals_o=ReadWriteSingle(Octave.FloatRowVector(allocate(sizeof(nearbypairs,({0.0})*n))));
	object nearbypairs_o=ReadOnlyUInt32(Octave.convert(Octave.Matrix(nearbypairs),"uint32"));

	my->ifmerge(nearbypairs_o,
			nearbypairs_ifmerge_count_o,
			nearbypairs_ifmerge_minvals_o,
			nearbypairs_ifmerge_maxvals_o,
			nearbypairs_ifmerge_entropy_o,
			pixel_classid_o,
			classid_count_o,
			classid_minvals_o,
			classid_maxvals_o,
			classid_entropy_o,
			classid_nearbylistidx_o,
			nearbylist_o
			);

	my->bestmerge(classid_count_o,
			classid_nearbylistidx_o,
			nearbylist_o,
			
}

int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	merge_graph(128,128,8);
}

/* 分阶段进行

	 * 生成归并元数组
	 * 生成相邻数组，归并元相邻边偏移 (归并元数量)
	 * 生成相邻归并结果表 (相邻边数量)
	 * 搜索最佳并行归并对数组，生成归并对数组 (归并元数量)
	 * 执行归并 (归并对数组数量)
	 * 更新相邻表 (归并对数组数量)
	 * 生成归并对数组相邻边数组 (归并对数组数量)
	 * 更新相邻归并结果表 (归并对数组相邻边数量)
	 * 增量搜索最佳并行归并组，生成归并对数组 (归并组数量)
	 * 循环

	 */


