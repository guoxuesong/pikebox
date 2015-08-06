#include <class.h>
#define CLASS_HOST "BitCoin"
class DynClass{
#include <class_imp.h>
}

#define okcoin_key "3416872"
#define okcoin_secret "3095EA53E2E5FA0B3360074B4465B284"
#define okcoin_btc_deposit_address "1479JzhmY9uF5rXosdyB4qbVbXCJKateYt"
#define okcoin_ltc_deposit_address "LeHvU1SejKvW1mvH9xky7QJch2ascmFEYv"

#define btcc_key "42608ac2-41c9-4d37-95d9-b33ee6319da0"
#define btcc_secret "186b1b7f-5243-41d6-bfd0-90f857035460"

#define huobi_key "da4b77a2-bae21201-416dfb70-36d23"
#define huobi_secret "a73aed6e-d5a53a5d-4748cbd9-087e0"
#define huobi_btc_deposit_address "1KApSvyU86gVcMtp87mERHwzty1QwV2Dxr"
#define huobi_ltc_deposit_address "Le7GkNJRUZLfPw5bLzEdPbNCD4oxWRcTfb"

#define bitstamp_key "61018"
#define bitstamp_secret "-"

#define TEST_MONEY 10.0
#define BTC_EFFECTIVE_PRECISION 4
#define BTC_PRECISION 8
#define CNY_PRECISION 2

//#define UNITTEST_ONLY
#define MANUAL_AMOUNT_MIN 0.2
#define MANUAL_AMOUNT_MAX 0.4

#define GET_SIGNAL_NO_WGET
#define wget wget78
#define Process Process78

mapping thread2name=([]);
Thread.Mutex localmatex=Thread.Mutex();
void mysetlocal(mixed val)
{
	object l=localmatex->lock();
	thread2name[this_thread()]=val;
	destruct(l);
}
mixed mygetlocal()
{
	object l=localmatex->lock();
	mixed res=thread2name[this_thread()];
	destruct(l);
	return res;
}

int mywerror(string fmt, mixed ... args)
{
	mapping m=/*Thread.Local()->get()*/.mygetlocal();
	if(m){
		return Stdio.append_file(sprintf("/home/work/btc/%s.log.%s",m->thread_name,Calendar.ISO.Second()->format_ymd_short()),sprintf("%s %s",Calendar.ISO.Second()->format_time_short(),sprintf(fmt,@args)));
	}else{
		return werror("%s %s",Calendar.ISO.Second()->format_time_short(),sprintf(fmt,@args));
	}
}

#define werror .mywerror

class RequesterAuthMode{/*{{{*/
	class Interface{
		extern string name;
		extern string auth_key,auth_secret;
	}
	class OkCoin{
		string name="OkCoin";
		string auth_key=okcoin_key;
		string auth_secret=okcoin_secret;
	}
	class BtcChina{
		string name="BtcChina";
		string auth_key=btcc_key;
		string auth_secret=btcc_secret;
	}
	class Huobi{
		string name="Huobi";
		string auth_key=huobi_key;
		string auth_secret=huobi_secret;
	}
	class BitStamp{
		string name="BitStamp";
		string auth_key=bitstamp_key;
		string auth_secret=bitstamp_secret;
	}
	class Test{
		string name="Test";
		string auth_key="test";
		string auth_secret="-";
	}
}/*}}}*/

