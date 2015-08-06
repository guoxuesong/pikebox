
MIXIN Session{
	extern int command(string cmd,array args);
	extern function write;
	//extern string html_encode_string(string s);
	extern int server_mode_flag;
	//extern void clear_todolist(Widget w);
	extern void drain_todolist(Widget widget);
	extern mapping id2widget;
	extern Widget curr_widget;
	//extern Widget text(string data,string|function|void click_cmd,string|void data_default);
	extern string request_type;
	object mime;

//#define Widget object

	private int httpwrite(mixed ... args)
	{
		string s=sprintf(@args);
		//werror("httpwrite: %s\n",s);
		//return write("%s",s);
		return write("%s",replace(s,"\0"," "));
	}

	private string print_widget_begin(Widget widget)
	{
		string res="";
		string tt;
		if(widget->type=="horizontal_panel")
			tt="h";
		else if(widget->type=="vertical_panel")
			tt="v";
		else if(widget->type=="camera")
			tt="image";
		else if(widget->type=="audio")
			tt="image";
		else if(widget->type=="voicebutton")
			tt="button";
		else
			tt=widget->type;

		res+=sprintf("<div class='%s' k='%s' ",html_encode_string(tt),widget->id);
		if(widget->init_name){
			res+=sprintf("name='%s' ",html_encode_string(widget->init_name));
		}
		if(widget->init_candidates){
			foreach(widget->init_candidates;int i;string k){
				res+=sprintf("candidate%d='%s' ",i,html_encode_string(k));
			}
		}
		if(widget->init_data){
			res+=sprintf("data='%s' ",html_encode_string(widget->init_data));
		}
		if(widget->init_click_cmd){
			res+=sprintf("click_cmd='%s' ",html_encode_string(widget->init_click_cmd));
		}
		if(widget->init_tags&&sizeof(widget->init_tags)){
			res+=sprintf("tags='%s' ",html_encode_string(join((array)widget->init_tags," ")));
		}
		if(widget->init_visible==0){
			res+=sprintf("invisible='yes' ",);
		}
		if(widget->init_disabled){
			res+=sprintf("disabled='yes' ",);
		}
		if(widget->init_width>Int.NATIVE_MIN){
			res+=sprintf("width='%d:%d:%d' ",widget->init_width,widget->init_width_percent,widget->init_width_min);
		}
		if(widget->init_height>Int.NATIVE_MIN){
			res+=sprintf("height='%d:%d:%d' ",widget->init_height,widget->init_height_percent,widget->init_height_min);
		}
		if(widget->init_scroll_to_bottom){
			res+=sprintf("scroll_to_bottom='yes' ");
		}
		if(widget->color){
			res+=sprintf("color='#%02x%02x%02x' ",@(widget->color));
		}
		if(widget->bgcolor){
			res+=sprintf("bgcolor='#%02x%02x%02x' ",@(widget->bgcolor));
		}
		if(sizeof(widget->todo)){
			foreach(widget->todo;int i;array a){
				string s=print_todolist_cmd(@a);
				res+=sprintf("cmd%d='%s' ",i,html_encode_string(s));
			}
		}
		/*if(widget->init_key_binding&&sizeof(widget->init_key_binding)){
			res+=sprintf("key_binding='");
			foreach(widget->init_key_binding;int key;string cmd){
				ASSERT(search(cmd,":")<0);
				res+=sprintf("%d:%s;",key,html_encode_string(cmd));
			}
			res+=sprintf("' ");
		}*/
		if(res[-1]==' '){
			res[-1]='>';
		}else{
			res+=sprintf(">");
		}
		return res;
	}
	private string print_widget_end(Widget widget)
	{
		return "</div>";
	}
	string print_widget(Widget widget)
	{
		string res=print_widget_begin(widget);
		foreach(widget->init_items,Widget item){
			res+=print_widget(item);
		}
		res+=print_widget_end(widget);
		return res;
	}

	string print_widget_for_client(Widget widget)
	{
		return sprintf("%O",widget->save());
	}

	void walk(Widget widget)
	{
		httpwrite("%s",print_widget_begin(widget));
		foreach(widget->init_items,Widget item){
			walk(item);
		}
		httpwrite("%s\n",print_widget_end(widget));
	}

	void _show(Widget w,string title)
	{
		httpwrite(
#"<!doctype html>
<!-- The DOCTYPE declaration above will set the    -->
<!-- browser's rendering engine into               -->
<!-- \"Standards Mode\". Replacing this declaration  -->
<!-- with a \"Quirks Mode\" doctype may lead to some -->
<!-- differences in layout.                        -->

<html><head>
%s
<meta http-equiv='Cache-Control' content='no-cache, must-revalidate' /> 
<meta http-equiv='Expires' content='Thu, 01 Dec 1994 16:00:00 GMT' />
<meta http-equiv='Last-Modified' content='%s' />
<meta name='viewport' content='width=device-width'/>
<!-- <link rel='stylesheet' type='text/css' href='Brain3GWT.css' /> -->
<link rel='stylesheet' type='text/css' href='Brain3GWT2.css' />
<script type='text/javascript' language='javascript' src='brain3gwt/brain3gwt.nocache.js' charset='UTF-8' ></script>
</head><body>
<script type='text/javascript' src='jscripts/tiny_mce/tiny_mce_src.js' > </script>
<script type='text/javascript' >
//function myCustomOnChangeHandler(inst) {
	        //alert(\"Some one modified something\");
//}

	tinyMCE.init({
		//onchange_callback : \"myCustomOnChangeHandler\",
		// General options
		mode : \"none\",
		language : \"zh-cn\",
		theme : \"advanced\",
		plugins : \"autolink,lists,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template,wordcount,advlist,autosave\",

		// Theme options
		theme_advanced_buttons1 : \"bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,styleselect,formatselect,fontselect,fontsizeselect\",
		theme_advanced_buttons2 : \"cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code\",
		theme_advanced_buttons3 : \"tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl\",
		theme_advanced_buttons4 : \"insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,pagebreak,restoredraft,|,insertdate,inserttime,preview,|,forecolor,backcolor,|,fullscreen\",
		theme_advanced_toolbar_location : \"top\",
		theme_advanced_toolbar_align : \"left\",
		theme_advanced_statusbar_location : \"bottom\",
		theme_advanced_resizing : true,

		// Example content CSS (should be your site CSS)
		content_css : \"css/content.css\",

		// Drop lists for link/image/media/template dialogs
		template_external_list_url : \"lists/template_list.js\",
		external_link_list_url : \"lists/link_list.js\",
		external_image_list_url : \"lists/image_list.js\",
		media_external_list_url : \"lists/media_list.js\",

		// Style formats
		style_formats : [
			{title : 'Bold text', inline : 'b'},
			{title : 'Red text', inline : 'span', styles : {color : '#ff0000'}},
			{title : 'Red header', block : 'h1', styles : {color : '#ff0000'}},
			{title : 'Example 1', inline : 'span', classes : 'example1'},
			{title : 'Example 2', inline : 'span', classes : 'example2'},
			{title : 'Table styles'},
			{title : 'Table row 1', selector : 'tr', classes : 'tablerow1'}
		],

		// Replace values for the template plugin
		template_replace_values : {
			username : \"Some User\",
			staffid : \"991234\"
		}
	});
</script>
<div id='start' align='center'><xml>",
	title?sprintf("<title>%s</title>",html_encode_string(title)):"",
	Protocols.HTTP.Server.http_date(time()),
	);
		
		httpwrite("<div class='dnd_rules' >");
		foreach(dnd_rules,[WidgetType wt,PositionType pt,RuleType rt,string cmd]){
			httpwrite("<div class='dnd_rule' widget_type='%s' container_tags='%s' last_tags='%s' next_tags='%s' rule_type='%s' cmd='%s' />",
					html_encode_string(join((array)(wt->tags)," ")),
					html_encode_string(join((array)(pt->container_tags)," ")),
					html_encode_string(join((array)(pt->last_tags)," ")),
					html_encode_string(join((array)(pt->next_tags)," ")),
					html_encode_string(rt->type),
					html_encode_string(cmd));
		}
		httpwrite("</div>\n");
		
		walk(w);
		httpwrite("</xml></div>%s</body></html>",
#ifdef DEMO
#ifdef DEMO_CONVERSION
/*{{{*/
#"<!-- Google Code for &#28857;&#20987;&#36141;&#20080; Conversion Page -->
<script type=\"text/javascript\">
/* <![CDATA[ */
var google_conversion_id = 1053167591;
var google_conversion_language = \"zh_CN\";
var google_conversion_format = \"3\";
var google_conversion_color = \"ffffff\";
var google_conversion_label = \"J1wJCKXFvgEQ55-Y9gM\";
var google_conversion_value = 0;
if (50) {
  google_conversion_value = 50;
}
/* ]]> */
</script>
<script type=\"text/javascript\" src=\"http://www.googleadservices.com/pagead/conversion.js\">
</script>
<noscript>
<div style=\"display:inline;\">
<img height=\"1\" width=\"1\" style=\"border-style:none;\" alt=\"\" src=\"http://www.googleadservices.com/pagead/conversion/1053167591/?value=50&amp;label=J1wJCKXFvgEQ55-Y9gM&amp;guid=ON&amp;script=0\"/>
</div>
</noscript>
"
/*}}}*/
#endif
#"
<script type=\"text/javascript\">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-1106390-4']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
"
#else 
#ifdef DEBUG2
#"<script type=\"text/javascript\">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-1106390-5']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
"
#else
""
#endif
+
#ifdef FREEMAIL
#"<div id='ad' style='position: absolute;'>
<script type=\"text/javascript\"><!--
google_ad_client = \"ca-pub-1131715458133605\";
/* freemail-rightside */
google_ad_slot = \"7898183490\";
google_ad_width = 160;
google_ad_height = 600;
//-->
</script>
<script type=\"text/javascript\"
src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\">
</script>
</div>"
#"<script type='text/javascript'>
    var myWidth = 0, myHeight = 0;
    if (typeof (window.innerWidth) == 'number') {
        //Non-IE
        myWidth = window.innerWidth-20;
        myHeight = window.innerHeight-20;
    } else if (document.documentElement && (document.documentElement.clientWidth ||   document.documentElement.clientHeight)) {
        //IE 6+ in 'standards compliant mode'
        myWidth = document.documentElement.clientWidth;
        myHeight = document.documentElement.clientHeight;
    } else if (document.body && (document.body.clientWidth || document.body.clientHeight)) {
        //IE 4 compatible
        myWidth = document.body.clientWidth;
        myHeight = document.body.clientHeight;
    }
	        //alert(\"myWidth=\"+myWidth+\",myHeight=\"+myHeight);

var clientWidth=myWidth;
if(clientWidth<=0) clientWidth=600;
var clientHeight=myHeight;
if(clientHeight<=0) clientHeight=600;
document.getElementById('ad').style.position=\"absolute\";
document.getElementById('ad').style.left=clientWidth-160-20+\"px\";
/*if(clientHeight-600-20>200){
	document.getElementById('ad').style.top=clientHeight-600-20+\"px\";
}*/
	document.getElementById('ad').style.top=200+\"px\";

</script>
"
#else
""
#endif
#endif
				);
	}
	void _reshow(Widget w)
	{
		httpwrite("<xml>\n");
		walk(w);
		httpwrite("</xml>\n");
	}

	array dnd_rules=({});

	void add_dnd_rule(WidgetType wt,PositionType pt,RuleType rt,string cmd)
	{
		dnd_rules+=({({wt,pt,rt,cmd})});
	}

	/*void start_dnd()
	{
	}*/
	void hide()/*{{{*/
	{
		if(server_mode_flag){
			httpwrite("remote_hide\n");
		}
	}/*}}}*/

	PUBLIC _file_upload_(string cmd,mixed ... args)
	{
		if(mime->body_parts)
		{
			foreach(mime->body_parts, object mpart){
				//werror("file_upload: mpart data = %O\n", mpart->getdata());
				if(mpart->disp_params&&mpart->disp_params["filename"]){
					return command(cmd,args+({mpart}));
				}
			}
		}
	}

	PUBLIC _session_timeout_(mixed ... args)
	{
		Widget w=WIDGETD->text("会话已过期。请刷新页面，重新登陆。");
		_reshow(w);
	}

	string print_todolist_cmd(string cmd,mixed ... args)
	{
		array a=({cmd})+args;
		if(cmd=="delete")
			a=a[..<2]+({a[-1]});
		a=map(a,lambda(mixed v){
				if(objectp(v)){
					v->clear_todolist();
					string res;
					if(!server_mode_flag){
						res=print_widget(v);
					}else{
						res=print_widget_for_client(v);
					}
					return res;
				}else if(stringp(v)){
					return v;
				}else if(intp(v)){
					return sprintf("%d",v);
				}else{
					ABORT();
				}
				});
		//werror("default handle_todolist_cmd:%O\n",a*" ");
		a=map(a,lambda(string s){
				if(sizeof(s)&&s[0]=='"'||
							search(s,"\r")!=-1||
							search(s,"\n")!=-1||
							search(s,"\"")!=-1||
							search(s,"\000")!=-1
					){
					s=join(({s})," ");
				}
				if(sizeof(s)&&s[0]=='='||search(s," ")>=0){
					if(request_type=="post"||request_type=="POST")
						return "=H="+String.string2hex(s);
					else{
						int n=sizeof(s/" ");
						return sprintf("=%d=%s",n,s);
					}
				}else{
					return s;
				}
				});
		string res=a*" ";
		for(int i=0;i<sizeof(res);i++){
			ASSERT_TRUE(res[i]<=255,({cmd})+args+({res}));
		}
		return res;
	}

	string handle_todolist_cmd(string cmd,mixed ... args)/*{{{*/
	{
		string res=print_todolist_cmd(cmd,@args);
		if(request_type=="post"||request_type=="POST")
			httpwrite(
					"<pre>\n"
					"%s\n"
					"</pre>\n"
					,res);
		else
			httpwrite( "%s\n" ,res);
		return res;
	}/*}}}*/
}

MIXIN RequestHandler{
	extern mapping m;
	extern object session;
	/*
	REGISTER(prelogin);
	private void prelogin()
	{
		//werror("m=%O\n",m);
		if(search(m->request_headers["user-agent"],"MSIE")>=0){
			mapping q=m->variables;
			if(q->cmd&&has_prefix(q->cmd,"from_gui ")){
				werror("before gbk_to_utf8: %s\n",q->cmd);
				q->cmd=gbk_to_utf8(q->cmd);
				werror("after gbk_to_utf8: %s\n",q->cmd);
			}
		}
	}
	*/
	REGISTER(precmd);
	private void precmd()
	{
		//werror("m->variables=%O\n",m->variables);
		//werror("body_raw=%O\n",m->body_raw);
		//werror("content-type=%O\n",m->request_headers["content-type"]);
		if(m->request_headers["content-type"]&&has_prefix(m->request_headers["content-type"],"multipart/form-data;")){
			object mime=MIME.Message(m->body_raw,(["content-type":m->request_headers["content-type"]]),0,1);
			session->mime=mime;
		}
	}
	REGISTER(postcmd);
	private void postcmd()
	{
		if(m->content_type==0){
			m->content_type="text/html; charset=utf-8";
		}

	}
}
