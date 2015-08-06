class ColumnVector{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i;
			ColumnVector *p=new ColumnVector(INT{sizeof(a)});
			for(i=0;i<INT{sizeof(a)};i++){
				p->insert(ColumnVector(1,FLOAT{(float)a[INT{i}]}),i);
			}
			P{
				p=POINTER{p};
			}
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			ColumnVector *p=(ColumnVector*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/
class RowVector{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i;
			RowVector *p=new RowVector(INT{sizeof(a)});
			for(i=0;i<INT{sizeof(a)};i++){
				p->insert(RowVector(1,FLOAT{(float)a[INT{i}]}),i);
			}
			P{
				p=POINTER{p};
			}
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			RowVector *p=(RowVector*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/
class Matrix{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i,j;
			Matrix *p=new Matrix(INT{sizeof(a)}, INT{sizeof(a[0])});
			for(i=0;i<INT{sizeof(a)};i++){
				for(j=0;j<INT{sizeof(a[0])};j++){
					p->fill(FLOAT{(float)a[INT{i}][INT{j}]},i,j,i,j);
				}
			}
			P{
				p=POINTER{p};
			}
		}
	}
	Matrix transpose()
	{
		Matrix res=Matrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			p=new Matrix(p->transpose());
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	int `!()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			P{
				res=INT{!(*p)};
			}
		}
		return res;
	}
	int xsize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			P{
				res=INT{p->rows()};
			}
		}
		return res;
	}
	int ysize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			P{
				res=INT{p->cols()};
			}
		}
		return res;
	}
	Matrix `*(Matrix rhd)
	{
		Matrix res=Matrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			Matrix *rhd=(Matrix*)POINTER{rhd->p};
			p=new Matrix((*p)*(*rhd));
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	Matrix `+=(Matrix rhd)
	{
		Matrix res=Matrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			Matrix *rhd=(Matrix*)POINTER{rhd->p};
			(*p)+=(*rhd);
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	mixed cast(string type)
	{
		if(type!="array")
			return 0;
		array res=({});
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			int i,j;
			for(i=0;i<p->rows();i++){
				P{res+=({({})});}
				for(j=0;j<p->cols();j++){
					P{
						res[INT{i}]+=({FLOAT{p->elem(i,j)}});
					}
				}
			}
		}
		return res;
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			Matrix *p=(Matrix*)POINTER{p};
			delete p;
		}
	}
	string _sprintf(int t)
	{
		if(t=='O'){
			return sprintf("Matrix(%O)",cast("array"));
		}
	}
}/*}}}*/
class FloatColumnVector{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i;
			FloatColumnVector *p=new FloatColumnVector(INT{sizeof(a)});
			for(i=0;i<INT{sizeof(a)};i++){
				p->insert(FloatColumnVector(1,FLOAT{(float)a[INT{i}]}),i);
			}
			P{
				p=POINTER{p};
			}
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatColumnVector *p=(FloatColumnVector*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/
class FloatRowVector{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i;
			FloatRowVector *p=new FloatRowVector(INT{sizeof(a)});
			for(i=0;i<INT{sizeof(a)};i++){
				p->insert(FloatRowVector(1,FLOAT{(float)a[INT{i}]}),i);
			}
			P{
				p=POINTER{p};
			}
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatRowVector *p=(FloatRowVector*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/
class FloatMatrix{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i,j;
			FloatMatrix *p=new FloatMatrix(INT{sizeof(a)}, INT{sizeof(a[0])});
			for(i=0;i<INT{sizeof(a)};i++){
				for(j=0;j<INT{sizeof(a[0])};j++){
					p->fill(FLOAT{(float)a[INT{i}][INT{j}]},i,j,i,j);
				}
			}
			P{
				p=POINTER{p};
			}
		}
	}
	FloatMatrix transpose()
	{
		FloatMatrix res=FloatMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			p=new FloatMatrix(p->transpose());
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	int `!()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			P{
				res=INT{!(*p)};
			}
		}
		return res;
	}
	int xsize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			P{
				res=INT{p->rows()};
			}
		}
		return res;
	}
	int ysize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			P{
				res=INT{p->cols()};
			}
		}
		return res;
	}
	FloatMatrix `*(FloatMatrix rhd)
	{
		FloatMatrix res=FloatMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			FloatMatrix *rhd=(FloatMatrix*)POINTER{rhd->p};
			p=new FloatMatrix((*p)*(*rhd));
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	FloatMatrix `+=(FloatMatrix rhd)
	{
		FloatMatrix res=FloatMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			FloatMatrix *rhd=(FloatMatrix*)POINTER{rhd->p};
			(*p)+=(*rhd);
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	mixed cast(string type)
	{
		if(type!="array")
			return 0;
		array res=({});
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			int i,j;
			for(i=0;i<p->rows();i++){
				P{res+=({({})});}
				for(j=0;j<p->cols();j++){
					P{
						res[INT{i}]+=({FLOAT{p->elem(i,j)}});
					}
				}
			}
		}
		return res;
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			FloatMatrix *p=(FloatMatrix*)POINTER{p};
			delete p;
		}
	}
	string _sprintf(int t)
	{
		if(t=='O'){
			return sprintf("FloatMatrix(%O)",cast("array"));
		}
	}
}/*}}}*/
class charMatrix{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			int i,j;
			charMatrix *p=new charMatrix(INT{sizeof(a)}, INT{sizeof(a[0])});
			for(i=0;i<INT{sizeof(a)};i++){
				for(j=0;j<INT{sizeof(a[0])};j++){
					p->fill(FLOAT{(float)a[INT{i}][INT{j}]},i,j,i,j);
				}
			}
			P{
				p=POINTER{p};
			}
		}
	}
	charMatrix transpose()
	{
		charMatrix res=charMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			p=new charMatrix(p->transpose());
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	int `!()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			P{
				res=INT{!(*p)};
			}
		}
		return res;
	}
	int xsize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			P{
				res=INT{p->rows()};
			}
		}
		return res;
	}
	int ysize()
	{
		int res;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			P{
				res=INT{p->cols()};
			}
		}
		return res;
	}
	charMatrix `*(charMatrix rhd)
	{
		charMatrix res=charMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			charMatrix *rhd=(charMatrix*)POINTER{rhd->p};
			p=new charMatrix((*p)*(*rhd));
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	charMatrix `+=(charMatrix rhd)
	{
		charMatrix res=charMatrix();
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			charMatrix *rhd=(charMatrix*)POINTER{rhd->p};
			(*p)+=(*rhd);
			P{
				res->p=POINTER{p};
			}
		}
		return res;
	}
	mixed cast(string type)
	{
		if(type!="array")
			return 0;
		array res=({});
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			int i,j;
			for(i=0;i<p->rows();i++){
				P{res+=({({})});}
				for(j=0;j<p->cols();j++){
					P{
						res[INT{i}]+=({FLOAT{p->elem(i,j)}});
					}
				}
			}
		}
		return res;
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			charMatrix *p=(charMatrix*)POINTER{p};
			delete p;
		}
	}
	string _sprintf(int t)
	{
		if(t=='O'){
			return sprintf("charMatrix(%O)",cast("array"));
		}
	}
}/*}}}*/
class octave_scalar_map{/*{{{*/
	int p;
	void create(mapping|void m)
	{
		if(m==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_scalar_map *p=new octave_scalar_map();
			P{
				p=POINTER{p};
				foreach(m;string key;mixed val)
				{
					if(stringp(val)){
						Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
				Cross.CC("bin/octavecc.pike");// -std=c++0x  g++ `mkoctfile -p ALL_CXXFLAGS` -std=c++0x -shared -fPIC -lm `mkoctfile -p LFLAGS` `mkoctfile -p OCTAVE_LIBS` `mkoctfile -p FLIBS`
						C{
							octave_scalar_map& m=*(octave_scalar_map*)POINTER{p};
							octave_value tmp(STRING{val});
							m.assign(STRING{key}, tmp);
						}
					}else if(intp(val)){
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
	using namespace std;
				");
		//Cross.CC("gcc -shared -fPIC");
		Cross.CC("bin/octavecc.pike");// -std=c++0x  g++ `mkoctfile -p ALL_CXXFLAGS` -std=c++0x -shared -fPIC -lm `mkoctfile -p LFLAGS` `mkoctfile -p OCTAVE_LIBS` `mkoctfile -p FLIBS`
						C{
							octave_scalar_map& m=*(octave_scalar_map*)POINTER{p};
							octave_value tmp(INT{val});
							m.assign(STRING{key}, tmp);
						}
					}else if(floatp(val)){
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
	using namespace std;
				");
		//Cross.CC("gcc -shared -fPIC");
		Cross.CC("bin/octavecc.pike");// -std=c++0x  g++ `mkoctfile -p ALL_CXXFLAGS` -std=c++0x -shared -fPIC -lm `mkoctfile -p LFLAGS` `mkoctfile -p OCTAVE_LIBS` `mkoctfile -p FLIBS`
						C{
							octave_scalar_map& m=*(octave_scalar_map*)POINTER{p};
							octave_value tmp(FLOAT{val});
							m.assign(STRING{key}, tmp);
						}
					}
				}
			}
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_scalar_map *p=(octave_scalar_map*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/
class octave_value{/*{{{*/
	int p;
	void create()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
		}
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_value *p=(octave_value*)POINTER{p};
			delete p;
		}
	}
	mixed cast(string type)
	{
		werror("WARNING: cast obsoleted, use value() instead.\n");
		if(type!="mixed")
			return 0;
		return value();
	}
	mixed value()
	{
		array res=({});
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_value *p=(octave_value*)POINTER{p};
			int i;
			octave_value& val=(*p);
			if(val.is_matrix_type()){
				P{
					Matrix m=Matrix();
					m->p=POINTER{new Matrix(val.matrix_value())};
					res+=({m});
				}
			}else if(val.is_real_scalar()){
				P{
					res+=({FLOAT{val.scalar_value()}});
				}
			}else if(val.is_integer_type()){
				P{
					res+=({FLOAT{(float)val.long_value()}});
				}
			}
		}
		return sizeof(res)&&res[0]; 
	}
	string _sprintf(int c)
	{
		if(c=='O'){
			object m=cast("mixed");
			return sprintf("%O",m);
		}
	}
}/*}}}*/
class octave_value_list{/*{{{*/
	int p;
	void create(array|void a)
	{
		if(a==0) return;
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_value_list *p=new octave_value_list(INT{sizeof(a)});
			P{
				p=POINTER{p};
			}
			int i;
			for(i=0;i<INT{sizeof(a)};i++){
				if(INT{intp(a[INT{i}])}){
					(*p)(i)=INT{a[INT{i}]};
				}else if(INT{floatp(a[INT{i}])}){
					(*p)(i)=FLOAT{a[INT{i}]};
				}else if(INT{stringp(a[INT{i}])}){
					(*p)(i)=charNDArray(STRING{a[INT{i}]});
				}else if(INT{objectp(a[INT{i}])}){
					if(INT{object_program(a[INT{i}])==Matrix}){
						(*p)(i)=*(Matrix*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==FloatMatrix}){
						(*p)(i)=*(FloatMatrix*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==charMatrix}){
						(*p)(i)=*(charMatrix*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==ColumnVector}){
						(*p)(i)=*(ColumnVector*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==FloatColumnVector}){
						(*p)(i)=*(FloatColumnVector*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==RowVector}){
						(*p)(i)=*(RowVector*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==FloatRowVector}){
						(*p)(i)=*(FloatRowVector*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==octave_scalar_map}){
						(*p)(i)=*(octave_scalar_map*)POINTER{a[INT{i}]->p};
					}else if(INT{object_program(a[INT{i}])==octave_value}){
						(*p)(i)=*(octave_value*)POINTER{a[INT{i}]->p};
					}
				}
			}
		}
	}
	mixed cast(string type)
	{
		if(type!="array")
			return 0;
		array res=({});
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_value_list *p=(octave_value_list*)POINTER{p};
			int i;
			for(i=0;i<p->length();i++){
				octave_value& val=(*p)(i);
				P{
					octave_value v=octave_value();
					v->p=POINTER{new octave_value(val)};
					res+=({v});
				}
			}
		}
		return res; 
	}
	void destroy()
	{
		Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
				");
		Cross.CC("bin/octavecc.pike");
		C{
			octave_value_list *p=(octave_value_list*)POINTER{p};
			delete p;
		}
	}
}/*}}}*/

array feval(string func,int n,mixed ... args)/*{{{*/
{
	object res=octave_value_list();
	object a=octave_value_list(args);
	Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
			");
	Cross.CC("bin/octavecc.pike");
	C{
		octave_value_list *retval=new octave_value_list;
		octave_value_list *p=(octave_value_list*)POINTER{a->p};
		*retval=feval(std::string(STRING{func}),*p,INT{n});
		P{
			res->p=POINTER{retval};
		}
	}
	return (array)res;
}/*}}}*/
mixed eval(mixed ... args)/*{{{*/
{
	werror("WARNING: eval obsoleted, use feval instead.\n");
	return feval(@args);
}/*}}}*/
mixed convert(mixed val,string type)/*{{{*/
{
	return feval("cast",1,val,type)[0];
}/*}}}*/
mixed cat(int n,mixed ... args)/*{{{*/
{
	return feval("cat",1,n,@args)[0];
}/*}}}*/
object select(object a,array ... args)/*{{{*/
{
	args=map(args,Array.arrayify);
	args=map(args,map,Cast.stringfy);
	feval("set_global_value",0,"tmp",a);
	feval("eval",0,sprintf("res=tmp(%s);",map(args,`*,":")*","));
	object res=feval("get_global_value",1,"res")[0];
	return res;
}/*}}}*/
object result(string code)/*{{{*/
{
	feval("eval",0,sprintf("res=%s;",code));
	object res=feval("get_global_value",1,"res")[0];
	return res;
}/*}}}*/
array dims(object a)/*{{{*/
{
	return feval("dims",1,a)[0]->value()->cast("array");
}/*}}}*/

