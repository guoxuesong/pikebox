#include <assert.h>
float diffa(array a1,array a2)/*{{{*/
{
	float res=0.0;
	for(int i=0;i<max(sizeof(a1),sizeof(a2));i++){
		res+=pow(a1[i]-a2[i],2);
	}
	return pow(res,0.5);
}/*}}}*/
/* e=m/2*(ln(e)+ln(2*Math.pi))+ln(abs())/2=0
	 abs()=exp(-m*(ln(e)+ln(2*Math.pi)))=pow(d2,m);
	 d2=pow(exp(-m*(ln(e)+ln(2*Math.pi))),1/m);
 */
class SigmaBase{
	array sigma;
	array avgval,crossval;
	array sumval,crosssumval;
	int m,n;
	void update_crossval()/*{{{*/
	{
		array cc=crossval=allocate(m*m,0.0);
		for(int i=0;i<m;i++){
			for(int j=0;j<m;j++){
				cc[i*m+j]=sigma[i][j]+avgval[i]*avgval[j];
			}
		}
	}/*}}}*/
	object quantum(array val)/*{{{*/
	{
		val=map(val,Cast.floatfy);
		object res=this_program();
		int m=res->m=sizeof(val);
		int n=res->n=1;
		float abs=exp(-m*(1.0+log(2*Math.pi)));
		//werror("abs sould be %e\n",abs);
		float d2=pow(abs,1.0/m);
		//werror("d2 sould be %f\n",d2);
		res->sigma=allocate(m,allocate(m,0.0));
		for(int i=0;i<m;i++){
			res->sigma[i][i]=d2;
		}
		res->avgval=res->sumval=val;
		//sigma[i][j]=cc[i*m+j]-avgval[i]*avgval[j];
		res->update_crossval();
		res->crosssumval=res->crossval;
		//res->crossval=res->crosssumval=(res->sigma*({}))[*]+allocate(m*m,d2)[*];
		return res;
	}/*}}}*/
	private array val2cross(array val)/*{{{*/
	{
		array res=allocate(sizeof(val)*sizeof(val),0.0);
		for(int i=0;i<sizeof(val);i++){
			for(int j=0;j<sizeof(val);j++){
				res[i*sizeof(val)+j]=val[i]*val[j];
			}
		}
		return res;
	}/*}}}*/
#if 0
	private array quantum_expend(array val)/*{{{*/
	{
		array res=({});
		Foreach.foreach_multidim(allocate(sizeof(val),({0,1})),lambda(array d){
				res+=({map(map(d,`-,0.5),`*,0.7767)[*]+val[*]}); //配平0.7767使得原子的熵是0
				});
		return res;
	}/*}}}*/
#endif
	void create(array(array)|void vals,int|void quantum_flag,array|void count)/*{{{*/
	{
		if(vals==0)
			return;
		if(count==0)
			count=allocate(sizeof(vals),1);
		if(quantum_flag){
			array a=map(vals,quantum);
			object res=a[0];
			foreach(a[1..],object ob){
				res=res+ob;
			}
			this->sigma=res->sigma;
			this->avgval=res->avgval;
			this->crossval=res->crossval;
			this->sumval=res->sumval;
			this->crosssumval=res->crosssumval;
			this->m=res->m;
			this->n=res->n;
		}else{
			m=sizeof(vals[0]);
			n=`+(0,@count);
			//vals=`+(({}),@map(vals,quantum_expend));
			//count=map(count/({}),`*,sizeof(vals)/n)*({});
			int total=`+(0,@count);
			//werror("%d %d\n",sizeof(vals),sizeof(count));
			//werror("%O",count);
			avgval=allocate(sizeof(vals[0]),0.0);
			for(int i=0;i<sizeof(avgval);i++){
				avgval[i]=`+(0.0,@(column(vals,i)[*]*count[*]))/total;
			}
			array(array) cross=map(vals,val2cross);
			crossval=allocate(sizeof(cross[0]),0.0);
			for(int i=0;i<sizeof(crossval);i++){
				crossval[i]=`+(0.0,@(column(cross,i)[*]*count[*]))/total;
			}
			sumval=map(avgval,`*,n);
			crosssumval=map(crossval,`*,n);
			update_sigma();
		}
		//check
		/*
		print();
		array sigma1=allocate(m,allocate(m,0.0));
		for(int i=0;i<m;i++){
			for(int j=0;j<m;j++){
				foreach(vals,array val){
					sigma1[i][j]+=(val[i]-avgval[i])*(val[j]-avgval[j]);
				}
				sigma1[i][j]/=sizeof(vals);
			}
		}
		for(int i=0;i<m;i++){
			for(int j=0;j<m;j++){
				werror("%f ",sigma1[i][j]);
			}
			werror("\n");
		}*/
		

	}/*}}}*/
	void update_sigma()/*{{{*/
	{
		//werror("m=%d\n",m);
		sigma=allocate(m,allocate(m,0.0));
		for(int i=0;i<m;i++){
			for(int j=0;j<m;j++){
				//werror("i=%d j=%d\n",i,j);
				sigma[i][j]=crossval[i*m+j]-avgval[i]*avgval[j];
			}
		}
	}/*}}}*/
	object sub(object rhd)/*{{{*/
	{
		if(m==rhd->m){
			object res=this_program();
			res->m=m;
			res->n=n-rhd->n;
			if(res->n<=0)
				return 0;
			/*res->avgval=allocate(m,0.0);
			for(int i=0;i<m;i++){
				res->avgval[i]=(avgval[i]*n-rhd->avgval[i]*rhd->n)/(n-rhd->n);
			}
			res->crossval=allocate(m*m,0.0);
			for(int i=0;i<m*m;i++){
				res->crossval[i]=(crossval[i]*n-rhd->crossval[i]*rhd->n)/(n-rhd->n);
			}*/
			res->sumval=sumval[*]-rhd->sumval[*];
			res->avgval=map(res->sumval,`/,res->n);
			res->crosssumval=crosssumval[*]-rhd->crosssumval[*];
			res->crossval=map(res->crosssumval,`/,res->n);
			res->update_sigma();
			return res;
		}
	}/*}}}*/
	object add(object rhd)/*{{{*/
	{
		if(m==rhd->m){
			object res=this_program();
			res->m=m;
			res->n=n+rhd->n;
			/*res->avgval=allocate(m,0.0);
			for(int i=0;i<m;i++){
				res->avgval[i]=(avgval[i]*n+rhd->avgval[i]*rhd->n)/(n+rhd->n);
			}*/
			/*res->crossval=allocate(m*m,0.0);
			for(int i=0;i<m*m;i++){
				res->crossval[i]=(crossval[i]*n+rhd->crossval[i]*rhd->n)/(n+rhd->n);
			}*/
			res->sumval=sumval[*]+rhd->sumval[*];
			res->avgval=map(res->sumval,`/,res->n);
			res->crosssumval=crosssumval[*]+rhd->crosssumval[*];
			res->crossval=map(res->crosssumval,`/,res->n);
			res->update_sigma();
			return res;
		}
		/* std2'=(sum[(xi-(u1+delta1))^2]+sum[(xj-(u2+delta2))^2])/(n1+n2)
			     =(sum[((xi-u1)-delta)^2]+sum[((xj-u2)-delta2)^2])/(n1+n2)
					 =(sum[(xi-u1)^2-2*(xi-u1)*delta1+delta1^2]+sum[(xj-u2)^2-2*(xj-u2)*delta2+delta2^2])/(n1+n2)
					 =(std21*n1-2*delta1*diffsum1+delta1^2+std22*n2-2*delta2*diffsum2+delta2^2)/(n1+n2)
			 cov'=(sum[(xi-(ux1+delta1_x))*(yi-(uy1+delta1_y))]+sum[(xj-(ux2+delta2_x))*(yj-(uy2+delta2_y))]/(n1+n2)
			 		=(sum[((xi-ux1)-delta1_x)*((yi-uy1)-delta1_y)]+sum[((xj-ux2)-delta2_x)*((yj-uy2)-delta2_y)]/(n1+n2)
					 */
	}/*}}}*/
	float abs()/*{{{*/
	{
		float sum=0.0;
		if(m>2){
			for(int i=0;i<m;i++){
				float t=1.0;
				//werror("+");
				//werror("%f",t);
				for(int j=0;j<m;j++){
					t*=sigma[(j+i)%m][j];
					//werror("*%0.8f",sigma[(j+i)%m][j]);
				}
				sum+=t;
			}
			//werror("sum1=%f\n",sum);
			for(int i=0;i<m;i++){
				float t=1.0;
				//werror("-");
				//werror("%f",t);
				for(int j=0;j<m;j++){
					t*=sigma[(-j+i)%m][j];
					//werror("*%0.8f",sigma[(-j+i)%m][j]);
				}
				sum-=t;
			}
			//werror("sum2=%f\n",sum);
		}else if(m==2){
			sum=sigma[0][0]*sigma[1][1]-sigma[1][0]*sigma[0][1];
		}else if(m==1){
			sum=sigma[0][0];
		}

		if(sum>-1e-9)
			sum=max(sum,0.0);

		if(sum<0)
			werror("n=%d sigma=%O",n,sigma);

		return sum;
	}/*}}}*/
	Sigma select(int ... args)/*{{{*/
	{
		object res=Sigma();
		res->m=sizeof(args);
		res->n=n;
		res->avgval=Array.columns(({avgval}),args)*({});
		res->sigma=Array.columns(({sigma}),args)*({});
		res->sigma=Array.columns(sigma,args);//本应该转置，但sigma是对称的，免
		res->crossval=({});
		multiset mm=(multiset)args;
		foreach(crossval;int i;mixed val){
			if(mm[i%m]&&mm[i/m]){
				res->crossval+=({val});
			}
		}
		res->sumval=map(res->avgval,`*,res->n);
		res->crosssumval=map(res->crossval,`*,res->n);
		return res;
	}/*}}}*/
	float atom_entropy()/*{{{*/
	{
		return 1.0*m/2*(Math.log2(Math.e)+Math.log2(2*Math.pi))+Math.log2(abs())/2;
	}/*}}}*/
	float entropy()/*{{{*/
	{
		return atom_entropy()*n;
	}/*}}}*/
	Sigma zero_mean()/*{{{*/
	{
		object res=Sigma();
		res->m=m;
		res->n=n;
		res->sigma=sigma;
		res->avgval=({0.0})*m;
		res->update_crossval();
		res->sumval=res->avgval;
		res->crosssumval=map(res->crossval,`*,n);
		return res;
	}/*}}}*/
}

class Sigma{
	inherit SigmaBase;
	object `+(object rhd)/*{{{*/
	{
		if(rhd==0)
			return this;
		else
			return add(rhd);
	}/*}}}*/
	object ``+(object lhd)/*{{{*/
	{
		if(lhd==0)
			return this;
		else
			return lhd->add(this);
	}/*}}}*/
	object `-(object rhd)/*{{{*/
	{
		if(rhd==0)
			return this;
		else
			return sub(rhd);
	}/*}}}*/
	object ``-(object lhd)/*{{{*/
	{
		if(lhd==0)
			throw(({"ERROR.\n",backtrace()}));
		else
			return lhd->sub(this);
	}/*}}}*/
}
class SIGMA{
	array _vals;
	inherit Sigma;
	void create(array(array)|void vals,int|void quantum,array|void count)
	{
		//werror("WARNING: Sigma.SIGMA is for debug.\n");
		_vals=vals;
		::create(vals,quantum,count);
	}
	object sub(object rhd)
	{
		array exclude=({});
		array resvals=({});
		foreach(rhd->_vals,array val){
			int found;
			foreach(_vals,array val0){
				if(equal(val0,val)){
					exclude+=({val0});
					found=1;
					break;
				}
			}
			if(!found){
				werror("sub a item not exists: %O.",val);
				float mindiff=Math.inf;
				array minval;
				foreach(_vals,array val0){
					float d=diffa(val0,val);
					if(d<mindiff){
						mindiff=d;
						minval=val0;
					}
				}
				if(minval){
					werror("nearest is %O\n",minval);
				}
				abort();
			}
		}
		object res=::sub(rhd);
		if(res)
			res->_vals=_vals-exclude;
		return res;
	}
	object add(object rhd)
	{
		object res=::add(rhd);
		if(res)
			res->_vals=_vals+rhd->_vals;
		return res;
	}
}

