#line 239 "/home/work/PikeBox/project/bityuan/feature/handle_prototype.pike"
mapping program2prototypes=([]);
mapping program2constants=([]);
mapping program2deprecated=([]);
mapping program2on_create=([]);
mapping program2on_remove=([]);
mapping program2actions=([]);
mapping program2noparam_actions=([]);
void add_prototype(program|multiset m,program p,function|void on_create,function|void on_remove)
{
if(!multisetp(m)){
m=(<m>);
}
foreach(m;program t;int one){
ASSERT(t);
program2prototypes[t]=program2prototypes[t]||({});
if(search(program2prototypes[t],p)<0)
program2prototypes[t]+=({p});
if(on_create){
program2on_create[t]=program2on_create[t]||({});
if(search(program2on_create[t],on_create)<0)
program2on_create[t]+=({on_create});
}
if(on_remove){
program2on_remove[t]=program2on_remove[t]||({});
if(search(program2on_remove[t],on_remove)<0)
program2on_remove[t]+=({on_remove});
}
//werror("add_prototype: %O %O\n",t,program2prototypes[t]);
}
}
void add_constants(program|multiset m,program p)
{
if(!multisetp(m)){
m=(<m>);
}
foreach(m;program t;int one){
ASSERT(t);
program2constants[t]=program2constants[t]||({});
if(search(program2constants[t],p)<0)
program2constants[t]+=({p});
}
}
void add_deprecated(program|multiset m,program p)
{
if(!multisetp(m)){
m=(<m>);
}
foreach(m;program t;int one){
ASSERT(t);
program2deprecated[t]=program2deprecated[t]||({});
if(search(program2deprecated[t],p)<0)
program2deprecated[t]+=({p});
}
}

void add_actions(program|multiset m,mapping p)
{
if(!multisetp(m)){
m=(<m>);
}
foreach(m;program t;int one){
ASSERT(t);
program2actions[t]=program2actions[t]||({});
if(search(program2actions[t],p)<0)
program2actions[t]+=({p});
}
}
void add_noparam_actions(program|multiset m,mapping p)
{
if(!multisetp(m)){
m=(<m>);
}
foreach(m;program t;int one){
ASSERT(t);
program2noparam_actions[t]=program2noparam_actions[t]||({});
if(search(program2noparam_actions[t],p)<0)
program2noparam_actions[t]+=({p});
}
}

