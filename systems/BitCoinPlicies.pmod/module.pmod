#define DYNPROG
#include <class.h>
#define CLASS_HOST "BitCoinPlicies"
class DynClass{
#include <class_imp.h>
}

#include <assert.h>

#define MANUAL_VALUE_FILES "/home/work/btc/var/manual_values"

#define USING_BINARY_SEARCH

//#define WEEK_PHASE 1
//#define WEEK_AVG_SIZE 1
//#define CALENDAR_LINE_COUNT (2+WEEK_PHASE)
#define CALENDAR_LINE_COUNT 3

#define HOLD_MONTH -1
//#define HOLD_WEEK (-1-WEEK_PHASE)
#define HOLD_WEEK -2
#define HOLD_DAY (HOLD_WEEK-1)
#define HOLD_HOUR (HOLD_DAY-1)
#define HOLD_HALF_AN_HOUR (HOLD_HOUR-1)


class UniqIDStatic{
	class Static{
		int sn;
	};
}

class UniqID{
	int id=++(STATIC(UniqIDStatic)->sn);
}

class Event{};
class State{};
class Action(string str){};

class InState{ inherit State;}
class OutState{ inherit State;}
class ShortState{ inherit State;}
class WaitInState{ inherit State;}
class WaitOutState{ inherit State;}
class KdjWeekIn{ inherit InState;}
class RateIn{ inherit InState;}
class KdjMonthKeep{ inherit InState;}
class KdjWeekOut{ inherit OutState;}
class KdjMonthOut{ inherit OutState;}
class RateOut{ inherit OutState;}
class KdjWeekWaitIn{ inherit WaitInState;}

class StateMachine(object state){/*{{{*/
	extern array rules;
	
	Action feed(Event event)
	{
		foreach(rules,[program begin,program|multiset ev,string|void action,program end]){
			if(programp(ev))
				ev=(<ev>);
			if(Array.all((array)ev,lambda(program ev){
						if(Program.inherits(state,begin)&&Program.inherits(event,ev)){
							return 1;
						}}
						)){
				state=end();
				return action&&.Action(action);
			}
		}
	}
}/*}}}*/

class SpeedMode{/*{{{*/
	class Interface{};
	class Fast{
	};
	class Slow{
	}
}/*}}}*/
class DeltaSpeedMode{/*{{{*/
	class Interface{};
	class DeltaFast{
	};
	class DeltaSlow{
	};
}/*}}}*/

class RangeMode{/*{{{*/
	class Interface{};
	class Quarter{
	};
	class HalfAnHour{
	};
	class Hour{
	};
	class Day{
	};
	class Week{
	};
	class Month{
	};
}/*}}}*/

class Gx{ inherit Event; }
class Dx{ inherit Event; }
class Raise{ inherit Event; }
class RaiseX2{ inherit Raise; }
class Drop{ inherit Event; }
class DropX2{ inherit Drop; }
class StopLoss{ inherit Event; }

#define LONGSHORT_RANGE Hour
#define LONGSHORT_RANGE_QUARTERS 4
#define LONGSHORT_REVERSE
//#define LONGSHORT2
//#define START_POS (4*24*(365*2+364/2))
#define START_POS 0

class StateMachineLongShort{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.RaiseX2>),"sell",.ShortState}),
			//({ .OutState,(<.DropX2>),"buy",.InState}),
			({ .InState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"sell",.OutState}),
			({ .ShortState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"buy",.OutState}),
			({ .InState,.StopLoss,"sell",.OutState}),
			({ .ShortState,.StopLoss,"buy",.OutState}),
			});
}

class StateMachineKdjShort{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.LONGSHORT_RANGE>),"sell",.ShortState}),
			({ .InState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"sell",.OutState}),
			({ .ShortState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"buy",.OutState}),
			({ .InState,.StopLoss,"sell",.OutState}),
			({ .ShortState,.StopLoss,"buy",.OutState}),
			});
}
class StateMachineKdjLongShort{//只在慢涨时做多，快涨做多做空都是不利的
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.LONGSHORT_RANGE,.SpeedMode.Slow>),"buy",.InState}),
			//({ .OutState,(<.Gx,.RangeMode.LONGSHORT_RANGE,.SpeedMode.Fast>),"sell",.ShortState}),
			({ .InState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"sell",.OutState}),
			({ .ShortState,(<.Dx,.RangeMode.LONGSHORT_RANGE>),"buy",.OutState}),
			({ .InState,.StopLoss,"sell",.OutState}),
			({ .ShortState,.StopLoss,"buy",.OutState}),
			});
}
class StateMachineKdjReverseLongShort{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Dx,.RangeMode.LONGSHORT_RANGE,.SpeedMode.Fast>),"buy",.InState}),
			({ .OutState,(<.Dx,.RangeMode.LONGSHORT_RANGE,.SpeedMode.Slow>),"sell",.ShortState}),
			({ .InState,(<.Gx,.RangeMode.LONGSHORT_RANGE>),"sell",.OutState}),
			({ .ShortState,(<.Gx,.RangeMode.LONGSHORT_RANGE>),"buy",.OutState}),
			({ .InState,.StopLoss,"sell",.OutState}),
			({ .ShortState,.StopLoss,"buy",.OutState}),
			});
}

class StateMachineWeekInWeekOut{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.Week>),"buy",.KdjWeekIn}),
			({ .InState,(<.Dx,.RangeMode.Week>),"sell",.KdjWeekOut}),
			});
}
class StateMachineSlowWeekInWeekOut{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.Week,.SpeedMode.Slow>),"buy",.KdjWeekIn}),
			({ .OutState,(<.Gx,.RangeMode.Week,.SpeedMode.Fast>),0,.KdjWeekWaitIn}),
				({ .KdjWeekWaitIn,(<.Gx,.RangeMode.Day>),"buy",.KdjWeekIn}),
				({ .KdjWeekWaitIn,(<.Dx,.RangeMode.Week>),0,.KdjWeekOut}),
			({ .InState,(<.Dx,.RangeMode.Week>),"sell",.KdjWeekOut}),
			});
}

class StateMachine0NoWeekOut{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.Week>),"buy",.KdjWeekIn}),
			({ .OutState,.DropX2,"buy",.RateIn}),
			({ .InState,(<.Dx,.RangeMode.Month>),"sell",.KdjMonthOut}),
			({ .InState,.RaiseX2,"sell",.RateOut}),
			//({ .KdjWeekIn,(<.Dx,.RangeMode.Week>),"sell",.KdjWeekOut}),
			//({ .KdjWeekIn,(<.Gx,.RangeMode.Month>),0,.KdjMonthKeep}),
			});
}
class StateMachine0{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.Week>),"buy",.KdjWeekIn}),
			({ .OutState,.DropX2,"buy",.RateIn}),
			({ .InState,(<.Dx,.RangeMode.Month>),"sell",.KdjMonthOut}),
			({ .InState,.RaiseX2,"sell",.RateOut}),
			({ .KdjWeekIn,(<.Dx,.RangeMode.Week>),"sell",.KdjWeekOut}),
			({ .KdjWeekIn,(<.Gx,.RangeMode.Month>),0,.KdjMonthKeep}),
			});
}
class StateMachine1{
	inherit StateMachine;
	array rules=({
			({ .OutState,(<.Gx,.RangeMode.Week,.SpeedMode.Slow>),"buy",.KdjWeekIn}),
			({ .OutState,(<.Gx,.RangeMode.Week,.SpeedMode.Fast>),0,.KdjWeekWaitIn}),
				({ .KdjWeekWaitIn,(<.Gx,.RangeMode.Day>),"buy",.KdjWeekIn}),
				/* WaitIn rule begin */
				({ .KdjWeekWaitIn,.DropX2,"buy",.RateIn}),
				({ .KdjWeekWaitIn,(<.Dx,.RangeMode.Week>),0,.KdjWeekOut}),
				({ .KdjWeekWaitIn,(<.Gx,.RangeMode.Month>),0,.KdjMonthKeep}),
				({ .KdjWeekWaitIn,.RaiseX2,0,.RateOut}),
				//({ .KdjWeekWaitIn,.DxMonth,0,.KdjMonthOut}),
				/* WaitIn rule end */
			({ .OutState,.DropX2,"buy",.RateIn}),
			({ .InState,(<.Dx,.RangeMode.Month>),"sell",.KdjMonthOut}),
			({ .InState,.RaiseX2,"sell",.RateOut}),
			({ .KdjWeekIn,(<.Dx,.RangeMode.Week>),"sell",.KdjWeekOut}),
			({ .KdjWeekIn,(<.Gx,.RangeMode.Month>),0,.KdjMonthKeep}),
			/* WaitIn rule: 除非有规则指明，否则WaitIn适合使用所有的Out规则，并正常发
			 * 送买进信号；除非有规则指明，否则WaitIn适合使用所有的In规则，但不发
			 * 送麦出信号 */
			});
}

