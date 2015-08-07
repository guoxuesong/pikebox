# PikeBox

## Features

* Class template and static data
* Multi-class template, AKA MCS.
* Support in-line C/Java code in pike, AKA spear.
* Some useful modules for pike or spear
* Some tools to make coding easier, run box.sh.
* AWLServer embeded in Plone.

## Class template and static data

This feature is designed to handle always-changing project. A always-changing
project is a project:

* you do not have a final design for it,
* you want to change from one idea to another as smoothly as posible,
* you want withdraw your change as smoothly as posible.

How to use this:

* enter PikeBox run "sh box.sh; home;"
* run "vi systems/MyProj.pmod" to create your project named "MyProj"
* edit your project in vim, using class template and static data feature, see below
* run your project with "run MyProj [ARGS]".

Following is how to use class template and static data feature in your code:

* "vi systems/MyProj.pmod" will create a empty project for you

```
#include <class.h>
#define CLASS_HOST "MyProj"
class DynClass{
#include <class_imp.h>
}

class UniqIDStatic{
	class Static{
		int sn;
	};
}

class UniqID{
	int id=++(STATIC(UniqIDStatic)->sn);
}

class MyProjMode{
	class Interface{
	}
	class Default{
	}
}

class MyProj{
	inherit MyProjMode.Interface;
}

object default_program=CLASS(MyProj,MyProjMode.Default);

#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}
```

* do not touch the first 5 lines
* class UniqIDStatic/UniqID is a example showing how to define static data for a class
* use keyword STATIC(ClassA) to reference the static object of the class ClassA, that is defined at ClassA.Static
* class MyProj/MyProjMode is a example showing how to define class template
* use keyword CLASS(BaseCass,ModeClass.FeatureA) to reference a class (return as pike datatype program) inheriting BaseCass and ModeClass.FeatureA
* BaseCass should inherit ModeClass.Interface
* CLASS can accept more than two arguments, the returned program will inherit all of them, and BaseCass should inherit all Interface of them

Following is a example how the idea of a project changes:

* we need a class to count words, wc -w style, this is original idea
* we think, may be, we need count c-string as a word, for example: "a word", this is idea A
* we improve the wc -c idea, count in feed(), improve the performance, this is idea B
* we think the idea A is slow and useless, we want to withdraw the idea A

We handle the changes this way:

* a "wc -w" style count words

```
class CountWords{
	string data="";
	object feed(string s){
		data+=s;
		return this;
	}
	int count(){
		return sizeof(filter(data/" ",sizeof));
	}
}
```

* when the idea A appears, we use class template

```
class CountWordsMode{
	class Interface{
		object feed(string s);
		int count();
	}
	class CountWords{
		string data="";
		object feed(string s){
			data+=s;
			return this;
		}
		int count(){
			return sizeof(filter(data/" ",sizeof));
		}
	}
	class CountWordsA{
		string data="";
		object feed(string s){
			data+=s;
			return this;
		}
		int count(){
			return sizeof(filter(Parser.C.split(data),lambda(string s){
					return sizeof(String.trim_all_whites(s));
					}))
		}
	}
}
class CountWordsBase{
	inherit CountWordsMode.Interface;
}
program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWordsA);
```

* improve wc -w idea, the idea B

```
class CountWordsMode{
	...
	class CountWordsB{
		int n;
		int last_is_space=1;
		object feed(string s){
			array a;
			if(last_is_space){
				a=s/" ";
			}else{
				n--;
				a=("A"+s)/" ";
			}
			n+=sizeof(filter(a,sizeof));
			last_is_space=(sizeof(a[-1])==0);
			return this;
		}
		int count(){
			return n;
		}
	}
	...
}
//program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWordsA);
program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWordsB);
```

* withdraw idea A, just delete CountWordsMode.CountWordsA

Apply idea B on the original idea is simple, but if we want to apply idea B on
idea A, it is complicated. This is a good example showing that some ideas are not
compatable with each other, if we can not withdraw a bad idea, we may need force
the good ones compatable with the bad ones, that is expensive.

