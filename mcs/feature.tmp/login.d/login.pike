#line 199 "/home/work/PikeBox/project/bityuan/feature/login.pike"
string md5passwd(string user)
{
string p=String.string2hex(Crypto.MD5()->update(user+this_app()->md5key)->digest());
return p;
}