class RequesterApiMode{
	class Interface{
		extern string auth_key,auth_secret;
		extern string url_prefix;
		extern mapping|array perform(string path,mapping args);
		array build_query(mapping req);
		string sign(string data);
		string build_inst(string btcltc,string cnyusd);
	}
	class Test{/*{{{*/
		string build_inst(string btcltc,string cnyusd)/*{{{*/
		{
			return lower_case(btcltc+"_"+cnyusd);
		}/*}}}*/
		string sign(string data)/*{{{*/
		{
			return "";
		}/*}}}*/
		array build_query(mapping req)/*{{{*/
		{
			string s="";
			foreach(SortMapping.sort(req);string key;mixed val)
			{
				if(intp(val)){
					req[key]=(string)val;
				}else if(floatp(val)){
					req[key]=sprintf("%0.9f",val);
				}
				s+=sprintf("%s=%s&",key,req[key]);
			}
			s=s[..<1];
			string sig=sign(s);
			req["sign"]=sig;
			string post_data=Protocols.HTTP.http_encode_query(req);
			mapping headers=([]);
			headers["Content-Type"]="application/x-www-form-urlencoded";
			return ({post_data,headers});
		}/*}}}*/
	}/*}}}*/
	class BitStamp{/*{{{*/
		extern mapping|array perform(string path,mapping args);
		string auth_key,auth_secret;
		string url_prefix="https://www.bitstamp.net/api/";
		array build_query(mapping req)/*{{{*/
		{
			req+=(["user":auth_key,"password":auth_secret]);
			foreach(req;string key;mixed val){
				if(floatp(val)){
					req[key]=sprintf("%.2f",(int)(val*100)*1.0/100);
				}else if(!stringp(val)){
					req[key]=(string)val;
				}
			}
			string post_data=Protocols.HTTP.http_encode_query(req);
			mapping headers=([]);
			headers["Content-Type"] = "application/x-www-form-urlencoded";
			return ({post_data,headers});
		}/*}}}*/
		mapping|array perform_get(string path,mapping args){/*{{{*/
			if(!has_suffix(path,"/"))
				path+="/";
			if(args&&sizeof(args)){
				string query=Protocols.HTTP.http_encode_query(args);
				path+="?"+query;
			}
			werror("perform_get: path=%s\n",path);
			string data=wget(url_prefix+path,);
			mapping res=data&&data!=""&&Standards.JSON.decode(data);
			werror("perform_get: res=%O\n",res);
			return res;
		}/*}}}*/

#define SIMPLE_POST(FN) mapping|array|string FN()\
		{\
			return perform(#FN,([]));\
		}

#define SIMPLE_GET(FN) mapping|array|string FN()\
		{\
			return perform_get(#FN,([]));\
		}


		SIMPLE_GET(ticker);

		mapping|array order_book(int group){/*{{{*/
			return perform_get("order_book",(["group":(string)group]));
		}/*}}}*/
		mapping|array transactions(int timedelta){/*{{{*/
			return perform_get("transactions",(["timedelta":(string)timedelta]));
		}/*}}}*/

		SIMPLE_POST(balance);
		mapping|array user_transactions(int timedelta){/*{{{*/
			return perform("user_transactions",(["timedelta":(string)timedelta]));
		}/*}}}*/
		SIMPLE_POST(open_orders);
		mapping|array cancel_order(int id){/*{{{*/
			return perform("cancel_order",(["id":id]));
		}/*}}}*/
		mapping|array buy(float price,float amount){/*{{{*/
			return perform("buy",(["amount":amount,"price":price]));
		}/*}}}*/
		mapping|array sell(float price,float amount){/*{{{*/
			return perform("sell",(["amount":amount,"price":price]));
		}/*}}}*/
		mapping|array bitcoin_withdrawal(float amount,string address)
		{
			return perform("bitcoin_withdrawal",(["amount":amount,"address":address]));
		}
		SIMPLE_POST(bitcoin_deposit_address);

#undef SIMPLE_GET
#undef SIMPLE_POST

	}/*}}}*/
	class Huobi{/*{{{*/
		extern string auth_key,auth_secret;
		extern mapping|array perform(string path,mapping args);
		int sn=time();
		string url_prefix="https://api.huobi.com/apiv2.php";
		string build_inst(string btcltc,string cnyusd)/*{{{*/
		{
			if(btcltc=="btc")
				return "1";
			else if(btcltc=="ltc")
				return "2";
		}/*}}}*/
		string sign(string data)/*{{{*/
		{
			//werror("sign(%s)\n",data);
			return lower_case(String.string2hex(Crypto.MD5.hash(data)));
		}/*}}}*/
		array build_query(mapping req0)/*{{{*/
		{
			req0["access_key"]=auth_key;
			req0["created"]=(string)time();

			foreach(req0;string key;mixed val)
			{
				if(intp(val)){
					req0[key]=(string)val;
				}else if(floatp(val)){
					req0[key]=sprintf("%0.9f",val);
				}
			}

			mapping req=req0+([
					"secret_key":auth_secret,
					])-({"trade_id"});//文档中说可以加trade_id，但加trade_id返回67私钥错，不加trade_id成功，但trade_id没有起作用

			string s="";
			foreach(SortMapping.sort(req);string key;mixed val)
			{
				s+=sprintf("%s=%s&",key,req[key]);
			}
			s=s[..<1];
			string sig=sign(s);
			req0["sign"]=sig;
			string post_data=Protocols.HTTP.http_encode_query(req0);
			mapping headers=([]);
			headers["Content-Type"]="application/x-www-form-urlencoded";
			return ({post_data,headers});
		}/*}}}*/

		mapping get_account_info()/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"get_account_info",
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping get_orders(string inst)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"get_orders",
							"coin_type":inst,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping buy_market(string inst,float money)/*{{{*/
		{
			return perform("",([
						"method":"buy_market",
						"coin_type":inst,
						"trade_id":sprintf("%d",sn++),
						"amount":sprintf("%0.2f",money),
						]));
		}/*}}}*/
		mapping sell_market(string inst,float amount)/*{{{*/
		{
			return perform("",([
						"method":"sell_market",
						"coin_type":inst,
						"trade_id":sprintf("%d",sn++),
						"amount":sprintf("%0.9f",amount),
						]));
		}/*}}}*/
		mapping cancel_order(string inst,string id)/*{{{*/
		{
			return perform("",([
						"method":"cancel_order",
						"coin_type":inst,
						"id":id,
						]));
		}/*}}}*/
		mapping order_info(string inst,string id)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"order_info",
							"coin_type":inst,
							"id":id,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping ticker(string inst)/*{{{*/
		{
			if(inst=="1"){
				string data=wget("http://market.huobi.com/staticmarket/ticker_btc_json.js");
				return data&&data!=""&&Standards.JSON.decode(data);
			}else if(inst=="2"){
				string data=wget("http://market.huobi.com/staticmarket/ticker_ltc_json.js");
				return data&&data!=""&&Standards.JSON.decode(data);
			}
		}/*}}}*/
	}/*}}}*/
	class BtcChina{/*{{{*/
		extern string auth_key,auth_secret;
		extern mapping|array perform(string path,mapping args);
		int sn=time();
		string url_prefix="https://api.btcchina.com/api_trade_v1.php";
		string build_inst(string btcltc,string cnyusd)
		{
			return upper_case(btcltc+cnyusd);
		}
		private string sign(string data){/*{{{*/
			string res=Crypto.HMAC(Crypto.SHA1,)(auth_secret)(data);
			//werror("res=%d\n",sizeof(res));
			return MIME.encode_base64(auth_key+":"+String.string2hex(res),1);
		}/*}}}*/
		array build_query(mapping req0)/*{{{*/
		{
			array hr=Time.hrtime();
			int tonce=hr[0]*1000000+hr[1];
			mapping req=req0+(["accesskey":auth_key,
					"requestmethod":"post",
					"tonce":tonce,]);
			array a=({ "tonce", "accesskey", "requestmethod", "id", "method", "params", });
			string s="";
			foreach(a,string key){
				mixed val=req[key];
				if(zero_type(val)){
					req[key]="";
				}else if(intp(val)){
					req[key]=(string)val;
				}else if(floatp(val)){
					req[key]=sprintf("%0.9f",val);
				}else if(arrayp(val)){
					if(key=="params"){
						if(req["params_string"])
							val=req["params_string"];
					}
					string res="";
					foreach(val,mixed v){
						if(floatp(v)){
							v=sprintf("%0.9f",v);
						}else if(v==Val.null){
							v="";
						}
						res+=(string)v+",";
					}
					req[key]=res[..<1];
				}
				s+=sprintf("%s=%s&",key,req[key]);
			}
			s=s[..<1];

			//werror("s=%s\n",s);

			string sig=sign(s);
			string post_data=Standards.JSON.encode(req0-({"params_string"}));
			mapping headers=([]);
			headers["Content-Type"]="application/json-rpc";
			headers["Authorization"]="Basic "+sig;
			headers["Json-Rpc-Tonce"]=sprintf("%d",tonce);
			return ({post_data,headers});
		}/*}}}*/
		private string print_float(float v,int d)/*{{{*/
		{
			v=norm_float(v,d);
			string t=sprintf("%."+d+"f",v);
			while(t[-1]=='0'){
				t=t[..<1];
			}
			if(t[-1]=='.')
				t=t[..<1];
			return t;
		}/*}}}*/
		private float norm_float(float v,int d)/*{{{*/
		{
			//return (float)print_float(v,d);
			return Norm.floor(v,d);
		}/*}}}*/
		mapping buyOrder2(string inst,float|int(0..0) price,float amount)/*{{{*/
		{
			if(inst=="BTCCNY"){
				return perform("",([
							"method":"buyOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),inst}), /* 文档说 amount 支持小数点后4位，实测只支持3位 */
							"id":sn++,
							]));
			}else if(inst=="LTCCNY"){
				return perform("",([
							"method":"buyOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),inst}),
							"id":sn++,
							]));
			}
		}/*}}}*/
		mapping sellOrder2(string inst,float|int(0..0) price,float amount)/*{{{*/
		{
			if(inst=="BTCCNY"){
				return perform("",([
							"method":"sellOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),inst}), /* 文档说 amount 支持小数点后4位，实测只支持3位 */
							"id":sn++,
							]));
			}else if(inst=="LTCCNY"){
				return perform("",([
							"method":"sellOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),inst}),
							"id":sn++,
							]));
			}
		}/*}}}*/
		mapping cancelOrder(string inst,int id)/*{{{*/
		{
			return perform("",([
						"method":"cancelOrder",
						"params":({id,inst}),
						"id":sn++,
						]));
		}/*}}}*/
		mapping getAccountInfo(string type)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"getAccountInfo",
							"params":({type}),
							"id":sn++,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping getOrders(string inst,int openonly,int limit,int offset,int since,int withdetail)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"getOrders",
							"params":({
								openonly?Val.true:Val.false,
								inst,
								limit,
								offset,
								since,
								withdetail?Val.true:Val.false,
								}),
							"id":sn++,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping buyIcebergOrder(string inst,float|int(0..0) price,float amount,float disclosed_amount,float variance)/*{{{*/
		{
			if(inst=="BTCCNY"){
				return perform("",([
							"method":"buyIcebergOrder",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),norm_float(disclosed_amount,3),norm_float(variance,2),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),print_float(disclosed_amount,3),print_float(variance,2),inst}), /* 文档说 amount 支持小数点后4位，实测buyOrder2只支持3位，遵循此实测，variance精度文档没说，假设为0.01  */
							"id":sn++,
							]));
			}else if(inst=="LTCCNY"){
				return perform("",([
							"method":"buyOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),norm_float(disclosed_amount,3),norm_float(variance,2),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),print_float(disclosed_amount,3),print_float(variance,2),inst}),
							"id":sn++,
							]));
			}
		}/*}}}*/
		mapping sellIcebergOrder(string inst,float|int(0..0) price,float amount,float disclosed_amount,float variance)/*{{{*/
		{
			if(inst=="BTCCNY"){
				return perform("",([
							"method":"buyIcebergOrder",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),norm_float(disclosed_amount,3),norm_float(variance,2),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),print_float(disclosed_amount,3),print_float(variance,2),inst}), /* 文档说 amount 支持小数点后4位，实测buyOrder2只支持3位，遵循此实测，variance精度文档没说，假设为0.01 */
							"id":sn++,
							]));
			}else if(inst=="LTCCNY"){
				return perform("",([
							"method":"buyOrder2",
							"params":({floatp(price)?norm_float(price,2):Val.null,norm_float(amount,3),norm_float(disclosed_amount,3),norm_float(variance,2),inst}),
							"params_string":({floatp(price)?print_float(price,2):Val.null,print_float(amount,3),print_float(disclosed_amount,3),print_float(variance,2),inst}),
							"id":sn++,
							]));
			}
		}/*}}}*/
		mapping getIcebergOrder(string inst,int id)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"getIcebergOrder",
							"params":({id,inst}),
							"id":sn++,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping getIcebergOrders(string inst,int limit,int offset)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"getIcebergOrders",
							"params":({limit,offset,inst}),
							"id":sn++,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping cancelIcebergOrder(string inst,int id)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"getIcebergOrder",
							"params":({id,inst}),
							"id":sn++,
							]));
				if(res)
					return res;
			}
		}/*}}}*/
		mapping requestWithdrawal(string btcltc,float amount)/*{{{*/
		{
			while(1){
				mapping res=perform("",([
							"method":"requestWithdrawal",
							"params":({btcltc,norm_float(amount,8)}),
							"params_string":({btcltc,print_float(amount,8)}),
							"id":sn++,
							]));
				if(res)
					return res;
			}

		}/*}}}*/
		mapping ticker(string inst)/*{{{*/
		{
				string data=wget("https://data.btcchina.com/data/ticker?market="+inst);
				return data&&data!=""&&Standards.JSON.decode(data);
		}/*}}}*/
	}/*}}}*/
	class OkCoin{/*{{{*/
		extern string auth_key,auth_secret;
		extern mapping|array perform(string path,mapping args);
		string url_prefix="https://www.okcoin.cn/api/";
		string build_inst(string btcltc,string cnyusd)/*{{{*/
		{
			return lower_case(btcltc+"_"+cnyusd);
		}/*}}}*/
		string sign(string data)/*{{{*/
		{
			return upper_case(String.string2hex(Crypto.MD5.hash(data+auth_secret)));
		}/*}}}*/
		array build_query(mapping req)/*{{{*/
		{
			string s="";
			foreach(SortMapping.sort(req);string key;mixed val)
			{
				if(intp(val)){
					req[key]=(string)val;
				}else if(floatp(val)){
					req[key]=sprintf("%0.9f",val);
				}
				s+=sprintf("%s=%s&",key,req[key]);
			}
			s=s[..<1];
			string sig=sign(s);
			req["sign"]=sig;
			string post_data=Protocols.HTTP.http_encode_query(req);
			mapping headers=([]);
			headers["Content-Type"]="application/x-www-form-urlencoded";
			return ({post_data,headers});
		}/*}}}*/

		mapping trade(string inst,string type,float rate,float amount)/*{{{*/
		{
			mapping args=([
						"partner":auth_key,
						"symbol":inst,
						"type":type,
						"rate":rate,
						"amount":amount,
						]);
			if(type=="buy_market"){
				m_delete(args,"amount");
			}else if(type=="sell_market"){
				m_delete(args,"rate");
			}
			return perform("trade.do",args);
		}/*}}}*/
		mapping userinfo()/*{{{*/
		{
			while(1){
				mapping res=perform("userinfo.do",([
							"partner":auth_key,
							]));
				if(res&&res->result==Val.true)
					return res;
			}
		}/*}}}*/
		mapping cancelorder(string inst,int order_id)/*{{{*/
		{
			mapping args=([
						"partner":auth_key,
						"symbol":inst,
						"order_id":order_id,
						]);
			return perform("cancelorder.do",args);
		}/*}}}*/
		mapping getorder(string inst,int order_id)/*{{{*/
		{
			while(1){
				mapping res=perform("getorder.do",([
							"partner":auth_key,
							"symbol":inst,
							"order_id":order_id,
							]));
				if(res&&res->result==Val.true)
					return res;
			}
		}/*}}}*/
		mapping getOrderHistory(string inst,int status,int currentPage,int pageLength)/*{{{*/
		{
			while(1){
				mapping res=perform("getOrderHistory.do",([
							"partner":auth_key,
							"symbol":inst,
							"status":status,
							"currentPage":currentPage,
							"pageLength":pageLength,
							]));
				if(res&&res->result==Val.true)
					return res;
			}
		}/*}}}*/

		mapping ticker(string inst)/*{{{*/
		{
			if(inst=="btc_cny"){
				string data=wget(url_prefix+"ticker.do");
				return data&&data!=""&&Standards.JSON.decode(data);
			}else if(inst=="ltc_cny"){
				string data=wget(url_prefix+"ticker.do?symbol=ltc_cny");
				return data&&data!=""&&Standards.JSON.decode(data);
			}
		}/*}}}*/
	}/*}}}*/
}

class ActiveOrder{/*{{{*/
	inherit Save.Save;
	string id;
	string inst;
	string type;
	float amount_limit;
	float money_limit;
	float price_limit;
	float amount_completed;
	float money_completed;
	float price_average;
}/*}}}*/
class Position{/*{{{*/
	inherit Save.Save;
	string inst;
	string type;
	float amount;
	float amount_frozen;
	float amount_free;
	float margin;
}/*}}}*/
class Account{/*{{{*/
	array active_orders=({});
	float money;
	float money_frozen;
	float money_free;
	mapping inst2position=([]);
	object clone()
	{
		object res=.Account();
		res->active_orders=map(map(active_orders,"save"),Function.curry(Save.load)(.ActiveOrder));
		res->money=money;
		res->money_frozen=money_frozen;
		res->money_free=money_free;
		res->inst2position=map(map(inst2position,"save",),Function.curry(Save.load)(.Position));
		return res;
	}
}/*}}}*/

class SafeOrderMarketOptions{/*{{{*/
	inherit Save.Save;
	int penny;
	int check_account_only;
	void create(mapping m)/*{{{*/
	{
		Save.load(this,m);
	}/*}}}*/
}/*}}}*/

class Wallet{
	class Transaction{/*{{{*/
		inherit Save.Save;
		float amount;
		float|int(0..0) fee;
		int confirmations;
		string blockhash;
		int blockindex;
		int blocktime;
		string txid;
		array walletconflicts;
    int time;
    int timereceived;
    array details;
    string hex;
	};/*}}}*/
	string cli;
	string passphase;
	mixed res,error;
	string default_account="";
	protected int run(string cmdline,int|void keep_string)/*{{{*/
	{
		res=error=0;
		mapping m=Process.run(cmdline);
		if(m->stderr==""){
			res=keep_string?m->stdout:Standards.JSON.decode(m->stdout);
			return 1;
		}else{
			werror("cmdline=%s\n",cmdline);
			werror("%s\n",m->stderr);
			sscanf(m->stderr,"error: %s",string errorinfo);
			error=Standards.JSON.decode(errorinfo);
			return 0;
		}
	}/*}}}*/
	//FOLLOWING FUNCTIONS RETURN NON ZERO FOR SUCCESS, 0 FOR FAILURE
	string sendfrom(string account,string address,float amount)/*{{{*/
	{
		while(1){
#ifdef UNITTEST_ONLY
			if(amount>MANUAL_AMOUNT_MAX){
				throw(({"sendfrom beyond limit.\n",backtrace()}));
			}
#endif
			string res=run(sprintf("%s sendfrom %q %s %0.8f",cli,account,address,amount),1)&&(res/"\n")[0];
			if(error&&error->code==-13&&passphase){
				run(sprintf("%s walletpassphrase %s 3600",cli,passphase),1);
				continue;
			}
			return res;
		}
	}/*}}}*/
	string getaccountaddress(string account)/*{{{*/
	{
		return run(sprintf("%s getaccountaddress %q",cli,account),1)&&(res/"\n")[0];
	}/*}}}*/
	float getbalance(string account,int|void minconf)/*{{{*/
	{
		if(zero_type(minconf))
			return run(sprintf("%s getbalance %q",cli,account),1)?(float)res:Math.nan;
		else
			return run(sprintf("%s getbalance %q %d",cli,account,minconf),1)?(float)res:Math.nan;
	}/*}}}*/
	object gettransaction(string id)/*{{{*/
	{
		return run(sprintf("%s gettransaction %s",cli,id))&&Save.load(Transaction(),res);
	}/*}}}*/
	string getaccount(string addr)/*{{{*/
	{
		return run(sprintf("%s getaccount %s",cli,addr),1)&&(res/"\n")[0];
	}/*}}}*/
	array listtransactions()/*{{{*/
	{
		return run(sprintf("%s listtransactions",cli))&&res;
	}/*}}}*/
	void submit(){}
}

