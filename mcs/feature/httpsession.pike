MIXIN Session{
/*
mapping q=([]);
string not_query="/";
mapping extra_heads=([]);
mapping request_headers=([]);
string request_type;
*/
	mapping `q(){ werror("Deprecated: use session->request->variables instead.\n");return request->variables; }
	mapping `q=(mapping v){return v;};
	string `not_query(){ werror("Deprecated: use session->request->not_query instead.\n"); return request->not_query; }
	string `not_query=(string v){return v;};
	mapping `extra_heads(){ werror("Deprecated: use session->request->extra_heads instead.\n"); return request->extra_heads; }
	mapping `extra_heads=(mapping v){return v;};
	mapping `request_headers(){ werror("Deprecated: use session->request->request_headers instead.\n"); return request->request_headers; }
	mapping `request_headers=(mapping v){return v;};
	string `request_type(){ werror("Deprecated: use session->request->request_type instead.\n"); return request->request_type; }
	string `request_type=(string v){return v;};
	string `content_type(){ werror("Deprecated: use session->request->content_type instead.\n"); return request->content_type; }
	string `content_type=(string v){return v;};
	string `filename(){ werror("Deprecated: use session->request->filename instead.\n"); return request->filename; }
	string `filename=(string v){return v;};
	void set_content_type(string t)
	{
		request->content_type=t;
	}

	void set_filename(string t)
	{
		request->filename=t;
	}

	mapping request=([]);
}