And, in the real world, our project may have severy facets, every facet may
have severy ideas, that means the ideas change in severy dimensions.  This is
more complicated.  Using class template feature of PikeBox, we can handle these
multi-dimension changes appropriately. We can try to split the wc example to
two facets: the feed facet and count facet:

```
class CountWordsFeedMode{
	class Interface{
		object feed(string s);
	}
	class CollectFeed{
		string data="";
		object feed(string s){
			data+=s;
			return this;
		}
	}
	class FastFeed{
		int n;
		int last_is_space=1;
		object feed(string s){
			array a;
			if(last_is_space){
				a=s/" ";
			}else{
				n--;
				a=("A"+s)/" ";
			}
			n+=sizeof(filter(a,sizeof));
			last_is_space=(sizeof(a[-1])==0);
			return this;
		}
	}
}
class CountWordsMode{
	class Interface{
		int count();
	}
	class FastCount{
		extern int n;
		int count(){
			return n;
		}
	}
	class CountWords{
		extern string data;
		int count(){
			return sizeof(filter(data/" ",sizeof));
		}
	}
	class CountWordsA{
		extern string data;
		int count(){
			return sizeof(filter(Parser.C.split(data),lambda(string s){
					return sizeof(String.trim_all_whites(s));
					}))
		}
	}
}
class CountWordsBase{
	inherit CountWordsFeedMode.Interface;
	inherit CountWordsMode.Interface;
}
program CountWords0=CLASS(CountWordsBase,CountWordsFeedMode.CollectFeed,CountWordsMode.CountWords);
program CountWordsA=CLASS(CountWordsBase,CountWordsFeedMode.CollectFeed,CountWordsMode.CountWordsA);
program CountWordsB=CLASS(CountWordsBase,CountWordsFeedMode.FastFeed,CountWordsMode.FastCount);
```

Notice CLASS return a program at runtime, that means we can create instance of class template dynamically. Use this feature when you need it.

## MCS

Class template is designed for small project, the source is just one file, and
act as a pike module. MCS is designed for large project. MCS is multi-class
template, that means compare with CLASS using one BaseCass, MCS use severy
base-classes. CLASS apply ideas on the BaseClass, MCS apply features on the
base-classes.

For exmaple, a online system most likely has severy classes like Session,
Player, DataBase ... A feature is some relative ideas about these classes,
these ideas must be applied together, or non of them works. This is a bit like
CountWordsFeedMode.FastFeed and CountWordsMode.FastCount.

For historical reason, MCS not use class template, they are independence. But
since class template impliments a pike module, you can use this module in your
MCS project.

See mcs/lineserver.pike for a example, mcs/awlserver.pike is more useful one.

MCS keywords: IMPORT CLASS ITEM MIXIM

More MCS documents come later.

## AWLServer embedded in Plone

Plone is a great open source CMS system. see http://www.plone.org for more
information.

AWLServer is GWT-enabled http server included in MCS. We provide method to
embed AWLServer into Plone:

* Install Plone from mcs/efun.d/plone.d/Plone-4.1.3-UnifiedInstaller.tgz
* Install Products.windowZ in Plone
* IMPORT(F_PLONE_LOGIN); in awlserver.pike, do not IMPORT(F_LOGIN);
* create this_player.py under Plone site in the Zope management interface

```
# this_player.py
from Products.PythonScripts.standard import html_quote

request = container.REQUEST
response =  request.response

from Products.CMFCore.utils import getToolByName

membership = getToolByName(container, 'portal_membership')
authenticated_user = membership.getAuthenticatedMember().getUserName()

print authenticated_user
return printed
```

* start AWLServer under the same domain of plone site, but with different port.
* create windowZ object in Plone, set the url to http://YOURDOMAIN:AWLPORT/?cmd=MYCMD
* create MYCMD.pike in mcs/bin to handle the request

A step by step howto comes later.
