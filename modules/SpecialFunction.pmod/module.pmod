#! /bin/env pike
object erf_cache=CacheLite.Cache(1024,1);
private float _erf(float x)
{
	/*

		 :<math>\begin{array}{rcl}
		 \tau & = & t\cdot\exp\left(-x^{2}-1.26551223+1.00002368\cdot t+0.37409196\cdot t^{2}+0.09678418\cdot t^{3}\right.\\
		  &  & \qquad-0.18628806\cdot t^{4}+0.27886807\cdot t^{5}-1.13520398\cdot t^{6}+1.48851587\cdot t^7\\
			 &  & \qquad\left.-0.82215223\cdot t^{8}+0.17087277\cdot t^{9}\right)
			 \end{array}</math>
		 */
	array a=reverse(({
-1.26551223,1.00002368,0.37409196,0.09678418,
-0.18628806,0.27886807,-1.13520398,1.48851587,
-0.82215223,0.17087277,
			}));
	float t=1/(1+0.5*abs(x));
	float T=0.0;
	for(int i=0;i<sizeof(a);i++){
		T=T*t+a[i];
	}
	T+=-x*x;
	T=t*exp(T);

	if(x==0.0)
		return 0.0;
	else if(x>0)
		return 1-T;
	else
		return T-1;
}
float erf(float x)
{
	return erf_cache(x,_erf,x);
}
#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	for(float x=0.0;x<=3.5;x=Norm.floor(x+0.05,2)){
		write("%f %0.7f\n",x,erf(x));
	}
	HANDLE_ARGUMENTS();
}