class BitCoinWallet{
	inherit Wallet;
	string cli="/home/work/bitcoin/bin/64/bitcoin-cli -datadir=/home/work/bitcoin/var";
}

class BitCoinUnitTestWallet{
	inherit Wallet;
	string default_account="unittest";
	string cli="/home/work/bitcoin/bin/64/bitcoin-cli -datadir=/home/work/bitcoin/var";
}

class BitCoinTestnetWalletStatic{
	class Static{
		mapping cache=([]);
	}
}

class BitCoinTestnetWallet{
	inherit Wallet;
	string default_account="default";
	string cli="/home/work/bitcoin-testnet/bin/64/bitcoin-cli -datadir=/home/work/bitcoin-testnet/var";
	void submit()/*{{{*/
	{
		run(sprintf("%s setgenerate true 1",cli),1);
		werror("clean cache.\n");
		STATIC(BitCoinTestnetWalletStatic)->cache=([]);
	}/*}}}*/
	float getbalance(string account,int|void minconf)/*{{{*/
	{
		if(minconf==0){
			if(STATIC(BitCoinTestnetWalletStatic)->cache[account]==0){
				STATIC(BitCoinTestnetWalletStatic)->cache[account]=::getbalance(account,minconf);
			}
			return STATIC(BitCoinTestnetWalletStatic)->cache[account];
		}else{
			return ::getbalance(account,minconf);
		}
	}/*}}}*/
}

class LiteCoinWallet{
	inherit Wallet;
	string passphase="-";
	string cli="/home/work/litecoin/bin/64/litecoind -datadir=/home/work/litecoin/var";
}

class RequesterIcebergMode{
	class Interface{
		void buy_many(string btcltc);
		void sell_many(string btcltc);
	}
	class BtcChina{//not works
		int buy_many(string btcltc)/*{{{*/
		{
			object r=this;
			r->update_account();
			while(1){
				object account=r->account;
				string inst=r->build_inst(btcltc,"cny");
				//werror("amount=%f\n",account->inst2position[inst]->amount_free);
				float money_free=account->money_free;
				object ticker=r->ticker(inst);
				while(ticker==0){
					ticker=r->ticker(inst);
				}
				werror("ticker=%O\n",ticker);
				float amount=Norm.floor(money_free/(float)ticker->ticker->last,BTC_EFFECTIVE_PRECISION);
				mapping res=r->buyIcebergOrder(inst,0,amount,max(0.001,Norm.floor(amount/8,BTC_EFFECTIVE_PRECISION)),0.1);
				r->update_account();
				if(r->account->money_free<account->money_free)
					return 1;
				if(res)
					return 0;
			}
		}/*}}}*/
		int sell_many(string btcltc)/*{{{*/
		{
			object r=this;
			r->update_account();
			while(1){
				object account=r->account;
				string inst=r->build_inst(btcltc,"cny");
				//werror("amount=%f\n",account->inst2position[inst]->amount_free);
				float money_free=account->money_free;
				object ticker=r->ticker(inst);
				while(ticker==0){
					ticker=r->ticker(inst);
				}
				werror("ticker=%O\n",ticker);
				float amount=account->inst2position[inst]->amount_free;
				mapping res=r->sellIcebergOrder(inst,0,amount,max(0.001,Norm.floor(amount/8,BTC_EFFECTIVE_PRECISION)),0.1);
				r->update_account();
				if(r->account->inst2position[inst]->amount_free<account->inst2position[inst]->amount_free)
					return 1;
				if(res)
					return 0;
			}
		}/*}}}*/
	}
	class ViaSafeOrderMarket{
		int buy_many(string btcltc)/*{{{*/
		{
			object r=this;
			r->update_account();
			object account=r->account;
			//werror("amount=%f\n",account->inst2position[r->build_inst(btcltc,"cny")]->amount_free);
			if(account->money_free>=0.01){
				for(int div=8;div>0;div/=2){
					if(r->safe_order_market(btcltc,"buy",1.0*1/div,.SafeOrderMarketOptions((["penny":0,"check_account_only":1])))){
						for(int i=0;i<div;i++){
							r->safe_order_market(btcltc,"buy",1.0*1/(div-i),.SafeOrderMarketOptions((["penny":0])));
						}
						break;
					}
				}
			}
			if(r->account->money_free<account->money_free)
				return 1;
		}/*}}}*/
		int sell_many(string btcltc)/*{{{*/
		{
			object r=this;
			r->update_account();
			object account=r->account;
			string inst=r->build_inst(btcltc,"cny");
			//werror("amount=%f\n",account->inst2position[inst]->amount_free);
			if(account->inst2position[inst]->amount_free>0){
				for(int div=8;div>0;div/=2){
					if(r->safe_order_market(btcltc,"sell",1.0*1/div,.SafeOrderMarketOptions((["penny":0,"check_account_only":1])))){
						for(int i=0;i<div;i++){
							r->safe_order_market(btcltc,"sell",1.0*1/(div-i),.SafeOrderMarketOptions((["penny":0])));
						}
						break;
					}
				}
			}
			if(r->account->inst2position[inst]->amount_free<account->inst2position[inst]->amount_free)
				return 1;
		}/*}}}*/
	}
}

class RequesterAbstraceLayerMode{
	class Interface{
		Account account;
		void update_account();

		extern string build_inst(string btcltc,string cnyusd);

		string query_deposit_address(string btcltc);

