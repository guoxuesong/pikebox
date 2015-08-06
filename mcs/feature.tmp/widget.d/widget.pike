#line 276 "/home/work/PikeBox/project/bityuan/feature/widget.pike"
int|Widget show_error(Widget curr_widget,UserException e,int err)
{
object WIDGETD=this;
Widget res;
if(e){
//master()->handle_error(e);
if(objectp(e)&&(object_program(e)==UserException
||object_program(e)==PermisionException)
){
res=WIDGETD->vertical_panel(({e[0]}));
}else{
//res=vertical_panel(({"发生错误，可能是因为连续点击了一个按钮两次导致"}));
}
}else if(err){
res=WIDGETD->vertical_panel(({"操作失败"}));
}
mixed ee=catch{
Widget w=curr_widget->find_widget("error_prompt");
if(w){
w->clear_panels();
if(res)
w->add(WIDGETD->horizontal_panel(({res,WIDGETD->button("确定","cancel_errorprompt")})));
return 0;
}else{
return res;
}
};
if(ee){
master()->handle_error(ee);
return res;
}
}
#include <defines.h>
//int widget_sn;
mapping id2widget=set_weak_flag(([]),Pike.WEAK_VALUES);
//mapping widget2onclick=set_weak_flag(([]),Pike.WEAK);
mapping tag2widgets=([]);
void update_tag2widgets(string tag,Widget w)
{
ASSERT(sizeof(tag2widgets)<5000);
tag2widgets[tag]=tag2widgets[tag]||set_weak_flag((<>),Pike.WEAK);
tag2widgets[tag][w]=1;
}

#ifdef WIDGET_OPT
#define IS_FINDABLE(p) p->_findable
#else
#define IS_FINDABLE(p) p->findable
#endif

multiset find_widgets_bytag(Widget root,string tag)/*{{{*/
{
multiset m=tag2widgets[tag]||(<>);
multiset res=(<>);
//werror("find_widgets_bytag: %O %s",tag2widgets,tag);
//werror("find_widgets_bytag: %O",m);
foreach(m;Widget w;int one){
int found;
for(Widget p=w;p&&IS_FINDABLE(p);p=p->father){
//werror("%O",p);
if(p==root){
found=1;
}
}
if(found){
res[w]=1;
}
}
return res;
}/*}}}*/

int basetime=time();

#ifdef WIDGET_OPT
#define CONSTANT(TYPE,ATTR) \
TYPE ATTR; \
TYPE `_##ATTR(){ return ATTR;}\
TYPE `_##ATTR##=(TYPE val){ return ATTR=val;}

#define READONLY(TYPE,ATTR) \
TYPE ATTR; \
TYPE init_##ATTR;\
TYPE `_##ATTR(){ return ATTR;}\
TYPE `_##ATTR##=(TYPE val){ return ATTR=val;}\
TYPE `_init_##ATTR(){ return init_##ATTR;}\
TYPE `_init_##ATTR##=(TYPE val){ return init_##ATTR=val;}\
void _set_##ATTR##_internal_(TYPE v){ ATTR=v;}\
void _set_init_##ATTR##_internal_(TYPE v){ init_##ATTR=v;}

#define READONLY3(TYPE,ATTR,VAL) \
TYPE ATTR=VAL; \
TYPE init_##ATTR=VAL;\
TYPE `_##ATTR(){ return ATTR;}\
TYPE `_##ATTR##=(TYPE val){ return ATTR=val;}\
TYPE `_init_##ATTR(){ return init_##ATTR;}\
TYPE `_init_##ATTR##=(TYPE val){ return init_##ATTR =val;}\
void _set_##ATTR##_internal_(TYPE v){ ATTR=v;}\
void _set_init_##ATTR##_internal_(TYPE v){ init_##ATTR =v;}

#define UPDATE(ATTR) init_##ATTR=ATTR

#define INIT(ATTR,VAL) ATTR=init_##ATTR=VAL

#define SET(ATTR,VAL) ATTR=VAL
#define SET_INIT(ATTR,VAL) init_##ATTR=VAL
#define QUERY(ATTR) ATTR
#define QUERY_INIT(ATTR) init_##ATTR