class MA(int n){/*{{{*/
	array a=({});
	int feed(object ymd,float open,float close,float maxval,float minval)
	{
		a+=({close});
		a=a[<n-1..];
		return `+(@a)/sizeof(a);
	}
}/*}}}*/
class CC{/*{{{*/
	float last_close;

	int dir;
	int total_count;
	int count;
	int fail_count;
	
	array feed(object ymd,float open,float close,float maxval,float minval)
	{
		total_count++;
		if(close>=last_close&&dir==1||close<=last_close&&dir==-1){
			count++;
		}else{
			fail_count++;
		}
		if(dir==0||fail_count>=2){
			dir=0;
			if(close>last_close)
				dir=1;
			else if(close<last_close)
				dir=-1;

			count=0;
			fail_count=0;
		}
		last_close=close;
		return ({total_count,count*dir});
	}
}/*}}}*/
class ANY{/*{{{*/
	int `[](mixed ig){return 1;}
}/*}}}*/

class BitCoinPliciesHandleRequestMode{
	class Interface{
	// sig:why:psig:pwhy
	// sig=1 持有 sig=0 空仓
	// psig=1 准备买进	psig=-1 准备卖出
		void handle_request(Protocols.HTTP.Server.Request r);
		void handle_manual_request(Protocols.HTTP.Server.Request r);
	}
	class NONE{
		void handle_request(Protocols.HTTP.Server.Request r){};
		void handle_manual_request(Protocols.HTTP.Server.Request r){};
	}
	class Default{
		extern mapping strategies;
		extern mapping strategies_why;
		extern mapping strategies_prepare;
		extern mapping strategies_prepare_why;
		extern float|void currprice;
		extern object strategy_db;
		void handle_request(Protocols.HTTP.Server.Request r)/*{{{*/
		{
			mapping m=r->variables;
			int t=(int)m->t;
			string data;
			string pdata;
			string pricedata;
			if(t==0){
				data=sprintf("%d:%s",(strategies||([]))[m->id],(strategies_why||([]))[m->id]||"unknown");
				pdata=sprintf("%d:%s",(strategies_prepare||([]))[m->id],(strategies_prepare_why||([]))[m->id]||"unknown");
				if(currprice!=0)
					pricedata=sprintf("%.8f",currprice);
				else
					pricedata="unknown";
			}else{
				t=t/(60*15)*(60*15);
				if(strategy_db[sprintf("%d",t)]){
					[mapping val,mapping why,mapping pval,mapping pwhy,float openval]=decode_value(strategy_db[sprintf("%d",t)]);
					data=sprintf("%d:%s",val[m->id],why[m->id]||"unknown");
					pdata=sprintf("%d:%s",pval[m->id],pwhy[m->id]||"unknown");
					pricedata=sprintf("%.8f",openval);
				}else{
					data="-1:unknown";
					pdata="0:unknown";
					pricedata="unknown";
				}
			}
			data=data+":"+pdata+":"+pricedata;
			werror("http req: id=%s,t=%d;data=%s\n",m->id,t,data);
			r->response_and_finish(([
						"data":data,
						"error":202,
						"length":sizeof(data),
						]));
		}/*}}}*/
		void handle_manual_request(Protocols.HTTP.Server.Request r)/*{{{*/
		{
			mapping m=r->variables;
			int t=(int)m->t;
			string data;
			string pdata;
			string pricedata;
			string str=Stdio.read_file(MANUAL_VALUE_FILES);
			int sig,psig;
			if(sscanf(str,"%d:%d",sig,psig)<2){
				data="";
				r->response_and_finish(([
							"data":data,
							"error":202,
							"length":sizeof(data),
							]));
				return;
			}

			data=sprintf("%d:%s",sig,"manual");
			pdata=sprintf("%d:%s",psig,"manual");
			if(currprice!=0)
				pricedata=sprintf("%.8f",currprice);
			else
				pricedata="unknown";
			data=data+":"+pdata+":"+pricedata;
			werror("http req: id=%s,t=%d;data=%s\n",m->id,t,data);
			r->response_and_finish(([
						"data":data,
						"error":202,
						"length":sizeof(data),
						]));
		}/*}}}*/

	}
}

class ExtraLines{
	array week_alters=({});
	int extra_lines_startpos=0;
	array extra_lines=({0})*CALENDAR_LINE_COUNT;

	// 更新 day,week,month K线。从lines的最大粒度的K线中生成，采用增量方式以提高效率，如果skiplast=1忽略掉原K线中最后一项。
	// 由于 lines 中的K线的最后一个时间段总是不完整的，所以取skiplast=1可以一致地处理最后一个时间段尚不完整的情况；只有在我们希望即使对于不完整的时间段也为之生成 day,week,month K线的时候，取 skiplast=0。但这使得 day,week,month K线特性和lines中的K线不一致；并且在 lines 中的K线刚刚生成了新的时间段的时候，day,week,month K线缺失了这个时间段
	// 在 Candle.calendar_line 中修正了这个问题，现在对于skiplast的处理为：对最后一个时间段不计入volume，因为对于 minval,maxval,openval,closeval 把最后一个时间段反复计算是OK的，只有volume只能计算一次
	// 现在 day,week,month K线和 lines 里面的K线只有一个区别，就是 lines 最大力度的K线的最后一项的volume没有被计入
	void update_extra_lines(object lines,mapping conf)/*{{{*/
	{
		int skiplast=1;
		extra_lines[0]=lines->a[-1]->day_line(0,extra_lines[0],extra_lines_startpos,skiplast);
		week_alters=({});
		/*
		for(int i=0;i<WEEK_PHASE;i++){
			extra_lines[1+i]=lines->a[-1]->week_line(7*3600*24/WEEK_PHASE*i,extra_lines[1+i],extra_lines_startpos,skiplast);
			week_alters+=({7*3600*24/WEEK_PHASE*i});
		}
		*/
		int n,m;
		if(conf->week_alter_flag)
			sscanf(conf->week_alter,"%d.%d",n,m);
		extra_lines[1]=lines->a[-1]->week_line(-3600*24*n-3600*m,extra_lines[1],extra_lines_startpos,skiplast);
		week_alters+=({-3600*24*n-3600*m});
		extra_lines[-1]=lines->a[-1]->month_line(0,extra_lines[-1],extra_lines_startpos,skiplast);
		extra_lines_startpos=sizeof(lines->a[-1])-(skiplast?1:0);
	};/*}}}*/


}


class BitCoinPliciesMode{
	class Interface{
		//lines的第i个最小时间片，进入的时候执行，制定策略
		void handle_level_advance_open(object lines,int i);
		//lines的第i个最小时间片，离开的时候执行，结算损益
		void handle_level_advance_close(object lines,int i);