	private void print(array sigma,int m)/*{{{*/
	{
		//werror("m=%O\n",m);
		for(int i=0;i<m;i++){
			for(int j=0;j<m;j++){
				werror("%f ",sigma[i][j]);
			}
			werror("\n");
		}
	}/*}}}*/
void main()
{
	array a=({});
	for(int i=0;i<10000;i++){
		a+=({({random(100)+20,random(20)+30,random(8)+200})});
	}
	array b=({});
	for(int i=0;i<10000;i++){
		b+=({({random(10)+20,random(2)+30,random(800)+200})});
	}
	array c=a[..sizeof(a)/2];
	array d=a[sizeof(a)/2+1..];

	object sig0=Sigma(({({100,200,300})}),1);
	print(sig0->sigma,sig0->m);
	sig0->update_sigma();
	print(sig0->sigma,sig0->m);
	werror("atm: %e\n",sig0->abs());
	werror("e1 : %e\n",1.0*sig0->m/2*(1+log(2*Math.pi))+log(sig0->abs())/2);
	werror("e2 : %e\n",1.0*sig0->m/2*(Math.log2(Math.e)+Math.log2(2*Math.pi))+Math.log2(sig0->abs())/2);
	//print((sig0+sig0)->sigma,sig0->m);
	
	object sig=Sigma(a);
	object sigb=Sigma(b);
	object sigsum=sig+sigb;
	object sigcheck=Sigma(a+b);
	object sig2=0+sig;
	object sig3=sig+0;
	print(sigsum->sigma,sigsum->m);
	print(sigcheck->sigma,sigcheck->m);
	werror("sum: %f\n",sigsum->abs());
	werror("chk: %f\n",sigcheck->abs());

	object sigc=Sigma(c);
	object sigdiff=sig-sigc;
	object sigcheck2=Sigma(d);
	print(sigdiff->sigma,sigdiff->m);
	print(sigcheck2->sigma,sigcheck2->m);
	werror("dif: %f\n",sigdiff->abs());
	werror("chk: %f\n",sigcheck2->abs());
	
}
