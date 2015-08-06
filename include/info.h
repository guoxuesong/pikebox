#define info(V...) (werror("INFO: "),werror(V))
#ifdef DEBUG
#define debug(V...) (werror("DEBUG: "),werror(V))
#else
#define debug(V...) 
#endif
#define error(V...) (werror("ERROR: "),werror(V))
#define warning(V...) (werror("WARNING: "),werror(V))
