#ifdef PROFILING
mapping profiling_data=([]);
float profiling_total=0.0;
int profiling_time0=time();
int profiling_last_diff=0;
#define PROFILING_BEGIN(X) profiling(X,1,lambda(){
#define PROFILING_FUNCTION_BEGIN(X) return profiling(X,1,lambda(){
#define PROFILING_PAUSE(X) profiling(X,-1,lambda(){
#define PROFILING_END });
#define PROFILING_FINAL profiling_final();
void profiling_final()/*{{{*/
{
	foreach(sort(indices(profiling_data)),string key){
		werror("profiling: %s %f (%f%%)\n",key,profiling_data[key],profiling_data[key]/profiling_total*100);
	}
}/*}}}*/
mixed profiling(string key,int sig,function f)/*{{{*/
{
	int t=time();
	float tb=time(t);
	mixed res=f();
	float te=time(t);
	profiling_data[key]+=sig*(te-tb);
	profiling_total+=sig*(te-tb);
	//werror("profiling: %s %f %f %f\n",key,te-tb,profiling_data[key],profiling_data[key]/profiling_total);
	if(time()-profiling_time0>profiling_last_diff+10){
		profiling_last_diff=time()-profiling_time0;
		profiling_final();
	}
	return res;
}/*}}}*/
#else
#define PROFILING_BEGIN(X) 
#define PROFILING_FUNCTION_BEGIN(X) 
#define PROFILING_END 
#define PROFILING_FINAL
#endif