object load_image(object(Image.Image) image)/*{{{*/
{
	object tmp=feval("reshape",1,(string)image,RowVector(({3,image->xsize()*image->ysize()})))[0];
	feval("set_global_value",0,"tmp",tmp);
	feval("eval",0,"r=tmp(1,:);g=tmp(2,:);b=tmp(3,:);");
	object r=feval("get_global_value",1,"r")[0];
	r=feval("reshape",1,r,RowVector(({image->xsize(),image->ysize()})))[0];
	object g=feval("get_global_value",1,"g")[0];
	g=feval("reshape",1,g,RowVector(({image->xsize(),image->ysize()})))[0];
	object b=feval("get_global_value",1,"b")[0];
	b=feval("reshape",1,b,RowVector(({image->xsize(),image->ysize()})))[0];
	return cat(3,r,g,b);
}/*}}}*/
object image_joint(object ... args)/*{{{*/
{
	return cat(3,@args);
}/*}}}*/
object image_layer(object ... args)/*{{{*/
{
	return feval("permute",1,cat(4,@args),RowVector(({1,2,4,3})))[0];
}/*}}}*/

void create()
{
	Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/octave.h>
#include <octave/toplev.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
			");
	//Cross.CC("gcc -shared -fPIC");
	Cross.CC("bin/octavecc.pike");// -std=c++0x  g++ `mkoctfile -p ALL_CXXFLAGS` -std=c++0x -shared -fPIC -lm `mkoctfile -p LFLAGS` `mkoctfile -p OCTAVE_LIBS` `mkoctfile -p FLIBS`
	C{
		string_vector argv(4);
		argv(0) = "embedded";
		argv(1) = "-q";
		argv(2) = "-p";
		argv(3) = "spear-modules/Octave.pmod/opencl-toolbox";

		octave_main (4, argv.c_str_vec(), 1);
	}
}
void exit()
{
	Cross.INCLUDE(
#"#include <stdio.h>
#include <octave/oct.h>
#include <octave/octave.h>
#include <octave/toplev.h>
#include <octave/ov-struct.h>
#include <octave/parse.h>
#include <iostream>
using namespace std;
			");
	//werror("Octave destroy ...\n");
	Cross.CC("bin/octavecc.pike");// -std=c++0x  g++ `mkoctfile -p ALL_CXXFLAGS` -std=c++0x -shared -fPIC -lm `mkoctfile -p LFLAGS` `mkoctfile -p OCTAVE_LIBS` `mkoctfile -p FLIBS`
	C{
	 clean_up_and_exit (0);
	}
}

void main()
{
/*        c = [10, 6, 4]';
          A = [ 1, 1, 1;
               10, 4, 5;
                2, 2, 6];
          b = [100, 600, 300]';
          lb = [0, 0, 0]';
          ub = [];
          ctype = "UUU";
          vartype = "CCC";
          s = -1;

          param.msglev = 1;
          param.itlim = 100;

          [xmin, fmin, status, extra] = ...
             glpk (c, A, b, lb, ub, ctype, vartype, s, param);
*/

  //setup();

	/*array c=({10,6,4});
	array a=({({1,1,1}),
			 ({10,4,5}),
			 ({2,2,6})});
	array b=({100,600,300}); */

	/*
	array c=({1});
	array a=({({1}),	//x>=0 x<=100
			 ({-1}),			//x>=-100
			 });
	array b=({100,100});

	array res=glpk(c,a,b,
			({0}),({}),"LL","C",-1,(["msglev":1,"itlim":100]));
	werror("res=%O\n",res);
	*/

	array c=({10,6,4});
	array a=({({1,1,1}),
			 ({10,4,5}),
			 ({2,2,6})});
	array b=({100,600,300}); 
	array res=feval("glpk",4,
			ColumnVector(c),
			Matrix(a),
			ColumnVector(b),
			ColumnVector(({0,0,0})),
			ColumnVector(({})),"UUU","CCC",-1,octave_scalar_map((["msglev":1,"itlim":100])));
	werror("res=%O\n",res);
}
