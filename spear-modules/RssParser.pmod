#pike __REAL_VERSION__

#define CC_USE_VARS() {Cross.INCLUDE(cc_var_include);Cross.CC(cc_var_cc);}

//! RssParser
//! Use PikeCross to access libmrss
//! To learn howto use it, just create a object ob=RssParser.RssParser("http://news.google.com/news?pz=1&ned=us&hl=en&output=rss") and check the indices(ob)
class RssParser{/*{{{*/

  string file;
  int size;
  string encoding;

  string version;
  //mrss_version_t version;      /* 0.91 0.92    1.0     2.0     ATOM    */

  string title;                  /* R    R       R       R       R       */
  string title_type;             /* -    -       -       -       O       */
  string description;            /* R    R       R       R       R       */
  string description_type;       /* -    -       -       -       O       */
  string link;                   /* R    R       R       R       O       */
  string id;                     /* -    -       -       -       O       */
  string language;               /* R    O       -       O       O       */
  string rating;                 /* O    O       -       O       -       */
  string copyright;              /* O    O       -       O       O       */
  string copyright_type;         /* -    -       -       -       O       */
  string pubDate;                /* O    O       -       O       -       */
  string lastBuildDate;          /* O    O       -       O       O       */
  string docs;                   /* O    O       -       O       -       */
  string managingeditor;         /* O    O       -       O       O       */
  string managingeditor_email;   /* O    O       -       O       O       */
  string managingeditor_uri;     /* O    O       -       O       O       */
  string webMaster;              /* O    O       -       O       -       */
  int ttl;                       /* -    -       -       O       -       */
  string about;                  /* -    -       R       -       -       */

  /* Contributor */              /* -    -       -       -       O       */
  string contributor;            /* -    -       -       -       R       */
  string contributor_email;      /* -    -       -       -       O       */
  string contributor_uri;        /* -    -       -       -       O       */

  /* Generator */
  string generator;              /* -    -       -       O       O       */
  string generator_uri;          /* -    -       -       -       O       */
  string generator_version;      /* -    -       -       -       O       */

  /* Tag Image: */               /* O    O       O       O       -       */
  string image_title;            /* R    R       R       R       -       */
  string image_url;              /* R    R       R       R       O       */
  string image_logo;             /* -    -       -       -       O       */
  string image_link;             /* R    R       R       R       -       */
  int image_width;               /* O    O       -       O       -       */
  int image_height;              /* O    O       -       O       -       */
  string image_description;      /* O    O       -       O       -       */

  /* TextInput: */               /* O    O       O       O       -       */
  string textinput_title;        /* R    R       R       R       -       */
  string textinput_description;  /* R    R       R       R       -       */
  string textinput_name;         /* R    R       R       R       -       */
  string textinput_link;         /* R    R       R       R       -       */

  /* Cloud */
  string cloud;                  /* -    O       -       O       -       */
  string cloud_domain;           /* -    R       -       R       -       */
  int cloud_port;                /* -    R       -       R       -       */
  string cloud_path;             /* -    R       -       R       -       */
  string cloud_registerProcedure;/* -    R       -       R       -       */
  string cloud_protocol;         /* -    R       -       R       -       */

  array skipHours=({});
//  mrss_hour_t *skipHours;       /* O    O       -       O       -       */
  array skipDays=({});
//  mrss_day_t *skipDays;         /* O    O       -       O       -       */

//  mrss_category_t *category;    /* -    O       -       O       O       */
  array category_and_domain=({});

//  mrss_item_t *item;            /* R    R       R       R       R       */

//  mrss_tag_t *other_tags;

  mapping other_tags;