		//FOLLOWING FUNCTIONS RETURN 1 FOR SUCCESS
		int safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options);
		int safe_cancel_order(string id);
		int safe_deposit(string btcltc,float amount,Wallet wallet,int|void wait)/*{{{*/
		{
			if(btcltc=="btc"){
				string addr=query_deposit_address("btc");
				werror("depositing %0.8f %s to %s\n",amount,btcltc,addr);
				object old_account=account;
				string txid=wallet->sendfrom(wallet->default_account,addr,amount);
				wallet->submit();
				if(txid){
					werror("txid=%s\n",txid);
				}

				if(txid&&wait){
					for(int i=0;i<=wait;i++){
						werror("wait %d confirms ...\n",i);
						object tx=wallet->gettransaction(txid);
						wallet->submit();
						werror("tx->confirmations=%d\n",tx->confirmations);
						while(tx->confirmations<i){
							sleep(10);
							tx=wallet->gettransaction(txid);
							wallet->submit();
						}
					}
					update_account();
					while(account->inst2position[build_inst("btc","cny")]->amount_free==old_account->inst2position[build_inst("btc","cny")]->amount_free){
						sleep(10);
						update_account();
					}
					return 1;
				}
			}
		}/*}}}*/
		int safe_withdraw(string btcltc,float amount,Wallet wallet,int|void wait){/*{{{*/
			return 0;
		}/*}}}*/
	}
	class OkCoin{
		extern Account account;
		void update_account()/*{{{*/
		{
			object r=this;
			mapping userinfo,userinfo2,inst2orders;
			int in_changing;
			while(1){
				in_changing=0;
				do{
					inst2orders=([]);
					userinfo=r->userinfo();
					werror("userinfo=%O\n",userinfo);
					foreach(({"btc_cny","ltc_cny"}),string inst){
						inst2orders[inst]=r->getorder(inst,"-1");
						werror("getorder(%s) return %O\n",inst,inst2orders[inst]);
					}
					userinfo2=r->userinfo();
					if(userinfo&&userinfo2){
						m_delete(userinfo->info->funds,"asset");
						m_delete(userinfo2->info->funds,"asset");
						werror("userinfo-asset=%O\n",userinfo);
						werror("userinfo2-asset=%O\n",userinfo2);
						werror("sizeof(values(inst2orders)&({0}))=%d\n",sizeof(values(inst2orders)&({0})));
						werror("userinfo changed: %d\n",!equal(userinfo,userinfo2));
					}
				}while(userinfo==0||sizeof(values(inst2orders)&({0}))||!equal(userinfo,userinfo2));
				mapping btc_ticker=r->ticker("btc_cny");
				mapping ltc_ticker=r->ticker("ltc_cny");
				mapping tickers=(["btc":btc_ticker,"ltc":ltc_ticker]);

				werror("tickers=%O\n",tickers);

				int orders_ok=1;
				foreach(inst2orders;string inst;mapping orders){
					if(orders->result!=Val.true){
						orders_ok=0;
					}
				}
				werror("orders_ok=%d\n",orders_ok);
				if(orders_ok&&userinfo->result==Val.true&&btc_ticker&&ltc_ticker){
					object res=.Account();
					foreach(inst2orders;string inst;mapping orders){/*{{{*/
						foreach(orders->orders,mapping m){
							werror("order=%O\n",m);
							object order=.ActiveOrder();
							if(m->type=="buy_market"){
								in_changing=1;
								order->id=(string)m->orders_id;
								order->inst=inst;
								order->type="buy";
								order->amount_limit=Math.inf;
								order->money_limit=(float)m->rate;
								order->price_limit=Math.inf;
								order->amount_completed=(float)m->deal_amount;
								order->money_completed=(float)m->rate;
								order->price_average=(float)m->avg_rate;
								if(order->amount_completed==0.0)
									order->price_average=Math.nan;
							}else if(m->type=="sell_market"){	//确实出现了
								in_changing=1;
								order->id=(string)m->orders_id;
								order->inst=inst;
								order->type="sell";
								order->amount_limit=m->amount;
								order->money_limit=Math.inf;
								order->price_limit=0.0;
								order->amount_completed=(float)m->deal_amount;
								order->money_completed=(float)m->rate;
								order->price_average=(float)m->avg_rate;
								if(order->amount_completed==0.0)
									order->price_average=Math.nan;
							}else if(m->type=="buy"){
								order->id=(string)m->orders_id;
								order->inst=inst;
								order->type="buy";
								order->amount_limit=(float)m->amount;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->rate;
								order->amount_completed=(float)m->deal_amount;
								order->money_completed=(float)m->avg_rate*(float)m->deal_amount;
								order->price_average=(float)m->avg_rate;
								if(order->amount_completed==0.0)
									order->price_average=Math.nan;
							}else if(m->type=="sell"){
								order->id=(string)m->orders_id;
								order->inst=inst;
								order->type="sell";
								order->amount_limit=(float)m->amount;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->rate;
								order->amount_completed=(float)m->deal_amount;
								order->money_completed=(float)m->avg_rate*(float)m->deal_amount;
								order->price_average=(float)m->avg_rate;
								if(order->amount_completed==0.0)
									order->price_average=Math.nan;
							}
							res->active_orders+=({order});
						}
					}/*}}}*/
					res->money=(float)userinfo->info->funds->free->cny+(float)userinfo->info->funds->freezed->cny;
					res->money_frozen=(float)userinfo->info->funds->freezed->cny;
					res->money_free=(float)userinfo->info->funds->free->cny;
					foreach(({"btc","ltc"}),string k){
						//if((float)userinfo->info->funds->free[k]!=0.0||(float)userinfo->info->funds->freezed[k]!=0.0){
							object position=.Position();
							position->inst=k+"_cny";
							position->type="buy";
							position->amount=(float)userinfo->info->funds->free[k]+(float)userinfo->info->funds->freezed[k];
							position->amount_frozen=(float)userinfo->info->funds->freezed[k];
							position->amount_free=(float)userinfo->info->funds->free[k];
							position->margin=(float)(tickers[k]->ticker->last)*position->amount;
							res->inst2position[position->inst]=position;
						//}
					}
					werror("in_changing=%d\n",in_changing);
					if(!in_changing){
						account=res;
						return;
					}else{
						sleep(5);
					}
				}
			}
		}/*}}}*/
		int safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options)/*{{{*/
		{
			object r=this;
			string inst=r->build_inst(btcltc,"cny");
			float min_amount;
			if(inst=="btc_cny")
				min_amount=0.01;
			else if(inst=="ltc_cny")
				min_amount=0.1;
			else
				throw(({"unknown inst.\n",backtrace()}));

			object ticker=r->ticker(inst);
			while(ticker==0){
				ticker=r->ticker(inst);
			}
			werror("ticker=%O\n",ticker);
			if(type=="buy"){
				float money_free=account->money_free;
				float amount=Norm.floor((money_free)*percent/(float)ticker->ticker->last,BTC_EFFECTIVE_PRECISION);
				float money;
				if(options->penny&&amount>=min_amount){
					amount=min_amount;
					money=Norm.floor(amount*1.1*(float)ticker->ticker->last+0.01,CNY_PRECISION);
				}else{
					money=Norm.floor(money_free*percent,CNY_PRECISION);
				}
				if(amount>=min_amount){
					if(options->check_account_only)
						return 1;
					mapping res=r->trade(inst,"buy_market",money,0.0);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){
						return 1;
					}
				}
			}else if(type=="sell"){
				float amount_free=account->inst2position[inst]->amount_free;
				float amount=Norm.floor(amount_free*percent,BTC_EFFECTIVE_PRECISION);
				if(options->penny&&amount>=min_amount){
					amount=min_amount;
				}
				//werror("amount=%O min_amount=%O\n",amount,min_amount);
				if(amount>=min_amount){
					if(options->check_account_only)
						return 1;
					mapping res=r->trade(inst,"sell_market",0.0,amount);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){
						return 1;
					}
				}
			}
		}/*}}}*/
		int safe_cancel_order(string id)/*{{{*/
		{
			object r=this;
			int found;
			foreach(account->active_orders,object order){
				if(order->id==id){
					r->cancelorder(order->inst,(int)id);
					found=1;
					break;
				}
			}
			if(found){
				update_account();
				found=0;
				foreach(account->active_orders,object order){
					if(order->id==id){
						found=1;
						break;
					}
				}
				if(!found){
					return 1;
				}
			}
		}/*}}}*/
		string query_deposit_address(string btcltc)/*{{{*/
		{
			string inst=this->build_inst(btcltc,"cny");
			if(inst=="btc_cny"){
				return okcoin_btc_deposit_address;
			}else if(inst=="ltc_cny"){
				return okcoin_ltc_deposit_address;
			}
		}/*}}}*/
	}
	class BtcChina{
		extern Account account;
		void update_account()/*{{{*/
		{
			object r=this;
			mapping userinfo,userinfo2,inst2orders;
			int in_changing;
			while(1){
				in_changing=0;
				do{
					inst2orders=([]);
					userinfo=r->getAccountInfo("all");
					werror("userinfo=%O\n",userinfo);
					foreach(({"BTCCNY","LTCCNY","LTCBTC"}),string inst){
						inst2orders[inst]=r->getOrders(inst,1,1000,0,0,1);
						werror("getorder(%s) return %O\n",inst,inst2orders[inst]);
					}
					userinfo2=r->getAccountInfo("all");
					if(userinfo&&userinfo2){
						werror("sizeof(values(inst2orders)&({0}))=%d\n",sizeof(values(inst2orders)&({0})));
						werror("userinfo changed: %d\n",!equal(userinfo->result,userinfo2->result));
					}
				}while(userinfo==0||sizeof(values(inst2orders)&({0}))||!equal(userinfo->result,userinfo2->result));
				mapping tickers=r->ticker("all");

				werror("tickers=%O\n",tickers);

				int orders_ok=1;
				foreach(inst2orders;string inst;mapping orders){
					if(!(mappingp(orders->result)&&arrayp(orders->result->order))){
						orders_ok=0;
					}
				}
				werror("orders_ok=%d\n",orders_ok);
				if(orders_ok&&mappingp(userinfo->result)&&tickers){/*{{{*/
					object res=.Account();
					foreach(inst2orders;string inst;mapping orders){/*{{{*/
						foreach(orders->result->order,mapping m){
							werror("order=%O\n",m);
							object order=.ActiveOrder();
							if(m->type=="bid"&&m->price==Val.null){
								in_changing=1;

								order->id=(string)m->id;
								order->inst=inst;
								order->type="buy";
								order->amount_limit=(float)m->amount_original;
								order->money_limit=Math.inf;
								order->price_limit=Math.inf;
								order->amount_completed=(float)m->amount_original-(float)m->amount;

								order->money_completed=0.0;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									foreach(m->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
								}

							}else if(m->type=="ask"&&m->price==Val.null){
								in_changing=1;

								order->id=(string)m->id;
								order->inst=inst;
								order->type="sell";
								order->amount_limit=(float)m->amount_original;
								order->money_limit=Math.inf;
								order->price_limit=0;
								order->amount_completed=(float)m->amount_original-(float)m->amount;

								order->money_completed=0.0;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									foreach(m->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
								}

							}else if(m->type=="bid"){

								order->id=(string)m->id;
								order->inst=inst;
								order->type="buy";
								order->amount_limit=(float)m->amount_original;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->price;
								order->amount_completed=(float)m->amount_original-(float)m->amount;

								order->money_completed=0.0;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									foreach(m->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
								}

							}else if(m->type=="ask"){

								order->id=(string)m->id;
								order->inst=inst;
								order->type="sell";
								order->amount_limit=(float)m->amount_original;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->price;
								order->amount_completed=(float)m->amount_original-(float)m->amount;

								order->money_completed=0.0;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									foreach(m->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
								}
							}
							res->active_orders+=({order});
						}
					}/*}}}*/
					res->money=(float)userinfo->result->balance->cny->amount;
					res->money_frozen=(float)userinfo->result->frozen->cny->amount;
					res->money_free=res->money-res->money_frozen;
					foreach(({"btc","ltc"}),string k){
						//if((float)userinfo->result->balance[k]->amount!=0.0){
							object position=.Position();
							position->inst=upper_case(k+"cny");
							position->type="buy";
							position->amount=(float)userinfo->result->balance[k]->amount;
							position->amount_frozen=(float)userinfo->result->frozen[k]->amount;
							position->amount_free=position->amount-position->amount_frozen;
							position->margin=(float)(tickers["ticker_"+k+"cny"]->last)*position->amount;
							res->inst2position[position->inst]=position;
						//}
					}
					werror("in_changing=%d\n",in_changing);
					if(!in_changing){
						account=res;
						return;
					}else{
						sleep(5);
					}
				}/*}}}*/
			}
		}/*}}}*/
		int _safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options)/*{{{*/
		{
			object r=this;
			string inst=r->build_inst(btcltc,"cny");
			float min_amount;
			if(inst=="BTCCNY")
				min_amount=0.001;
			else if(inst=="LTCCNY")
				min_amount=0.001;
			else
				throw(({"unknown inst.\n",backtrace()}));

			object ticker=r->ticker(inst);
			while(ticker==0){
				ticker=r->ticker(inst);
			}
			werror("ticker=%O\n",ticker);
			if(type=="buy"){
				float money_free=account->money_free;
				float amount=Norm.floor((money_free)*percent/(float)ticker->ticker->last,BTC_EFFECTIVE_PRECISION);
				float money;
				if(options->penny&&amount>=min_amount){
					amount=min_amount;
					money=Norm.floor(amount*1.1*(float)ticker->ticker->last,CNY_PRECISION);
				}else{
					money=Norm.floor(money_free*percent,CNY_PRECISION);
				}
				if(amount>=min_amount){
					if(options->check_account_only)
						return 1;
					//mapping res=r->trade(inst,"buy_market",money,0.0);
					mapping res=r->buyOrder2(inst,0,amount);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){
						return 1;
					}
				}
			}else if(type=="sell"){
				float amount_free=account->inst2position[inst]->amount_free;
				float amount=Norm.floor(amount_free*percent,BTC_EFFECTIVE_PRECISION);
				if(options->penny&&amount>=min_amount){
					amount=min_amount;
				}
				werror("amount=%O min_amount=%O\n",amount,min_amount);
				if(amount>=min_amount){
					if(options->check_account_only)
						return 1;
					//mapping res=r->trade(inst,"sell_market",0.0,amount);
					mapping res=r->sellOrder2(inst,0,amount);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){//XXX: 20141030 11:45:23 开始的两次sell失败
						return 1;
					}
				}
			}
		}/*}}}*/
		int safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options)/*{{{*/
		{
			int res=_safe_order_market(btcltc,type,percent,options);
			if(res==0&&type=="buy"&&percent==1.0&&options->penny==0&&options->check_account_only==0){
				for(int i=0;i<10;i++){
					int res=_safe_order_market(btcltc,type,1.0-i*0.1,options);
					if(res)
						return res;
				}
			}
			return res;
		}/*}}}*/
		int safe_cancel_order(string id)/*{{{*/
		{
			object r=this;
			int found;
			foreach(account->active_orders,object order){
				if(order->id==id){
					r->cancelOrder(order->inst,(int)id);
					found=1;
					break;
				}
			}
			if(found){
				update_account();
				found=0;
				foreach(account->active_orders,object order){
					if(order->id==id){
						found=1;
						break;
					}
				}
				if(!found){
					return 1;
				}
			}
		}/*}}}*/
		string query_deposit_address(string btcltc)/*{{{*/
		{
			object r=this;
			string inst=r->build_inst(btcltc,"cny");
			mapping m=r->getAccountInfo("profile");
			werror("profile: %O\n",m);
			if(inst=="BTCCNY"){
				return m->result->profile->btc_deposit_address;
			}else if(inst=="LTCCNY"){
				return m->result->profile->ltc_deposit_address;
			}
		}/*}}}*/
		string query_withdrawal_address(string btcltc)/*{{{*/
		{
			object r=this;
			string inst=r->build_inst(btcltc,"cny");
			mapping m=r->getAccountInfo("profile");
			werror("profile: %O\n",m);
			if(inst=="BTCCNY"){
				return m->result->profile->btc_withdrawal_address;
			}else if(inst=="LTCCNY"){
				return m->result->profile->ltc_withdrawal_address;
			}
		}/*}}}*/
		int safe_withdraw(string btcltc,float amount,Wallet wallet,int|void wait)/*{{{*/
		{
			return 0;
			string addr=query_withdrawal_address(btcltc);
			string wallet_account=wallet->getaccount(addr);
			if(wallet_account!=wallet->default_account||wallet_account=="")//getaccount return "" if the address not found
				return 0;
			float wallet_old_amount=wallet->getbalance(wallet_account);
			object r=this;
			werror("withdrawing %0.8f %s to %s\n",amount,btcltc,addr);
			object old_account=account;
			r->requestWithdrawal(btcltc,Norm.floor(amount-0.0001,BTC_EFFECTIVE_PRECISION));
			r->update_account();
			float old_amount=r->account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			float new_amount=old_account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			if(old_amount==Norm.floor(new_amount-amount,BTC_PRECISION)){
				if(wait){
					while(wallet->getbalance(wallet_account)!=Norm.floor(wallet_old_amount+amount-0.0001,BTC_PRECISION)){
						sleep(10);
					}
					return 1;
				}
			}else if(old_amount==new_amount){
				return 0;
			}else{
				werror("WARNING: %.8f - %.8f =%.8f\n",old_amount,amount,new_amount);
			}
		}/*}}}*/
	}
	class Huobi{
		extern Account account;
		void update_account()/*{{{*/
		{
			object r=this;
			mapping userinfo,userinfo2,inst2orders;
			int in_changing;
			while(1){
				in_changing=0;
				do{
					inst2orders=([]);
					userinfo=r->get_account_info();
					werror("userinfo=%O\n",userinfo);
					foreach(({"1","2"}),string inst){
						inst2orders[inst]=r->get_orders(inst);
						werror("getorder(%s) return %O\n",inst,inst2orders[inst]);
					}
					userinfo2=r->get_account_info();
					/*if(userinfo&&userinfo2){
						werror("sizeof(values(inst2orders)&({0}))=%d\n",sizeof(values(inst2orders)&({0})));
						werror("userinfo changed: %d\n",!equal(userinfo,userinfo2));
					}*/
				}while(userinfo==0||sizeof(values(inst2orders)&({0}))||!equal(userinfo,userinfo2));


				mapping btc_ticker=r->ticker("1");
				mapping ltc_ticker=r->ticker("2");

				mapping tickers=(["btc":btc_ticker,"ltc":ltc_ticker]);
				werror("tickers=%O\n",tickers);

				if(btc_ticker&&ltc_ticker){
					object res=.Account();
					foreach(inst2orders;string inst;array orders){/*{{{*/
						foreach(orders,mapping m){
							werror("order=%O\n",m);
							object order=.ActiveOrder();

    /*([
      "id": 32144857,
      "order_amount": "0.0200",
      "order_price": "9000.00",
      "order_time": 1408060559,
      "processed_amount": "0.0000",
      "type": 2
    ])*/

							if(m->type==1/*"bid"*/){

								order->id=(string)m->id;
								order->inst=inst;
								order->type="buy";
								order->amount_limit=(float)m->order_amount;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->order_price;
								order->amount_completed=(float)m->processed_amount;

								order->money_completed=Math.nan;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									order->price_average=Math.nan;
									/*
									foreach(order->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
									*/
								}

							}else if(m->type==2/*"ask"*/){

								order->id=(string)m->id;
								order->inst=inst;
								order->type="sell";
								order->amount_limit=(float)m->order_amount;
								order->money_limit=Math.inf;
								order->price_limit=(float)m->order_price;
								order->amount_completed=(float)m->processed_amount;

								order->money_completed=Math.nan;
								if(order->amount_completed==0.0){
									order->price_average=Math.nan;
								}else{
									order->price_average=Math.nan;
									/*
									foreach(order->detail,mapping m){
										order->money_completed+=(float)m->price*(float)m->amount;
									}
									order->price_average=order->money_completed/order->amount_completed;
									*/
								}
							}
							res->active_orders+=({order});
						}
					}/*}}}*/
					foreach(res->active_orders,object order){
						mapping info=r->order_info(order->inst,order->id);
						while(info==0){
							info=r->order_info(order->inst,order->id);
						}
						if((float)info->processed_amount==order->amount_completed){
							order->price_average=(float)info->processed_price;
							order->money_completed=(float)info->total;
						}else{
							in_changing=1;
						}
					}


/*userinfo=([
  "available_btc_display": "0.0000",
  "available_cny_display": "0.00",
  "available_ltc_display": "0.0000",
  "frozen_btc_display": "0.0200",
  "frozen_cny_display": "0.00",
  "frozen_ltc_display": "0.0000",
  "loan_btc_display": "0.0000",
  "loan_cny_display": "0.00",
  "loan_ltc_display": "0.0000",
  "net_asset": "62.50",
  "total": "62.50"
])*/

					res->money_frozen=(float)userinfo->frozen_cny_display;
					res->money_free=(float)userinfo->available_cny_display;
					res->money=res->money_free+res->money_frozen;
					foreach(({"btc","ltc"}),string k){
						//if((float)userinfo->result->balance[k]->amount!=0.0){
							object position=.Position();
							position->inst=r->build_inst(k,"cny");
							position->type="buy";
							position->amount_free=(float)userinfo["available_"+k+"_display"];
							position->amount_frozen=(float)userinfo["frozen_"+k+"_display"];
							position->amount=position->amount_free+position->amount_frozen;
							position->margin=(float)(tickers[k]->ticker->last)*position->amount;
							res->inst2position[position->inst]=position;
						//}
					}
					werror("in_changing=%d\n",in_changing);
					if(!in_changing){
						account=res;
						return;
					}else{
						sleep(5);
					}
				}
			}
		}/*}}}*/
		int safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options)/*{{{*/
		{
			object r=this;
			string inst=r->build_inst(btcltc,"cny");

			float min_amount;
			if(inst=="1")
				min_amount=0.001;
			else if(inst=="2")
				min_amount=0.001;
			else
				throw(({"unknown inst.\n",backtrace()}));

			float min_money; //文档里没写，但网页上实测有最小1元的限制
			if(inst=="1")
				min_money=1.0;
			else if(inst=="2")
				min_money=1.0;
			else
				throw(({"unknown inst.\n",backtrace()}));

			object ticker=r->ticker(inst);
			while(ticker==0){
				ticker=r->ticker(inst);
			}
			werror("ticker=%O\n",ticker);
			if(type=="buy"){
				float money_free=account->money_free;
				float amount=Norm.floor((money_free)*percent/(float)ticker->ticker->last,BTC_EFFECTIVE_PRECISION);
				float money=Norm.floor(money_free*percent,CNY_PRECISION);
				werror("amount=%O min_amount=%O money=%O min_money=%O\n",amount,min_amount,money,min_money);
				if(options->penny&&amount>=min_amount&&money>=min_money){
					amount=min_amount;
					money=Norm.floor(amount*1.1*(float)ticker->ticker->last+0.01,CNY_PRECISION);
					if(money<min_money){
						money=min_money;
						amount=Norm.floor(min_money/(float)ticker->ticker->last,BTC_EFFECTIVE_PRECISION);
					}
				}else{
					money=Norm.floor(money_free*percent,CNY_PRECISION);
				}
				werror("amount=%O min_amount=%O money=%O min_money=%O\n",amount,min_amount,money,min_money);
				if(amount>=min_amount&&money>=min_money){
					if(options->check_account_only)
						return 1;
					//mapping res=r->trade(inst,"buy_market",money,0.0);
					mapping res=r->buy_market(inst,money);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){
						return 1;
					}
				}
			}else if(type=="sell"){
				float amount_free=account->inst2position[inst]->amount_free;
				float amount=Norm.floor(amount_free*percent,BTC_EFFECTIVE_PRECISION);
				if(options->penny&&amount>=min_amount){
					amount=min_amount;
				}
				werror("amount=%O min_amount=%O\n",amount,min_amount);
				if(amount>=min_amount){
					if(options->check_account_only)
						return 1;
					//mapping res=r->trade(inst,"sell_market",0.0,amount);
					mapping res=r->sell_market(inst,amount);
					//werror("trade return %O\n",res);
					object old_account=account;
					update_account();
					if(account->money_free!=old_account->money_free){
						return 1;
					}
				}
			}
		}/*}}}*/
		int safe_cancel_order(string id)/*{{{*/
		{
			object r=this;
			int found;
			foreach(account->active_orders,object order){
				if(order->id==id){
					mixed res=r->cancel_order(order->inst,(int)id);
					//werror("cancel_order return: %O\n",res);
					found=1;
					break;
				}
			}
			if(found){
				update_account();
				found=0;
				foreach(account->active_orders,object order){
					if(order->id==id){
						found=1;
						break;
					}
				}
				if(!found){
					return 1;
				}
			}
		}/*}}}*/
		string query_deposit_address(string btcltc)/*{{{*/
		{
			if(btcltc=="btc"){
				return huobi_btc_deposit_address;
			}else if(btcltc=="ltc"){
				return huobi_ltc_deposit_address;
			}
		}/*}}}*/
	}
	class BitStamp{
		extern Account account;
	}
	class Test{
		extern Account account;
		Account nextaccount;
		constant is_test=1;
		float|void currprice;
		int first=1;
		void update_account()/*{{{*/
		{
			object r=this;
			if(first){
				first=0;
				account=.Account();
				account->money=TEST_MONEY;
				account->money_frozen=0.0;
				account->money_free=account->money;
				foreach(({"btc","ltc"}),string k){
						object position=.Position();
						position->inst=r->build_inst(k,"cny");
						position->type="buy";
						position->amount=0.0;
						position->amount_frozen=0.0;
						position->amount_free=0.0;
						position->margin=0.0;
						account->inst2position[position->inst]=position;
				}
				object position=account->inst2position[r->build_inst("btc","cny")];
				position->amount=position->amount_free=.BitCoinTestnetWallet()->getbalance("exchange");//exchange storage 
				position->amount_frozen=0.0;
				position->margin=position->amount*1.0;
			}else{
				account=nextaccount;
				nextaccount=0;
				object position=account->inst2position[r->build_inst("btc","cny")];
				position->amount=position->amount_free=.BitCoinTestnetWallet()->getbalance("exchange");//exchange storage 
				position->amount_frozen=0.0;
				position->margin=position->amount*1.0;
			}
			if(currprice){
				object position=account->inst2position[r->build_inst("btc","cny")];
				position->margin=position->amount*currprice;
			}
			nextaccount=account->clone();
		}/*}}}*/
		int safe_order_market(string btcltc,string type,float percent,SafeOrderMarketOptions|void options)/*{{{*/
		{
			object wallet=.BitCoinTestnetWallet();
			object r=this;
			string inst=r->build_inst(btcltc,"cny");
			//Stdio.append_file("/home/work/test-exchange.log",sprintf("safe_order_market(%q,%q,%f,[penny=%d,check_account_only=%d]) currprice=%f\n",btcltc,type,percent,options->penny,options->check_account_only,currprice));
			werror("safe_order_market(%q,%q,%f,[penny=%d,check_account_only=%d]) currprice=%f\n",btcltc,type,percent,options->penny,options->check_account_only,currprice);
			if(btcltc=="btc"){
				if(type=="buy"){
					float money=account->money_free*percent;
					float amount=Norm.floor((money/currprice),BTC_EFFECTIVE_PRECISION);
					if(amount>0){
						if(options->check_account_only)
							return 1;
						nextaccount->money_free-=amount*currprice;
						nextaccount->money-=amount*currprice;
						nextaccount->inst2position[inst]->amount_free+=amount;
						nextaccount->inst2position[inst]->amount+=amount;
						nextaccount->inst2position[inst]->amount_free=Norm.round(nextaccount->inst2position[inst]->amount_free,BTC_EFFECTIVE_PRECISION);
						nextaccount->inst2position[inst]->amount=Norm.round(nextaccount->inst2position[inst]->amount,BTC_EFFECTIVE_PRECISION);
						wallet->sendfrom("storage",wallet->getaccountaddress("exchange"),amount);
						wallet->submit();
						update_account();

						return 1;
					}
				}else if(type=="sell"){
					float amount=Norm.floor(account->inst2position[inst]->amount_free*percent,BTC_EFFECTIVE_PRECISION);
					float money=amount*currprice;
					if(amount>0){
						if(options->check_account_only)
							return 1;
						nextaccount->money_free+=money;
						nextaccount->money+=money;
						nextaccount->inst2position[inst]->amount_free-=amount;
						nextaccount->inst2position[inst]->amount-=amount;
						nextaccount->inst2position[inst]->amount_free=Norm.round(nextaccount->inst2position[inst]->amount_free,BTC_EFFECTIVE_PRECISION);
						nextaccount->inst2position[inst]->amount=Norm.round(nextaccount->inst2position[inst]->amount,BTC_EFFECTIVE_PRECISION);
						wallet->sendfrom("exchange",wallet->getaccountaddress("storage"),amount);
						wallet->submit();
						update_account();
						return 1;
					}
				}
			}
		}/*}}}*/
		int safe_cancel_order(string id)/*{{{*/
		{
			//Stdio.append_file("/home/work/test-exchange.log",sprintf("safe_cancel_order(%q)\n",id));
			werror("safe_cancel_order(%q)\n",id);
			return 1;
		}/*}}}*/
		string query_deposit_address(string btcltc)/*{{{*/
		{
			if(btcltc=="btc"){
				return .BitCoinTestnetWallet()->getaccountaddress("exchange");
			}else if(btcltc=="ltc"){
				return "-";
			}
		}/*}}}*/
		extern string build_inst(string btcltc,string cnyusd);
		int safe_withdraw(string btcltc,float amount,Wallet wallet,int|void wait)/*{{{*/
		{
			if(btcltc=="btc"){
				string addr=wallet->getaccountaddress(wallet->default_account);
				werror("withdrawing %0.8f %s to %s\n",amount,btcltc,addr);
				object old_account=account;
				string txid=wallet->sendfrom("exchange",addr,amount);
				wallet->submit();
				if(txid){
					werror("txid=%s\n",txid);
				}

				if(txid&&wait){
					for(int i=0;i<=wait;i++){
						werror("wait %d confirms ...\n",i);
						object tx=wallet->gettransaction(txid);
						wallet->submit();
						werror("tx->confirmations=%d\n",tx->confirmations);
						while(tx->confirmations<i){
							sleep(10);
							tx=wallet->gettransaction(txid);
							wallet->submit();
						}
					}
					update_account();
					while(account->inst2position[build_inst("btc","cny")]->amount_free==old_account->inst2position[build_inst("btc","cny")]->amount_free){
						sleep(10);
						update_account();
					}
					return 1;
				}
			}
		}/*}}}*/
	}
}