#else
#define CONSTANT(TYPE,ATTR) \
protected TYPE _##ATTR; \
TYPE `##ATTR(){ return copy_value(_##ATTR);}

#define READONLY(TYPE,ATTR) \
protected TYPE _##ATTR; \
protected TYPE _init_##ATTR;\
TYPE `##ATTR(){ return copy_value(_##ATTR);}\
TYPE `init_##ATTR(){ return copy_value(_init_##ATTR);}\
void _set_##ATTR##_internal_(TYPE v){ _##ATTR=v;}\
void _set_init_##ATTR##_internal_(TYPE v){ _init_##ATTR=v;}

#define READONLY3(TYPE,ATTR,VAL) \
protected TYPE _##ATTR=VAL; \
protected TYPE _init_##ATTR=VAL;\
TYPE `##ATTR(){ return copy_value(_##ATTR);}\
TYPE `init_##ATTR(){ return copy_value(_init_##ATTR);}\
void _set_##ATTR##_internal_(TYPE v){ _##ATTR=v;}\
void _set_init_##ATTR##_internal_(TYPE v){ _init_##ATTR=v;}

#define UPDATE(ATTR) _init_##ATTR=_##ATTR

#define INIT(ATTR,VAL) _##ATTR=_init_##ATTR=VAL

#define SET(ATTR,VAL) _##ATTR=VAL
#define SET_INIT(ATTR,VAL) _init_##ATTR=VAL
#define QUERY(ATTR) _##ATTR
#define QUERY_INIT(ATTR) _init_##ATTR

#endif
class UserException{
inherit Error.Generic;
}

int todo_sn;

class FixPikeBug{
CONSTANT(string,id);
CONSTANT(string,type);
READONLY(string,name);
READONLY(array,items);
READONLY(array,candidates);
READONLY(string,data);
READONLY(string,click_cmd);
READONLY3(int,visible,1);
READONLY3(int,width,Int.NATIVE_MIN);
READONLY3(int,width_percent,100);
READONLY(int,width_min);
READONLY3(int,height,Int.NATIVE_MIN);
READONLY3(int,height_percent,100);
READONLY(int,height_min);
READONLY3(multiset,tags,(<>));
}

class Widget{
inherit FixPikeBug;
READONLY(int,disabled);
//READONLY(mapping,key_binding);
READONLY(int,scroll_to_bottom);
READONLY3(int,findable,1);
READONLY(array,color);
READONLY(array,bgcolor);
READONLY(int,cursor_pos);

string data_default;
Widget _father;
object `father(){return _father;};
Widget _lru;
object `lru(){return _lru;};
int _lru_limit;
int `lru_limit(){return _lru_limit;};
int deleted_flag;
void set_lru_panel(Widget w,int limit)/*{{{*/
{
ASSERT(_lru==0);
_lru=w;
_lru_limit=limit;
}/*}}}*/

mapping extra_cmds=([]);
array todo=({});

function on_change;
int always_call_on_change;
string|function on_click;

string namecn;
Widget set_namecn(string s){
namecn=s;
return this;
}

//mixed bt;

