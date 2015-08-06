#! /bin/env pike
#define BEGIN "open"
#define END "close"
#define MAX "maxval"
#define MIN "minval"


private class KDJTool{/*{{{*/
	protected float rsv(int n,array a,int i)
	{
		return (a[i][END]-min(@map(a[i-n+1..i],`[],MIN)))/(max(@map(a[i-n+1..i],`[],MAX))-min(@map(a[i-n+1..i],`[],MIN)));
	}
	protected float kdj_k(int n,array a,int i,float lastk)
	{
		catch{
			return lastk*2/3+rsv(n,a,i)*1/3;
		};
		return 0.5;
	}
	protected float kdj_d(int n,array a,int i,float lastk,float lastd)
	{
		catch{
			return lastd*2/3+kdj_k(n,a,i,lastk)*1/3;
		};
		return 0.5;
	}

	protected float kdj_j(int n,array a,int i,float lastk,float lastd)
	{
		return kdj_k(n,a,i,lastk)*3-kdj_d(n,a,i,lastk,lastd)*2;
	}
}/*}}}*/

int kdj_count_goldcross(array kdj,int n,float limit)
{
        int res;
        for(int i=max(0,sizeof(kdj)-n-1);i<sizeof(kdj)-1;i++){
                if(kdj[i][0]<limit&&kdj[i][0]<kdj[i][1]&&kdj[i+1][0]>kdj[i+1][1]){
                        res++;
                }
        }
        return res;
}
int kdj_count_deadcross(array kdj,int n,float limit)
{
        int res;
        for(int i=max(0,sizeof(kdj)-n-1);i<sizeof(kdj)-1;i++){
                if(kdj[i][0]>limit&&kdj[i][0]>kdj[i][1]&&kdj[i+1][0]<kdj[i+1][1]){
                        res++;
                }
        }
        return res;
}

class KDJ{
	inherit KDJTool;
	array a=({});
	array kdjlist=({({0.5,0.5,0.5})})*11;
	array ymdlist=({0})*11;
	array feed(object ymd,float open,float close,float maxval,float minval)
	{
		mapping info=(["open":open,"close":close,"maxval":maxval,"minval":minval]);
		a+=({info});
		float kk=kdj_k(9,a,sizeof(a)-1,kdjlist[-1][0]);
		float dd=kdj_d(9,a,sizeof(a)-1,kdjlist[-1][0],kdjlist[-1][1]);
		float jj=kdj_j(9,a,sizeof(a)-1,kdjlist[-1][0],kdjlist[-1][1]);
		kdjlist+=({({kk,dd,jj})});
		//append_kdj(kk,dd,jj);
		//Stdio.append_file(file,sprintf("%s,%f,%f,%f,%f,%f,%f,%f\n",ymd->format_ymd(),info->open,info->close,info->maxval,info->minval,kk,dd,jj));
		ymdlist+=({ymd});
		a=a[<10..];
		kdjlist=kdjlist[<10..];
		return query();
	};
	array query(int|void n)
	{
		return ({ymdlist[-(1+n)]})+kdjlist[-(1+n)];
	}
	array rollback()
	{
		a=a[..<1];
		kdjlist=kdjlist[..<1];
		ymdlist=ymdlist[..<1];
		return query();
	}
};