class Requester{
	inherit RequesterAuthMode.Interface;
	inherit RequesterApiMode.Interface;
	inherit RequesterAbstraceLayerMode.Interface;
	inherit RequesterIcebergMode.Interface;
	Thread.Mutex mutex=Thread.Mutex();
	extern string url_prefix;
	mapping|array perform(string path,mapping args)/*{{{*/
	{
		[string post_data,mapping headers]=build_query(args);
		werror("perform: path=%s post_data=%O headers=%O\n",path,post_data,headers);
		Stdio.write_file("requester-"+System.getpid()+"-"+Thread.this_thread()->id_number()+".data",post_data);
		string data=wget(url_prefix+path,headers,"--post-file="+"requester-"+System.getpid()+"-"+Thread.this_thread()->id_number()+".data","--tries=1");
		rm("requester-"+System.getpid()+"-"+Thread.this_thread()->id_number()+".data");
		mapping res=data&&data!=""&&Standards.JSON.decode(data);
		werror("perform: res=%O\n",res);
		return res;
	}/*}}}*/
}

object OkCoinRequester=CLASS(Requester,RequesterAuthMode.OkCoin,RequesterApiMode.OkCoin,RequesterAbstraceLayerMode.OkCoin,RequesterIcebergMode.ViaSafeOrderMarket);
object BtcChinaRequester=CLASS(Requester,RequesterAuthMode.BtcChina,RequesterApiMode.BtcChina,RequesterAbstraceLayerMode.BtcChina,RequesterIcebergMode.ViaSafeOrderMarket);
object HuobiRequester=CLASS(Requester,RequesterAuthMode.Huobi,RequesterApiMode.Huobi,RequesterAbstraceLayerMode.Huobi,RequesterIcebergMode.ViaSafeOrderMarket);
object BitStampRequester=CLASS(Requester,RequesterAuthMode.BitStamp,RequesterApiMode.BitS,RequesterAbstraceLayerMode.BitStamp,RequesterIcebergMode.ViaSafeOrderMarket);
object TestRequester=CLASS(Requester,RequesterAuthMode.Test,RequesterApiMode.Test,RequesterAbstraceLayerMode.Test,RequesterIcebergMode.ViaSafeOrderMarket);