void create(string init_type__, string init_name__, array init_items__, array init_candidates__,string init_data__, string|function|array init_click_cmd__, mapping init_key_binding__,string|void _data_default__,string|void _init_id){/*{{{*/
//bt=backtrace();
//call_out(lambda(){if(_init_items!=_items&&sizeof(_init_items)){master()->handle_error(({"Widget not updated.",bt}));}},10);

_id=gen_uniq_id("w",basetime);


if(arrayp(init_click_cmd__)){
ASSERT(functionp(init_click_cmd__[0]));
on_click=init_click_cmd__[0];
init_click_cmd__=replace(join(({"_widget_onclick_",_id})+init_click_cmd__[1..]," "),"$(THIS_WIDGET)",_id);
}else if(functionp(init_click_cmd__)){
on_click=init_click_cmd__;
//widget2onclick[this]=init_click_cmd__;
//werror("sizeof(widget2onclick)=%d\n",sizeof(widget2onclick));
init_click_cmd__="_widget_onclick_ "+_id;
}else if(stringp(init_click_cmd__)){
init_click_cmd__=replace(init_click_cmd__,"$(THIS_WIDGET)",_id);
}

_type=init_type__;
INIT(name,init_name__);
if(name)
ASSERT(search(name,"#")<0);
INIT(items,map(init_items__,lambda(mixed ob){if(objectp(ob))return ob;else return this_program(@decode_value(ob));}));
//_items=_init_items=map(init_items__,lambda(mixed ob){if(objectp(ob))return ob;else return this_program(@decode_value(ob));});
INIT(candidates,init_candidates__);
INIT(data,init_data__);
INIT(click_cmd,init_click_cmd__);
//INIT(key_binding,init_key_binding);

/*
_type=_init_type=init_type__;
_name=init_name__;
_data=_init_data=init_data__;
_click_cmd=init_click_cmd__;
_key_binding=init_key_binding;
*/
data_default=_data_default__;
if(QUERY(data)==""&&data_default) INIT(data,data_default);

if(_init_id)
_id=_init_id;

foreach(QUERY(items),object item){
item->_father=this;
}

id2widget[_id]=this;
//werror("sizeof(id2widget)=%d\n",sizeof(id2widget));
}/*}}}*/
void destroy()/*{{{*/
{
//werror("destroy widget %s\n",_id);
m_delete(id2widget,_id);
//m_delete(widget2object,this);
}/*}}}*/
int _insert_internal_(int pos,Widget w){/*{{{*/
//ASSERT(search(_items,w)<0);
//if(search(_items,w)<0){
if(w->_father==0){
if(pos<=sizeof(QUERY(items))){
SET(items,QUERY(items)[..pos-1]+({w})+QUERY(items)[pos..]);
w->_father=this;
return 0;
}
}else{
//werror("WARNING: 现在我们允许老Widget被再次添加到Panel里面，GTK需要对此添加额外的支持。\n");
w->_father->_delete_internal_(search(w->_father->items,w));
ASSERT(pos<=sizeof(_items));
SET(items,QUERY(items)[..pos-1]+({w})+QUERY(items)[pos..]);
w->_father=this;
return 0;
}
//}else{
//werror("ERROR: Widget重复插入。\n");
//}
return 1;
}/*}}}*/
int _delete_internal_(int pos){/*{{{*/
if(pos<sizeof(QUERY(items))){
QUERY(items)[pos]->_father=0;
SET(items,QUERY(items)[..pos-1]+QUERY(items)[pos+1..]);
//werror("delete ok",);
return 0;
}else{
//werror("delete fail",);
return 1;
}
}/*}}}*/

