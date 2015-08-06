#define DYNPROG
#include <class.h>
#define CLASS_HOST "SparseEntropyReduce"
class DynClass{
#include <class_imp.h>
}

class UniqIDStatic{
	class Static{
		int sn;
	};
}

class UniqID{
	int id=++(STATIC(UniqIDStatic)->sn);
}

class Model{
	HighDimensionRelationMap r;
	int dimension(){return r->dimension();};
	/* 多线性拟合 {{{

		 y=a11 x1 + a12 x2 + ... a1n xn
		   + a21 x1x2 + a22 x2x3 + ... a_{2,C_n^2) x_{n-1}xn
			 + a31 x1x2x3 + ... + a_{3,C_n^3} x_{n-2}x_{n-1}x_n
			 + ...
			 + an1 x1x2x3...xn
			 + a{n+1}1
		 能使用的参数个数与样本点在空间的分布有关，比如在一个三维空间，可能的最小归
		 并单位是四个点组成的体，只能使用 y=a1x1+a2x2+a3x3+a4 来拟合，不可能使用三
		 线性拟合。

		 降维熵的概念
		 
		 在一个由n个参数定义的原子空间里面，如果存在一个原子集合，用n-m个参数就完全
		 确定，定位这个原子集合的熵，就是这n-m个参数的熵。比如一个系统我们打算对大
		 多数原子集合用y=ax+b来拟合，现在有一个原子集合只有一个元素{(x0,y0)}，我们
		 如何完全确定这个集合呢？我们可以用y=(y0/x0)x+0来拟合，更一般的，对于任意的
		 b，我们可以用y=a(b)x+b来拟合，其中a(b)是b的函数，如果我们给出一个确定的形
		 式y=ax+b，我们就多给出了信息。

		 这样看待这个问题，如果集合的元素数量信息是免费的，我们就知道元素数量距离标
		 准模型差了几个，设置一个标准的退化路径，我们就可以不支付额外的代价直接用
		 n-m个参数的熵来描述这个元素比较少的现象集合的熵。

		 上述数学表达形式没有很好地体现熵的信息，比如a21，在上式中似乎其精度要求与
		 x1x2的范围有关，即a21的精度应该保证在x1x2从x1_{min}x2_{min}变化到
		 x1_{max}x2_{max}的时候不对y值产生超过y值精度的影响。问题是同样宽度的x1,x2
		 区域，根据其坐标原点的定义不同x1x2的变化范围是不一样的。我们真正关心的不是
		 x1x2的乘积，而是原子集合在x1上投影的宽度和在x2上投影的宽度的乘积。我们需要
		 把上式平移，使得每个维度的最小坐标为0。

		 a21的本质含义是x1的平均增量在随着x2增大的增量，x1的平均增量的精度就是a1的
		 精度，

		 我们先考虑一个简单的情况：z=ax+by+cxy+d

		 如果x=0，退化成z=by+d，如果y=0，退化成z=ax+d，如果y=k，退化成
		 z=(a+ck)*x+(bk+d)，这个意思是说：dz/dx随着y的增加而增加，y每增加1，dz/dx增
		 加c，我们现在关心c的精度，c的精度应该保证y从最小值增大到最大值的过程中对
		 dz/dx的影响保持在dz/dx的精度要求之内，用R_x1*R_x2来衡量a21的精度是基本正确
		 的，但要考虑到受到dz/dx除了受到c的影响在高维情况下还受到别的a2j的影响，因
		 此a21的精度熵应该在ln(R_x1*R_x2)的基础上再加上一个ln(C_n^2)。

		 有了每个参数的精度，通过假设参数服从正态分布，用概率密度函数乘精度间隔就得
		 到了该参数取得当前值的概率。

		 考虑抛弃三次项及更高次项，这意味着我们仍然试图解释任何两个维度之间的潜在的
		 比例关系，但我们不打算解释三个维度之间的比例关系，直观告诉我们这是合适的。

		 下面考虑如何计算哪些点是相邻的，基本的思想是：要判断两个点A,B是否相邻，如
		 果空间中存在一个点，这个点到A,B的距离相等，并且比到其他任何采样点都近，我
		 们认为A,B相邻。

		 点(x,y)到点(x1,y1) (x2,y2)是否相邻，需要计算
		 (x-x1)^2+(y-y1)^2=(x-x2)^2+(y-y2)^2展开：
		 x^2-2*x1*x+x1^2+y^2-2*y1*y+y1^2=x^2-2*x2*x+x2^2+y^2-2*y2*y+y2^2

		 消元移项：
		 2*(x1-x2)*x+2*(y1-y2)*y-x1^2-y1^2+x2^2+y2^2=0
		 
		 假设y1!=y2 有y=((x1^2+y1^2-x2^2-y2^2)-2*(x1-x2)*x)/(2*(y1-y2)) ...(1)
		 反之x1!=x2 有x=((x1^2+y1^2-x2^2-y2^2)-2*(y1-y2)*y)/(2*(x1-x2)) ...(2)

		 以及不等式：
		 2*(x1-xi)*x+2*(y1-yi)*y-x1^2-y1^2+xi^2+yi^2>0 i>2 ...(3)

		 将(1)或(2)带入(3)得到一元不等式组，如果解集非空A,B相邻。计算复杂度和原子数
		 的立方成正比，和维度数成正比。

		 }}} */
	array args=({});
}

