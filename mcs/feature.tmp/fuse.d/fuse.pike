#line 2 "/home/work/PikeBox/project/bityuan/feature/fuse.pike"
#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/
/*{{{*/
#ifndef S_IFMT
#define S_IFMT	0xf000
#endif /* !S_IFMT */
#ifndef S_IFREG
#define S_IFREG	0x8000
#endif /* !S_IFREG */
#ifndef S_IFLNK
#define S_IFLNK	0xA000
#endif /* !S_IFLNK */
#ifndef S_IFDIR
#define S_IFDIR	0x4000
#endif /* !S_IFDIR */
#ifndef S_IFCHR
#define S_IFCHR	0x2000
#endif /* !S_IFCHR */
#ifndef S_IFBLK
#define S_IFBLK	0x6000
#endif /* !S_IFBLK */
#ifndef S_IFIFO
#define S_IFIFO	0x1000
#endif /* !S_IFIFO */
#ifndef S_IFSOCK
#define S_IFSOCK 0xC000
#endif /* !S_IFSOCK */
/*}}}*/

#ifndef ENTER

//#define ENTER(x)
//#define LEAVE()

#else
#define _stdin_session_ this_app()->sessions["stdin"]
#endif



int array_is_dir(array a)/*{{{*/
{
foreach(a,mixed d)
{
if(!mappingp(d)||!stringp(d->_id_))
return 0;
}
return 1;
}/*}}}*/
int is_dir(mixed m)
{
return mappingp(m)&&m->_type_!="symlink"&&m->_type_!="file"||arrayp(m)&&array_is_dir(m);
}

