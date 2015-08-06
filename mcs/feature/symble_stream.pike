MIXIN Session{
private String.Buffer buffer=String.Buffer();
private mapping symble_pos=([]);
private multiset deleted_symbles=(<>);
private mapping replaced_symbles=([]);
int symble_write(string fmt,mixed ... args)/*{{{*/
{
	buffer->add(sprintf(fmt,@args));
}/*}}}*/
void symble_begin(string s)/*{{{*/
{
	if(symble_pos[s]==0){
		symble_pos[s]=([]);
	}
	symble_pos[s]["begin"]=sizeof(buffer);
}/*}}}*/
void symble_end(string s)/*{{{*/
{
	if(symble_pos[s]==0){
		symble_pos[s]=([]);
	}
	symble_pos[s]["end"]=sizeof(buffer);
}/*}}}*/
void symble_delete(string s)/*{{{*/
{
	deleted_symbles[s]=1;
}/*}}}*/
void symble_replace(string s,string d)/*{{{*/
{
	replaced_symbles[s]=d;
}/*}}}*/
string symble_read(string s)/*{{{*/
{
	return ((string)buffer)[symble_pos[s]["begin"]..symble_pos[s]["end"]-1];
}/*}}}*/
void symble_reset()/*{{{*/
{
	string res=buffer->get();
	symble_pos=([]);
	deleted_symbles=(<>);
	replaced_symbles=([]);
}/*}}}*/
void symble_clear(function|void real_write)/*{{{*/
{
	//werror("replaced_symbles:%O",replaced_symbles);
	//werror("symble_pos:%O",symble_pos);
	string res=buffer->get();
	if(sizeof(replaced_symbles)==0&&sizeof(deleted_symbles)==0){
		real_write&&real_write("%s",res);
	}else{
		multiset mask=(<>);
		foreach(deleted_symbles;string k;int one){
			if(symble_pos[k]){
				for(int i=symble_pos[k]->begin;i<symble_pos[k]->end;i++){
					mask[i]=1;
				}
			}
		}
		mapping replace_pos=([]);
		foreach(replaced_symbles;string k;string d){
			if(symble_pos[k]){
				replace_pos[symble_pos[k]->begin]=d;
			}
		}
		for(int i=0;i<sizeof(res);i++){
			if(replace_pos[i]){
				real_write&&real_write("%s",replace_pos[i]);
			}
			if(!mask[i]){
				real_write&&real_write("%s",res[i..i]);
			}
		}
	}
	symble_pos=([]);
	deleted_symbles=(<>);
	replaced_symbles=([]);
}/*}}}*/
}
