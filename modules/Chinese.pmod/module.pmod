private array(string) numbers=map(({"","十","百","千","万","十","百","千","亿","十","百","千","万","十","百","千"}),utf8_to_string);
private array(string) numbers2=map(({"","拾","佰","仟","万","拾","佰","仟","亿","拾","佰","仟","万","拾","佰","仟",}),utf8_to_string);
private array(string) digits=map(({"零","一","二","三","四","五","六","七","八","九"}),utf8_to_string);
private array(string) digits2=map(({"零","壹","贰","叁","肆","伍","陆","柒","捌","玖"}),utf8_to_string);
private string number2chinese_internal(int key,array(string) numbers_array,array(string) digits)
{
	string out="";
	int is_negative;
	if(key<0){
		is_negative=1;
		key=-key;
	}
	int i=0;
	if(key==0){
		return digits[0];
	}
	int is_zero=1;
	while(key!=0){
		int n=key%10;
		if(n!=0&&is_zero){
			is_zero=0;
		}
		//第i+1位的数字为n
		if(n!=0||i%4==0){	//n非0，且当前单位是 万、亿、万亿
			if(sizeof(out)&&out[0..0]==utf8_to_string("万")){
				out=numbers[i]+out[1..];
			}
			else{
				out=numbers[i]+out;
			}
		}
		if(n!=0){
			out=digits[n]+out;
		}
		else if(!is_zero){
			out=utf8_to_string("零")+out;
			is_zero=1;
		}
		key=key/10;
		i++;
	}
	if(out[0..1]==utf8_to_string("一十")){
		out=out[1..];
	}
	if(is_negative)
		out=utf8_to_string("负")+out;
	return out;
}
string number(int key,int|void using_cap)
{
	if(using_cap)
		return number2chinese_internal(key,numbers2,digits2);
	else
		return number2chinese_internal(key,numbers,digits);
}
string money(float key,int|void using_cap)
{
	int d=(int)round(key*100);

	string s;
	s=number2chinese_internal(d/100,using_cap?numbers2:numbers,using_cap?digits2:digits);

	s+=utf8_to_string("元");
	if(d%100==0){
		s+=utf8_to_string("整");
	}else{
		int jiao=d%100/10;
		int fen=d%10;
		if(jiao){
			s+=number2chinese_internal(jiao,using_cap?numbers2:numbers,using_cap?digits2:digits)+utf8_to_string("角");
		}
		if(fen){
			s+=number2chinese_internal(fen,using_cap?numbers2:numbers,using_cap?digits2:digits)+utf8_to_string("分");
		}
	}
	return s;
}

void main()
{
	write("%s\n",string_to_utf8(money(100000009.124999,1)));
}