array glpk(array c,array(array) a,array b,array lb,array ub,string ctype,string vartype,int sense,mapping param)
{
	array res=Octave.eval("glpk",4,
			Octave.ColumnVector(c),
			Octave.Matrix(a),
			Octave.ColumnVector(b),
			Octave.ColumnVector(lb),
			Octave.ColumnVector(ub),
			ctype,vartype,sense,Octave.octave_scalar_map(param));
	return res;
}

array linear_fit(array(array) a,array b)
{
	array res=Octave.eval("mldivide",1,
			Octave.Matrix(a),
			Octave.ColumnVector(b));
	return res;
}

class SparseAtom{
	inherit ByValue.Item;
	array query_position();
	array query_value();
}

class SparseNode{
	HighDimensionRelationMap r;
	multiset atoms=(<>);
}

class HighDimensionRelationMap{
	array classifiers=({});
	int dimension(){return sizeof(classifiers);};
	mapping weak=([]);
	mapping strong=([]);
	private void insert(mapping store,object atom1,object atom2)/*{{{*/
	{
		store[atom1]=store[atom1]||(<>);
		store[atom1][atom2]=1;
		store[atom2]=store[atom2]||(<>);
		store[atom2][atom1]=1;
	}/*}}}*/
	int is_nearby(object atom1,object atom2)/*{{{*/
	{
		return weak[atom1]&&weak[atom1][atom2]||strong[atom1]&&strong[atom1][atom2];
	}/*}}}*/
	void add_weak_relation(object atom1,object atom2){insert(weak,atom1,atom2);}
	void add_relation(object atom1,object atom2){insert(strong,atom1,atom2);}
	void add_corner(object atom1,Polyhedron corner){}
	array expand_nearbyset(multiset curr,object atom)
	{
		multiset m=strong[atom];
		array a=({});
		foreach(curr;object atom2;int one){
			multiset m2=strong[atom2]|weak[atom2];
			a+=({m2});
		}
		if(sizeof(a)){
			multiset res=`&(@a)-curr;
			return map((array)res,lambda(object a){
					return (<a>)|curr;
					});
		}
		//return ({});
	}
	array multiset_uniq(array a)/*{{{*/
	{
		array res=({});
		for(int i=0;i<sizeof(a);i++){
			int skip;
			for(int j=0;j<sizeof(res);j++){
				if(equal(a[i],res[j])){
					skip=1;
					break;
				}
			}
			if(!skip){
				res+=({a[i]});
			}
		}
		return res;
	}/*}}}*/
	array(multiset) create_nearbyset(object atom,int n)//返回在atom强周围选n个两两强或弱相邻原子的所有可能
	{
		array res=map((array)strong[atom],lambda(object a){
				return (<a>);
				});
		for(int i=0;i<n-1;i++){
			res=multiset_uniq(`+(({}),@map(res,expand_nearbyset,atom)));
		}
		return res;
	}
	void create_nodes()
	{
		mapping corners=([]);
		foreach(strong;object atom1;multiset m){
			corners[atom1]=create_nearbyset(atom1,dimension()-1);
		}
	}
}