class Trade(
		int tid,
		int sec,
		int usec,
		float val,
		int vol){
	inherit Save.Save;
}

class FetchToolMode{
	class Interface{
		extern int preload_size;
		Trade parse(mapping m);
		array preload(int tid);
		int query_max_tid();
	}
	class OkCoin{/*{{{*/
		int preload_size=60;
		private object run=Time.Sleeper(1);
		Trade parse(mapping m)/*{{{*/
		{
			return .Trade((int)(m->tid),(int)(m->date),0,(float)(m->price),(int)(((float)m->amount)*100000000));
		}/*}}}*/
		array preload(int tid)/*{{{*/
		{
			string data=run(wget,"https://www.okcoin.com/api/trades.do?since="+tid);
			while(1){
				if(data!="")
					break;
				data=run(wget,"https://www.okcoin.com/api/trades.do?since="+tid);
			}
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return res;
		}/*}}}*/
		int query_max_tid()/*{{{*/
		{
			string data=run(wget,"https://www.okcoin.com/api/trades.do");
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return (int)(res[-1]->tid);
		}/*}}}*/
	}/*}}}*/
	class BtcChina{/*{{{*/
		int preload_size=60;
		private object run=Time.Sleeper(1);
		Trade parse(mapping m)/*{{{*/
		{
			return .Trade((int)(m->tid),(int)(m->date),0,(float)(m->price),(int)(m->amount*100000000));
		}/*}}}*/
		array preload(int tid)/*{{{*/
		{
			string data=run(wget,sprintf("https://data.btcchina.com/data/historydata?since=%d&limit=%d",tid,60));
			while(1){
				if(data!="")
					break;
				data=run(wget,sprintf("https://data.btcchina.com/data/historydata?since=%d&limit=%d",tid,60));
			}
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return res;
		}/*}}}*/
		int query_max_tid()/*{{{*/
		{
			string data=run(wget,"https://data.btcchina.com/data/historydata");
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return (int)(res[-1]->tid);
		}/*}}}*/
	}/*}}}*/
#if 0
	class BtcE{/*{{{*/
		int preload_size=60;
		private object run=Time.Sleeper(1);
		Trade parse(mapping m)/*{{{*/
		{
			return .Trade((int)(m->tid),(int)(m->date),0,(float)(m->price),(int)(m->amount*100000000));
		}/*}}}*/
		array preload(int tid)/*{{{*/
		{
			string data=run(wget,sprintf("https://btc-e.com/api/2/btc_usd/trades?from_id=%d&count=%d",tid,60));
			while(1){
				if(data!="")
					break;
				data=run(wget,sprintf("https://btc-e.com/api/2/btc_usd/trades?from_id=%d&count=%d",tid,60));
			}
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return res;
		}/*}}}*/
		int query_max_tid()/*{{{*/
		{
			string data=run(wget,"https://data.btcchina.com/data/historydata");
			array res=data&&data!=""&&Standards.JSON.decode(data);
			return (int)(res[-1]->tid);
		}/*}}}*/
	}/*}}}*/
#endif
}

class FetchTool{
	inherit FetchToolMode.Interface;
	array last;
	void load(int tid)/*{{{*/
	{
		last=map(preload(tid),parse);
		//werror("load %d\n",sizeof(last));
	}/*}}}*/
	int in_range(int tid)/*{{{*/
	{
		if(last&&sizeof(last)&&last[0]->tid<=tid&&last[-1]->tid>=tid)
			return 1;
	}/*}}}*/
	Trade|int(-1..0) find(int tid)/*{{{*/
	{
		foreach(last||({}),object m){
			if(m->tid==tid){
				//werror("hit\n");
				return m;
			}
		}
		if(last&&(sizeof(last)==0||last[-1]->tid<tid)){
			//werror("eof\n");
			return -1;
		}
	}/*}}}*/
	Trade|int(-1..0) fetch(int tid,int|void forward_optimize)/*{{{*/
	{
		if(!in_range(tid)){
			if(forward_optimize)
				load(tid-1);
			else
				load(tid-preload_size/2);
		}
		return find(tid);
	}/*}}}*/
	int locate_trade(array hr,int first,int last)/*{{{*/
	{
		return BinarySearch.search(fetch,lambda(object ob){
				return CompareArray.CompareArray(({ob->sec,ob->usec}));
				},CompareArray.CompareArray(hr),first,last+1);
	}/*}}}*/
}

object OkCoinFetchTool=CLASS(FetchTool,FetchToolMode.OkCoin);
object BtcChinaFetchTool=CLASS(FetchTool,FetchToolMode.BtcChina);

#include <args.h>
int unittest_account_info_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"OKCOIN|BTCC|HUOBI|TEST",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string exchange=lower_case(rest[0]);
	object r;
	if(exchange=="btcc")
		r=BtcChinaRequester();
	else if(exchange=="okcoin")
		r=OkCoinRequester();
	else if(exchange=="huobi")
		r=HuobiRequester();
	else if(exchange=="test")
		r=TestRequester();

	r->update_account();

	write("btc deposit addtress=%s\n",r->query_deposit_address("btc"));
	write("ltc deposit addtress=%s\n",r->query_deposit_address("ltc"));

	write("active_orders=%O\n",map(r->account->active_orders,"save"));
	write("money=%f\n",r->account->money);
	write("money_frozen=%f\n",r->account->money_frozen);
	write("inst2position=%O\n",map(r->account->inst2position,"save"));

}
int fetch_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_STRING_REQUIRED("exchange",exchange_flag,exchange,"=OKCOIN|BTCC");
	DECLARE_ARGUMENT_STRING("begin-day",begin_day_flag,daystr,"!=YYYYMMDD");
	DECLARE_ARGUMENT_INTEGER("begin-tid",begin_tid_flag,begin_tid,"!=TID");
	DECLARE_ARGUMENT_INTEGER("last-tid",last_tid_flag,last_tid,"!=TID");
	DECLARE_ARGUMENT_STRING("end-day",end_day_flag,enddaystr,"=YYYYMMDD");
	DECLARE_ARGUMENT_FLAG("follow",follow_flag,"Loop.");
	DECLARE_ARGUMENT_INTEGER_LIST("exclude",exclude_flag,exclude_list,"=TID1:TID2:...");

	if(Usage.usage(args,"--begin-day=YYYYMMDD\n--last-tid=TID",0)){
		/*werror(
#" -h,	--help		Show this help.
 --exchange=OKCOIN|BTCC
 [--end-day=YYYYMMDD]
 [--exclude=TID1:TID2:...]
 [--follow]
");*/
		return 0;

	}
	HANDLE_ARGUMENTS();

	multiset exclude_set=(<>);
	if(exclude_flag){
		exclude_set=(multiset)exclude_list;
	}

	object dumper;

	if(exchange=="OKCOIN"){
		dumper=OkCoinFetchTool();
	}else if(exchange=="BTCC"){
		dumper=BtcChinaFetchTool();
	}

	int p;
	if(begin_day_flag){
		int t=dumper->query_max_tid();
		werror("max_tid=%d\n",t);
		object day=Calendar.ISO.dwim_day(daystr);
		p=dumper->locate_trade(({day->unix_time(),0}),0,t);
		werror("today=%d\n",p);
		werror("today=%O\n",dumper->fetch(p)->save());
		object b=dumper->fetch(p-1);
		while(b==0){
			p--;
			b=dumper->fetch(p-1);
		}
		werror("before today=%O\n",b->save());
	}else{
		if(begin_tid_flag)
			p=begin_tid;
		if(p==0){
			if(last_tid_flag)
				p=last_tid+1;
		}
	}

	object end;
	if(!follow_flag&&end_day_flag)
		end=CompareArray.CompareArray(({Calendar.ISO.dwim_day(enddaystr)->unix_time(),0}));

	object trade=dumper->fetch(p,1);
	while(trade!=-1&&(trade==0||end==0||CompareArray.CompareArray(({trade->sec,trade->usec}))<end)){
		if(trade&&!exclude_set[trade->tid]){
			//werror("tid=%d\n",p);
			write("%s,%d,%d,%0.2f,%d,%d,-\n",exchange+"-BTC",trade->sec,trade->usec,trade->val,trade->vol,trade->tid);
			//werror("%s,%d,%d,%0.2f,%d\n",exchange+"-BTC",trade->sec,trade->usec,trade->val,trade->vol);
		}
		p++;
		trade=dumper->fetch(p,1);
	}
	if(follow_flag){
		while(1){
			trade=dumper->fetch(p,1);
			while(trade==-1){
				trade=dumper->fetch(p,1);
			}
			if(trade){
				write("%s,%d,%d,%0.2f,%d,%d,+\n",exchange+"-BTC",trade->sec,trade->usec,trade->val,trade->vol,trade->tid);
			}
			p++;
		}
	}
}