string mixed_to_string(mixed d)/*{{{*/
{
if(stringp(d)){
return d;
}else if(mappingp(d)&&d->_type_=="file"){
return d->_value_||"";
}else{
return sprintf("%O",d);
}
}/*}}}*/
mapping file_open_count=([]);
mapping file_change_flag=([]);
private class Operations
{
inherit Fuse.Operations;
int chmod(string path, int mode){ return System.EROFS; }
int chown(string path, int uid, int gid){ return System.EROFS; }
int fsync(string path, int datasync){}
int readdir(string path, function(string:void) callback)/*{{{*/
{
werror("file_open_count size=%d\n",sizeof(file_open_count));
werror("file_change_flag size=%d\n",sizeof(file_change_flag));
int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(arrayp(m)&&array_is_dir(m)){
callback(".");
callback("..");
foreach(m,mapping mm){
if(mappingp(mm)&&mm->_id_){
string key=mm->_id_;
/*if(key=="/"){
werror("found / in dbase: %O\n",mm);
}*/
callback(key);
}
}
}else if(mappingp(m)&&is_dir(m)){
callback(".");
callback("..");
foreach(indices(m)-({"_id_","_atime_","_ctime_","_mtime_"}),string key){
if(key=="/"){
//werror("found / in dbase: %O\n",m[key]);
}
callback(key);
}
}else{
res=System.ENOENT;
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
Stdio.Stat|int(1..) getattr(string path)/*{{{*/
{
object|int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
//werror("path=%O\n",path);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
//werror("zero_type(m)=%O\n",zero_type(m));
if(!zero_type(m)){
//werror("_typeof(m)=%O\n",_typeof(m));
int t=time();

res=Stdio.Stat();
if(is_dir(m)){
res->mode=0700;
}else{
res->mode=0600;
}
if(!is_dir(m)){
res->size=sizeof(mixed_to_string(m));
}else{
res->size=0;
}
if(mappingp(m)){
res->atime=m->_atime_;
res->mtime=m->_mtime_;
res->ctime=m->_ctime_;
}else{
res->atime=t;
res->mtime=t;
res->ctime=t;
}
res->uid=WORKING_UID;
res->gid=WORKING_GID;
//res->isdir=arrayp(m)||mappingp(m);
//res->isreg=!arrayp(m)&&!mappingp(m);
if(is_dir(m)){
res->mode|=S_IFDIR;
}else if(mappingp(m)&&m->_type_=="symlink"){
res->mode|=S_IFLNK;
}else{
res->mode|=S_IFREG;
}
if(arrayp(m)&&array_is_dir(m))
res->nlink=sizeof(m);
else if(mappingp(m)&&is_dir(m))
res->nlink=sizeof(indices(m)-({"_id_"}));
else
res->nlink=1;
}else{
res=System.ENOENT;
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;

}/*}}}*/
string|int getxattr(string path, string name) { /*{{{*/
string|int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
//werror("name=%s\n",name);
sscanf(name,"user.%s",name);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(!zero_type(m)){
if(name=="type"){
if(arrayp(m)){
res="array";
}else if(mappingp(m)){
res="mapping";
}else if(intp(m)){
res="int";
}else if(stringp(m)){
res="string";
}else if(floatp(m)){
res="float";
}else if(objectp(m)){
res="object";
}else{
res=System.ENODATA;
}
}else if(arrayp(m)){
int pos=(int)name;
if(name!=(string)pos) return System.ENODATA;
if(pos>=0&&pos<sizeof(m)&&mappingp(m[pos])){
res=(string)(m[pos]->_id_);
}else{
res=System.ENODATA;
}
}else if(mappingp(m)){
int pos=(int)name;
array keys=indices(m);
if(sizeof(keys)==0||name!=(string)pos+"."+(string)keys[pos]) return System.ENODATA;
if(pos>=0&&pos<sizeof(m)){
res=(string)keys[pos];
}else{
res=System.ENODATA;
}
}else{
res=System.ENODATA;
}
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int setxattr(string path, string name, string value, int flags) { /*{{{*/
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
sscanf(name,"user.%s",name);
if(m){
if(name=="type"){
if(arrayp(m)&&array_is_dir(m)&&value=="mapping"){
mapping data=([]);
foreach(m;int pos;mapping mm){
if(mm->_id_==0){
res=System.EINVAL;
break;
}
}
if(res==0){
foreach(m;int pos;mapping mm){
data[mm->_id_]=mm;
}
_stdin_session_->dbase_set(GLOBALD,a,data);
}
}else if(mappingp(m)&&value=="array"){
array data=({});
foreach(m;string key;mapping mm){
if(key=="_id_"){
res=System.EINVAL;
break;
}
}
if(res==0){
data=values(m);
array b=map(data,lambda(mapping mm){return mm->_ctime_;});
sort(b,data);
/*foreach(m;string key;mapping mm){
if(key!="_id_")
data+=({mm});
}*/
_stdin_session_->dbase_set(GLOBALD,a,data);
}
}else if(stringp(m)&&value=="int"){
_stdin_session_->dbase_set(GLOBALD,a,(int)m);
}else if(stringp(m)&&value=="float"){
_stdin_session_->dbase_set(GLOBALD,a,(float)m);
}else if((intp(m)||floatp(m))&&value=="string"){
_stdin_session_->dbase_set(GLOBALD,a,(string)m);
}else{
res=System.EINVAL;
}
}else{
if(arrayp(m)){
int pos=(int)name;
if(name!=(string)pos) return System.EINVAL;
if(pos>=0&&pos<sizeof(m)&&mappingp(m[pos])){
m[pos]->_id_=value;
}else{
res=System.EINVAL;
}
}else if(mappingp(m)){
int pos=(int)name;
array keys=indices(m);
if(sizeof(keys)==0||name!=(string)pos+"."+(string)keys[pos]&&name!=(string)pos+"._") return System.EINVAL;
if(pos>=0&&pos<sizeof(m)){
if(value!=""){
if(mappingp(m[keys[pos]]))
m[keys[pos]]->_id_=value;
m[value]=m[keys[pos]];
}
m_delete(m,keys[pos]);
}else{
res=System.EINVAL;
}
}else{
res=System.EINVAL;
}
}
}else{
res=System.ENOENT;
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int removexattr(string path, string name)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
sscanf(name,"user.%s",name);
if(m){
if(name=="type"){
res=System.EINVAL;
}else{
if(arrayp(m)){
int pos=(int)name;
if(name!=(string)pos) return System.EINVAL;
res=System.EINVAL;
}else if(mappingp(m)){
int pos=(int)name;
array keys=indices(m);
if(sizeof(keys)==0||name!=(string)pos+"."+(string)keys[pos]&&name!=(string)pos+"._") return System.EINVAL;
if(pos>=0&&pos<sizeof(m)){
m_delete(m,keys[pos]);
}else{
res=System.EINVAL;
}
}else{
res=System.EINVAL;
}
}
}else{
res=System.ENOENT;
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
array(string)|int listxattr(string path)/*{{{*/
{
array(string)|int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
res=({"user.type"});
if(arrayp(m)){
for(int i=0;i<sizeof(m);i++){
if(mappingp(m[i]))
res+=({"user."+i});
}
}else if(mappingp(m)){
array mm=indices(m);
for(int i=0;i<sizeof(mm);i++){
res+=({"user."+i+"."+(string)mm[i]});
}
}
res+=({""});
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int creat(string path, int mode, int flag)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(m){
res=System.EEXIST;
werror("CREATE %s fail\n",path);
}else{
file_change_flag[path]=1;
int t=time();
_stdin_session_->dbase_set(GLOBALD,a,(["_id_":a[-1],"_type_":"file","_value_":"","value":"","_mtime_":t,"_atime_":t,"_ctime_":t]));
handle_file_change(path,1,0,0,0);
file_open_count[path]++;
werror("CREATE %s succ\n",path);
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int mkdir(string path, int mode)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(m){
res=System.EEXIST;
}else{
int t=time();
_stdin_session_->dbase_set(GLOBALD,a,(["_id_":a[-1],"_mtime_":t,"_atime_":t,"_ctime_":t]));
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
string|int(1..) read(string path, int len, int offset)/*{{{*/
{
werror("file_open_count size=%d\n",sizeof(file_open_count));
werror("file_change_flag size=%d\n",sizeof(file_change_flag));
string|int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(is_dir(m)){
res=System.EISDIR;
}else{
string data=mixed_to_string(m);
res=data[offset..offset+len-1];
if(mappingp(m)){
m->_atime_=time();
}
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;

}/*}}}*/
int rename(string source, string destination)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
foreach(file_open_count;string path;int n){
if(n&&(has_prefix(path,source)||has_prefix(path,destination))){
return System.EBUSY;
}
}
if(has_prefix(destination,source)){
res=System.EINVAL;
}else if(has_prefix(source,destination)){
res=System.ENOTEMPTY;
}
if(res==0){
array a=explode_path(source);
array b=explode_path(destination);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(m){
_stdin_session_->dbase_set(GLOBALD,b,m);
handle_file_change(destination,1,0,0,0);
handle_file_change(source,0,0,1,0);
_stdin_session_->dbase_delete(GLOBALD,a);
/*
foreach(({source,destination}),string path){
file_change_flag[path]=1;
if(file_open_count[path]==0){
if(file_change_flag[path]){
function f=query_file_change_handler(path);
f&&f(explode_path(path));
}
}
}*/
}else{
res=System.ENOENT;
}
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int rmdir(string path)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(is_dir(m)){
_stdin_session_->dbase_delete(GLOBALD,a);
}else if(m){
res=System.ENOTDIR;
}else{
res=System.ENOENT;
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
mapping(string:int) statfs(string path)/*{{{*/
{
return filesystem_stat(path);
}/*}}}*/
int truncate(string path, int new_length)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
if(new_length<0)
res=System.EINVAL;
if(res==0){
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(is_dir(m)){
res=System.EISDIR;
}else if(stringp(m)){
if(new_length<sizeof(m)){
m=m[..new_length-1];
}else{
m=m+"\0"*(new_length-sizeof(m));
}
_stdin_session_->dbase_set(GLOBALD,a,m);
file_change_flag[path]=1;
}else if(mappingp(m)&&m->_type_=="file"){
if(new_length<sizeof(m->_value_||"")){
m->_value_=m->_value_[..new_length-1];
}else{
m->_value_=m->_value_+"\0"*(new_length-sizeof(m->_value_));
}
file_change_flag[path]=1;
m->_ctime_=m->_mtime_=time();
}else{
res=System.EINVAL;
}
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int unlink(string path)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(zero_type(m)){
res=System.ENOENT;
}else if(is_dir(m)){
res=System.EISDIR;
}else{
handle_file_change(path,0,0,1,0);
file_change_flag[path]=0;
_stdin_session_->dbase_delete(GLOBALD,a);
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int write(string path, string data, int offset)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
werror("WRITE a=%O\n",a);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
werror("BEFORE write %O\n",m);

if(stringp(m)){
file_change_flag[path]=1;
int i,j;
for(i=offset,j=0;i<sizeof(m)&&j<sizeof(data);i++,j++){
m[i]=data[j];
}
if(j<sizeof(data)){
m+=data[j..];
}
_stdin_session_->dbase_set(GLOBALD,a,m);
res=-sizeof(data);
}else if(mappingp(m)&&m->_type_=="file"){
file_change_flag[path]=1;
int i,j;
for(i=offset,j=0;i<sizeof(m->_value_)&&j<sizeof(data);i++,j++){
m->_value_[i]=data[j];
}
if(j<sizeof(data)){
m->_value_+=data[j..];
}
//_stdin_session_->dbase_set(GLOBALD,a,m);
res=-sizeof(data);
m->_ctime_=m->_mtime_=time();
}else{
werror("DEBUG:m=%O",m);
res=System.EINVAL;
}
werror("AFTER write %O\n",m);
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int symlink(string source, string destination)/*{{{*/
{
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(destination);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(m){
res=System.EEXIST;
}else{
_stdin_session_->dbase_set(GLOBALD,a,([ "_id_":basename(destination),
"_type_":"symlink",
"_target_":source,
]));
werror("symlink: source=%s\n",source);
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;

}/*}}}*/
string|int(1..) readlink(string path)/*{{{*/
{
string|int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
//werror("a=%O\n",a);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
//werror("m=%O\n",m);
if(m){
if(m->_type_=="symlink"){
res=m->_target_;
}else{
res=System.EINVAL;
}
}else{
res=System.ENOENT;
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
werror("readlink: res=%O\n",res);
return res;

}/*}}}*/

int utime(string path, int atime, int mtime){/*{{{*/
int res;
object lock=GLOBALD->mutex->lock();
cache_end();
mixed e=catch{ ENTER(_stdin_session_);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(m){
m->_atime_=atime;
m->_mtime_=mtime;
}else{
res=System.ENOENT;
}
LEAVE();};
cache_begin();
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int flush(string path, int flags){ }
int release(string path){ /*{{{*/
int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
//werror("path=%s\n",path);
file_open_count[path]--;
werror("RELEASE %s succ %d %d\n",path,file_open_count[path],file_change_flag[path]);
if(file_open_count[path]==0){
if(file_change_flag[path]){
cache_end();
mixed e=catch{
handle_file_change(path,0,0,0,0);
};
if(e){
master()->handle_error(e);
}
cache_begin();
}
}
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
int open(string path, int mode){ /*{{{*/
werror("OPEN %s\n",path);
int res;
object lock=GLOBALD->mutex->lock();
mixed e=catch{ ENTER(_stdin_session_);
//werror("path=%s\n",path);
array a=explode_path(path);
mixed m=_stdin_session_->dbase_query(GLOBALD,a);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
if(file_open_count[path]==0){
file_change_flag[path]=0;
if(mappingp(m)&&m->_type_=="file"){
m->_value_=m->value;
}
}
if(mappingp(m)&&m->_type_=="file"){
m->_atime_=time();
if(mode&O_WRONLY||mode&O_RDWR){
file_change_flag[path]=1;
//m->_mtime_=m->_atime_;
}
}
file_open_count[path]++;
werror("OPEN %s succ\n",path);
LEAVE();};
if(e){
master()->handle_error(e);
}
destruct(lock);
return res;
}/*}}}*/
}

void handle_file_change(string path,int set_from,string from,int set_to,string to)
{
array a=explode_path(path);
werror("handle_file_change: a=%O\n",a);
object ob;
mixed m=ob=_stdin_session_->dbase_query(GLOBALD,a);
werror("DEBUG3: m0=%O\n",m);
if(objectp(m)&&m->is_dbase){
m=m->data;
}
werror("DEBUG3: m=%O\n",m);
if(mappingp(m)&&m->_type_=="file"){
if(set_from){
m->value=from;
}
if(set_to){
m->_value_=to;
}
string str=m->_handle_file_change_;
if(str){
object f=Func(@(str/"."));
int err;
if(ob)
err=f(ob);
else{
err=f(a[-1],m,GLOBALD,a[..<1]);
}
if(err){
m->_value_=m->value;
}else{
m->value=m->_value_;
m->_mtime_=m->_atime_;
}
}else{
m->value=m->_value_;
m->_mtime_=m->_atime_;
}
}
}

/*
mapping file_change_handlers=([]);

void register_file_change_handler(array dir,function f)
{
file_change_handlers[combine_path_unix(@dir)]=f;
}

function query_file_change_handler(string file)
{
werror("file=%O\n",file);
while(file!="/"&&file_change_handlers[file]==0){
file=dirname(file);
//werror("file=%O\n",file);
}

return file_change_handlers[file];
}

*/

void create()
{
werror("Info: fused setup\n");
//::create();
#ifndef __NT__
Process.system("umount var/globald");

Thread.Thread(Fuse.run,Operations(),({"fuse.pike","var/globald",
"-d",
"-f","-o","default_permissions,allow_other"}));
#endif
}