		void setup();
	}
	class UsingStateMachine{
		extern mapping conf;
		extern int start_pos;

		array kdjs=({});
		array ccs=({});
		array mas=({});
		array gxs;
		array dxs;
		array next_holds;
		array ccvals;
		array ttvals;
		array mavals;
		array rates=({});
		array drates=({});

		/* handle_level_advance_close vars begin */
		float last_curr=0.0;
		float curr=0.0;

		array last_timevals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);

		mapping strategies;
		mapping|object last_strategies=.ANY();
		mapping strategy2ratecurr=([]);

		mapping strategy2rate=([]);
		//mapping strategy2rangerate=([]);
		mapping strategy2maxrate=([]);
		mapping strategy2maxdrop=([]);

		extern array week_alters;
		extern array extra_lines;
		extern void update_extra_lines(object lines,mapping conf);
		/* handle_level_advance_close vars end */

		mapping states=([]);
		//lines的第i个最小时间片，进入的时候执行，制定策略
		void handle_level_advance_open(object lines,int i)/*{{{*/
		{

	/* 如果当前没有持有，周线金叉kdjin，暴跌30分钟ratein
		 如果当前持有，月线死叉kdjout，暴涨30分钟rateout，另外有gateout规则如下
			 如果进入是周线金叉kdjin，允许周线死叉gateout，除非月线优先发生金叉
		 希望修改如下：
			 如果月线金叉发生，等待一个日线金叉再进入
		 这是一个状态机，画状态转换图：

		 *out-(gx of week)-[buy]->kdjin
				.-(dropx2)-[buy]->ratein
				
		 *in -(dx of month)-[sell]->kdjout
				.-(raisex2)-[sell]->rateout

		 kdjin-(dx of week)-[sell]->gateout
				 .-(gx of month)->monthkeepin

		 修改如下：

		 *out-(gx of week)->kdjwaitin-(gx of day)-[buy]->kdjin
				.                     .-(dropx2)-[buy]->ratein
				. 										.-(dx of month)->kdjout
				. 										.-(raisex2)->rateout
				. 										.-(dx of week)->gateout
				. 										.-(gx of month)->monthin
				.-(dropx2)-[buy]->ratein

		 *in -(dx of month)-[sell]->kdjout
				.-(raisex2)-[sell]->rateout

		 kdjin-(dx of week)-[sell]->gateout
				 .-(gx of month)->monthin

		 上述修改可能有误，以代码为准。

			 */
			strategies=([
					"in":1,
					"short":-1,
					]);

			
			//strategies_prepare=([]);

			object m;
			m=Matrix.Matrix(([
						"enter_rate":({5,5,1}),
						"leave_rate":({5,5,1}),
						"fast_dayrate":({-20,20,5}),
						"normal_widow":({0,5,5}),
						]));
			float fee=0.003;

			m->_foreach(lambda(mapping m){
					int d=m->enter_rate;
					int s=m->leave_rate;
					int q=m->fast_dayrate;
					int p=m->normal_widow;

					string key;
					key=sprintf("b%ds%dn%df%d",d,s,p,q);
					//string why;

					int daysize=LONGSHORT_RANGE_QUARTERS;

					float dayrate=`*(1.0,@rates[<daysize-1..]);
					float ddayrate=`*(1.0,@rates[<daysize-1..])/`*(1.0,@rates[<daysize*2-1..daysize]);
					float limitup=1+1.0*(q+p)/100;
					float limitnoup=1+1.0*(q-p)/100;
					float limitdown=1-1.0*(q+p)/100;
					float limitnodown=1-1.0*(q-p)/100;

					int fast_flag_up,fast_flag_down;
					int slow_flag_up,slow_flag_down;
					if(dayrate>limitup){
						fast_flag_up=1;
					}else if(dayrate<limitnoup){
						slow_flag_up=1;
					}
					if(dayrate<limitdown){
						fast_flag_down=1;
					}else if(dayrate>limitnodown){
						slow_flag_down=1;
					}
					/*int dfast_flag;
					int dslow_flag;
					if(ddayrate>limitup){
						dfast_flag=1;
					}
					if(ddayrate<limitdown){
						dfast_flag=-1;
					}
					if(!dfast_flag){
						if(ddayrate<limitnoup&&ddayrate>limitnodown){
							dslow_flag=1;
						}
					}*/

					//werror("dayrate=%f up=%f down=%f fast_flag=%d\n",dayrate,limitup,limitdown,fast_flag);

					array rangerates=({});
					for(int i=1;i<4*24;i*=2){
						rangerates+=({
								`*(1.0,@rates[<i-1..]),
								});
					}

					if(states[key]==0){
#ifdef LONGSHORT2
						states[key]=.StateMachineLongShort(.OutState());
#else

#ifdef LONGSHORT_REVERSE
						states[key]=.StateMachineKdjReverseLongShort(.InState());
#else
						states[key]=.StateMachineKdjLongShort(.InState());
#endif
#endif
					}

					object action;

					if(strategy2ratecurr[key]==0){
						strategy2ratecurr[key]=1.0;
					}
					if(strategy2ratecurr[key]<0.5){
						action=action||states[key]->feed(.StopLoss());
					}

					array classobs=({});
					if(gxs[HOLD_HALF_AN_HOUR]){
						classobs+=({CLASS_OBJECT(Gx,RangeMode.HalfAnHour)});
					}
					if(gxs[HOLD_HOUR]){
						classobs+=({CLASS_OBJECT(Gx,RangeMode.Hour)});
					}
					if(gxs[HOLD_DAY]){
						classobs+=({CLASS_OBJECT(Gx,RangeMode.Day)});
					}
					if(gxs[HOLD_WEEK]){
						classobs+=({CLASS_OBJECT(Gx,RangeMode.Week)});
					}
					if(gxs[HOLD_MONTH]){
						classobs+=({CLASS_OBJECT(Gx,RangeMode.Month)});
					}

					if(gxs[HOLD_HALF_AN_HOUR]){
						classobs+=({CLASS_OBJECT(Dx,RangeMode.HalfAnHour)});
					}
					if(dxs[HOLD_HOUR]){
						classobs+=({CLASS_OBJECT(Dx,RangeMode.Hour)});
					}
					if(dxs[HOLD_DAY]){
						classobs+=({CLASS_OBJECT(Dx,RangeMode.Day)});
					}
					if(dxs[HOLD_WEEK]){
						classobs+=({CLASS_OBJECT(Dx,RangeMode.Week)});
					}
					if(dxs[HOLD_MONTH]){
						classobs+=({CLASS_OBJECT(Dx,RangeMode.Month)});
					}

					foreach(classobs,object classob){
						if(Program.inherits(classob,.Gx)){
							if(fast_flag_up)
								classob->add_feature("SpeedMode.Fast");
							else if(slow_flag_up)
								classob->add_feature("SpeedMode.Slow");
						}
						if(Program.inherits(classob,.Dx)){
							if(fast_flag_down)
								classob->add_feature("SpeedMode.Fast");
							else if(slow_flag_down)
								classob->add_feature("SpeedMode.Slow");
						}
					}
					/*if(dslow_flag){
						foreach(classobs,object classob){
							classob->add_feature("DeltaSpeedMode.DeltaSlow");
						}
					}else if(dfast_flag){
						foreach(classobs,object classob){
							if(Program.inherits(classob,.Gx)&&dfast_flag>0)
								classob->add_feature("DeltaSpeedMode.DeltaFast");
							else if(Program.inherits(classob,.Dx)&&dfast_flag<0)
								classob->add_feature("DeltaSpeedMode.DeltaFast");
						}
					}*/
					foreach(classobs,object classob){
						action=action||states[key]->feed(classob());
					}
					int K=2,KD=0;float B=1-1.0*d/100;
					if(sizeof(rates)>=(K)&&Array.all(rates[<(K)+(KD)-1..<(KD)],`<,(B))){
						action=action||states[key]->feed(.DropX2());
					}
					int N=2,ND=0;float R=1+1.0*s/100;
					if(sizeof(rates)>=(N)&&Array.all(rates[<(N)+(ND)-1..<(ND)],`>,(R))){
						action=action||states[key]->feed(.RaiseX2());
					}