class EA{
	string url="http://10.200.3.167:8080/";
	program withdraw_walletp;
	int quit_flag;
	void quit()/*{{{*/
	{
		werror("Quit...\n");
		quit_flag=1;
	}/*}}}*/
	int get_time()/*{{{*/
	{
		return time();
	}/*}}}*/
	array get_signal(string stra)
	{
#ifdef GET_SIGNAL_NO_WGET
		//werror("%s\n",url+"?id="+stra+"&t="+get_time());
		object q=Protocols.HTTP.get_url(url+"?id="+stra+"&t="+get_time());
		string data=q->data();
		while(data==0||data==""){
			q=Protocols.HTTP.get_url(url+"?id="+stra+"&t="+get_time());
			data=q->data();
		}
#else
		string data=wget(url+"?id="+stra+"&t="+get_time());
		while(data==0||data=="")
			data=wget(url+"?id="+stra+"&t="+get_time());
#endif
		sscanf(data,"%d:%s:%d:%s:%s",int sig,string why,int psig,string pwhy,string pricestr);
		if(pricestr!="unknown"){
			sscanf(pricestr,"%f",float currprice);
			return ({sig,why,psig,pwhy,currprice});
		}else{
			return ({sig,why,psig,pwhy,0});
		}
	}

	void on_timer_psig(array rr,object wallet,int psig,string pwhy,float|void currprice)
	{
		if(psig==-1){
			float all=wallet->getbalance(wallet->default_account);
			float one=Norm.floor(all/sizeof(rr),BTC_EFFECTIVE_PRECISION);

			foreach(rr,object r){
				object l=r->mutex->lock();
				r->safe_deposit("btc",one,wallet);
				destruct(l);
			}
		}
	}
	void on_timer_sig(object r,program walletp,int sig,string why,float|void currprice)
	{
		object l=r->mutex->lock();
		string btcltc="btc";
		r->update_account();
		if(sig==1){
			if(r->account->inst2position[r->build_inst(btcltc,"cny")]->amount_free<0.1){
				if(r->is_test)
					r->currprice=currprice;
				r->buy_many("btc");
			}
		}else if(sig==0){
			if(r->account->inst2position[r->build_inst(btcltc,"cny")]->amount_free>0){
				if(r->is_test)
					r->currprice=currprice;
				r->sell_many("btc");
			}
		}else{
			werror("no signal.\n");
		}

		if(walletp){
			if(r->account->inst2position[r->build_inst("btc","cny")]->amount_free>0){
				r->safe_withdraw("btc",r->account->inst2position[r->build_inst("btc","cny")]->amount_free,walletp(),0);
			}
		}
		destruct(l);
	}

	//Thread.Mutex mutex=Thread.Mutex();
	//object wait_queue=Thread.Queue();

	int ea_prepare(array rr,object wallet,object in,object out)
	{
		string thread_name="EA-Prepare";
		/*Thread.Local()->set*/.mysetlocal((["thread_name":thread_name]));
		string stra="b5s5g0";
		int sig,psig;
		string why,pwhy;
		float|void currprice;

		[sig,why,psig,pwhy,currprice]=get_signal(stra);

		//object condition=Thread.Condition();
		while(!quit_flag){
			mixed e=catch{
				on_timer_psig(rr,wallet,psig,pwhy,currprice);
			};
			if(e){
				master()->handle_error(e);
			}
			out->write(1);
			in->read();
			[sig,why,psig,pwhy,currprice]=get_signal(stra);
		}
	}
	int ea_thread_main(object r,object in,object out)
	{
		string thread_name=sprintf("EA-%s",r->name);
		/*Thread.Local()->set*/.mysetlocal((["thread_name":thread_name]));
		//object condition=Thread.Condition();
		string stra="b5s5g0";
		int sig,psig;
		string why,pwhy;
		float|void currprice;

		[sig,why,psig,pwhy,currprice]=get_signal(stra);
		if(r->is_test)
			r->currprice=currprice;


		while(!quit_flag){
			mixed e=catch{
				on_timer_sig(r,withdraw_walletp,sig,why,currprice);
			};
			if(e){
				master()->handle_error(e);
			}
			werror("money=%f btc=%0.8f price=%O\n",r->account->money_free,r->account->inst2position[r->build_inst("btc","cny")]->amount_free,currprice);
			out->write(1);
			in->read();
			[sig,why,psig,pwhy,currprice]=get_signal(stra);
			if(r->is_test)
				r->currprice=currprice;
		}
	}
}
class TestEA(int begin){
	inherit EA;
	string url="http://127.0.0.1:8080/";
	int step;
	int get_time()
	{
		return begin+step*15*60;
	}
	/*void on_timer_sig(object r,int sig,string why,float|void currprice)
	{
		::on_timer_sig(r,sig,why,currprice);
		if(r->account->inst2position[r->build_inst("btc","cny")]->amount_free>0){
			r->safe_withdraw("btc",r->account->inst2position[r->build_inst("btc","cny")]->amount_free,BitCoinTestnetWallet(),1);
		}
	}*/
	/*void on_timer_psig(array rr,object wallet,int psig,string pwhy,float|void currprice)
	{
		if(psig==-1){
			::on_timer_psig(rr,wallet,psig,pwhy,currprice);
		}else if(psig==1){
			float all=wallet->getbalance("exchange");
			float one=floor(all/sizeof(rr)*1000)/1000.0;

			[object r]=rr;
			object l=r->mutex->lock();
			r->safe_withdraw("btc",one,wallet,1);
			destruct(l);
		}
	}*/
	void advance()
	{
		step++;
		werror("%s\n",Calendar.ISO.Second(get_time())->format_time_short());
	}
}

int unittest_wallet_main(int argc,array argv)/*{{{*/
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_FLAG("tx-sample",tx_sample_flag,"Print transaction sample.");
	if(Usage.usage(args,"BTC|LTC|TEST",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	string btcltc=lower_case(rest[0]);

	object wallet;
	if(btcltc=="btc")
		wallet=BitCoinWallet();
	else if(btcltc=="ltc")
		wallet=LiteCoinWallet();
	else if(btcltc=="test")
		wallet=BitCoinTestnetWallet();

	werror("default account addr=%O\n",wallet->getaccountaddress(wallet->default_account));
	werror("unittest account addr=%O\n",wallet->getaccountaddress("unittest"));
	if(btcltc=="test"){
		werror("exchange account addr=%O\n",wallet->getaccountaddress("exchange"));
		werror("storage account addr=%O\n",wallet->getaccountaddress("storage"));
	}
	werror("default account balance=%O\n",wallet->getbalance(wallet->default_account));
	werror("unittest account balance=%O\n",wallet->getbalance("unittest"));
	if(btcltc=="test"){
		werror("exchange balance=%O\n",wallet->getbalance("exchange"));
		werror("storage balance=%O\n",wallet->getbalance("storage"));
	}

	if(tx_sample_flag){
		array txlist=wallet->listtransactions();
		foreach(txlist,mapping info){
			object tx=wallet->gettransaction(info->txid);
			werror("tx sample: %O\n",tx->save());
			break;
		}
	}
}/*}}}*/
int unittest_send_money_main(int argc,array argv)/*{{{*/
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_FLAG("r",reverse_flag,"Reverse");

	if(Usage.usage(args,"BTC|LTC|TEST",1)){
		return 0;
	}

	HANDLE_ARGUMENTS();

	string btcltc=lower_case(rest[0]);


	object wallet;
	if(btcltc=="btc")
		wallet=BitCoinWallet();
	else if(btcltc=="ltc")
		wallet=LiteCoinWallet();
	else if(btcltc=="test")
		wallet=BitCoinTestnetWallet();

	string src_account=wallet->default_account,dest_account="unittest";

	if(reverse_flag){
		[src_account,dest_account]=({dest_account,src_account});
	}

	string src=wallet->getaccountaddress(src_account);
	float src_balance=wallet->getbalance(src_account);
	string dest=wallet->getaccountaddress(dest_account);
	float dest_balance=wallet->getbalance(dest_account);


	werror("src=%O(%.8f)\n",src,src_balance);
	werror("dest=%O(%.8f)\n",dest,dest_balance);
	if(src_balance<0.0001){
		throw(({"no money.\n",backtrace()}));
	}
	wallet->sendfrom(src_account,dest,0.0001)||throw(({"sendfrom fail.\n",backtrace()}));
	wallet->submit();
	for(int i=0;i<3;i++){
		werror("wait %d confirms ...\n",i);
		while(wallet->getbalance(dest_account,i)<=dest_balance){
			sleep(60);
		}
		wallet->submit();
	}
	werror("wait final confirms ...\n");
	while(wallet->getbalance(dest_account)<=dest_balance){
		sleep(60);
		wallet->submit();
	}
	werror("done.\n");
}/*}}}*/
int unittest_buysell_many_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	if(Usage.usage(args,"BUY|SELL OKCOIN|BTCC|HUOBI|TEST BTC|LTC",3)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string buysell=lower_case(rest[0]);
	string exchange=lower_case(rest[1]);
	string btcltc=lower_case(rest[2]);

	werror("buysell=%s exchange=%s btcltc=%s\n",buysell,exchange,btcltc);

	object r;
	if(exchange=="okcoin")
		r=OkCoinRequester();
	else if(exchange=="btcc")
		r=BtcChinaRequester();
	else if(exchange=="huobi")
		r=HuobiRequester();
	else if(exchange=="test")
		r=TestRequester();

	if(r->is_test)
		r->currprice=4000.0;

	if(buysell=="buy")
		r->buy_many(btcltc);
	else if(buysell=="sell")
		r->sell_many(btcltc);
}