Widget add(Widget w)/*{{{*/
{
return insert(sizeof(items),w);
}/*}}}*/
Widget insert(int pos,Widget w){/*{{{*/
int flag;
if(w->_father){
flag=1;
//w->remove(1,1);
}
if(_lru){
foreach(_lru->items,Widget ww){
ASSERT(w==ww||ww->id!=w->id);
}
}
if(_insert_internal_(pos,w)==0){
if(flag){
if(deleted_flag==0) todo+=({({todo_sn++,"reinsert",_id,pos,w->id})});
}else{
if(deleted_flag==0) todo+=({({todo_sn++,"insert",_id,pos,w})});
}
//werror("todo=%O\n",todo);
}
return this;
}/*}}}*/
Widget delete(int pos,int|void from_lru,int|void donnot_destruct){/*{{{*/
//ASSERT(donnot_destruct==0);//used in pop_view(), start_workflow need pop_view to return deleted widget
Widget w=items[pos];
if(_lru&&!from_lru){
werror("add %s to lru\n",w->id);
_lru->insert(0,w);
if(sizeof(_lru->items)>_lru_limit){
_lru->delete(sizeof(_lru->items)-1,1,0);
}
}else{
if(_delete_internal_(pos)==0){
if(!donnot_destruct){
void walk(Widget w)
{
//werror("delete widget %s\n",w->id);
w->deleted_flag=1;
w->_father=0;
foreach(w->items,Widget ww){
walk(ww);
}
w->_set_items_internal_(({}));
};
walk(w);
}

if(deleted_flag==0) todo+=({({todo_sn++,"delete",_id,pos,w,donnot_destruct})});
//werror("todo=%O\n",todo);
}
}
return this;
}/*}}}*/
Widget hide(int|void cannot_found)/*{{{*/
{
_visible=0;
if(cannot_found)
_findable=0;
if(deleted_flag==0) todo+=({({todo_sn++,"hide",_id})});
return this;
}/*}}}*/
Widget show()/*{{{*/
{
_visible=1;
_findable=1;
if(deleted_flag==0) todo+=({({todo_sn++,"show",_id})});
return this;
}/*}}}*/
Widget disable()/*{{{*/
{
_disabled=1;
if(deleted_flag==0) todo+=({({todo_sn++,"disable",_id})});
return this;
}/*}}}*/
Widget enable()/*{{{*/
{
_disabled=0;
if(deleted_flag==0) todo+=({({todo_sn++,"enable",_id})});
return this;
}/*}}}*/
Widget set_width(int n,int|void percent,int|void min)/*{{{*/
{
SET(width,n);
SET(width_percent,percent||100);
if(deleted_flag==0) todo+=({({todo_sn++,"set_width",_id,n,percent||100,min})});
return this;
}/*}}}*/
Widget set_cursor_pos(int pos)/*{{{*/
{
_cursor_pos=pos;
if(deleted_flag==0) todo+=({({todo_sn++,"set_cursor_pos",_id,pos})});
}/*}}}*/
Widget set_height(int n,int|void percent,int|void min)/*{{{*/
{
SET(height,n);
SET(height_percent,percent||100);
if(deleted_flag==0) todo+=({({todo_sn++,"set_height",_id,n,percent||100,min})});
return this;
}/*}}}*/
//int set_data_flag=0;
Widget set_data_default(string data__)/*{{{*/
{
data_default=data__;
if(QUERY(data)==""){
SET(data,data__);
}
if(deleted_flag==0) todo+=({({todo_sn++,"set_data",_id,data__})});
return this;
}/*}}}*/
Widget set_data(string data__)/*{{{*/
{
//if(_data=="查看此代理商关联的客户"&&data=="")
//ABORT();
if(data__==""&&data_default)
data__=data_default;
//set_data_flag=1;
SET(data,data__);
if(deleted_flag==0) todo+=({({todo_sn++,"set_data",_id,data__})});
return this;
}/*}}}*/
Widget set_candidates(array a)/*{{{*/
{
SET(candidates,a);
if(deleted_flag==0) todo+=({({todo_sn++,"set_candidates",_id})+a});
}/*}}}*/
Widget mark(string name__,multiset|void tags_val){/*{{{*/
if(name__){
ASSERT(search(name__,"#")<0);
SET(name,name__);
}
if(tags_val){
_tags=tags_val;
foreach(tags_val;string tag;int one){
update_tag2widgets(tag,this);
}
}
if(deleted_flag==0) todo+=({({todo_sn++,"mark",_id,name__,join((array)(tags_val||(<>))," ")})});
return this;
}/*}}}*/
Widget set_bgcolor(array c){/*{{{*/
_bgcolor=c;
if(deleted_flag==0) todo+=({({todo_sn++,"set_background",_id,})+_bgcolor});
return this;
}/*}}}*/
Widget set_color(array c){/*{{{*/
_color=c;
if(deleted_flag==0) todo+=({({todo_sn++,"set_color",_id,})+c});
return this;
}/*}}}*/
void reset_scroll_position(Widget sp,int|void bottom)/*{{{*/
{
if(bottom)
THIS_SESSIOND->this_session()->global_todolist+=({({"scroll_to_bottom",sp->id})});
else
THIS_SESSIOND->this_session()->global_todolist+=({({"reset_scroll_position",sp->id})});
}/*}}}*/
void adjust_scroll_position(Widget sp,string sym,Widget w)/*{{{*/
{
THIS_SESSIOND->this_session()->global_todolist+=({({"adjust_scroll_position",sp->id,sym,w->id})});
}/*}}}*/
void adjust_scroll_position_and_delete(Widget sp,int pos)/*{{{*/
{
if(_lru){
werror("_insert_internal_ %s to lru\n",items[pos]);
if(_lru->_insert_internal_(0,items[pos])==0){
if(deleted_flag==0) todo+=({({todo_sn++,"adjust_scroll_position_and_reinsert_to",sp->id,id,pos,_lru,0})});
}
}else{
_delete_internal_(pos);
if(deleted_flag==0) todo+=({({todo_sn++,"adjust_scroll_position_and_delete",sp->id,id,pos})});
}
}/*}}}*/
void adjust_scroll_position_and_insert(Widget sp,int pos,Widget w)/*{{{*/
{
if(w->_father){
_insert_internal_(pos,w);
if(deleted_flag==0) todo+=({({todo_sn++,"adjust_scroll_position_and_reinsert",sp->id,id,pos,w->id})});
}else{
_insert_internal_(pos,w);
if(deleted_flag==0) todo+=({({todo_sn++,"adjust_scroll_position_and_insert",sp->id,id,pos,w})});
}
}/*}}}*/
void update_scroll(){
THIS_SESSIOND->this_session()->global_todolist+=({({"update_scroll",id})});
}

