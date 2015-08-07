# PikeBox

## Features

* Class template and static data
* Some useful modules for pike
* Support in-line C/Java code in pike, AKA spear.
* Multi-class template, AKA MCS.
* Some tools to make coding easier, run box.sh.

## Class template and static data

This feature is designed to handle always-changing project. A always-changing
project is a project:

* always changes,
* you do not have a final design for it,
* you want to change from one idea to another as smoothly as posible,
* you want withdraw your change as smoothly as posible.

How to do this:

* enter PikeBox run "sh box.sh; home;"
* run "vi systems/MyProj.pmod" to create your project named "MyProj"
* edit your project in vim, using class template and static data feature
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

* donnot touch the first 5 lines
* class UniqIDStatic/UniqID is a example showing how to define static data for a class
* use keyword STATIC(ClassA) to reference the static object of the class ClassA, that is defined at ClassA.Static
* class MyProj/MyProjMode is a example showing how to define class template
* use keyword CLASS(BaseCass,ModeClass.FeatureA) to reference a class (as pike program) inheriting BaseCass and ModeClass.FeatureA
* BaseCass should inherit ModeClass.Interface
* CLASS can accept more than two arguments, the returned program will inherit all of them, and BaseCass should inherit all Interface of them

Following is a example how the idea of a project changes:

* we need a class to count words, wc -w style, this is original idea
* we found out, may be, we need count c-string as a word, for example: "a word"
* we think the above idea is slow and useless, we want to withdraw the last change

We handle the changes this way:

* a "wc -w" style count words

```
class CountWords{
	string data="";
	int n;
	object feed(string s){
		data+=s;
		return this;
	}
	int count(){
		return sizeof(filter(data/" ",sizeof));
	}
}
```

* when the second idea appears, we use class template

```
class CountWordsMode{
	class Interface{
		object feed(string s);
		int count();
	}
	class CountWords{
		string data="";
		int n;
		object feed(string s){
			data+=s;
			return this;
		}
		int count(){
			return sizeof(filter(data/" ",sizeof));
		}
	}
	class CountWords2{
		string data="";
		int n;
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
program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWords2);
```

* withdraw the second idea

```
//program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWords2);
program CountWords=CLASS(CountWordsBase,CountWordsMode.CountWords);
```

This example is simple. In the real world, we may have severy facets, every
facet may have severy ideas, that is the ideas change in severy dimensions,
this is complicated. Using PikeBox we can handle this changes
appropriately.