private void test_account(object r,string btcltc,int|void deposit_flag,int|void trade_flag)/*{{{*/
{
	r->update_account();
	object old_account=r->account;
	werror("active_orders=%O\n",map(r->account->active_orders,"save"));
	if(deposit_flag){
		if(btcltc=="btc"){
			float deposit_amount=0.01;
			r->safe_deposit("btc",deposit_amount,r->is_test?BitCoinTestnetWallet():BitCoinWallet());
			r->update_account();
			float old_amount=old_account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			float curr_amount=r->account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			if(curr_amount-old_amount-deposit_amount>-0.000000001){

			}else{
				werror("old_amount=%0.9f\n",old_amount);
				werror("deposit_amount=%0.9f\n",deposit_amount);
				werror("curr_amount=%0.9f\n",curr_amount);
				throw(({"lost btc in transaction.\n",backtrace()}));
			}
		}else{
			float deposit_amount=0.1;
			r->safe_deposit("ltc",deposit_amount,r->is_test?0:LiteCoinWallet());
			r->update_account();
			float old_amount=old_account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			float curr_amount=r->account->inst2position[r->build_inst(btcltc,"cny")]->amount_free;
			if(curr_amount-old_amount-deposit_amount>-0.000000001){

			}else{
				werror("old_amount=%0.9f\n",old_amount);
				werror("deposit_amount=%0.9f\n",deposit_amount);
				werror("curr_amount=%0.9f\n",curr_amount);
				throw(({"lost ltc in transaction.\n",backtrace()}));
			}
		}
	}

	werror("PREPARE(TRY CANCEL_OPEN_ORDERS):\n");
	foreach(r->account->active_orders,object order){
		r->safe_cancel_order(order->id)
			||throw(({"safe_cancel_order fail.\n",backtrace()}));
	}
	werror("PREPARE(TRY CANCEL_OPEN_ORDERS) DONE\n");

	if(trade_flag){
		werror("PREPARE(TRY CLOSE POSITION):\n");
		if(r->safe_order_market(btcltc,"sell",1.0,SafeOrderMarketOptions((["penny":0,"check_account_only":1])))){
			r->safe_order_market(btcltc,"sell",1.0,SafeOrderMarketOptions((["penny":0])))
				||throw(({"safe_order_market fail.\n",backtrace()}));
		}
		werror("PREPARE(TRY CLOSE POSITION) DONE\n");
		werror("CHECK BUY:\n");
		int res=r->safe_order_market(btcltc,"buy",1.0,SafeOrderMarketOptions((["penny":1,"check_account_only":1])));
		werror("CHECK BUY DONE: res=%d\n",res);
		if(res){
			werror("BUY: \n");
			r->safe_order_market(btcltc,"buy",1.0,SafeOrderMarketOptions((["penny":1])))
				||throw(({"safe_order_market fail.\n",backtrace()}));
			werror("BUY DONE\n");
			werror("CLOSE: \n");
			r->safe_order_market(btcltc,"sell",1.0,SafeOrderMarketOptions((["penny":0])))
				||throw(({"safe_order_market fail.\n",backtrace()}));
			werror("CLOSE DONE\n");
		}else{
			throw(({"no money.\n",backtrace()}));
		}
	}
}/*}}}*/
int unittest_exchange_account_main(int argc,array argv)/*{{{*/
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_FLAG("deposit",deposit_flag,"COST MONEY!");
	DECLARE_ARGUMENT_FLAG("trade",trade_flag,"COST MONEY!");
	if(Usage.usage(args,"OKCOIN|BTCC|HUOBI|TEST BTC|LTC",2)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string exchange=lower_case(rest[0]);
	string btcltc=lower_case(rest[1]);

	object r;
	if(exchange=="okcoin")
		r=OkCoinRequester();
	else if(exchange=="btcc")
		r=BtcChinaRequester();
	else if(exchange=="huobi")
		r=HuobiRequester();
	else if(exchange=="test")
		r=TestRequester();

	if(trade_flag&&r->is_test)
		r->currprice=4000.0;

	test_account(r,btcltc,deposit_flag,trade_flag);

	werror("active_orders=%O\n",map(r->account->active_orders,"save"));
	werror("money=%f\n",r->account->money);
	werror("money_frozen=%f\n",r->account->money_frozen);
	werror("inst2position=%O\n",map(r->account->inst2position,"save"));
}/*}}}*/

array read_queues(array a,int(-1..) timeout,mixed|void defval)/*{{{*/
{
	array done=allocate(sizeof(a),0);
	array res=allocate(sizeof(a),defval);
	int begin=time();
	while(1){
		foreach(a;int i;object q){
			if(!done[i]){
				if(sizeof(q)){
					res[i]=q->read();
					done[i]=1;
				}
			}
		}
		if(`+(0,@done)==sizeof(a)||timeout>=0&&time()-begin>=timeout)
			return res;
		sleep(1);
	}
}/*}}}*/

int ea_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_FLAG("manual",manual_flag,"");

	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	.mysetlocal((["thread_name":"EA"]));

	object wallet;
	if(manual_flag){
		wallet=BitCoinUnitTestWallet();
		float val=wallet->getbalance(wallet->default_account);
		if(val<MANUAL_AMOUNT_MIN){
			werror("WARNING: balance of %s is less than %f\n",wallet->default_account,MANUAL_AMOUNT_MIN);
			//throw(({sprintf("balance of %s is less than %f\n",wallet->default_account,MANUAL_AMOUNT_MIN),backtrace()}));
		}else if(val>MANUAL_AMOUNT_MAX){
			throw(({sprintf("balance of %s is greater than %f\n",wallet->default_account,MANUAL_AMOUNT_MAX),backtrace()}));
		}
	}else{
		wallet=BitCoinWallet();
	}
	array rr=({OkCoinRequester(),BtcChinaRequester()/*,HuobiRequester()*/});
	array tt=({});
	array in_queues=({});
	array out_queues=({});
	foreach(rr,object r){
		r->update_account();
	}

	object ea=EA();
	ea->withdraw_walletp=object_program(wallet);
	if(manual_flag){
		ea->url="http://10.200.3.167:8081/";
	}

	signal(signum("SIGINT"),ea->quit);
	signal(signum("SIGTERM"),ea->quit);
	signal(signum("SIGKILL"),ea->quit);


	object in,out;
	in_queues+=({in=Thread.Queue()});
	out_queues+=({out=Thread.Queue()});
	tt+=({Thread.Thread(ea->ea_prepare,rr,ea->withdraw_walletp(),in,out)});
	foreach(rr,object r){
		in_queues+=({in=Thread.Queue()});
		out_queues+=({out=Thread.Queue()});
		tt+=({Thread.Thread(ea->ea_thread_main,r,in,out)});
	}
	object run=Time.Sleeper(60);
	out_queues[0]->read();
	while(!ea->quit_flag){
		array active=read_queues(out_queues[1..],300);
		foreach(active;int i;int yes){
			if(!yes){
				werror("WARNING: %s DEAD.\n",rr[i]->name);
				Process.run(sprintf("echo '%s' | mail -s \"EA Alert\" zenothing@hotmail.com",sprintf("%s DEAD.\n",rr[i]->name)));
				in_queues[1+i]=0;
				out_queues[1+i]=0;
			}
		}
		in_queues=filter(in_queues,`!=,0);
		out_queues=filter(out_queues,`!=,0);
		if(sizeof(in_queues)==1)
			break;
		/*for(int i=1;i<sizeof(tt);i++){
			out_queues[i]->read();
		}*/
		in_queues[0]->write(1);
		out_queues[0]->read();
		//ea->advance();
		werror("wallet=%0.8f\n",wallet->getbalance(wallet->default_account));
		//werror("money=%f btc=%0.8f/%0.8f price=%f\n",rr[0]->account->money_free,rr[0]->account->inst2position[rr[0]->build_inst("btc","cny")]->amount_free,wallet->getbalance(wallet->default_account),rr[0]->currprice||0.0);
		run(lambda(){
			for(int i=1;i<sizeof(tt);i++){
				in_queues[i]->write(1);
			}
		});

		/*array res=({});
		for(int i=0;i<sizeof(tt);i++){
			res+=({ea->wait_queue->read()});
		}
		run(lambda(){
				foreach(res,object c){
					c->signal();
				}
				});*/
	}
	for(int i=0;i<sizeof(tt);i++){
		in_queues[i]->write(1);
	}
}

int unittest_ea_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	if(Usage.usage(args,"YYMMDD,HH:MM:SS YYMMDD,HH:MM:SS",2)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	object wallet=BitCoinTestnetWallet();
	float v;

	v=wallet->getbalance("exchange");
	if(v>0){
		wallet->sendfrom("exchange",wallet->getaccountaddress("storage"),v);
		wallet->submit();
	}
	v=wallet->getbalance("default");
	if(v>0){
		wallet->sendfrom("default",wallet->getaccountaddress("storage"),v);
		wallet->submit();
	}

	int begintime=Calendar.ISO.dwim_time(rest[0])->unix_time();
	int endtime=Calendar.ISO.dwim_time(rest[1])->unix_time();;

	array rr=({TestRequester()});
	array tt=({});
	array in_queues=({});
	array out_queues=({});
	rr[0]->update_account();

	object ea=TestEA(begintime);
	ea->withdraw_walletp=object_program(wallet);

	object in,out;
	in_queues+=({in=Thread.Queue()});
	out_queues+=({out=Thread.Queue()});
	tt+=({Thread.Thread(ea->ea_prepare,rr,BitCoinTestnetWallet(),in,out)});
	foreach(rr,object r){
		in_queues+=({in=Thread.Queue()});
		out_queues+=({out=Thread.Queue()});
		tt+=({Thread.Thread(ea->ea_thread_main,r,in,out)});
	}
	object run=Time.Sleeper(0);
	out_queues[0]->read();
	while(1){
		for(int i=1;i<sizeof(tt);i++){
			out_queues[i]->read();
		}
		in_queues[0]->write(1);
		out_queues[0]->read();
		ea->advance();
		werror("money=%f btc=%0.8f/%0.8f price=%f\n",rr[0]->account->money_free,rr[0]->account->inst2position[rr[0]->build_inst("btc","cny")]->amount_free,wallet->getbalance(wallet->default_account),rr[0]->currprice||0.0);
		//werror("wallet=%0.8f\n",wallet->getbalance(wallet->default_account));
		if(ea->get_time()>endtime)
			break;
		run(lambda(){
			for(int i=1;i<sizeof(tt);i++){
				in_queues[i]->write(1);
			}
		});
	}
}
int unittest_bitstamp_account_main(int argc,array argv)/*{{{*/
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	if(Usage.usage(args,"BTC|LTC",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	object r=BitStampRequester();

	//r->update_account();

	mapping res;

	res=r->get_account_info();

	werror("res=%O",res);
}/*}}}*/

int unittest_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	DECLARE_ARGUMENT_EXECUTE("account_info",unittest_account_info_main,"");
	DECLARE_ARGUMENT_EXECUTE("wallet",unittest_wallet_main,"");
	DECLARE_ARGUMENT_EXECUTE("send_money",unittest_send_money_main,"Send money to account 'unittest', and back. COST MONEY!");
	DECLARE_ARGUMENT_EXECUTE("exchange_account",unittest_exchange_account_main,"");
	DECLARE_ARGUMENT_EXECUTE("buysell_many",unittest_buysell_many_main,"Buy/sell BTCs. COST MONEY!");
	DECLARE_ARGUMENT_EXECUTE("bitstamp_account",unittest_bitstamp_account_main,"!");
	DECLARE_ARGUMENT_EXECUTE("ea",unittest_ea_main,"");

	if(Usage.usage(args,"",0)){
		return 0;
	}

	HANDLE_ARGUMENTS();
}

int manual_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	if(Usage.usage(args,"BUY|SELL|PBUY[+]|PSELL[+]",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string action=lower_case(rest[0]);

	if(action=="buy"){
		Stdio.write_file("/home/work/btc/var/manual_values","1:0\n");
	}else if(action=="sell"){
		Stdio.write_file("/home/work/btc/var/manual_values","0:0\n");
	}else if(action=="pbuy"){
		Stdio.write_file("/home/work/btc/var/manual_values","0:1\n");
	}else if(action=="psell"){
		Stdio.write_file("/home/work/btc/var/manual_values","1:-1\n");
	}else if(action=="pbuy+"){
		Stdio.write_file("/home/work/btc/var/manual_values","1:1\n");
	}else if(action=="psell+"){
		Stdio.write_file("/home/work/btc/var/manual_values","0:-1\n");
	}
}
int test_main(int argc,array argv)
{
	object r=BtcChinaRequester();
	//r->safe_order_market("btc","buy",1.0,SafeOrderMarketOptions((["penny":0])))
	//mapping res=r->buyOrder2(r->build_inst("btc","cny"),0,2.0);
	int res=r->buy_many("btc");
	werror("test result: %O\n",res);
}

int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];

	//DECLARE_ARGUMENT_FLAG("test",test_flag,"!");
	DECLARE_ARGUMENT_EXECUTE("fetch",fetch_main,"Fetch ticker history from exchange.");
	DECLARE_ARGUMENT_EXECUTE("ea",ea_main,"Automatic trading.");
	DECLARE_ARGUMENT_EXECUTE("unittest",unittest_main,"Run unittest");
	DECLARE_ARGUMENT_EXECUTE("manual",manual_main,"Manual actions");
	DECLARE_ARGUMENT_EXECUTE("test",test_main,"Test");

	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}