void remove(int|void from_lru,int|void donnot_destruct)/*{{{*/
{
ASSERT(donnot_destruct==0);
int pos=search(_father->items,this);
if(pos>=0){
_father->delete(pos,from_lru,donnot_destruct);
}
}/*}}}*/

#if 0
Widget binding(mapping m){/*{{{*/
foreach(m;int key;string cmd){
_key_binding[key]=cmd;
}
return this;
}/*}}}*/
#endif
Widget|multiset find_widget(string|multiset name)/*{{{*/
{
multiset res;
if(multisetp(name)){
foreach(name;string tag;int one){
if(res==0)
res=find_widgets_bytag(this,tag);
else
res=res&find_widgets_bytag(this,tag);

}
}else{
werror("WARNING: find_widget by name would be slow. name=%O\n",name);
res=(<>);
void walk(Widget w)
{
if(stringp(name)&&w->name==name||multisetp(name)&&sizeof(w->tags&name)==sizeof(name)){
res[w]=1;
//return;
}
foreach(w->items,Widget ww){
if(IS_FINDABLE(ww))
walk(ww);
}
};
walk(this);
}
if(sizeof(res)==0){
return 0;
}else if(sizeof(res)==1){
foreach(res;Widget w;int one)
return w;
}else{
return res;
}
}/*}}}*/
Widget clear_panels(string|multiset|void name,int|void and_hide)/*{{{*/
{
object|multiset m=(<this>);
if(name)
m=find_widget(name);
if(m&&!multisetp(m))
m=(<m>);
foreach(m||(<>);Widget w;int one){
while(sizeof(w->items)){
w->delete(0,1,0);
}
if(and_hide){
w->hide();
}
}
return this;
}/*}}}*/

int my_clear_todolist_sn;
void clear_todolist()/*{{{*/
{
if(my_clear_todolist_sn==clear_todolist_sn)
return;
my_clear_todolist_sn=clear_todolist_sn;
todo=({});

foreach(init_items-items,Widget item)
item->clear_todolist();

UPDATE(name);
UPDATE(items);
UPDATE(candidates);
UPDATE(data);
UPDATE(click_cmd);
UPDATE(visible);
UPDATE(width);
UPDATE(height);
UPDATE(width_percent);
UPDATE(height_percent);
UPDATE(width_min);
UPDATE(height_min);
UPDATE(tags);
//UPDATE(key_binding);
UPDATE(scroll_to_bottom);
UPDATE(disabled);
UPDATE(color);
UPDATE(bgcolor);
UPDATE(cursor_pos);

foreach(items,Widget item)
item->clear_todolist();
};/*}}}*/
}

int clear_todolist_sn;

class WidgetType(multiset tags){
}
class PositionType(multiset container_tags,multiset last_tags,multiset next_tags){
}
class RuleType(string type){
}

private void widget2info_heartbeat(mapping m)
{
foreach(m;Widget key;mixed val)
{
if(key->deleted_flag){
m_delete(m,key);
}
}
//gc();
call_out(widget2info_heartbeat,30,m);
}
mapping setup_widget2info(mapping m)
{
m=set_weak_flag(m,Pike.WEAK_INDICES);
call_out(widget2info_heartbeat,30,m);
return m;
}