class Polyhedron(int dimension,array lb,array ub){
	array(array) a=({}); array b=({}); //a x' <= b'
	array infos=({});
	Polyhedron corner(multiset m)
	{
		Polyhedron res=.Polyhedron(dimension,lb,ub);
		foreach(m;int i;int one){
			res->a+=a[i..i];
			res->b+=b[i..i];
			res->infos+=infos[i..i];
		}
		return res;
	}
	Polyhedron `+(Polyhedron rhd)/*{{{*/
	{
		Polyhedron res=.Polyhedron(dimension,lb,ub);
		res->a=a+rhd->a;
		res->b=b+rhd->b;
		return res;
	}/*}}}*/
	int `&(Polyhedron p) //判断当前多面体和p是否有交集，包括边界
	{
		//werror("p=%O\n",p);
		array c=({1})*dimension;
		array aa=a+p->a;
		array bb=b+p->b;
		string ctype="U"*sizeof(a)+"S"*sizeof(p->a);
		string vartype="C"*dimension;
		int sense=1;
		array res=.glpk(c,aa,bb,lb,ub,ctype,vartype,sense,([]));
		return !Float.isnan(res[1]);
	}
	int cross_inside(Polyhedron p) //判断当前多面体和p是否有交集，不包括边界
	{
		array c=({1})*dimension;
		array aa=map(a,map,Function.curry(`-)(0))+p->a;
		array bb=map(b,Function.curry(`-)(0))+p->b;
		string ctype="L"*sizeof(a)+"S"*sizeof(p->a);
		string vartype="C"*dimension;
		int sense=1;
		array res=.glpk(c,aa,bb,lb,ub,ctype,vartype,sense,([]));
		//werror("%O %d\n",res[1],Float.isnan(res[1]));
		return !Float.isnan(res[1]);
	}
	int solve_nearby(multiset i,multiset j) //检查第i个斜面和第j个斜面是否相邻
	{
		array c=({1})*dimension;
		array aa=a;
		array bb=b;
		string ctype="U"*sizeof(a);
		foreach(i+j;int p;int one){
			ctype[p]='S';
		}
		string vartype="C"*dimension;
		int sense=1;
		array res=.glpk(c,aa,bb,lb,ub,ctype,vartype,sense,([]));
		//werror("res=%O\n",res);
		return !Float.isnan(res[1]);
	}
	Polyhedron absorb(Polyhedron p) //将p吸收，并吐出无交集的斜面集合
	{
		a+=p->a;b+=p->b;infos+=p->infos;

		Polyhedron res=.Polyhedron(dimension,lb,ub);
		int found;
		do{
			found=0;
			for(int i=0;i<sizeof(a)-1;i++){
				array olda=a,oldb=b,oldinfos=infos;
				object t=.Polyhedron(dimension,lb,ub);
				t->a=a[i..i];
				t->b=b[i..i];
				t->infos=infos[i..i];
				a=a[..i-1]+a[i+1..];
				b=b[..i-1]+b[i+1..];
				infos=infos[..i-1]+infos[i+1..];
				//werror("t=%O\n",t);
				if((this&t)==0){
					res+=t;
					found=1;
					break;
				}else{
					a=olda;b=oldb;infos=oldinfos;
				}
			}
		}while(found);
		if(sizeof(res->a))
			return res;
	}
	array range()
	{
		array res=({});
		for(int i=0;i<dimension;i++){
			array r=({});
			foreach(({1,-1}),int sense){
				array c=({0})*dimension; c[i]=1;
				array aa=a;
				array bb=b;
				string ctype="U"*sizeof(a);
				string vartype="C"*dimension;
				array res=.glpk(c,aa,bb,lb,ub,ctype,vartype,sense,([]));
				r+=({res[1]});
			}
			res+=({r});
		}
		return res;
	}
}