					//strategies_prepare[key]=0;
					//strategies_prepare_why[key]=0;


					if(action){
						strategy2ratecurr[key]=1.0;
						strategy2rate[key]*=1.0-fee;
					}
					if(Program.inherits(states[key]->state,.InState)){
						strategies[key]=1;
					}else if(Program.inherits(states[key]->state,.ShortState)){
						strategies[key]=-1;
					}else{
						strategies[key]=0;
					}

			});
			/*if(ttvals[HOLD_WEEK]<=20){
				foreach(strategies;string key;int val){
					strategies[key]=0;
					//strategies_why[key]=0;
					//strategies_prepare[key]=0;
					//strategies_prepare_why[key]=0;
				}
			}*/

			//last_holds=copy_value(holds);

			
			object item=lines->line(Candle.all_intervals[conf->start_interval_level])->a[i-1];

			float currprice=0.0;

			if(item->volume){
				currprice=item->closeval;
				string s="";
				s+=sprintf("- %s %f/%f %s",Calendar.ISO.Second(item->timeval)->format_time_short(),last_curr,currprice,map(next_holds,Cast.stringfy)*" ");
				foreach(SortMapping.sort_values(strategies);string key;int ig){
					s+=sprintf(" %s:%d->%d:%s:%d:%s:%s",key,last_strategies[key],strategies[key],((sprintf("%O",states[key]?->state)/".")[-1]/"(")[0],/*strategies_prepare[key]*/0,/*strategies_prepare_why[key]||*/"",/*gate[key]?"o":"x"*/"");
				}
				s+="\n";
				if(conf->out_flag){
					Stdio.append_file(conf->outfilestr,s);
				}else{
					write("%s",s);
				}
			}
			//if(strategy_db)
				//strategy_db[sprintf("%d",item->timeval)]=encode_value(({strategies,strategies_why,strategies_prepare,strategies_prepare_why,currprice}));
				
		};/*}}}*/
		//lines的第i个最小时间片，离开的时候执行，结算损益
		void handle_level_advance_close(object lines,int i)/*{{{*/
		{
			//werror("handle_level_advance_close: i=%d\n",i);
			object item=lines->line(Candle.all_intervals[conf->start_interval_level])->a[i];

			last_curr=curr;
			if(item->volume){
				curr=item->closeval;
			}

			//计算rate,drate
			if(last_curr!=0.0){
				rates+=({curr/last_curr});
				if(sizeof(rates)>=2)
					drates+=({rates[-2]/rates[-1]});
			}

			int active;

			void handle_item(int n,object item,mixed info/*,int week_mode,int|void week_base*/)/*{{{*/
			{
				//werror("handle_item: n=%d %O %O",n,info,item->save());
				if(item->volume){
					active=1;
					if(last_curr!=0.0&&last_curr!=item->closeval){
						werror("last_curr=%f curr=%f item->closeval=%f n=%d\n",last_curr,curr,item->closeval,n);
						throw(({"closeval not match.\n",backtrace()}));
					}
					//curr=item->closeval;
					int lk,ld,lj,k,d,j;
					object ltm,tm;

					[ltm,lk,ld,lj]=kdjs[n]->query();
					if(conf->ockdj_flag)
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,max(item->openval,item->closeval),min(item->openval,item->closeval));
					else if(conf->oclkdj_flag)
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,max(item->openval,item->closeval),item->minval);
					else
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);

					[int tt,int cc]=ccs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);
					int mav=mas[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);

					int upflag=k>d;
					int gx=k>d&&lk<ld;
					int dx=k<d&&lk>ld;
					//int hold=dx||upflag&&!gx;
					int nexthold=upflag;

					//holds[n]=hold;
					next_holds[n]=nexthold;
					gxs[n]=gx;
					dxs[n]=dx;
					ccvals[n]=cc;
					ttvals[n]=tt;
					mavals[n]=mav;
				}
			};/*}}}*/
			for(int n=conf->start_interval_level;n<sizeof(Candle.all_intervals);n++){
#ifndef CHANGE
				int timeval=Time.align(item->timeval,Candle.all_intervals[n]);
#else
				int timeval=Time.align(item->timeval+Candle.all_intervals[conf->start_interval_level],Candle.all_intervals[n]);//CHANGED
				int last_timeval=last_timevals[n];//CHANGED
#endif
				if(timeval>last_timevals[n]){
					last_timevals[n]=timeval;
					object line=lines->line(Candle.all_intervals[n]);
#ifndef CHANGE
					int pos=line->search(timeval);
#else
					int pos=line->search(last_timeval);//CHANGED
#endif
					//werror("n=%d,pos=%d\n",n,pos);
					if(pos>=0){
							if(pos>0){
#ifndef CHANGE
								handle_item(n,line->a[pos-1],pos-1);
#else
								handle_item(n,line->a[pos],pos);//CHANGED
#endif
							}
					}else{
						throw(({Candle.all_intervals[n]+" not found.\n",backtrace()}));
					}
				}
			}

			foreach(extra_lines;int nn;object line){
				int n=sizeof(Candle.all_intervals)+nn;
				string key;int alter;
				if(nn==0){
					key="day";alter=0;
				}else if(/*nn-1>=0&&nn-1<WEEK_PHASE*/nn==1){
					key="week";alter=week_alters[nn-1];
				}else{
					key="month";alter=0;
				}
#ifndef CHANGE
				int timeval=Calendar.ISO.Second(item->timeval+alter)[key]()->unix_time()-alter;
#else
				int timeval=Calendar.ISO.Second(item->timeval+Candle.all_intervals[conf->start_interval_level]+alter)[key]()->unix_time()-alter;//CHANGED
				int last_timeval=last_timevals[n];//CHANGED
#endif
				if(timeval>last_timevals[n]){
					last_timevals[n]=timeval;

#ifndef CHANGE
					int pos=line->search(timeval);
#else
					int pos=line->search(last_timeval);//CHANGED
#endif
					if(pos>=0){
							if(pos>0){
#ifndef CHANGE
								handle_item(n,line->a[pos-1],pos-1);
#else
								handle_item(n,line->a[pos],pos);//CHANGED
#endif
							}
					}else{
						throw(({key+" not found.\n",backtrace()}));
					}
				}
			}

			/*string oyd=strategy_db[sprintf("%d",item->timeval-365*24*3600)];
			mapping oneyear=([]);
			if(oyd){
				[mapping val,mapping why,mapping pval,mapping pwhy,float openval]=decode_value(oyd);
				oneyear=val;//decode_value(oyd);
			}*/

			last_strategies=copy_value(strategies);
			foreach(strategies;string key;int hold){
				strategy2rate[key]=strategy2rate[key]||1.0;
				//strategy2rangerate[key]=strategy2rangerate[key]||1.0;
				strategy2maxrate[key]=strategy2maxrate[key]||1.0;
				//strategy2recentrate[key]=strategy2recentrate[key]||({});
				strategy2maxdrop[key]=strategy2maxdrop[key]||1.0;
				//strategy2recentdrop[key]=strategy2recentdrop[key]||1.0;
				if(hold&&sizeof(rates)){
					//if(!mappingp(strategy2rate))
						//werror("strategy2rate=%O\n",strategy2rate);
					//if(!mappingp(strategy2rangerate))
						//werror("strategy2rangerate=%O\n",strategy2rangerate);
					//if(!mappingp(oneyear))
						//werror("oneyear=%O\n",oneyear);
					if(hold>0){
						strategy2rate[key]*=rates[-1];
						strategy2ratecurr[key]*=rates[-1];
					}else if(hold<0&&strategy2rate[key]>0){
						strategy2rate[key]*=2-rates[-1];
						strategy2ratecurr[key]*=2-rates[-1];
					}
					//strategy2rangerate[key]*=rates[-1];
					//if(oneyear[key]){
						//strategy2rangerate[key]/=rates[-365*24*4];
					//}
					//strategy2recentrate[key]+=({strategy2rate[key]});
					//strategy2recentrate[key]=strategy2recentrate[key][<29..];
					strategy2maxrate[key]=max(strategy2maxrate[key],strategy2rate[key]);
					strategy2maxdrop[key]=min(strategy2maxdrop[key],strategy2rate[key]/strategy2maxrate[key]);
					/*if(sizeof(strategy2recentrate[key])){
						strategy2recentdrop[key]=strategy2rate[key]/(`+(0.0,@strategy2recentrate[key])/(sizeof(strategy2recentrate[key])));
					}*/
				}
			}
			if(active&&sizeof(rates)>0){
				string s="";
				s+=sprintf("+ %s %f %f",Calendar.ISO.Second(item->timeval)->format_time_short(),last_curr,rates[-1],/*map(holds,`+,"")*" "*/);
				float maxrate=max(@values(strategy2rate));
				foreach(SortMapping.sort_values(strategy2rate);string key;float rate){
					s+=sprintf(" %s=%.1f,%.2f,%.2f",key,rate,1-strategy2maxdrop[key],rate/maxrate);
				}
				s+="\n";
				if(conf->out_flag){
					Stdio.append_file(conf->outfilestr,s);
				}else{
					write("%s",s);
				}
				if(conf->crfpp_sample_out_flag){
					if(sizeof(rates)>4*24*7+4*24){
						float r=`*(1.0,@rates[<4*24*7+4*24-1..4*24*7]);
						string s="R"+(int)(r*100)/5*5;

						for(int i=50;i<=150;i+=5){
							if(r>i/100.0){
								s+=" U"+i;
							}else{
								s+=" D"+i;
							}
						}
						s+=" "+map(next_holds,`+,"")*" ";
						r=`*(1.0,@rates[<4*24*7-1..]);
						if(r>1.2){
							s+=" U";
						}else if(r<0.8){
							s+=" D";
						}else{
							s+=" N";
						}
						s+="\n";
						Stdio.append_file(conf->crfpp_sample_outfilestr,s);
					}
				}
			}
		};/*}}}*/

		void setup()
		{
			start_pos=START_POS;

			for(int i=0;i<sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT;i++){
				kdjs+=({KDJ.KDJ()});
				ccs+=({.CC()});
				mas+=({.MA(7)});
				//states+=({StateMachine()});
			}
			gxs=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			dxs=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			next_holds=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			ccvals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			ttvals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			mavals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
		}
	}
	class Default{
		mapping|object last_strategies=.ANY();
		mapping|object gate=.ANY();
		mapping strategies_prepare;
		mapping strategies_prepare_why=([]);
		mapping strategies_why=([]);
		float|void currprice=0;
		array kdjs=({});
		array ccs=({});
		array mas=({});
		array holds;
		array next_holds;
		array last_holds;
		array gxs;
		array dxs;
		array ccvals;
		array ttvals;
		array mavals;
		int interval=Candle.all_intervals[0];
		int active=0;
		float last_curr=0.0;
		float curr=0.0;

		array rates=({});
		array drates=({});

		mapping strategy2rate=([]);
		mapping strategy2rangerate=([]);
		mapping strategy2maxrate=([]);
		mapping strategy2maxdrop=([]);

		array last_timevals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);

		mapping strategies;
		object strategy_db;

		extern mapping conf;

		extern array week_alters;
		extern array extra_lines;
		extern void update_extra_lines(object lines,mapping conf);

		extern object lines;

		//lines的第i个最小时间片，进入的时候执行，制定策略
		void handle_level_advance_open(object lines,int i)/*{{{*/
		{

#define SET_IF(X,VAR,VAL) ((X)?((VAR=VAL),(X)):0)
#define SET_IFNOT(X,VAR,VAL) ((X)?(X):((VAR=VAL),0))

#ifdef USING_HOLDS
#define KDJIN_KDJOUT(KEY,HOLD1,HOLD2) (!last_strategies[KEY]&&!last_holds[HOLD1]&&holds[HOLD1]||last_strategies[KEY]&&!(last_holds[HOLD2]&&!holds[HOLD2]))
#define KDJIN_CC_KDJOUT(KEY,HOLD1,HOLD2,N) (!last_strategies[KEY]&&!last_holds[HOLD1]&&holds[HOLD1]||last_strategies[KEY]&&!(ccvals[HOLD_WEEK]>=N&&!holds[HOLD2]))
	//#define KDJIN_CC_MAOUT(KEY,HOLD1,HOLD2,N) (!last_strategies[KEY]&&!last_holds[HOLD1]&&holds[HOLD1]||last_strategies[KEY]&&!(ccvals[HOLD_WEEK]>=N&&item->closeval<mavals[HOLD2]))

#define KDJIN_KDJOUTGATE_RATEOUT(KEY,HOLD1,HOLD2,K,KD,B,N,ND,R,T,TD,Q) (\
			 (/*enter*/\
				!last_strategies[KEY]&&(\
					(SET_IF(!last_holds[HOLD1]&&holds[HOLD1],why,"kdjin")\
					||SET_IF(sizeof(rates)>=(K)&&Array.all(rates[<(K)+(KD)-1..<(KD)],`<,(B)),why,"ratein")\
					)\
				)\
			 )\
			 ||\
			 (/*leave*/\
				last_strategies[KEY]&&(\
					!(SET_IF(last_holds[HOLD2]&&!holds[HOLD2],why,"kdjout"))\
					&&!(SET_IF(last_holds[HOLD1]&&!holds[HOLD1]&&gate[KEY],why,"gateout"))\
					&&!(SET_IF(sizeof(rates)>=(N)&&Array.all(rates[<(N)+(ND)-1..<(ND)],`>,(R)),why,"rateout"))\
					)\
				)\
			)
					//&&!(SET_IF(sizeof(drates)>=(T)&&rates[(T)+(TD)-1]>1.0&&Array.all(drates[<(T)+(TD)-1..<(TD)],`>,(Q)),why,"drateout"))\
					//&&!(SET_IF((ccvals[HOLD_WEEK]>=8&&`*(1.0,@rates[<(N2)-1..])>(R2)/*&&`*(1.0,@rates[<(N2)*2-1..(N2)])>(R2)*/),why,"dayrateout"))\

#define KDJIN_RATEOUT(KEY,HOLD1,HOLD2,K,B,N,R) (!last_strategies[KEY]&&(\
				(!last_holds[HOLD1]&&holds[HOLD1])\
				||(sizeof(rates)>=K&&Array.all(rates[<K-1..],`<,B))\
				)||last_strategies[KEY]&&(\
					!(sizeof(rates)>=N&&Array.all(rates[<N-1..],`>,R))\
					))