Widget vertical_separator()/*{{{*/
{
return Widget("vertical_separator",0,({}),0,0,0,([]));
}/*}}}*/
Widget horizontal_separator()/*{{{*/
{
return Widget("horizontal_separator",0,({}),0,0,0,([]));
}/*}}}*/
Widget vertical_panel(array|void items)/*{{{*/
{
if(items==0)
items=({});
items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("vertical_panel",0,items,0,0,0,([]));
}/*}}}*/
Widget horizontal_panel(array|void items)/*{{{*/
{
if(items==0)
items=({});
items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("horizontal_panel",0,items,0,0,0,([]));
}/*}}}*/
Widget focus_panel(Widget w,string|function|array|void click_cmd)/*{{{*/
{
return Widget("focus_panel",0,({w}),0,0,click_cmd,([]));
}/*}}}*/
Widget flow_panel(array items)/*{{{*/
{
items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("flow_panel",0,items,0,0,0,([]));
}/*}}}*/
Widget scroll_panel(Widget|string item,string|function|array|void click_cmd)/*{{{*/
{
array items=({item});
items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("scroll_panel",0,items,0,0,click_cmd,([]));
}/*}}}*/
Widget button(string text,string|function|array click_cmd,string|void data_default)/*{{{*/
{
//array items=({item});
//items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("button",0,({}),0,text,click_cmd,([]),data_default);
}/*}}}*/
Widget voicebutton(string name,string text,string|function|array click_cmd,string|void data_default)/*{{{*/
{
//array items=({item});
//items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("voicebutton",name,({}),0,text,click_cmd,([]),data_default);
}/*}}}*/
Widget htmlbutton(string text,string|function|array click_cmd,string|void data_default)/*{{{*/
{
//array items=({item});
//items=map(items,lambda(mixed d){if(!objectp(d)){return text((string)d);}else{return d;}});
return Widget("htmlbutton",0,({}),0,text,click_cmd,([]),data_default);
}/*}}}*/
Widget text(string data,string|function|array|void click_cmd,string|void data_default)/*{{{*/
{
ASSERT(data);
Widget w=Widget("text",0,({}),0,data,click_cmd,([]),data_default);
ASSERT(w->data);
return w;
}/*}}}*/
Widget image(string url,string|function|array|void click_cmd)/*{{{*/
{
string data=url;
ASSERT(data);
Widget w=Widget("image",0,({}),0,data,click_cmd,([]));
ASSERT(w->data);
return w;
}/*}}}*/
Widget audio(string url,string|function|array|void click_cmd)/*{{{*/
{
string data=url;
ASSERT(data);
Widget w=Widget("audio",0,({}),0,data,click_cmd,([]));
ASSERT(w->data);
return w;
}/*}}}*/
Widget camera(string name)/*{{{*/
{
Widget w=Widget("camera",name,({}),0,0,0,([]));
return w;
}/*}}}*/
Widget html(string data,string|function|array|void click_cmd,string|void data_default)/*{{{*/
{
ASSERT(data);
Widget w=Widget("html",0,({}),0,data,click_cmd,([]),data_default);
ASSERT(w->data);
return w;
}/*}}}*/
Widget textbox(string name,string|void data,int|void is_passwd)/*{{{*/
{
if(data==0)
data="";
if(!is_passwd)
return Widget("textbox",name,({}),0,data,0,([]));
else
return Widget("passwd_textbox",name,({}),0,data,0,([]));
}/*}}}*/
Widget checkbox(string name,int|void checked,multiset|void tags)/*{{{*/
{
return Widget("checkbox",0,({}),0,checked?"1":"0",0,([]))->mark(name,tags);
}/*}}}*/
Widget textarea(string name,string data)/*{{{*/
{
return Widget("textarea",name,({}),0,data,0,([]));
}/*}}}*/
Widget richedit(string name,string data)/*{{{*/
{
return Widget("richedit",name,({}),0,data,0,([]));
}/*}}}*/
Widget dropdown(string name,array candidates,string|void selected)/*{{{*/
{
return Widget("dropdown",name,({}),({""})+candidates,selected||"",0,([]));
}/*}}}*/
Widget listbox(string name,array candidates,string|void selected)/*{{{*/
{
return Widget("listbox",name,({}),({""})+candidates,selected||"",0,([]));
}/*}}}*/
Widget file_upload(string text,string|function|array click_cmd)/*{{{*/
{
return Widget("file_upload",0,({}),0,text,click_cmd,([]));
}/*}}}*/
Widget file_download(string text,string|function|array click_cmd)/*{{{*/
{
return Widget("file_download",0,({}),0,text,click_cmd,([]));
}/*}}}*/
Widget field(string data,string|function|array|void click_cmd,string|void data_default)/*{{{*/
{
return Widget("textbox",0,({}),0,data,click_cmd,([]),data_default)->mark(0,(<"pikecross-Field">))->disable();
}/*}}}*/
Widget frame(string url)/*{{{*/
{
return Widget("frame",0,({}),0,url,0,([]));
}/*}}}*/

Widget space()/*{{{*/
{
return horizontal_panel(({horizontal_panel()}));
}/*}}}*/

Widget panels(array(array) a)/*{{{*/
{
array aa=({});
foreach(a,array items){
aa+=({horizontal_panel(items)});
}
return vertical_panel(aa);
}/*}}}*/
Widget vpanels(array(array) a)/*{{{*/
{
array t=({});
for(int i=0;i<sizeof(a[0]);i++){
t+=({column(a,i)});
}

array aa=({});
foreach(t,array items){
aa+=({vertical_panel(items)});
}

return horizontal_panel(aa);

}/*}}}*/



