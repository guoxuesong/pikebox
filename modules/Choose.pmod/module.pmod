class P(int b,int a){
	int val;
	void create()/*{{{*/
	{
		val=1;
		for(int i=b-a+1;i<=b;i++){
			val*=i;
		}
	}/*}}}*/
	void inc_b()/*{{{*/
	{
		val/=b-a+1;
		val*=++b;
	}/*}}}*/
	void dec_b()/*{{{*/
	{
		val/=b;
		b--;
		val*=b-a+1;
	}/*}}}*/
	void inc_a()/*{{{*/
	{
		val*=b-(++a)+1;
	}/*}}}*/
	void dec_a()/*{{{*/
	{
		val/=b-a+1;
		a--;
	}/*}}}*/
}
class C(int b,int a){
	object pba,paa;
	int val;
#define update_val() val=pba->val/paa->val
	void create()/*{{{*/
	{
		pba=.P(b,a);
		paa=.P(a,a);
		update_val();
	}/*}}}*/
	void inc_b()/*{{{*/
	{
		b++;
		pba->inc_b();
		update_val();
	}/*}}}*/
	void dec_b()/*{{{*/
	{
		b--;
		pba->dec_b();
		update_val();
	}/*}}}*/
	void inc_a()/*{{{*/
	{
		a++;
		pba->inc_a();
		paa->inc_b();
		paa->inc_a();
		update_val();
	}/*}}}*/
	void dec_a()/*{{{*/
	{
		a--;
		pba->dec_a();
		paa->dec_a();
		paa->dec_b();
		update_val();
	}/*}}}*/
#undef update_val
}
class Coprime{/*{{{*/
	int maxvalue;
	int basevalue;
	mapping number_factors=([]);
	mapping r_count=([]);
	void create(int base,int r)
	{
		basevalue=base;
		maxvalue=max(base,r);
		number_factors[1]=(<>);
		for(int i=2;i<=maxvalue;i++){
			number_factors[i]=(multiset)Math.factor(i);
		}
		for(int i=1;i<=r;i++){
			r_count[i]=_count(base,i);
		}
	}
	int _count(int n,int m)
	{
		if(n>maxvalue||m>maxvalue)
			throw(({"too large.\n",backtrace()}));
		int res;
		for(int i=1;i<=n;i++){
			for(int j=1;j<=m;j++){
				if(sizeof(number_factors[i]&number_factors[j])==0){
					res++;
				}
			}
		}
		return res;
	}
	int count(int n,int m)
	{
		if(n==basevalue){
			return r_count[m]||_count(n,m);
		}else if(m==basevalue){
			return r_count[n]||_count(n,m);
		}
		return _count(n,m);
	}
}/*}}}*/

function fac=Gmp.fac;

int p(int b,int a)/*{{{*/
{
	if(b==a) return fac(b);
	int res=1;
	for(int i=b-a+1;i<=b;i++){
		res*=i;
	}
	return res;
}/*}}}*/
int c(int b,int a)/*{{{*/
{
	return Math.choose(b,a);
	//return p(b,a)/p(a,a);
}/*}}}*/
float ln_p(int b,int a)/*{{{*/
{
	return Math.log2(p(b,a)*1.0);
}/*}}}*/
float ln_c(int b,int a)/*{{{*/
{
	return Math.log2(c(b,a)*1.0);
}/*}}}*/

#if 1
int boson_classify(int b,int a)/*{{{*/
{
	return fac(b+a-1)/fac(b)/fac(a-1);
}/*}}}*/
#else
int boson_classify(int inst_count,int class_count)/*{{{*/
{
	int res;
	object c1=.C(inst_count-1,0);
	object c2=.C(class_count,1);
	res=c1->val*c2->val;
	int m=min(inst_count,class_count);
	while(c2->a<m){
		c1->inc_a();
		c2->inc_a();
		res+=c1->val*c2->val;
	}
	return res;
};/*}}}*/
#endif

int boson_sim(int b,int a)
{
	return min(pow(a,b),pow(b,a));
}
int fermion_sim(int b,int a)
{
	return pow(a,b);
}

int fermion_classify(int b,int a)/*{{{*/
{
	return c(b,a);
}/*}}}*/

void main()
{
	/*object c=C(100,0);
	write("%d ",c->val);
	while(c->a<c->b){
		c->inc_a();
		write("%d ",c->val);
	}
	write("\n");
	write("%d ",c->val);
	while(c->a>0){
		c->dec_a();
		write("%d ",c->val);
	}*/

	/*float t;
	for(int i=0;i<10;i++){
	t=Time.timeof(lambda(){
		werror("%d\n",boson_classify(1000,900));
		});
	werror("time=%0.8f\n",t);
	}*/

	/*object cache=CacheLite.Cache(1024*1024);

	for(int i=1;i<64;i++){
		werror("%d\n",i);
		for(int j=1;j<=i;j++){
		cache(({i,j}),lambda(){
				return boson_classify(i,j);
				});
		}
	}*/
	for(int i=5;i<10;i++){
		for(int j=1;j<=5;j++){
			//werror("%d %d ",fermion_classify(i,j),fermion_sim(i,j));
			werror("%f ",Math.log2(1.0*fermion_classify(i,j))-Math.log2(1.0*fermion_sim(i,j)));
		}
		werror("\n");
	}
}