#else
#define KDJIN_KDJOUT(KEY,HOLD1,HOLD2) (!last_strategies[KEY]&&gxs[HOLD1]||last_strategies[KEY]&&!(dxs[HOLD2]))
#define KDJIN_CC_KDJOUT(KEY,HOLD1,HOLD2,N) (!last_strategies[KEY]&&gxs[HOLD1]||last_strategies[KEY]&&!(ccvals[HOLD_WEEK]>=N&&!dxs[HOLD2]))


	/* 如果当前没有持有，周线金叉kdjin，暴跌30分钟ratein
		 如果当前持有，月线死叉kdjout，暴涨30分钟rateout，另外有gateout规则如下
			 如果进入是周线金叉kdjin，允许周线死叉gateout，除非月线优先发生金叉
		 希望修改如下：
			 如果月线金叉发生，等待一个日线金叉再进入
		 这是一个状态机，画状态转换图：

		 *out-(gx of week)-[buy]->kdjin
				.-(dropx2)-[buy]->ratein
				
		 *in -(dx of month)-[sell]->kdjout
				.-(raisex2)-[sell]->rateout

		 kdjin-(dx of week)-[sell]->gateout
				 .-(gx of month)->monthkeepin

		 修改如下：

		 *out-(gx of week)->kdjwaitin-(gx of day)-[buy]->kdjin
				.                     .-(dropx2)-[buy]->ratein
				. 										.-(dx of month)->kdjout
				. 										.-(raisex2)->rateout
				. 										.-(dx of week)->gateout
				. 										.-(gx of month)->monthin
				.-(dropx2)-[buy]->ratein

		 *in -(dx of month)-[sell]->kdjout
				.-(raisex2)-[sell]->rateout

		 kdjin-(dx of week)-[sell]->gateout
				 .-(gx of month)->monthin

		 上述修改可能有误，以代码为准。

			 */