/* 地板空间，分类空间，解释空间

	 地板空间是由变化为坐标轴，每个坐标轴表示一组正反两个变化方向，典型的地板空间是时间，空间。数据在地板空间里面致密排布。

	 分类空间是通过引入分类器，把地板空间上的数据映射到更高维度的空间，由可以衡量相似程度的量做为坐标轴，典型的相似空间是概率密度空间。数据在相似空间里面稀疏排布。典型的分类器是马尔科夫场中的领域系统。

	 分类空间的维度加上待解释的现象量的维度，构成了解释空间。试图对分类空间予以划分，对每个分块上提出统一的解释，从而解释现象量的值为什么是那个值。

	 */
/* 
	 A,B相邻定义为：至少存在一个点到A,B距离相等，但到任何其他原子的距离不更近如果
	 原子A有m个相邻原子，对这m个相邻原子中任意三个B,C,D，如果B,C,D相邻，则A,B,C,D
	 构成了对A周围的三维空间的一个划分，我们需要证明：A周围的三维空间可以被这样的
	 相邻原子集合完全划分，我们还需要推广到高维：三维需要三个相邻原子，n维需要n个
	 相邻原子 

	 在确定原子的相邻关系时，我们用到了一个多面体来包围A，这个多面体的每个面代表
	 了相邻原子划分到A的周围空间的相邻关系，我们并不能确定A相邻的两个原子是否相邻
	 ，但我们可以确定A的两个相邻原子对A周围空间的划分是否相邻，然而如果A,B的中位
	 面和A,C的中位面如果存在交线，则交线上的点到A,B,C的距离相等，则B,C相邻，但不
	 能保证强相邻

	 弱相邻：如果在包围A的多面体上，属于B的部分不是一个面，而是点或者线，即维度
	 比空间维度小2或以上，称AB弱相邻。如何探知弱相邻，把多面体方程从<=改为<，然
	 后把弱相邻中位面方程代入求解，解集为空判断为弱相邻 

	 考虑弱相邻以后，这样找归并元：对于n维空间，在A的强相邻原子集中找n-1个原子
	 这n-1个原子两两相邻但不一定强相邻，称这n-1个原子是一个角，找出所有的角，用
	 这些角来拼接成多面体作为归并元，或者直接用角作归并元，从计算规模考虑，用角
	 作归并元较劣。不使用角作为归并元有大圈悖论：假设在一个大圈上均匀分布着原子，
	 大圈会被当作一个归并元，实际上导致我们对大圈的局部的一致性无法作任何归纳。

	 前面已经证明，或容易证明，一个原子的周围空间一定可以被相邻原子完全划分，并
	 且中位多边形共线的原子相邻，中位多边形共点的原子构成对原子周围空间的一个划
	 分，所有顶点构成对中心原子周围空间的完全划分。考虑弱相邻以后，共线多边形可
	 能是强相邻也可能是弱相邻
	 */