  array items=({});

//  				/* 0.91	0.92	1.0	2.0	ATOM	*/
//  char *title;		/* R	O	O	O	R	*/
//  char *title_type;		/* -	-	-	-	O	*/
//  char *link;			/* R	O	O	O	O	*/
//  char *description;		/* R	O	-	O	O	*/
//  char *description_type;	/* -	-	-	-	0	*/
//  char *copyright;		/* -	-	-	-	O	*/
//  char *copyright_type;	/* -	-	-	-	O	*/
//  
//  char *author;		/* -	-	-	O	O	*/
//  char *author_uri;		/* -	-	-	-	O	*/
//  char *author_email;		/* -	-	-	-	O	*/
//
//  char *contributor;		/* -	-	-	-	O	*/
//  char *contributor_uri;	/* -	-	-	-	O	*/
//  char *contributor_email;	/* -	-	-	-	O	*/
//
//  char *comments;		/* -	-	-	O	-	*/
//  char *pubDate;		/* -	-	-	O	O	*/
//  char *guid;			/* -	-	-	O	O	*/
//  int guid_isPermaLink;	/* -	-	-	O	-	*/
//
//  char *source;		/* -	O	-	O	-	*/
//  char *source_url;		/* -	R	-	R	-	*/
//
//  char *enclosure;		/* -	O	-	O	-	*/
//  char *enclosure_url;	/* -	R	-	R	-	*/
//  int enclosure_length;	/* -	R	-	R	-	*/
//  char *enclosure_type;	/* -	R	-	R	-	*/
//
//  mrss_category_t *category;	/* -	O	-	O	O	*/
  

  constant cc_var_cc="gcc -g -shared -lmrss -fPIC";
  constant cc_var_include=
	  "#include <string.h>\n"
	  "#include <mrss.h>\n"
	  ;
	
  private mapping mrss_tag_t2mapping(int tag_ptr)
  {
	  mapping res=([]);
	  CC_USE_VARS();
	  C{
		  mrss_tag_t *tag=(mrss_tag_t *)INT{tag_ptr};
		  mrss_attribute_t *attribute;
		  int i;
		  while(tag){
			  P{res["name"]=STRING{tag->name};}
			  P{res["value"]=STRING{tag->value};}
			  P{res["ns"]=STRING{tag->ns};}
			  if (tag->children){
				  P{res["children"]=mrss_tag_t2mapping(INT{tag->children});}
			  }
			  P{res["attributes"]=([]);}
			  for (attribute = tag->attributes; attribute;
					  attribute = attribute->next)
			  {

				  P{res["attributes"]["name"]=STRING{attribute->name};}
				  P{res["attributes"]["value"]=STRING{attribute->value};}
				  P{res["attributes"]["ns"]=STRING{attribute->ns};}
			  }
			  tag = tag->next;
		  }
	  }
	  return res;
  }