#define KDJIN_KDJOUTGATE_RATEOUT(KEY,HOLD1,HOLD2,K,KD,B,N,ND,R,T,TD,Q) (\
			 (/*enter*/\
				!last_strategies[KEY]&&(\
					(SET_IF(gxs[HOLD1],why,"kdjin")\
					||SET_IF(sizeof(rates)>=(K)&&Array.all(rates[<(K)+(KD)-1..<(KD)],`<,(B)),why,"ratein")\
					)\
				)\
			 )\
			 ||\
			 (/*leave*/\
				last_strategies[KEY]&&(\
					!(SET_IF(dxs[HOLD2],why,"kdjout"))\
					&&!(SET_IF(dxs[HOLD1]&&gate[KEY],why,"gateout"))\
					&&!(SET_IF(sizeof(rates)>=(N)&&Array.all(rates[<(N)+(ND)-1..<(ND)],`>,(R)),why,"rateout"))\
					)\
				)\
			)
					//&&!(SET_IF(sizeof(drates)>=(T)&&rates[(T)+(TD)-1]>1.0&&Array.all(drates[<(T)+(TD)-1..<(TD)],`>,(Q)),why,"drateout"))\
					//&&!(SET_IF((ccvals[HOLD_WEEK]>=8&&`*(1.0,@rates[<(N2)-1..])>(R2)/*&&`*(1.0,@rates[<(N2)*2-1..(N2)])>(R2)*/),why,"dayrateout"))\

#define KDJIN_RATEOUT(KEY,HOLD1,HOLD2,K,B,N,R) (!last_strategies[KEY]&&(\
				(gxs[HOLD1])\
				||(sizeof(rates)>=K&&Array.all(rates[<K-1..],`<,B))\
				)||last_strategies[KEY]&&(\
					!(sizeof(rates)>=N&&Array.all(rates[<N-1..],`>,R))\
					))