/* 升幂与复计

	 因为大圈悖论的存在，用角做为归约元是必然的选择，这同时意味着归约将是线性的而
	 非多线性，第一层归约中归约节点都被表达为r=ax+by+c，没有xy项，把a,b,c看作归约
	 节点的参数，我们必须考虑它们的熵，因为归约的结果是拓扑的，只能从概率分布上讨
	 论a,b,c的熵，这是不够的，我们期望解析a是x,y的函数，用一个平面拟合a，然后对残
	 差统计概率分布，这是合理的做法，但要做到这一点就不能把a视为归约节点的参数，
	 而应该对归约节点动态升幂。

	 如果考虑动态升幂，那么起点就不是r=ax+by+c了，而是r=c，然后r=ax+c,r=by+c。也
	 就是说最初的归约元既不是角也不是线段，而是原子，这是合理的，问题是如何解决一
	 个原子和左边的原子归并和和右边的原子归并没有差异的问题。第一个困难是要不要升
	 幂，如果决定升幂那简单了，升幂以后和左边归并与和右面归并熵一样，视做既和左边
	 归并也和右边归并，把两个归并结果都放进关系表里面，这样如果中间位置的节点的熵
	 仍然正常计入则熵增加了，修正为视做左右两个归约分别解释了中间位置节点所代表的
	 空间体积的一半。

	 动态升幂设计不能破坏空间的分析结构，仍然需要从角开始，只不过即时对于角也可以
	 选择r=c解释。从原子开始升幂和复计的困难在于一旦选择不升幂我们就会损失掉一个
	 方向的变化现象，从任何低于空间维度的结构开始都会有同样的弊端。综上，复计不是
	 一个可以接受的策略。

	 从角开始分析的困难在于，维度之间的相关性是局域的，做全局维度分析会导致归并元
	 的尺寸太大，并且所有的归并元都相邻，看来，动态升幂和复计的想法是正确的，问题
	 是如何实现。

	 一个归并节点应该被表述为，首先维度划分，某几个维度是相关维度，用一个或几个方
	 程来表示其相关关系，加上残差来得到确切地现象值，有几组这样的相关维度，用每个
	 维度的理论值来建立相关维度组之间的熵模型。比如说x,y是相关的，我们有方程
	 a1x+a2y+c1+e1=0，残差为e1，然后r,g,b有一个方程a3r+a4g+a5b+c2+e2=0 有一个包含
	 x,y,r,g,b的方程a1'x+a2'y+a3'r+a4'g+a5'b+c3+e3=0

	 精度分析：a1x+a2y+c1+e1=0 假设x的变化范围较大，改写为 a1/a2 * x + y + c1/a2
	 +e1/a2 = 0, a1/a2的精度为1/R_x，c1/a2的精度为1，e1/a2的精度为1，也即a1的精度
	 为a2/R_x，a2的精度为1，c1,e1的精度为a2。

	 如果允许在任何时刻做升幂归约，就会导致r=ax+by+cz+dxy+e和r=ax+by+cz+dyz+e之间
	 的竞争，除非我们能够采取全参数描述并且在一些参数为0的时候保持平滑过渡。

	 把升幂看作更高一阶的归约，最低一阶的归约模型就是r=ax+by+cx+d，(a,b,c,d)是第
	 一阶归约结果的属性，对每一个属性，比如a，做一个a=a'x+b'y+c'z+d'的归约模型

	 形象地说：狗群里面混进了一只猪怎么办呢，首先要不要对齐，按头对齐还是按尾巴对
	 齐，如果不对齐怎么处理变化呢？狗是二维的猪是三维的，放在一起怎么办呢？如果猪
	 可以被视为狗的运动轨迹，又如何呢？拓扑关系没有位置信息，不需要处理变化。

	 拓扑关系是有位置信息的，位置信息是一个集合，但对于如何处理这种位置信息尚不明
	 确。这是形状问题。

	 */

/* 区块熵困难

	 分类空间的结构是稀疏的，这导致区块熵会比在致密的地板空间高，加上相邻关系的暴增，看起来在高维稀疏空间定义相邻变得不可行。

	 */

/* 退化到马尔科夫随机场

	 如果对分类空间的任意维度x，用模型r=x+c来解释现象，这是马尔科夫随机场，并且等效于对(dx-,dx+,dy-,dy+)做正态分布r解释。

	 相对于马尔科夫随机场我们的优势是：1、我们计熵；2、我们有形状。

	 */