  //! @decl void create(string url_or_filename);
	void create(string url)
	{
		CC_USE_VARS();
		string err;
		C{
			char* url=STRING{url};
			mrss_t *data;
			mrss_error_t ret;
			mrss_hour_t *hour;
			mrss_day_t *day;
			mrss_category_t *category;
			mrss_item_t *item;
			CURLcode code;
			if (!strncmp (url, "http://", 7) || !strncmp (url, "https://", 8))
				ret = mrss_parse_url_with_options_and_error (url, &data, NULL, &code);
			else
				ret = mrss_parse_file (url, &data);

			if (ret)
			{
				fprintf (stderr, "MRSS return error: %s\n",
						ret ==
						MRSS_ERR_DOWNLOAD ? mrss_curl_strerror (code) :
						mrss_strerror (ret));
				P{err=STRING{ret ==
						MRSS_ERR_DOWNLOAD ? mrss_curl_strerror (code) :
						mrss_strerror (ret)};}
				return 1;
			}
				P{file=STRING{data->file};}
				P{size=INT{data->size};}
				P{encoding=STRING{data->encoding};}
				P{title=STRING{data->title};}
				P{title_type=STRING{data->title_type};}
				P{description=STRING{data->description};}
				P{description_type=STRING{data->description_type};}
				P{link=STRING{data->link};}
				P{id=STRING{data->id};}
				P{language=STRING{data->language};}
				P{rating=STRING{data->rating};}
				P{copyright=STRING{data->copyright};}
				P{copyright_type=STRING{data->copyright_type};}
				P{pubDate=STRING{data->pubDate};}
				P{lastBuildDate=STRING{data->lastBuildDate};}
				P{docs=STRING{data->docs};}
				P{managingeditor=STRING{data->managingeditor};}
				P{managingeditor_email=STRING{data->managingeditor_email};}
				P{managingeditor_uri=STRING{data->managingeditor_uri};}
				P{webMaster=STRING{data->webMaster};}
				P{ttl=INT{data->ttl};}
				P{about=STRING{data->about};}
				P{contributor=STRING{data->contributor};}
				P{contributor_email=STRING{data->contributor_email};}
				P{contributor_uri=STRING{data->contributor_uri};}
				P{generator=STRING{data->generator};}
				P{generator_uri=STRING{data->generator_uri};}
				P{generator_version=STRING{data->generator_version};}
				P{image_title=STRING{data->image_title};}
				P{image_url=STRING{data->image_url};}
				P{image_logo=STRING{data->image_logo};}
				P{image_link=STRING{data->image_link};}
				P{image_width=INT{data->image_width};}
				P{image_height=INT{data->image_height};}
				P{image_description=STRING{data->image_description};}
				P{textinput_title=STRING{data->textinput_title};}
				P{textinput_description=STRING{data->textinput_description};}
				P{textinput_name=STRING{data->textinput_name};}
				P{textinput_link=STRING{data->textinput_link};}
				P{cloud=STRING{data->cloud};}
				P{cloud_domain=STRING{data->cloud_domain};}
				P{cloud_port=INT{data->cloud_port};}
				P{cloud_path=STRING{data->cloud_path};}
				P{cloud_registerProcedure=STRING{data->cloud_registerProcedure};}
				P{cloud_protocol=STRING{data->cloud_protocol};}
			P{
			version=([
					INT{MRSS_VERSION_0_91}:            "0.91 RSS",
					INT{MRSS_VERSION_0_92}:            "0.92 RSS",
					INT{MRSS_VERSION_1_0}:             "1.0 RSS",
					INT{MRSS_VERSION_2_0}:             "2.0 RSS",
					INT{MRSS_VERSION_ATOM_0_3}:        "0.3 Atom",
					INT{MRSS_VERSION_ATOM_1_0}:        "1.0 Atom",
					])[INT{data->version}];
			}

			
			hour = data->skipHours;
			while (hour)
			{
				P{skipHours+=({STRING{hour->hour}});};
				hour = hour->next;
			}

			day = data->skipDays;
			while (day)
			{
				P{skipDays+=({STRING{day->day}});};
				day = day->next;
			}
			category = data->category;
			while (category)
			{
				P{category_and_domain+=({({STRING{category->category},STRING{category->domain}})});};
				category = category->next;
			}
			P{other_tags=mrss_tag_t2mapping(INT{data->other_tags});}
			
			
			item = data->item;
			while (item)
			{
				P{
					int item_ptr=INT{item};
					mapping m=([
							"title": STRING{item->title},
						"link": STRING{item->link},
						"description": STRING{item->description},
						"author": STRING{item->author},
						"comments": STRING{item->comments},
						"pubDate": STRING{item->pubDate},
						"guid": STRING{item->guid},
						"guid_notPermaLink": INT{item->guid_isPermaLink},//it is notPermaLink actually
						"source": STRING{item->source},
						"source_url": STRING{item->source_url},
						"enclosure": STRING{item->enclosure},
						"enclosure_url": STRING{item->enclosure_url},
						"enclosure_length": INT{item->enclosure_length},
						"enclosure_type": STRING{item->enclosure_type},
						]);

					array category_and_domain=({});
					CC_USE_VARS();
					C{
						mrss_item_t *item=(mrss_item_t *)INT{item_ptr};
						mrss_category_t *category;
						category = item->category;
						while (category)
						{
							P{category_and_domain+=({({STRING{category->category},STRING{category->domain}})});};
							category = category->next;
						}
					}
					m["category_and_domain"]=category_and_domain;
					m["other_tags"]=mrss_tag_t2mapping(INT{item->other_tags});

					items+=({m});
				}

				//if (item->other_tags)
					//print_tags (item->other_tags, 1);

				item = item->next;
			}
			
			
			mrss_free (data);
			
		}
		if(err)
			throw(({sprintf("ERROR: %s\n",err),backtrace()}));
	}
}/*}}}*/
