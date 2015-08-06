MIXIN Session{
extern int accept_wml;

string command_url(string cmd,string|void uri)/*{{{*/
{
	return html_encode_string(sprintf("%s?%s",uri||"",http_encode_query((["cmd":cmd]),accept_wml)));
}/*}}}*/
string linked_command(string name,string cmd,string|void uri)/*{{{*/
{
	return sprintf("<a href='%s'>%s</a>",command_url(cmd,uri),html_encode_string(name));
}/*}}}*/
string action_command(string name,string cmd,int|void post,string|void uri)/*{{{*/
{
	if(uri==0)
		uri="./";
	string res="";
	res+=sprintf("<form action='%s' method='%s' style='display:inline;'>",html_encode_string(uri),post?"post":"send");
	res+=sprintf("<input type='hidden' name='cmd' value='%s' />",html_encode_string(cmd));
	res+=sprintf("<input style='display:inline;' type='submit' value='%s'/>",html_encode_string(name));
	res+=sprintf("</form>");
	return res;
}/*}}}*/

}