class Data{
	array size();	//地板空间是致密的空间，每个位置都有数据，size返回各维度的宽度
	SparseAtom query(array pos);
	function(SparseAtom:int) position_classifier(int i)/*{{{*/
	{
		return lambda(SparseAtom atom){
			return atom->query_position()[i];
		};
	}/*}}}*/
	function(SparseAtom:int) value_classifier(array delta,int i)/*{{{*/
	{
		return lambda(SparseAtom atom){
			return query(atom->query_position()[*]+delta[*])->query_value()[i];
		};
	}/*}}}*/
	HighDimensionRelationMap create_relation_map(int n,array...deltaranges)/*{{{*/
	{
		HighDimensionRelationMap res=.HighDimensionRelationMap();
		for(int i=0;i<sizeof(size());i++){
			res->classifiers+=({position_classifier(i)});
		}
		foreach(deltaranges,array deltarange){
			Foreach.foreach_multidim(deltarange,lambda(array delta){
					//if(!Array.all(delta,`==,0)){
						for(int i=0;i<n;i++){
							res->classifiers+=({value_classifier(delta,i)});
						}
					//}
			});
		}

		werror("dimension=%d\n",res->dimension());

		array a=map(size(),lambda(int n){return ({0,n-1});});

		mapping atom2cp=([]);
		array minvals=allocate(res->dimension(),Math.inf);
		array maxvals=allocate(res->dimension(),-Math.inf);
		Foreach.foreach_multidim(a,lambda(array pos1){
			object atom1=query(pos1);
			array cp1=res->classifiers(atom1);//atom1在分类空间的坐标
			werror("cp=(%s)\n",map(cp1,Cast.stringfy)*",");
			atom2cp[atom1]=cp1;
			for(int i=0;i<res->dimension();i++){
				minvals[i]=min(minvals[i],cp1[i]);
				maxvals[i]=max(maxvals[i],cp1[i]);
			}
		});

		/* 线性规划的搜索范围问题

			 比如说每个分量的变化范围是0-255，二维情况，如果两个面相交最远在什么地方相交呢？因为能表达的最小delta值是1/256，假设在x方向上有1/256的delta值，在y方向两个平面的最大距离是254，最远在边界外254*256的位置相交，也即[-254*256..255+254*256]

			 高维的情况，最粗略和简单的估计，把所有维度的变化范围相加，假设为N，则最小delta为1/N，最远的交点为[-N*maxrange,maxrange+N*maxrange]
			 */
		array ranges=maxvals[*]-minvals[*];
		float totalrange=`+(0.0,@ranges);
		float maxrange=max(0,@ranges)+0.0;
		array minvals0=minvals;
		array maxvals0=maxvals;
		minvals=({-totalrange*maxrange})*sizeof(minvals);
		maxvals=({(totalrange+1)*maxrange})*sizeof(maxvals);
		werror("minvals0=%O\n",minvals0);
		werror("maxvals0=%O\n",maxvals0);
		werror("minvals=%O\n",minvals);
		werror("maxvals=%O\n",maxvals);



		werror("create dd ...\n");

		mapping dd=([]);
		multiset done=(<>);
		Foreach.foreach_multidim(a,lambda(array pos1){/*{{{*/
				object atom1=query(pos1);
				Foreach.foreach_multidim(a,lambda(array pos2){
					object atom2=query(pos2);
					object pair=ByValue.Set(atom1,atom2);
					if(atom2!=atom1&&!done[pair]){
						//float d=`+(0.0,@map(atom1->query_value()[*]-atom2->query_value()[*],pow,2));
						float d=`+(0.0,@map((atom2cp[atom1])[*]-(atom2cp[atom2])[*],pow,2));
						dd[atom1]=dd[atom1]||([]);
						dd[atom2]=dd[atom2]||([]);
						dd[atom1][atom2]=dd[atom2][atom1]=d;
						done[pair]=1;
					}
					});
		});/*}}}*/

		werror("create polyhedrons ...\n");

		foreach(dd;object atom1;mapping atom2d){
			werror("create polyhedron of %O\n",atom1);
			array cp1=atom2cp[atom1];
			object polyhedron=.Polyhedron(res->dimension(),minvals,maxvals);//使用分类空间的维度
			object it=SortMapping.sort_values(atom2d);
			float limit=Math.inf;
			//每一个原子，由近及远找它周围的原子，用中位面来构造多面体包围，直到多面体的最大半径小于下一个最近的距离的一半。
			foreach(it->clone();object atom2;float d){
				//werror("limit=%O d=%f\n",limit,d);
				if(d>limit)
					break;
				//建立atom1和atom2的中位平面，并确定方向
				array cp2=atom2cp[atom2];
				array center=map(cp1[*]+cp2[*],`/,2.0);//中点
				array delta=cp2[*]-cp1[*];//法线方向由atom1指向atom2
				object t=.Polyhedron(res->dimension(),minvals,maxvals);
				t->a+=({delta});
				t->b+=({`+(0.0,@(delta[*]*center[*]))});
				t->infos+=({atom2});
				//比如cp1=(0,0),cp2=(1,1),center=(0.5,0.5),delta=(1,1)
				//做方程 1 x + 1 y = 0.5*1 + 0.5*1 即 x+y=1
				//写成不等式，如果写作x+y>=1，表示的是靠近cp2的一面；x+y<=1，表示靠近cp1的一面
				//我们需要靠近cp1的一面，取<=1

				//werror("t->a=%O\n",t->a);
				if(polyhedron->cross_inside(t)){
					polyhedron->absorb(t);
#if 0
					array r=polyhedron->range();
					//werror("range=%O\n",r);
					float sum=0.0;
					foreach(r;int i;[float lb,float ub]){
						float r=max(abs(cp1[i]-lb),abs(cp1[i]-ub));
						sum+=pow(r,2);
					}
					limit=pow(sum,0.5)*2;
#endif
				}
			}
			werror("%d faces\n",sizeof(polyhedron->a));

			
#if 0
			//计算corner
			werror("create corners of %O\n",atom1);
			array a=({});
			for(int i=0;i<sizeof(polyhedron->infos);i++){
				a+=({(<i>)});
			}
			for(int t=0;t<res->dimension()-1;t++){
				array aa=({});
				for(int i=0;i<sizeof(a);i++){
					for(int j=i+1;j<sizeof(a);j++){
						if(polyhedron->solve_nearby(a[i],a[j])){
							aa+=({a[i]|a[j]});
						}
					}
				}
				a=aa;
			}
#endif
			werror("update r\n");
			foreach(a,multiset m){
				res->add_corner(atom1,polyhedron->corner(m));
			}

			for(int i=0;i<sizeof(polyhedron->a);i++){
				for(int j=i+1;j<sizeof(polyhedron->a);j++){
					res->add_weak_relation(polyhedron->infos[i],polyhedron->infos[j]);
				}
			}
			foreach(polyhedron->infos;int i;object atom2){
				res->add_relation(atom1,atom2);
				werror("(%O,%O)\n",atom1,atom2);
			}
		}
	}/*}}}*/
}

class PixelAtom(array pos,array vals){
	inherit SparseAtom;
	array query_position(){return pos;}
	array query_value(){return vals;};
	string _sprintf(int t)
	{
		if(t=='O'){
			return sprintf("Pixel(%s)",map(pos,Cast.stringfy)*",");
		}
	}
}
class PixelData(object image){
	inherit Data;
	mapping pos2atom=([]);
	array size()
	{
		return ({image->xsize(),image->ysize()});
	}
	SparseAtom query(array pos)
	{
		object pair=ByValue.Pair(@pos);
		if(pos2atom[pair]==0){
			pos2atom[pair]=PixelAtom(pos,image->getpixel(@pos));
		}
		return pos2atom[pair];
	}
}

class SparseEntropyReduceMode{
	class Interface{
	}
	class Default{
	}
}

class SparseEntropyReduce{
	inherit SparseEntropyReduceMode.Interface;
}

program default_program=CLASS(SparseEntropyReduce,SparseEntropyReduceMode.Default);

#include <args.h>
int unittest_pixeldata_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	object image=Image.Image(10,10)->test();
	object data=PixelData(image);
	object r=data->create_relation_map(3,({({0,0})}));
	//object r=data->create_relation_map(1,({({-1,1}),({0,0})}),({({0,0}),({-1,1})}));
	//object r=data->create_relation_map(3,({({0,0})}));
}
int unittest_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_EXECUTE("pixeldata",unittest_pixeldata_main,"");
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_EXECUTE("unittest",unittest_main,"");
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