#endif

			strategies=([
					"in":1,
					"wiwo":next_holds[HOLD_WEEK],

					//"dkwo":holds[HOLD_DAY]||last_strategies["dkwo"]&&holds[HOLD_WEEK],
					//"aiao":holds[sizeof(Candle.all_intervals)+1+active_phase], //使用周KDJ的相位
					//"worm":holds[HOLD_WEEK]||holds[HOLD_MONTH],
					//"wkmo":holds[HOLD_WEEK]||last_strategies["wkmo"]&&holds[HOLD_MONTH],

					]);

			
			strategies_prepare=([]);

			if(objectp(gate)&&object_program(gate)==.ANY){
				gate=([]);
			}

			object m;
			//if(conf->follow_stdin_flag){
				if(conf->enable_dynamic_flag){
					m=Matrix.Matrix(([
								"enter_rate":({1,16,1}),
								"leave_rate":({1,16,1}),
								]));
				}else{
					m=Matrix.Matrix(([
								"enter_rate":({5,5,1}),
								"leave_rate":({5,5,1}),
								]));
				}
			/*}else{
				m=Matrix.Matrix(([
							"enter_rate":({5,6,1}),
							"leave_rate":({5,6,1}),

							//"delay_level":({0,5,1}),
							"leave_drate":({1,9,1}),
							"leave_drate_count":({3,6,1}),

							]));
			}*/
			//"gate_delta":({2,5,1}),

			m->_foreach(lambda(mapping m){
					int k=m->enter_rate;
					int i=m->leave_rate;
					int j=m->gate_delta;
					int q=m->leave_drate;
					int x=m->leave_drate_count;

					string key;
					//if(!conf->follow_stdin_flag){
						//key=sprintf("b%ds%dg%dq%dx%d",k,i,j,q,x);
					//}else{
						key=sprintf("b%ds%dg%d",k,i,j);
					//}
					string why;

					why=0;
					int psig=KDJIN_KDJOUTGATE_RATEOUT(key,HOLD_WEEK,HOLD_MONTH,
							1,0,1-1.0*k/100,
							1,0,1+1.0*i/100,
							0,0,0.0//x,0,1+1.0*q/1000
							);
					if(psig!=last_strategies[key]){
						if(psig==1)
							strategies_prepare[key]=1;
						else
							strategies_prepare[key]=-1;
						strategies_prepare_why[key]=why;
					}else{
						strategies_prepare[key]=0;
						strategies_prepare_why[key]=0;
					}

					why=0;
					strategies[key]=KDJIN_KDJOUTGATE_RATEOUT(key,HOLD_WEEK,HOLD_MONTH,
							2,0,1-1.0*k/100,
							2,0,1+1.0*i/100,
							0,0,0.0//x,0,1+1.0*q/1000
							);
					if(why)
						strategies_why[key]=why;

					
					if(strategies_why[key]=="kdjin"){
						gate[key]=1;
					}

					if(holds[HOLD_MONTH]){
						gate[key]=0;
					}
				
					//gate[key]=1;
			});
			if(conf->follow_stdin_flag&&conf->enable_dynamic_flag){/*{{{*/
				do{
					foreach(SortMapping.sort_values(strategy2rangerate,1);string key;float value){
						if(has_prefix(key,"dynamic")){
							continue;
						}
						int k,i,j;
						if(sscanf(key,"b%ds%dg%d",k,i,j)!=3)
							continue;
						if(k>10||i>10)
							continue;
						for(int q=0;q<=5;q++){
							if(value>5.0){
								string key1=sprintf("b%ds%dg%d",k+q,i+q,j);
								strategies["dynamic"+q]=strategies[key1];
								strategies_why["dynamic"+q]=strategies_why[key1];
							}else{
								strategies["dynamic"+q]=strategies["in"];
							}
						}
						break;
					}
					strategies["dynamic"]=strategies["in"];
					foreach(SortMapping.sort_values(strategy2rangerate,1);string key;float value){
						if(key!="dynamic"&&has_prefix(key,"dynamic")){
							if(value>25.0){
								strategies["dynamic"]=strategies[key];
								strategies_why["dynamic"]=strategies_why[key];
							}else{
								strategies["dynamic"]=strategies["dynamic0"];
								strategies_why["dynamic"]=strategies_why["dynamic0"];
							}
							break;
						}
					}
				}while(0);
			}/*}}}*/

			/*for(int i=5;i<10;i+=1){
				string k="wic"+i+"wo";
				strategies[k]=KDJIN_CC_KDJOUT(k,HOLD_WEEK,HOLD_WEEK,i);
			}*/
			if(ttvals[HOLD_WEEK]<=20){
				foreach(strategies;string key;int val){
					strategies[key]=0;
					strategies_why[key]=0;
					strategies_prepare[key]=0;
					strategies_prepare_why[key]=0;
				}
			}
			/*foreach(strategies;string key;int val){
				strategies[key]=ttvals[HOLD_WEEK]>20&&val;
			}
			foreach(strategies_prepare;string key;int val){
				strategies_prepare[key]=ttvals[HOLD_WEEK]>20&&val;
			}*/

			last_holds=copy_value(holds);
			//werror("i=%d\n",i);

			object item=lines->line(Candle.all_intervals[conf->start_interval_level])->a[i];

			if(item->volume){
				currprice=item->openval;
				string s="";
				s+=sprintf("- %s %f/%f %s",Calendar.ISO.Second(item->timeval)->format_time_short(),last_curr,currprice,map(holds,`+,"")*" ");
				foreach(SortMapping.sort_values(strategy2rate);string key;float rate){
					s+=sprintf(" %s:%d->%d:%s:%d:%s:%s",key,last_strategies[key],strategies[key],strategies_why[key]||"",strategies_prepare[key],strategies_prepare_why[key]||"",gate[key]?"o":"x");
				}
				s+="\n";
				if(conf->out_flag){
					Stdio.append_file(conf->outfilestr,s);
				}else{
					write("%s",s);
				}
			}
			if(strategy_db)
				strategy_db[sprintf("%d",item->timeval)]=encode_value(({strategies,strategies_why,strategies_prepare,strategies_prepare_why,currprice}));
		};/*}}}*/

		//lines的第i个最小时间片，离开的时候执行，结算损益
		void handle_level_advance_close(object lines,int i)/*{{{*/
		{
			//werror("handle_level_advance_close: i=%d\n",i);
			object item=lines->line(Candle.all_intervals[conf->start_interval_level])->a[i];
			last_curr=curr;
			if(item->volume){
				curr=item->closeval;
			}
			if(last_curr!=0.0){
				rates+=({curr/last_curr});
				if(sizeof(rates)>=2)
					drates+=({rates[-2]/rates[-1]});
			}

			void handle_item(int n,object item,mixed info/*,int week_mode,int|void week_base*/)/*{{{*/
			{
				//werror("handle_item: n=%d %O %O",n,info,item->save());
				if(item->volume){
					active=1;
					if(last_curr!=0.0&&last_curr!=item->closeval){
						werror("last_curr=%f curr=%f item->closeval=%f n=%d\n",last_curr,curr,item->closeval,n);
						throw(({"closeval not match.\n",backtrace()}));
					}
					//curr=item->closeval;
					int lk,ld,lj,k,d,j;
					object ltm,tm;

					[ltm,lk,ld,lj]=kdjs[n]->query();
					if(conf->ockdj_flag)
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,max(item->openval,item->closeval),min(item->openval,item->closeval));
					else if(conf->oclkdj_flag)
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,max(item->openval,item->closeval),item->minval);
					else
						[tm,k,d,j]=kdjs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);

#if 0
					int week_mode=0;
					if(!week_mode){
						/*int days=WEEK_AVG_SIZE;
						for(int i=1;i<days;i++){
							int lk1,ld1,lj1,k1,d1,j1;
							[object ltm,lk1,ld1,lj1]=kdjs[week_base+((n+i-week_base)%WEEK_PHASE)]->query(1);
							[object tm,k1,d1,j1]=kdjs[week_base+((n+i-week_base)%WEEK_PHASE)]->query();
							lk+=lk1;ld+=ld1;lj+=lj1;k+=k1;d+=d1;j+=j1;
						}
						lk/=days; ld/=days; lj/=days; k/=days; d/=days; j/=days;
						*/
					}
#endif
					[int tt,int cc]=ccs[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);
					int mav=mas[n]->feed(Calendar.ISO.Second(item->timeval),item->openval,item->closeval,item->maxval,item->minval);

					int upflag=k>d;
					int gx=k>d&&lk<ld;
					int dx=k<d&&lk>ld;
					int hold=dx||upflag&&!gx;
					int nexthold=upflag;

					holds[n]=hold;
					next_holds[n]=nexthold;
					gxs[n]=gx;
					dxs[n]=dx;
					ccvals[n]=cc;
					ttvals[n]=tt;
					mavals[n]=mav;
				}
			};/*}}}*/
			for(int n=conf->start_interval_level;n<sizeof(Candle.all_intervals);n++){
				int timeval=Time.align(item->timeval,Candle.all_intervals[n]);
				if(timeval>last_timevals[n]){ //if(timeval==item->timeval)
					last_timevals[n]=timeval;
					object line=lines->line(Candle.all_intervals[n]);
#ifdef USING_BINARY_SEARCH

					int pos=line->search(timeval);
					//werror("n=%d,pos=%d\n",n,pos);
					if(pos>=0){
							if(pos>0)
								handle_item(n,line->a[pos-1],pos-1/*,0*/);
					}else{
						throw(({Candle.all_intervals[n]+" not found.\n",backtrace()}));
					}
#else

					int found;
					foreach(line->a;int i;object item){
						if(line->a[i]->timeval==timeval){
							if(i>0)
								handle_item(n,line->a[i-1],i-1/*,0*/);
							found=1;
							break;
						}
					}
					if(!found){
						throw(({Candle.all_intervals[n]+" not found.\n",backtrace()}));
					}
#endif
				}

			}

			//int active_phase;
			foreach(extra_lines;int nn;object line){
				int n=sizeof(Candle.all_intervals)+nn;
				string key;int alter;
				if(nn==0){
					key="day";alter=0;
				}else if(/*nn-1>=0&&nn-1<WEEK_PHASE*/nn==1){
					key="week";alter=week_alters[nn-1];
				}else{
					key="month";alter=0;
				}
				int timeval=Calendar.ISO.Second(item->timeval+alter)[key]()->unix_time()-alter;
				if(timeval>last_timevals[n]){
					last_timevals[n]=timeval;

#ifdef USING_BINARY_SEARCH
					int pos=line->search(timeval);
					if(pos>=0){
							if(pos>0){
								handle_item(n,line->a[pos-1],pos-1/*,nn>=1&&nn<1+WEEK_PHASE,sizeof(Candle.all_intervals)+1*/);
								//if(nn>=1&&nn<1+WEEK_PHASE){
									//active_phase=nn-1;
								//}
							}
					}else{
						throw(({key+" not found.\n",backtrace()}));
					}
#else

					int found;
					foreach(line->a;int i;object item){
						if(item->timeval==timeval){
							if(i>0){
								handle_item(n,line->a[i-1],i-1/*,nn>=1&&nn<1+WEEK_PHASE,sizeof(Candle.all_intervals)+1*/);
								//if(nn>=1&&nn<1+WEEK_PHASE){
									//active_phase=nn-1;
								//}
							}
							found=1;
							break;
						}
					}
					if(!found){
						throw(({key+" not found.\n",backtrace()}));
					}
#endif
				}
			}

			string oyd=strategy_db[sprintf("%d",item->timeval-365*24*3600)];
			mapping oneyear=([]);
			if(oyd){
				[mapping val,mapping why,mapping pval,mapping pwhy,float openval]=decode_value(oyd);
				oneyear=val;//decode_value(oyd);
			}

			last_strategies=copy_value(strategies);
			foreach(strategies;string key;int hold){
				strategy2rate[key]=strategy2rate[key]||1.0;
				strategy2rangerate[key]=strategy2rangerate[key]||1.0;
				strategy2maxrate[key]=strategy2maxrate[key]||1.0;
				//strategy2recentrate[key]=strategy2recentrate[key]||({});
				strategy2maxdrop[key]=strategy2maxdrop[key]||1.0;
				//strategy2recentdrop[key]=strategy2recentdrop[key]||1.0;
				if(hold){
					if(!mappingp(strategy2rate))
						werror("strategy2rate=%O\n",strategy2rate);
					if(!mappingp(strategy2rangerate))
						werror("strategy2rangerate=%O\n",strategy2rangerate);
					if(!mappingp(oneyear))
						werror("oneyear=%O\n",oneyear);
					strategy2rate[key]*=rates[-1];
					strategy2rangerate[key]*=rates[-1];
					if(oneyear[key]){
						strategy2rangerate[key]/=rates[-365*24*4];
					}
					//strategy2recentrate[key]+=({strategy2rate[key]});
					//strategy2recentrate[key]=strategy2recentrate[key][<29..];
					strategy2maxrate[key]=max(strategy2maxrate[key],strategy2rate[key]);
					strategy2maxdrop[key]=min(strategy2maxdrop[key],strategy2rate[key]/strategy2maxrate[key]);
					/*if(sizeof(strategy2recentrate[key])){
						strategy2recentdrop[key]=strategy2rate[key]/(`+(0.0,@strategy2recentrate[key])/(sizeof(strategy2recentrate[key])));
					}*/
				}
			}
			if(active){
				string s="";
				s+=sprintf("+ %s %f %f",Calendar.ISO.Second(item->timeval)->format_time_short(),last_curr,rates[-1],/*map(holds,`+,"")*" "*/);
				float maxrate=max(@values(strategy2rate));
				foreach(SortMapping.sort_values(strategy2rate);string key;float rate){
					s+=sprintf(" %s=%.1f,%.2f,%.2f",key,rate,1-strategy2maxdrop[key],rate/maxrate);
				}
				s+="\n";
				if(conf->out_flag){
					Stdio.append_file(conf->outfilestr,s);
				}else{
					write("%s",s);
				}
			}
		};/*}}}*/

		void setup()
		{
			strategy_db=Gdbm.gdbm(conf->savepath+"/strategies.db","rwc");
			for(int i=0;i<sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT;i++){
				kdjs+=({KDJ.KDJ()});
				ccs+=({.CC()});
				mas+=({.MA(7)});
			}
			holds=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			next_holds=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			last_holds=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			gxs=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			dxs=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			ccvals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			ttvals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
			mavals=allocate(sizeof(Candle.all_intervals)+CALENDAR_LINE_COUNT,0);
		}
	}
}


