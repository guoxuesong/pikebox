#pragma OPENCL EXTENSION cl_amd_printf:enable
__kernel void ifmerge(
		__global float *out, 
		__global const unsigned int *pixel_classid, 
		__global const unsigned int *classid_minvals,
		__global const unsigned int *classid_maxvals,
		__global const float *classid_entropy,
		__global const unsigned int *classid_nearbylistidx,
		__global const unsigned int *nearbylist
		) {

	for(int i=0;i<3;i++){
		int gid = get_global_id(i);
		int lid = get_local_id(i);
		int gsize = get_global_size(i);
		int lsize = get_local_size(i);
		int groups = get_num_groups(i);
		printf("DIM %d: %d %d %d %d %d; ",i,gid,lid,gsize,lsize,groups);
	}
	printf("\n");

	int pos=(get_global_id(2)*get_global_size(1)+get_global_id(1))*get_global_size(0)+get_global_id(0);
	wait_group_events(2,&t);
	//barrier(CLK_LOCAL_MEM_FENCE);
	out[pos]=buff1[pos]+buff2[pos];
	printf("res=%d x=%d y=%d\n",out[pos],x[pos],y[pos]);
}