class BitCoinPlicies{
	inherit BitCoinPliciesMode.Interface;
	inherit BitCoinPliciesHandleRequestMode.Interface;
	inherit ExtraLines;

	mapping conf;

	object lines;

	int start_pos;

	int run(mapping _conf)
	{
		conf=_conf;
		lines=Candle.Lines(conf->savepath+"/"+conf->inst,"r");
		update_extra_lines(lines,conf);

		if(conf->manual_flag){
			Stdio.write_file(MANUAL_VALUE_FILES,sprintf("%d:0\n",conf->manual_init_value));
			object port=Protocols.HTTP.Server.Port(handle_manual_request,conf->http_port,conf->http_ip);
			return -1;
		}

		setup();

		for(int i=start_pos;i<sizeof(lines->line(Candle.all_intervals[conf->start_interval_level])->a);i++){
			if(i-1>=start_pos)
				handle_level_advance_close(lines,i-1);
			handle_level_advance_open(lines,i);
		}
		lines->close();
		if(conf->follow_stdin_flag){
			signal(signum("SIGINT"),0);
			object port=Protocols.HTTP.Server.Port(handle_request,conf->http_port,conf->http_ip);
			object pf;
			object logfile=conf->logfile_flag&&Stdio.File(conf->logfile_str,"rwca");
			pf=Candle.ParseFile(conf->savepath,lambda(string inst){
				return inst!="";
				},lambda(int level){	// level 为此次更新完成的最大粒度
					if(level==sizeof(Candle.all_intervals)-1){
						update_extra_lines(pf->parsers[conf->inst],conf);
					}
					if(level>=conf->start_interval_level){
						int p0=sizeof(pf->parsers[conf->inst]->a[conf->start_interval_level]->a)-2;
						int p=p0;
						while(pf->parsers[conf->inst]->a[conf->start_interval_level]->a[p]->volume==0&&p>0)
							p--;
						while(p<=p0){
							handle_level_advance_close(pf->parsers[conf->inst],p);
							handle_level_advance_open(pf->parsers[conf->inst],p+1);
							p++;
						}
					}
				},logfile);
			object t=Thread.Thread(lambda(){
				pf->parse(Stdio.stdin);
				pf->close();
				logfile&&logfile->close();
				exit(0);
			});
			return -1;
		}else if(conf->daemon_flag){
			object port=Protocols.HTTP.Server.Port(handle_request,conf->http_port,conf->http_ip);
			return -1;
		}
	}
}

program default_program=CLASS(BitCoinPlicies,BitCoinPliciesMode.Default,BitCoinPliciesHandleRequestMode.Default);
program statemachine_program=CLASS(BitCoinPlicies,BitCoinPliciesMode.UsingStateMachine,BitCoinPliciesHandleRequestMode.NONE);


#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_STRING_REQUIRED("inst",inst_flag,inst,"=INSTANCE");
	DECLARE_ARGUMENT_STRING_REQUIRED("path",path_flag,savepath,"=PATH");
	DECLARE_ARGUMENT_INTEGER("start-interval-level",start_interval_level_flag,start_interval_level,"=N");
	DECLARE_ARGUMENT_STRING("http-ip",http_ip_flag,http_ip,"=IP");
	DECLARE_ARGUMENT_INTEGER("http-port",http_port_flag,http_port,"=PORT");
	DECLARE_ARGUMENT_FLAG("follow-stdin",follow_stdin_flag,"");
	DECLARE_ARGUMENT_FLAG("enable-dynamic",enable_dynamic_flag," ");
	DECLARE_ARGUMENT_FLAG("ockdj",ockdj_flag," ");
	DECLARE_ARGUMENT_FLAG("oclkdj",oclkdj_flag," ");
	DECLARE_ARGUMENT_FLAG("daemon",daemon_flag," ");
	DECLARE_ARGUMENT_STRING("out",out_flag,outfilestr,"=FILE");
	DECLARE_ARGUMENT_STRING("crfpp-sample-out",crfpp_sample_out_flag,crfpp_sample_outfilestr,"=FILE");
	DECLARE_ARGUMENT_STRING("log-file",logfile_flag,logfile_str,"=FILE");
	DECLARE_ARGUMENT_STRING("week-alter",week_alter_flag,week_alter,"=N[.N]");
	DECLARE_ARGUMENT_INTEGER("manual",manual_flag,manual_init_value,"=1|0\tManual mode, and set the init hold flag.");

	if(Usage.usage(args,"",0)){
		return 0;
	}

	mapping conf=HANDLE_ARGUMENTS();

	if(conf->out_flag)
		Stdio.write_file(conf->outfilestr,"");
	if(conf->crfpp_sample_out_flag)
		Stdio.write_file(conf->crfpp_sample_outfilestr,"");

	conf->http_ip=conf->http_ip||"0.0.0.0";
	conf->http_port=conf->http_port||80;

	return statemachine_program()->run(conf);
	//return default_program()->run(conf);
}
